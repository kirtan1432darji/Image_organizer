using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;

namespace AI.ScreenshotOrganizer.Application.Common.Interfaces;

public interface IAIClassificationService
{
    Task<ClassificationResultDto> ClassifyScreenshotAsync(ClassifyScreenshotRequestDto request, CancellationToken cancellationToken = default);
}
