using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class User : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;

    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
    public ICollection<Screenshot> Screenshots { get; set; } = new List<Screenshot>();
    public ICollection<Category> Categories { get; set; } = new List<Category>();
    public ICollection<Tag> Tags { get; set; } = new List<Tag>();
    public ICollection<DeviceInfo> Devices { get; set; } = new List<DeviceInfo>();
    public ICollection<AppSetting> Settings { get; set; } = new List<AppSetting>();
    public ICollection<FolderContext> FolderContexts { get; set; } = new List<FolderContext>();
    public ICollection<ScreenshotEntity> ExtractedEntities { get; set; } = new List<ScreenshotEntity>();
    public ICollection<TaskItem> Tasks { get; set; } = new List<TaskItem>();
    public ICollection<ChatHistory> ChatHistories { get; set; } = new List<ChatHistory>();
    public ICollection<SearchHistory> SearchHistories { get; set; } = new List<SearchHistory>();
    public ICollection<Collection> Collections { get; set; } = new List<Collection>();
    public ICollection<NotificationHistory> Notifications { get; set; } = new List<NotificationHistory>();
}
