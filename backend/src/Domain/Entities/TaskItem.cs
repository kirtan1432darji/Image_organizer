using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class TaskItem : BaseEntity
{
    public Guid? ScreenshotId { get; set; }
    public Screenshot? Screenshot { get; set; }

    public Guid? CategoryId { get; set; }
    public Category? Category { get; set; }

    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime? DueDate { get; set; }
    public string Priority { get; set; } = "Medium"; // Low, Medium, High, Urgent
    public string Status { get; set; } = "Pending"; // Pending, InProgress, Completed, Dismissed
    public bool IsCompleted { get; set; } = false;
    public DateTime? CompletedAt { get; set; }
}
