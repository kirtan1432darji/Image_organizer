namespace AI.ScreenshotOrganizer.Domain.Entities;

public class ScreenshotTag
{
    public Guid ScreenshotId { get; set; }
    public Screenshot Screenshot { get; set; } = null!;

    public Guid TagId { get; set; }
    public Tag Tag { get; set; } = null!;
}
