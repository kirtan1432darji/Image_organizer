using AutoMapper;
using FluentAssertions;
using Moq;
using Xunit;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Common.Mappings;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.ScanScreenshot;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.UnitTests.Features.Screenshots;

public class ScanScreenshotCommandHandlerTests
{
    private readonly Mock<IUnitOfWork> _unitOfWorkMock;
    private readonly Mock<ICurrentUserService> _currentUserServiceMock;
    private readonly Mock<IAIClassificationService> _aiServiceMock;
    private readonly Mock<IScreenshotRepository> _screenshotRepoMock;
    private readonly Mock<ICategoryRepository> _categoryRepoMock;
    private readonly Mock<ITagRepository> _tagRepoMock;
    private readonly IMapper _mapper;
    private readonly ScanScreenshotCommandHandler _handler;

    private readonly Guid _testUserId = Guid.NewGuid();

    public ScanScreenshotCommandHandlerTests()
    {
        _unitOfWorkMock = new Mock<IUnitOfWork>();
        _currentUserServiceMock = new Mock<ICurrentUserService>();
        _aiServiceMock = new Mock<IAIClassificationService>();
        _screenshotRepoMock = new Mock<IScreenshotRepository>();
        _categoryRepoMock = new Mock<ICategoryRepository>();
        _tagRepoMock = new Mock<ITagRepository>();

        _currentUserServiceMock.Setup(c => c.UserId).Returns(_testUserId);
        _currentUserServiceMock.Setup(c => c.IsAuthenticated).Returns(true);

        _unitOfWorkMock.Setup(u => u.Screenshots).Returns(_screenshotRepoMock.Object);
        _unitOfWorkMock.Setup(u => u.Categories).Returns(_categoryRepoMock.Object);
        _unitOfWorkMock.Setup(u => u.Tags).Returns(_tagRepoMock.Object);

        var config = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>());
        _mapper = config.CreateMapper();

        _handler = new ScanScreenshotCommandHandler(
            _unitOfWorkMock.Object,
            _currentUserServiceMock.Object,
            _aiServiceMock.Object,
            _mapper);
    }

    [Fact]
    public async Task Handle_NewScreenshot_ClassifiesAndSaves()
    {
        var scanReq = new ScanScreenshotRequestDto
        {
            ImageId = "img-1001",
            ImagePath = "/storage/emulated/0/DCIM/Screenshots/Screenshot_1.png",
            CapturedDate = DateTime.UtcNow,
            SourceApp = "Starbucks",
            Width = 1080,
            Height = 2400,
            OCRText = "Starbucks Total $5.50 Paid",
            AutoClassify = true
        };

        _screenshotRepoMock.Setup(r => r.GetByImageIdAsync(scanReq.ImageId, _testUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Screenshot?)null);

        _aiServiceMock.Setup(a => a.ClassifyScreenshotAsync(It.IsAny<ClassifyScreenshotRequestDto>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ClassificationResultDto
            {
                Category = "Receipts & Invoices",
                SubCategory = "Dining",
                Tags = new List<string> { "receipt", "starbucks", "food" },
                Confidence = 0.95,
                ModelName = "gemini-1.5-flash-screenshot-v1"
            });

        _categoryRepoMock.Setup(c => c.GetByNameAsync(It.IsAny<string>(), _testUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Category?)null);

        _tagRepoMock.Setup(t => t.GetOrCreateTagsAsync(It.IsAny<IEnumerable<string>>(), _testUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Tag> { new Tag { Name = "receipt" }, new Tag { Name = "food" } });

        var result = await _handler.Handle(new ScanScreenshotCommand(scanReq), CancellationToken.None);

        result.Should().NotBeNull();
        result.ImageId.Should().Be(scanReq.ImageId);
        _screenshotRepoMock.Verify(r => r.AddAsync(It.IsAny<Screenshot>(), It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWorkMock.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }
}

