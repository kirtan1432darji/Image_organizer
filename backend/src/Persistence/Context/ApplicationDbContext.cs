using Microsoft.EntityFrameworkCore;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Domain.Entities;
using System.Reflection;

namespace AI.ScreenshotOrganizer.Persistence.Context;

public class ApplicationDbContext : DbContext, IApplicationDbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }

    // Core Domain Sets
    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Screenshot> Screenshots => Set<Screenshot>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<ScreenshotCategory> ScreenshotCategories => Set<ScreenshotCategory>();
    public DbSet<Tag> Tags => Set<Tag>();
    public DbSet<ScreenshotTag> ScreenshotTags => Set<ScreenshotTag>();
    public DbSet<OCRCache> OCRCache => Set<OCRCache>();
    public DbSet<ClassificationHistory> ClassificationHistories => Set<ClassificationHistory>();

    // ContextVault AI Workspace Sets
    public DbSet<AIModel> AIModels => Set<AIModel>();
    public DbSet<DeviceInfo> DeviceInfo => Set<DeviceInfo>();
    public DbSet<AppSetting> AppSettings => Set<AppSetting>();
    public DbSet<FolderContext> FolderContexts => Set<FolderContext>();
    public DbSet<ScreenshotEntity> Entities => Set<ScreenshotEntity>();
    public DbSet<TaskItem> Tasks => Set<TaskItem>();
    public DbSet<ChatHistory> ChatHistories => Set<ChatHistory>();
    public DbSet<SearchHistory> SearchHistories => Set<SearchHistory>();

    // Future Scalability Sets
    public DbSet<Collection> Collections => Set<Collection>();
    public DbSet<CollectionScreenshot> CollectionScreenshots => Set<CollectionScreenshot>();
    public DbSet<EmbeddingCache> EmbeddingCaches => Set<EmbeddingCache>();
    public DbSet<NotificationHistory> NotificationHistories => Set<NotificationHistory>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
}
