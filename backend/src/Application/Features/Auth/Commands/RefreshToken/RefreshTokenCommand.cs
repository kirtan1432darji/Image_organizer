using FluentValidation;
using MediatR;
using AutoMapper;
using System.Security.Claims;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Auth.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Features.Auth.Commands.RefreshToken;

public record RefreshTokenCommand(string AccessToken, string RefreshToken) : IRequest<AuthResponseDto>;

public class RefreshTokenCommandValidator : AbstractValidator<RefreshTokenCommand>
{
    public RefreshTokenCommandValidator()
    {
        RuleFor(v => v.AccessToken).NotEmpty().WithMessage("AccessToken is required.");
        RuleFor(v => v.RefreshToken).NotEmpty().WithMessage("RefreshToken is required.");
    }
}

public class RefreshTokenCommandHandler : IRequestHandler<RefreshTokenCommand, AuthResponseDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IJwtTokenGenerator _jwtTokenGenerator;
    private readonly IMapper _mapper;

    public RefreshTokenCommandHandler(
        IUnitOfWork unitOfWork,
        IJwtTokenGenerator jwtTokenGenerator,
        IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _jwtTokenGenerator = jwtTokenGenerator;
        _mapper = mapper;
    }

    public async Task<AuthResponseDto> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
    {
        var principal = _jwtTokenGenerator.GetPrincipalFromExpiredToken(request.AccessToken);
        if (principal == null)
        {
            throw new UnauthorizedException("Invalid access token.");
        }

        var jti = principal.Claims.FirstOrDefault(c => c.Type == "jti" || c.Type.EndsWith("/jti"))?.Value;
        var userIdStr = principal.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier || c.Type == "sub" || c.Type.EndsWith("/nameidentifier"))?.Value;

        if (string.IsNullOrEmpty(userIdStr) || !Guid.TryParse(userIdStr, out var userId))
        {
            throw new UnauthorizedException("Invalid token claims.");
        }

        var storedTokens = await _unitOfWork.RefreshTokens.FindAsync(
            r => r.Token == request.RefreshToken && r.UserId == userId,
            cancellationToken);

        var storedToken = storedTokens.FirstOrDefault();
        if (storedToken == null || storedToken.IsUsed || storedToken.IsRevoked || storedToken.ExpiryDate <= DateTime.UtcNow)
        {
            throw new UnauthorizedException("Invalid or expired refresh token.");
        }

        storedToken.IsUsed = true;
        storedToken.UpdatedDate = DateTime.UtcNow;
        _unitOfWork.RefreshTokens.Update(storedToken);

        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken);
        if (user == null || !user.IsActive || user.IsDeleted)
        {
            throw new UnauthorizedException("User not found or deactivated.");
        }

        var (newToken, newJwtId, expiration) = _jwtTokenGenerator.GenerateAccessToken(user);
        var newRefreshTokenString = _jwtTokenGenerator.GenerateRefreshToken();

        var newRefreshToken = new Domain.Entities.RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Token = newRefreshTokenString,
            JwtId = newJwtId,
            ExpiryDate = DateTime.UtcNow.AddDays(30),
            CreatedDate = DateTime.UtcNow
        };

        await _unitOfWork.RefreshTokens.AddAsync(newRefreshToken, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new AuthResponseDto
        {
            AccessToken = newToken,
            RefreshToken = newRefreshTokenString,
            Expiration = expiration,
            User = _mapper.Map<UserDto>(user)
        };
    }
}
