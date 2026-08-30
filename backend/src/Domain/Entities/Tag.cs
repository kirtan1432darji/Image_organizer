using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class Tag : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public Guid? UserId { get; set; }
    public User? User { get; set; }

    public ICollection<ScreenshotTag> ScreenshotTags { get; set; } = new List<ScreenshotTag>();
}
