using AutoMapper;
using FluentAssertions;
using Moq;
using Xunit;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Common.Mappings;
using AI.ScreenshotOrganizer.Application.Features.Auth.Commands.Login;
using AI.ScreenshotOrganizer.Domain.Entities;
using System.Linq.Expressions;

namespace AI.ScreenshotOrganizer.UnitTests.Features.Auth;

public class LoginCommandHandlerTests
{
    private readonly Mock<IUnitOfWork> _unitOfWorkMock;
    private readonly Mock<IPasswordHasherService> _passwordHasherMock;
    private readonly Mock<IJwtTokenGenerator> _jwtGeneratorMock;
    private readonly Mock<IGenericRepository<User>> _userRepoMock;
    private readonly Mock<IGenericRepository<RefreshToken>> _tokenRepoMock;
    private readonly IMapper _mapper;
    private readonly LoginCommandHandler _handler;

    public LoginCommandHandlerTests()
    {
        _unitOfWorkMock = new Mock<IUnitOfWork>();
        _passwordHasherMock = new Mock<IPasswordHasherService>();
        _jwtGeneratorMock = new Mock<IJwtTokenGenerator>();
        _userRepoMock = new Mock<IGenericRepository<User>>();
        _tokenRepoMock = new Mock<IGenericRepository<RefreshToken>>();

        _unitOfWorkMock.Setup(u => u.Users).Returns(_userRepoMock.Object);
        _unitOfWorkMock.Setup(u => u.RefreshTokens).Returns(_tokenRepoMock.Object);

        var config = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>());
        _mapper = config.CreateMapper();

        _handler = new LoginCommandHandler(_unitOfWorkMock.Object, _passwordHasherMock.Object, _jwtGeneratorMock.Object, _mapper);
    }

    [Fact]
    public async Task Handle_ValidCredentials_ReturnsAuthResponse()
    {
        var command = new LoginCommand("user@example.com", "Password123!");
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "user@example.com",
            Name = "John Doe",
            PasswordHash = "correct_hash",
            IsActive = true
        };

        _userRepoMock.Setup(r => r.FindAsync(It.IsAny<Expression<Func<User, bool>>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<User> { user });

        _passwordHasherMock.Setup(p => p.VerifyPassword("correct_hash", "Password123!"))
            .Returns(true);

        _jwtGeneratorMock.Setup(j => j.GenerateAccessToken(user))
            .Returns(("access_token_123", "jwt_id", DateTime.UtcNow.AddHours(1)));

        _jwtGeneratorMock.Setup(j => j.GenerateRefreshToken())
            .Returns("refresh_token_123");

        var result = await _handler.Handle(command, CancellationToken.None);

        result.Should().NotBeNull();
        result.AccessToken.Should().Be("access_token_123");
        result.RefreshToken.Should().Be("refresh_token_123");
        result.User.Email.Should().Be(user.Email);
    }

    [Fact]
    public async Task Handle_InvalidPassword_ThrowsUnauthorizedException()
    {
        var command = new LoginCommand("user@example.com", "WrongPassword");
        var user = new User { Email = "user@example.com", PasswordHash = "hash" };

        _userRepoMock.Setup(r => r.FindAsync(It.IsAny<Expression<Func<User, bool>>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<User> { user });

        _passwordHasherMock.Setup(p => p.VerifyPassword("hash", "WrongPassword"))
            .Returns(false);

        var act = () => _handler.Handle(command, CancellationToken.None);

        await act.Should().ThrowAsync<UnauthorizedException>();
    }
}

