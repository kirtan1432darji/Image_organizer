using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class Collection : BaseEntity
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? CoverScreenshotId { get; set; }
    public Screenshot? CoverScreenshot { get; set; }
    public bool IsPublic { get; set; } = false;

    public ICollection<CollectionScreenshot> CollectionScreenshots { get; set; } = new List<CollectionScreenshot>();
}
