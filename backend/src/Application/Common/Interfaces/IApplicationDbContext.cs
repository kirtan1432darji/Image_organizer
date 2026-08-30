using Microsoft.EntityFrameworkCore;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Common.Interfaces;

public interface IApplicationDbContext
{
    DbSet<User> Users { get; }
    DbSet<RefreshToken> RefreshTokens { get; }
    DbSet<Screenshot> Screenshots { get; }
    DbSet<Category> Categories { get; }
    DbSet<ScreenshotCategory> ScreenshotCategories { get; }
    DbSet<Tag> Tags { get; }
    DbSet<ScreenshotTag> ScreenshotTags { get; }
    DbSet<OCRCache> OCRCache { get; }
    DbSet<ClassificationHistory> ClassificationHistories { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
