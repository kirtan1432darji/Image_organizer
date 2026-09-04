namespace AI.ScreenshotOrganizer.Domain.Entities;

public class CollectionScreenshot
{
    public Guid CollectionId { get; set; }
    public Collection Collection { get; set; } = null!;

    public Guid ScreenshotId { get; set; }
    public Screenshot Screenshot { get; set; } = null!;

    public int OrderIndex { get; set; } = 0;
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;
}
