using FluentValidation;
using MediatR;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;

namespace AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.ClassifyScreenshot;

public record ClassifyScreenshotCommand(ClassifyScreenshotRequestDto Request) : IRequest<ClassificationResultDto>;

public class ClassifyScreenshotCommandValidator : AbstractValidator<ClassifyScreenshotCommand>
{
    public ClassifyScreenshotCommandValidator()
    {
        RuleFor(v => v.Request).NotNull().WithMessage("Request payload is required.");
    }
}

public class ClassifyScreenshotCommandHandler : IRequestHandler<ClassifyScreenshotCommand, ClassificationResultDto>
{
    private readonly IAIClassificationService _aiClassificationService;

    public ClassifyScreenshotCommandHandler(IAIClassificationService aiClassificationService)
    {
        _aiClassificationService = aiClassificationService;
    }

    public async Task<ClassificationResultDto> Handle(ClassifyScreenshotCommand request, CancellationToken cancellationToken)
    {
        return await _aiClassificationService.ClassifyScreenshotAsync(request.Request, cancellationToken);
    }
}
