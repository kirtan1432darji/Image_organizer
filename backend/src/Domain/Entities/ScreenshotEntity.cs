using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class ScreenshotEntity : BaseEntity
{
    public Guid ScreenshotId { get; set; }
    public Screenshot Screenshot { get; set; } = null!;

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public string EntityType { get; set; } = string.Empty;
    public string EntityValue { get; set; } = string.Empty;
    public double Confidence { get; set; } = 1.0;
    public string? MetadataJson { get; set; }
}
