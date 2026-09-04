using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class FolderContext : BaseEntity
{
    public Guid CategoryId { get; set; }
    public Category Category { get; set; } = null!;

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public string Summary { get; set; } = string.Empty;
    public string KeyTopicsJson { get; set; } = "[]";
    public int ScreenshotCount { get; set; } = 0;
    public DateTime LastGeneratedAt { get; set; } = DateTime.UtcNow;

    public Guid? AIModelId { get; set; }
    public AIModel? AIModel { get; set; }
}
