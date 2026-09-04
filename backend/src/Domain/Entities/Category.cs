using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class Category : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public Guid? ParentCategoryId { get; set; }
    public Category? ParentCategory { get; set; }
    public ICollection<Category> SubCategories { get; set; } = new List<Category>();

    public string? Icon { get; set; }
    public string? Color { get; set; }
    public bool CreatedByAI { get; set; } = false;
    public Guid? UserId { get; set; }
    public User? User { get; set; }

    public int DisplayOrder { get; set; } = 0;
    public string? Description { get; set; }

    public ICollection<ScreenshotCategory> ScreenshotCategories { get; set; } = new List<ScreenshotCategory>();
    public ICollection<FolderContext> FolderContexts { get; set; } = new List<FolderContext>();
    public ICollection<TaskItem> Tasks { get; set; } = new List<TaskItem>();
    public ICollection<ChatHistory> ChatHistories { get; set; } = new List<ChatHistory>();
}
