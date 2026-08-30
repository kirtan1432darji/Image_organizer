using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class ClassificationHistory : BaseEntity
{
    public Guid ScreenshotId { get; set; }
    public Screenshot Screenshot { get; set; } = null!;

    public string Category { get; set; } = string.Empty;
    public string? SubCategory { get; set; }
    public string TagsJson { get; set; } = "[]";
    public double Confidence { get; set; }
    public string ModelName { get; set; } = string.Empty;
}
