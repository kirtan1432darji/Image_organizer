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

    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Screenshot> Screenshots => Set<Screenshot>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<ScreenshotCategory> ScreenshotCategories => Set<ScreenshotCategory>();
    public DbSet<Tag> Tags => Set<Tag>();
    public DbSet<ScreenshotTag> ScreenshotTags => Set<ScreenshotTag>();
    public DbSet<OCRCache> OCRCache => Set<OCRCache>();
    public DbSet<ClassificationHistory> ClassificationHistories => Set<ClassificationHistory>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
}
