using Microsoft.EntityFrameworkCore;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Common.Interfaces;

public interface IApplicationDbContext
{
    // Core Domain Sets
    DbSet<User> Users { get; }
    DbSet<RefreshToken> RefreshTokens { get; }
    DbSet<Screenshot> Screenshots { get; }
    DbSet<Category> Categories { get; }
    DbSet<ScreenshotCategory> ScreenshotCategories { get; }
    DbSet<Tag> Tags { get; }
    DbSet<ScreenshotTag> ScreenshotTags { get; }
    DbSet<OCRCache> OCRCache { get; }
    DbSet<ClassificationHistory> ClassificationHistories { get; }

    // ContextVault AI Workspace Sets
    DbSet<AIModel> AIModels { get; }
    DbSet<DeviceInfo> DeviceInfo { get; }
    DbSet<AppSetting> AppSettings { get; }
    DbSet<FolderContext> FolderContexts { get; }
    DbSet<ScreenshotEntity> Entities { get; }
    DbSet<TaskItem> Tasks { get; }
    DbSet<ChatHistory> ChatHistories { get; }
    DbSet<SearchHistory> SearchHistories { get; }

    // Future Scalability Sets
    DbSet<Collection> Collections { get; }
    DbSet<CollectionScreenshot> CollectionScreenshots { get; }
    DbSet<EmbeddingCache> EmbeddingCaches { get; }
    DbSet<NotificationHistory> NotificationHistories { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
