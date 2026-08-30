using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class OCRCache : BaseEntity
{
    public Guid ScreenshotId { get; set; }
    public Screenshot Screenshot { get; set; } = null!;

    public string OCRText { get; set; } = string.Empty;
    public string Language { get; set; } = "en";
    public double Confidence { get; set; }
}
