using AutoMapper;
using FluentAssertions;
using Moq;
using Xunit;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Common.Mappings;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.BatchScan;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.ScanScreenshot;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.UnitTests.Features.Screenshots;

public class IdempotentScanTests
{
    private readonly Mock<IUnitOfWork> _unitOfWorkMock;
    private readonly Mock<ICurrentUserService> _currentUserServiceMock;
    private readonly Mock<IAIClassificationService> _aiServiceMock;
    private readonly Mock<IScreenshotRepository> _screenshotRepoMock;
    private readonly Mock<ICategoryRepository> _categoryRepoMock;
    private readonly Mock<ITagRepository> _tagRepoMock;
    private readonly IMapper _mapper;
    private readonly Guid _userId = Guid.NewGuid();

    public IdempotentScanTests()
    {
        _unitOfWorkMock = new Mock<IUnitOfWork>();
        _currentUserServiceMock = new Mock<ICurrentUserService>();
        _aiServiceMock = new Mock<IAIClassificationService>();
        _screenshotRepoMock = new Mock<IScreenshotRepository>();
        _categoryRepoMock = new Mock<ICategoryRepository>();
        _tagRepoMock = new Mock<ITagRepository>();

        _currentUserServiceMock.Setup(c => c.UserId).Returns(_userId);
        _currentUserServiceMock.Setup(c => c.IsAuthenticated).Returns(true);

        _unitOfWorkMock.Setup(u => u.Screenshots).Returns(_screenshotRepoMock.Object);
        _unitOfWorkMock.Setup(u => u.Categories).Returns(_categoryRepoMock.Object);
        _unitOfWorkMock.Setup(u => u.Tags).Returns(_tagRepoMock.Object);

        var config = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>());
        _mapper = config.CreateMapper();
    }

    [Fact]
    public async Task Scan_SameDeviceAssetId_UpdatesExistingRecord()
    {
        var assetId = "media_asset_999";
        var existing = new Screenshot
        {
            Id = Guid.NewGuid(),
            UserId = _userId,
            DeviceAssetId = assetId,
            ImageId = assetId,
            FileName = "Old_Screenshot.png",
            ImagePath = "/storage/old.png",
            Width = 1080,
            Height = 1920
        };

        _screenshotRepoMock.Setup(r => r.GetByDeviceAssetIdAsync(assetId, _userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(existing);

        _screenshotRepoMock.Setup(r => r.GetWithDetailsByIdAsync(existing.Id, _userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(existing);

        var request = new ScanScreenshotRequestDto
        {
            DeviceAssetId = assetId,
            FileName = "New_Screenshot.png",
            ImagePath = "/storage/new.png",
            Width = 1080,
            Height = 2400,
            OCRText = "Updated OCR text",
            AutoClassify = false
        };

        var handler = new ScanScreenshotCommandHandler(_unitOfWorkMock.Object, _currentUserServiceMock.Object, _aiServiceMock.Object, _mapper);
        var result = await handler.Handle(new ScanScreenshotCommand(request), CancellationToken.None);

        result.Should().NotBeNull();
        result.DeviceAssetId.Should().Be(assetId);
        result.FileName.Should().Be("New_Screenshot.png");
        _unitOfWorkMock.Verify(u => u.Screenshots.Update(It.Is<Screenshot>(s => s.DeviceAssetId == assetId)), Times.Once);
        _unitOfWorkMock.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task BatchScan_MultipleItems_ProcessesAndReturnsSummary()
    {
        var items = new List<ScanScreenshotRequestDto>
        {
            new() { DeviceAssetId = "asset_1", FileName = "1.png", ImagePath = "/1.png", AutoClassify = false },
            new() { DeviceAssetId = "asset_2", FileName = "2.png", ImagePath = "/2.png", AutoClassify = false }
        };

        _screenshotRepoMock.Setup(r => r.GetByDeviceAssetIdAsync(It.IsAny<string>(), _userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Screenshot?)null);

        var handler = new BatchScanScreenshotsCommandHandler(_unitOfWorkMock.Object, _currentUserServiceMock.Object, _aiServiceMock.Object, _mapper);
        var result = await handler.Handle(new BatchScanScreenshotsCommand(items), CancellationToken.None);

        result.Should().NotBeNull();
        result.ProcessedCount.Should().Be(2);
        result.UpsertedCount.Should().Be(2);
        result.Errors.Should().BeEmpty();
        _unitOfWorkMock.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }
}
