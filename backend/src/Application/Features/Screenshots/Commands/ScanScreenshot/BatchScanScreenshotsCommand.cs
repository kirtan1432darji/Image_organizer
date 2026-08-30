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
