using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class SearchHistory : BaseEntity
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public string Query { get; set; } = string.Empty;
    public string? FilterJson { get; set; }
    public int ResultsCount { get; set; } = 0;
    public int ExecutionTimeMs { get; set; } = 0;

    public Guid? ClickedScreenshotId { get; set; }
    public Screenshot? ClickedScreenshot { get; set; }
}
