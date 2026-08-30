using MediatR;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;

namespace AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.BatchClassify;

public record BatchClassifyScreenshotsCommand(List<ClassifyScreenshotRequestDto> Items) : IRequest<BatchClassifyResponseDto>;

public class BatchClassifyScreenshotsCommandHandler : IRequestHandler<BatchClassifyScreenshotsCommand, BatchClassifyResponseDto>
{
    private readonly IAIClassificationService _aiClassificationService;

    public BatchClassifyScreenshotsCommandHandler(IAIClassificationService aiClassificationService)
    {
        _aiClassificationService = aiClassificationService;
    }

    public async Task<BatchClassifyResponseDto> Handle(BatchClassifyScreenshotsCommand request, CancellationToken cancellationToken)
    {
        var response = new BatchClassifyResponseDto();

        foreach (var item in request.Items)
        {
            var res = await _aiClassificationService.ClassifyScreenshotAsync(item, cancellationToken);
            if (!string.IsNullOrEmpty(item.ScreenshotId))
            {
                res.ScreenshotId = item.ScreenshotId;
            }
            response.Results.Add(res);
        }

        return response;
    }
}
