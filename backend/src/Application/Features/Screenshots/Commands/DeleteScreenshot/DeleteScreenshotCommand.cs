using MediatR;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.DeleteScreenshot;

public record DeleteScreenshotCommand(Guid Id) : IRequest<bool>;

public class DeleteScreenshotCommandHandler : IRequestHandler<DeleteScreenshotCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;

    public DeleteScreenshotCommandHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUserService)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
    }

    public async Task<bool> Handle(DeleteScreenshotCommand request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var screenshot = await _unitOfWork.Screenshots.GetWithDetailsByIdAsync(request.Id, userId, cancellationToken);

        if (screenshot == null)
        {
            throw new NotFoundException(nameof(Screenshot), request.Id);
        }

        // Soft delete screenshot metadata
        screenshot.IsDeleted = true;
        screenshot.UpdatedDate = DateTime.UtcNow;

        _unitOfWork.Screenshots.Update(screenshot);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return true;
    }
}
