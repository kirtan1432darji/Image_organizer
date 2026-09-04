using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class AIModel : BaseEntity
{
    public string ModelCode { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Provider { get; set; } = string.Empty;
    public string Version { get; set; } = "1.0";
    public int MaxContextTokens { get; set; } = 8192;
    public bool IsActive { get; set; } = true;
    public string? CapabilitiesJson { get; set; }

    public ICollection<FolderContext> FolderContexts { get; set; } = new List<FolderContext>();
    public ICollection<ChatHistory> ChatHistories { get; set; } = new List<ChatHistory>();
}
