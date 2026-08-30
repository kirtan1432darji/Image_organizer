using AutoMapper;
using FluentAssertions;
using Moq;
using Xunit;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Common.Mappings;
using AI.ScreenshotOrganizer.Application.Features.Search.Queries.SearchScreenshots;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.UnitTests.Features.Search;

public class SearchScreenshotsQueryHandlerTests
{
    private readonly Mock<IUnitOfWork> _unitOfWorkMock;
    private readonly Mock<ICurrentUserService> _currentUserServiceMock;
    private readonly Mock<IScreenshotRepository> _screenshotRepoMock;
    private readonly IMapper _mapper;
    private readonly Guid _userId = Guid.NewGuid();

    public SearchScreenshotsQueryHandlerTests()
    {
        _unitOfWorkMock = new Mock<IUnitOfWork>();
        _currentUserServiceMock = new Mock<ICurrentUserService>();
        _screenshotRepoMock = new Mock<IScreenshotRepository>();

        _currentUserServiceMock.Setup(c => c.UserId).Returns(_userId);
        _unitOfWorkMock.Setup(u => u.Screenshots).Returns(_screenshotRepoMock.Object);

        var config = new MapperConfiguration(cfg => cfg.AddProfile<MappingProfile>());
        _mapper = config.CreateMapper();
    }

    [Fact]
    public async Task Search_KeywordGiven_ReturnsMatchingResults()
    {
        var screenshots = new List<Screenshot>
        {
            new() { Id = Guid.NewGuid(), UserId = _userId, ImageId = "s1", OCRText = "Meeting notes with CEO", SourceApp = "Notes" },
            new() { Id = Guid.NewGuid(), UserId = _userId, ImageId = "s2", OCRText = "Agenda for CEO meeting", SourceApp = "Notion" }
        };

        _screenshotRepoMock.Setup(r => r.SearchAsync(_userId, "CEO", null, null, 50, It.IsAny<CancellationToken>()))
            .ReturnsAsync(screenshots);

        var handler = new SearchScreenshotsQueryHandler(_unitOfWorkMock.Object, _currentUserServiceMock.Object, _mapper);
        var result = await handler.Handle(new SearchScreenshotsQuery("CEO"), CancellationToken.None);

        result.Should().NotBeNull();
        result.TotalResults.Should().Be(2);
        result.Query.Should().Be("CEO");
        result.Screenshots.Should().HaveCount(2);
    }
}

