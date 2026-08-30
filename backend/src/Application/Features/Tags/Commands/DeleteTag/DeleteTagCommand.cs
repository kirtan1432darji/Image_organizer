using MediatR;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Features.Tags.Commands.DeleteTag;

public record DeleteTagCommand(Guid Id) : IRequest<bool>;

public class DeleteTagCommandHandler : IRequestHandler<DeleteTagCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;

    public DeleteTagCommandHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUserService)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
    }

    public async Task<bool> Handle(DeleteTagCommand request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var tag = await _unitOfWork.Tags.GetByIdAsync(request.Id, cancellationToken);

        if (tag == null || (tag.UserId != null && tag.UserId != userId))
        {
            throw new NotFoundException(nameof(Tag), request.Id);
        }

        tag.IsDeleted = true;
        tag.UpdatedDate = DateTime.UtcNow;

        _unitOfWork.Tags.Update(tag);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return true;
    }
}
