using MediatR;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.ToggleReview;

public record ToggleReviewStatusCommand(Guid Id, bool? IsReviewed = true) : IRequest<bool>;

public class ToggleReviewStatusCommandHandler : IRequestHandler<ToggleReviewStatusCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;

    public ToggleReviewStatusCommandHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUserService)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
    }

    public async Task<bool> Handle(ToggleReviewStatusCommand request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var screenshot = await _unitOfWork.Screenshots.GetWithDetailsByIdAsync(request.Id, userId, cancellationToken);

        if (screenshot == null)
        {
            throw new NotFoundException(nameof(Screenshot), request.Id);
        }

        screenshot.IsReviewed = request.IsReviewed ?? !screenshot.IsReviewed;
        screenshot.UpdatedDate = DateTime.UtcNow;

        _unitOfWork.Screenshots.Update(screenshot);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return screenshot.IsReviewed;
    }
}
