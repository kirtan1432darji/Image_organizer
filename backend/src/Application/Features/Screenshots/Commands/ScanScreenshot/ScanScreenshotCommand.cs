using FluentValidation;
using MediatR;
using AutoMapper;
using System.Text.Json;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;
using AI.ScreenshotOrganizer.Shared.Helpers;

namespace AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.ScanScreenshot;

public record ScanScreenshotCommand(ScanScreenshotRequestDto Request) : IRequest<ScreenshotDto>;

public class ScanScreenshotCommandValidator : AbstractValidator<ScanScreenshotCommand>
{
    public ScanScreenshotCommandValidator()
    {
        RuleFor(v => v.Request).NotNull().WithMessage("Request is required.");
        RuleFor(v => v.Request)
            .Must(r => !string.IsNullOrEmpty(r.DeviceAssetId) || !string.IsNullOrEmpty(r.ImageId))
            .WithMessage("Either device_asset_id or image_id must be provided.");
    }
}

public class ScanScreenshotCommandHandler : IRequestHandler<ScanScreenshotCommand, ScreenshotDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IAIClassificationService _aiClassificationService;
    private readonly IMapper _mapper;

    public ScanScreenshotCommandHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IAIClassificationService aiClassificationService,
        IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _aiClassificationService = aiClassificationService;
        _mapper = mapper;
    }

    public async Task<ScreenshotDto> Handle(ScanScreenshotCommand request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException("Authenticated user is required to scan screenshots.");
        var req = request.Request;

        var assetId = !string.IsNullOrEmpty(req.DeviceAssetId) ? req.DeviceAssetId : req.ImageId!;
        var imagePath = req.ImagePath ?? req.FilePath ?? string.Empty;
        var fileName = !string.IsNullOrEmpty(req.FileName) ? req.FileName : System.IO.Path.GetFileName(imagePath);
        var capturedDate = req.CapturedDate ?? req.CreatedAt ?? DateTime.UtcNow;

        var hash = !string.IsNullOrEmpty(req.Hash) 
            ? req.Hash 
            : HashHelper.ComputeSha256Hash($"{assetId}_{req.Width}_{req.Height}_{capturedDate:O}");

        var existing = await _unitOfWork.Screenshots.GetByDeviceAssetIdAsync(assetId, userId, cancellationToken);
        var isNew = existing == null;

        var screenshot = existing ?? new Screenshot
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            DeviceAssetId = assetId,
            ImageId = assetId,
            CreatedDate = DateTime.UtcNow
        };

        screenshot.ImagePath = imagePath;
        screenshot.ThumbnailPath = req.ThumbnailPath ?? screenshot.ThumbnailPath;
        screenshot.FileName = fileName;
        screenshot.FileSize = req.FileSize > 0 ? req.FileSize : screenshot.FileSize;
        screenshot.ContentUri = req.ContentUri ?? screenshot.ContentUri;
        screenshot.CapturedDate = capturedDate;
        screenshot.SourceApp = req.SourceApp ?? screenshot.SourceApp ?? string.Empty;
        screenshot.Width = req.Width > 0 ? req.Width : screenshot.Width;
        screenshot.Height = req.Height > 0 ? req.Height : screenshot.Height;
        screenshot.OCRText = req.OCRText ?? screenshot.OCRText ?? string.Empty;
        screenshot.VisionDescription = req.VisionDescription ?? screenshot.VisionDescription;
        screenshot.Hash = hash;
        screenshot.LastScannedAt = DateTime.UtcNow;
        screenshot.UpdatedDate = DateTime.UtcNow;
        screenshot.IsMock = req.IsMock ?? false;

        if (req.IsFavorite.HasValue)
        {
            screenshot.IsFavorite = req.IsFavorite.Value;
        }

        if (req.IsReviewed.HasValue)
        {
            screenshot.IsReviewed = req.IsReviewed.Value;
        }

        if (!string.IsNullOrWhiteSpace(req.OCRText))
        {
            screenshot.OCRStatus = "completed";
            if (screenshot.OCRCache == null)
            {
                screenshot.OCRCache = new OCRCache
                {
                    Id = Guid.NewGuid(),
                    ScreenshotId = screenshot.Id,
                    OCRText = req.OCRText,
                    Language = "en",
                    Confidence = 0.95,
                    CreatedDate = DateTime.UtcNow
                };
            }
            else
            {
                screenshot.OCRCache.OCRText = req.OCRText;
                screenshot.OCRCache.UpdatedDate = DateTime.UtcNow;
            }
        }

        // Auto classification if requested
        if ((req.AutoClassify ?? true) && (isNew || string.IsNullOrEmpty(screenshot.OCRText) || screenshot.CategoryId == null))
        {
            var classification = await _aiClassificationService.ClassifyScreenshotAsync(new ClassifyScreenshotRequestDto
            {
                ScreenshotId = screenshot.Id.ToString(),
                FileName = fileName,
                OCRText = screenshot.OCRText,
                VisionDescription = screenshot.VisionDescription,
                SourceApp = screenshot.SourceApp
            }, cancellationToken);

            screenshot.Confidence = classification.Confidence;
            screenshot.IsReviewed = classification.Confidence >= 0.85;

            // Resolve or create Category
            if (!string.IsNullOrEmpty(classification.Category))
            {
                var category = await _unitOfWork.Categories.GetByNameAsync(classification.Category, userId, cancellationToken);
                if (category == null)
                {
                    category = new Category
                    {
                        Id = Guid.NewGuid(),
                        Name = classification.Category,
                        UserId = userId,
                        CreatedByAI = true,
                        CreatedDate = DateTime.UtcNow
                    };
                    await _unitOfWork.Categories.AddAsync(category, cancellationToken);
                }
                screenshot.CategoryId = category.Id;

                if (!screenshot.ScreenshotCategories.Any(sc => sc.CategoryId == category.Id))
                {
                    screenshot.ScreenshotCategories.Add(new ScreenshotCategory
                    {
                        ScreenshotId = screenshot.Id,
                        CategoryId = category.Id
                    });
                }

                // Resolve subcategory
                if (!string.IsNullOrEmpty(classification.SubCategory))
                {
                    var subCat = await _unitOfWork.Categories.GetByNameAsync(classification.SubCategory, userId, cancellationToken);
                    if (subCat == null)
                    {
                        subCat = new Category
                        {
                            Id = Guid.NewGuid(),
                            Name = classification.SubCategory,
                            ParentCategoryId = category.Id,
                            UserId = userId,
                            CreatedByAI = true,
                            CreatedDate = DateTime.UtcNow
                        };
                        await _unitOfWork.Categories.AddAsync(subCat, cancellationToken);
                    }
                    screenshot.SubCategoryId = subCat.Id;
                }
            }

            // Resolve tags
            if (classification.Tags.Any())
            {
                var tags = await _unitOfWork.Tags.GetOrCreateTagsAsync(classification.Tags, userId, cancellationToken);
                foreach (var tag in tags)
                {
                    if (!screenshot.ScreenshotTags.Any(st => st.TagId == tag.Id))
                    {
                        screenshot.ScreenshotTags.Add(new ScreenshotTag
                        {
                            ScreenshotId = screenshot.Id,
                            TagId = tag.Id
                        });
                    }
                }
            }

            screenshot.ClassificationHistories.Add(new ClassificationHistory
            {
                Id = Guid.NewGuid(),
                ScreenshotId = screenshot.Id,
                Category = classification.Category,
                SubCategory = classification.SubCategory,
                TagsJson = JsonSerializer.Serialize(classification.Tags),
                Confidence = classification.Confidence,
                ModelName = classification.ModelName,
                CreatedDate = DateTime.UtcNow
            });
        }

        if (isNew)
        {
            await _unitOfWork.Screenshots.AddAsync(screenshot, cancellationToken);
        }
        else
        {
            _unitOfWork.Screenshots.Update(screenshot);
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var result = await _unitOfWork.Screenshots.GetWithDetailsByIdAsync(screenshot.Id, userId, cancellationToken);
        return _mapper.Map<ScreenshotDto>(result ?? screenshot);
    }
}
