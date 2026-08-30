using FluentAssertions;
using Moq;
using Xunit;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Sync.Commands.SyncScreenshots;
using AI.ScreenshotOrganizer.Application.Features.Sync.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.UnitTests.Features.Sync;

public class SyncScreenshotsCommandHandlerTests
{
    private readonly Mock<IUnitOfWork> _unitOfWorkMock;
    private readonly Mock<ICurrentUserService> _currentUserServiceMock;
    private readonly Mock<IAIClassificationService> _aiServiceMock;
    private readonly Mock<IScreenshotRepository> _screenshotRepoMock;
    private readonly Mock<ICategoryRepository> _categoryRepoMock;
    private readonly Mock<ITagRepository> _tagRepoMock;
    private readonly Guid _userId = Guid.NewGuid();

    public SyncScreenshotsCommandHandlerTests()
    {
        _unitOfWorkMock = new Mock<IUnitOfWork>();
        _currentUserServiceMock = new Mock<ICurrentUserService>();
        _aiServiceMock = new Mock<IAIClassificationService>();
        _screenshotRepoMock = new Mock<IScreenshotRepository>();
        _categoryRepoMock = new Mock<ICategoryRepository>();
        _tagRepoMock = new Mock<ITagRepository>();

        _currentUserServiceMock.Setup(c => c.UserId).Returns(_userId);
        _unitOfWorkMock.Setup(u => u.Screenshots).Returns(_screenshotRepoMock.Object);
        _unitOfWorkMock.Setup(u => u.Categories).Returns(_categoryRepoMock.Object);
        _unitOfWorkMock.Setup(u => u.Tags).Returns(_tagRepoMock.Object);
    }

    [Fact]
    public async Task SyncScreenshots_ProcessesBatchSuccessfully()
    {
        var syncRequest = new SyncRequestDto
        {
            Screenshots = new List<SyncScreenshotItemDto>
            {
                new()
                {
                    ImageId = "sync-1",
                    ImagePath = "/path/1.jpg",
                    CapturedDate = DateTime.UtcNow,
                    OCRText = "Receipt total $10",
                    CategoryName = "Receipts & Invoices"
                },
                new()
                {
                    ImageId = "sync-2",
                    ImagePath = "/path/2.jpg",
                    CapturedDate = DateTime.UtcNow,
                    OCRText = "Python code def hello():",
                    CategoryName = "Code & Tech"
                }
            }
        };

        _screenshotRepoMock.Setup(r => r.GetByImageIdAsync(It.IsAny<string>(), _userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Screenshot?)null);

        _categoryRepoMock.Setup(c => c.GetByNameAsync(It.IsAny<string>(), _userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Category { Id = Guid.NewGuid(), Name = "Category" });

        var handler = new SyncScreenshotsCommandHandler(_unitOfWorkMock.Object, _currentUserServiceMock.Object, _aiServiceMock.Object);
        var result = await handler.Handle(new SyncScreenshotsCommand(syncRequest), CancellationToken.None);

        result.Should().NotBeNull();
        result.ProcessedCount.Should().Be(2);
        result.Errors.Should().BeEmpty();
        _unitOfWorkMock.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }
}

