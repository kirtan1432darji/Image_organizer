using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class EmbeddingCache : BaseEntity
{
    public Guid ScreenshotId { get; set; }
    public Screenshot Screenshot { get; set; } = null!;

    public string EmbeddingModel { get; set; } = string.Empty;
    public byte[] EmbeddingVector { get; set; } = Array.Empty<byte>();
    public int Dimensions { get; set; } = 768;
    public string Checksum { get; set; } = string.Empty;
}
