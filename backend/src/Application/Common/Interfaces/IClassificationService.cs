using AI.ScreenshotOrganizer.Application.Features.Classification.DTOs;

namespace AI.ScreenshotOrganizer.Application.Common.Interfaces;

public interface IClassificationService
{
    Task<ClassificationResponseDto> ClassifyAsync(ClassifyRequestDto request, Guid? userId = null, CancellationToken cancellationToken = default);
    Task<ClassificationResponseDto> ReclassifyAsync(ReclassifyRequestDto request, Guid? userId = null, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ClassificationHistoryDto>> GetHistoryAsync(Guid screenshotId, CancellationToken cancellationToken = default);
}
