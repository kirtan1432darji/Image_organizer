namespace AI.ScreenshotOrganizer.Domain.Entities;

public class ScreenshotCategory
{
    public Guid ScreenshotId { get; set; }
    public Screenshot Screenshot { get; set; } = null!;

    public Guid CategoryId { get; set; }
    public Category Category { get; set; } = null!;
}
