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
        RuleFor(v => v.Request.ImageId).NotEmpty().WithMessage("ImageId is required.");
        RuleFor(v => v.Request.ImagePath).NotEmpty().WithMessage("ImagePath is required.");
        RuleFor(v => v.Request.CapturedDate).NotEmpty().WithMessage("CapturedDate is required.");
        RuleFor(v => v.Request.Width).GreaterThanOrEqualTo(0).WithMessage("Width must be non-negative.");
        RuleFor(v => v.Request.Height).GreaterThanOrEqualTo(0).WithMessage("Height must be non-negative.");
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
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var req = request.Request;

        var existing = await _unitOfWork.Screenshots.GetByImageIdAsync(req.ImageId, userId, cancellationToken);
        if (existing != null)
        {
            return _mapper.Map<ScreenshotDto>(existing);
        }

        var hash = !string.IsNullOrEmpty(req.Hash) 
            ? req.Hash 
            : HashHelper.ComputeSha256Hash($"{req.ImageId}_{req.Width}_{req.Height}_{req.CapturedDate:O}");

        var screenshot = new Screenshot
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ImageId = req.ImageId,
            ImagePath = req.ImagePath,
            ThumbnailPath = req.ThumbnailPath,
            CapturedDate = req.CapturedDate,
            SourceApp = req.SourceApp ?? string.Empty,
            Width = req.Width,
            Height = req.Height,
            OCRText = req.OCRText ?? string.Empty,
            VisionDescription = req.VisionDescription,
            Hash = hash,
            CreatedDate = DateTime.UtcNow
        };

        // Cache OCR
        if (!string.IsNullOrWhiteSpace(req.OCRText))
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

        // AI Classification if enabled
        if (req.AutoClassify ?? true)
        {
            var classification = await _aiClassificationService.ClassifyScreenshotAsync(new ClassifyScreenshotRequestDto
            {
                OCRText = req.OCRText ?? string.Empty,
                VisionDescription = req.VisionDescription,
                SourceApp = req.SourceApp ?? string.Empty
            }, cancellationToken);

            screenshot.Confidence = classification.Confidence;

            // Resolve or Create Category
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
                screenshot.ScreenshotCategories.Add(new ScreenshotCategory
                {
                    ScreenshotId = screenshot.Id,
                    CategoryId = category.Id
                });

                // Resolve SubCategory if present
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

            // Resolve Tags
            if (classification.Tags.Any())
            {
                var tags = await _unitOfWork.Tags.GetOrCreateTagsAsync(classification.Tags, userId, cancellationToken);
                foreach (var tag in tags)
                {
                    screenshot.ScreenshotTags.Add(new ScreenshotTag
                    {
                        ScreenshotId = screenshot.Id,
                        TagId = tag.Id
                    });
                }
            }

            // Save Classification History
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

        await _unitOfWork.Screenshots.AddAsync(screenshot, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var result = await _unitOfWork.Screenshots.GetWithDetailsByIdAsync(screenshot.Id, userId, cancellationToken);
        return _mapper.Map<ScreenshotDto>(result ?? screenshot);
    }
}
