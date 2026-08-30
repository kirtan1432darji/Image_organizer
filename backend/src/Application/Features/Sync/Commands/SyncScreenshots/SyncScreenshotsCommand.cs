using FluentValidation;
using MediatR;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Sync.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;
using AI.ScreenshotOrganizer.Shared.Helpers;

namespace AI.ScreenshotOrganizer.Application.Features.Sync.Commands.SyncScreenshots;

public record SyncScreenshotsCommand(SyncRequestDto Request) : IRequest<SyncResponseDto>;

public class SyncScreenshotsCommandValidator : AbstractValidator<SyncScreenshotsCommand>
{
    public SyncScreenshotsCommandValidator()
    {
        RuleFor(v => v.Request).NotNull().WithMessage("Sync request is required.");
    }
}

public class SyncScreenshotsCommandHandler : IRequestHandler<SyncScreenshotsCommand, SyncResponseDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IAIClassificationService _aiClassificationService;

    public SyncScreenshotsCommandHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IAIClassificationService aiClassificationService)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _aiClassificationService = aiClassificationService;
    }

    public async Task<SyncResponseDto> Handle(SyncScreenshotsCommand request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var processed = 0;
        var errors = new List<string>();

        foreach (var item in request.Request.Screenshots)
        {
            try
            {
                var existing = await _unitOfWork.Screenshots.GetByImageIdAsync(item.ImageId, userId, cancellationToken);
                if (existing != null)
                {
                    if (item.IsDeleted)
                    {
                        existing.IsDeleted = true;
                        existing.UpdatedDate = DateTime.UtcNow;
                        _unitOfWork.Screenshots.Update(existing);
                    }
                    else
                    {
                        existing.IsFavorite = item.IsFavorite;
                        existing.ImagePath = item.ImagePath;
                        existing.ThumbnailPath = item.ThumbnailPath ?? existing.ThumbnailPath;
                        existing.UpdatedDate = DateTime.UtcNow;
                        _unitOfWork.Screenshots.Update(existing);
                    }
                }
                else if (!item.IsDeleted)
                {
                    var hash = !string.IsNullOrEmpty(item.Hash)
                        ? item.Hash
                        : HashHelper.ComputeSha256Hash($"{item.ImageId}_{item.Width}_{item.Height}_{item.CapturedDate:O}");

                    var screenshot = new Screenshot
                    {
                        Id = Guid.NewGuid(),
                        UserId = userId,
                        ImageId = item.ImageId,
                        ImagePath = item.ImagePath,
                        ThumbnailPath = item.ThumbnailPath,
                        CapturedDate = item.CapturedDate,
                        SourceApp = item.SourceApp ?? string.Empty,
                        Width = item.Width,
                        Height = item.Height,
                        OCRText = item.OCRText ?? string.Empty,
                        VisionDescription = item.VisionDescription,
                        IsFavorite = item.IsFavorite,
                        Hash = hash,
                        CreatedDate = DateTime.UtcNow
                    };

                    if (!string.IsNullOrWhiteSpace(item.OCRText))
                    {
                        screenshot.OCRCache = new OCRCache
                        {
                            Id = Guid.NewGuid(),
                            ScreenshotId = screenshot.Id,
                            OCRText = item.OCRText,
                            Language = "en",
                            Confidence = 0.95,
                            CreatedDate = DateTime.UtcNow
                        };
                    }

                    // Auto classification if category is missing
                    var categoryName = item.CategoryName;
                    var subCatName = item.SubCategoryName;
                    var tagsList = item.Tags;

                    if (string.IsNullOrEmpty(categoryName))
                    {
                        var classification = await _aiClassificationService.ClassifyScreenshotAsync(new Features.Screenshots.DTOs.ClassifyScreenshotRequestDto
                        {
                            OCRText = item.OCRText ?? string.Empty,
                            VisionDescription = item.VisionDescription,
                            SourceApp = item.SourceApp ?? string.Empty
                        }, cancellationToken);

                        categoryName = classification.Category;
                        subCatName = classification.SubCategory;
                        tagsList = classification.Tags;
                        screenshot.Confidence = classification.Confidence;
                    }

                    if (!string.IsNullOrEmpty(categoryName))
                    {
                        var cat = await _unitOfWork.Categories.GetByNameAsync(categoryName, userId, cancellationToken);
                        if (cat == null)
                        {
                            cat = new Category
                            {
                                Id = Guid.NewGuid(),
                                Name = categoryName,
                                UserId = userId,
                                CreatedByAI = true,
                                CreatedDate = DateTime.UtcNow
                            };
                            await _unitOfWork.Categories.AddAsync(cat, cancellationToken);
                        }
                        screenshot.CategoryId = cat.Id;
                        screenshot.ScreenshotCategories.Add(new ScreenshotCategory
                        {
                            ScreenshotId = screenshot.Id,
                            CategoryId = cat.Id
                        });

                        if (!string.IsNullOrEmpty(subCatName))
                        {
                            var subCat = await _unitOfWork.Categories.GetByNameAsync(subCatName, userId, cancellationToken);
                            if (subCat == null)
                            {
                                subCat = new Category
                                {
                                    Id = Guid.NewGuid(),
                                    Name = subCatName,
                                    ParentCategoryId = cat.Id,
                                    UserId = userId,
                                    CreatedByAI = true,
                                    CreatedDate = DateTime.UtcNow
                                };
                                await _unitOfWork.Categories.AddAsync(subCat, cancellationToken);
                            }
                            screenshot.SubCategoryId = subCat.Id;
                        }
                    }

                    if (tagsList != null && tagsList.Any())
                    {
                        var tags = await _unitOfWork.Tags.GetOrCreateTagsAsync(tagsList, userId, cancellationToken);
                        foreach (var tag in tags)
                        {
                            screenshot.ScreenshotTags.Add(new ScreenshotTag
                            {
                                ScreenshotId = screenshot.Id,
                                TagId = tag.Id
                            });
                        }
                    }

                    await _unitOfWork.Screenshots.AddAsync(screenshot, cancellationToken);
                }

                processed++;
            }
            catch (Exception ex)
            {
                errors.Add($"Error processing imageId '{item.ImageId}': {ex.Message}");
            }
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new SyncResponseDto
        {
            ProcessedCount = processed,
            ServerSyncTimestamp = DateTime.UtcNow,
            Errors = errors
        };
    }
}
