using FluentValidation;
using MediatR;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;

namespace AI.ScreenshotOrganizer.Application.Features.Auth.Commands.Logout;

public record LogoutCommand(string RefreshToken) : IRequest<bool>;

public class LogoutCommandValidator : AbstractValidator<LogoutCommand>
{
    public LogoutCommandValidator()
    {
        RuleFor(v => v.RefreshToken).NotEmpty().WithMessage("RefreshToken is required.");
    }
}

public class LogoutCommandHandler : IRequestHandler<LogoutCommand, bool>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;

    public LogoutCommandHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUserService)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
    }

    public async Task<bool> Handle(LogoutCommand request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        var tokens = await _unitOfWork.RefreshTokens.FindAsync(
            r => r.Token == request.RefreshToken && (!userId.HasValue || r.UserId == userId.Value),
            cancellationToken);

        var token = tokens.FirstOrDefault();
        if (token != null)
        {
            token.IsRevoked = true;
            token.UpdatedDate = DateTime.UtcNow;
            _unitOfWork.RefreshTokens.Update(token);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }

        return true;
    }
}
