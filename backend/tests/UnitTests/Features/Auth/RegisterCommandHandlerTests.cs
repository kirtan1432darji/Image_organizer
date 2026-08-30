using AutoMapper;
using FluentAssertions;
using Moq;
using Xunit;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Common.Mappings;
using AI.ScreenshotOrganizer.Application.Features.Auth.Commands.Register;
using AI.ScreenshotOrganizer.Domain.Entities;
using System.Linq.Expressions;

namespace AI.ScreenshotOrganizer.UnitTests.Features.Auth;

public class RegisterCommandHandlerTests
{
    private readonly Mock<IUnitOfWork> _unitOfWorkMock;
    private readonly Mock<IPasswordHasherService> _passwordHasherMock;
    private readonly Mock<IJwtTokenGenerator> _jwtGeneratorMock;
    private readonly Mock<IGenericRepository<User>> _userRepoMock;
    private readonly Mock<IGenericRepository<RefreshToken>> _tokenRepoMock;
    private readonly IMapper _mapper;
    private readonly RegisterCommandHandler _handler;

    public RegisterCommandHandlerTests()
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

        _handler = new RegisterCommandHandler(_unitOfWorkMock.Object, _passwordHasherMock.Object, _jwtGeneratorMock.Object, _mapper);
    }

    [Fact]
    public async Task Handle_ValidRequest_RegistersUserAndReturnsTokens()
    {
        var command = new RegisterCommand("Test User", "test@example.com", "Password123!");

        _userRepoMock.Setup(r => r.FindAsync(It.IsAny<Expression<Func<User, bool>>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<User>());

        _passwordHasherMock.Setup(p => p.HashPassword(command.Password))
            .Returns("hashed_secret");

        _jwtGeneratorMock.Setup(j => j.GenerateAccessToken(It.IsAny<User>()))
            .Returns(("jwt_token_123", "jwt_id_123", DateTime.UtcNow.AddHours(1)));

        _jwtGeneratorMock.Setup(j => j.GenerateRefreshToken())
            .Returns("refresh_token_123");

        var result = await _handler.Handle(command, CancellationToken.None);

        result.Should().NotBeNull();
        result.AccessToken.Should().Be("jwt_token_123");
        result.RefreshToken.Should().Be("refresh_token_123");
        result.User.Email.Should().Be("test@example.com");
        result.User.Name.Should().Be("Test User");

        _userRepoMock.Verify(r => r.AddAsync(It.Is<User>(u => u.Email == "test@example.com"), It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWorkMock.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Handle_DuplicateEmail_ThrowsConflictException()
    {
        var command = new RegisterCommand("Test User", "existing@example.com", "Password123!");

        _userRepoMock.Setup(r => r.FindAsync(It.IsAny<Expression<Func<User, bool>>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<User> { new User { Email = "existing@example.com" } });

        var act = () => _handler.Handle(command, CancellationToken.None);

        await act.Should().ThrowAsync<ConflictException>();
    }
}

