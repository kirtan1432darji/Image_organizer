using AutoMapper;
using FluentAssertions;
using Moq;
using Xunit;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Common.Mappings;
using AI.ScreenshotOrganizer.Application.Features.Categories.Commands.CreateCategory;
using AI.ScreenshotOrganizer.Application.Features.Categories.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.UnitTests.Features.Categories;

public class CategoryCommandTests
{
    private readonly Mock<IUnitOfWork> _unitOfWorkMock;
    private readonly Mock<ICurrentUserService> _currentUserServiceMock;
    private readonly Mock<ICategoryRepository> _categoryRepoMock;
    private readonly IMapper _mapper;
    private readonly Guid _userId = Guid.NewGuid();

    public CategoryCommandTests()
    {
        _unitOfWorkMock = new Mock<IUnitOfWork>();
        _currentUserServiceMock = new Mock<ICurrentUserService>();
        _categoryRepoMock = new Mock<ICategoryRepository>();

        _currentUserServiceMock.Setup(c => c.UserId).Returns(_userId);
        _unitOfWorkMock.Setup(u => u.Categories).Returns(_categoryRepoMock.Object);

        var config = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>());
        _mapper = config.CreateMapper();
    }

    [Fact]
    public async Task CreateCategory_ValidRequest_CreatesCategory()
    {
        var command = new CreateCategoryCommand(new CreateCategoryRequestDto
        {
            Name = "Work Projects",
            Icon = "work",
            Color = "#336699"
        });

        _categoryRepoMock.Setup(r => r.GetByNameAsync(command.Request.Name, _userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Category?)null);

        var handler = new CreateCategoryCommandHandler(_unitOfWorkMock.Object, _currentUserServiceMock.Object, _mapper);
        var result = await handler.Handle(command, CancellationToken.None);

        result.Should().NotBeNull();
        result.Name.Should().Be("Work Projects");
        result.Icon.Should().Be("work");
        _categoryRepoMock.Verify(r => r.AddAsync(It.Is<Category>(c => c.Name == "Work Projects"), It.IsAny<CancellationToken>()), Times.Once);
    }
}

