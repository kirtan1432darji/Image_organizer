using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class ChatHistory : BaseEntity
{
    public Guid SessionId { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public Guid? CategoryId { get; set; }
    public Category? Category { get; set; }

    public Guid? ScreenshotId { get; set; }
    public Screenshot? Screenshot { get; set; }

    public string Role { get; set; } = "User"; // User, Assistant, System
    public string Message { get; set; } = string.Empty;
    public string? ReferencedScreenshotIdsJson { get; set; }

    public int? PromptTokens { get; set; }
    public int? CompletionTokens { get; set; }

    public Guid? AIModelId { get; set; }
    public AIModel? AIModel { get; set; }
}
