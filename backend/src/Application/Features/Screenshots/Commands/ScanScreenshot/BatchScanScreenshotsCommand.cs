using FluentValidation;
using MediatR;
using AutoMapper;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;
using AI.ScreenshotOrganizer.Shared.Helpers;

namespace AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.BatchScan;

public record BatchScanScreenshotsCommand(List<ScanScreenshotRequestDto> Items) : IRequest<BatchScanResponseDto>;

public class BatchScanScreenshotsCommandValidator : AbstractValidator<BatchScanScreenshotsCommand>
{
    public BatchScanScreenshotsCommandValidator()
    {
        RuleFor(v => v.Items).NotNull().WithMessage("Items list is required.");
    }
}

public class BatchScanScreenshotsCommandHandler : IRequestHandler<BatchScanScreenshotsCommand, BatchScanResponseDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IAIClassificationService _aiClassificationService;
    private readonly IMapper _mapper;

    public BatchScanScreenshotsCommandHandler(
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

    public async Task<BatchScanResponseDto> Handle(BatchScanScreenshotsCommand request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException("Authenticated user required.");
        var response = new BatchScanResponseDto();

        foreach (var req in request.Items)
        {
            try
            {
                var assetId = !string.IsNullOrEmpty(req.DeviceAssetId) ? req.DeviceAssetId : req.ImageId;
                if (string.IsNullOrEmpty(assetId))
                {
                    response.Errors.Add("Skipping item with missing device_asset_id.");
                    continue;
                }

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

                if (req.IsFavorite.HasValue) screenshot.IsFavorite = req.IsFavorite.Value;
                if (req.IsReviewed.HasValue) screenshot.IsReviewed = req.IsReviewed.Value;

                if (!string.IsNullOrWhiteSpace(req.OCRText))
                {
                    screenshot.OCRStatus = "completed";
                }

                // Auto classification into Category & Subcategory folders
                if ((req.AutoClassify ?? true) && (isNew || screenshot.CategoryId == null))
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
                        screenshot.Category = category;

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
                            screenshot.SubCategory = subCat;
                        }

                        if (classification.Tags != null)
                        {
                            foreach (var tagName in classification.Tags)
                            {
                                var tag = await _unitOfWork.Tags.GetByNameAsync(tagName, userId, cancellationToken);
                                if (tag == null)
                                {
                                    tag = new Tag
                                    {
                                        Id = Guid.NewGuid(),
                                        Name = tagName,
                                        UserId = userId,
                                        CreatedDate = DateTime.UtcNow
                                    };
                                    await _unitOfWork.Tags.AddAsync(tag, cancellationToken);
                                }
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
                    }
                }

                if (isNew)
                {
                    await _unitOfWork.Screenshots.AddAsync(screenshot, cancellationToken);
                }
                else
                {
                    _unitOfWork.Screenshots.Update(screenshot);
                }

                response.UpsertedCount++;
                response.ProcessedCount++;
                response.Screenshots.Add(_mapper.Map<ScreenshotDto>(screenshot));
            }
            catch (Exception ex)
            {
                response.Errors.Add($"Error processing item: {ex.Message}");
            }
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return response;
    }
}
