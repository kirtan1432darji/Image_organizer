namespace AI.ScreenshotOrganizer.Application.Common.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IScreenshotRepository Screenshots { get; }
    ICategoryRepository Categories { get; }
    ITagRepository Tags { get; }
    IGenericRepository<Domain.Entities.User> Users { get; }
    IGenericRepository<Domain.Entities.RefreshToken> RefreshTokens { get; }
    IGenericRepository<Domain.Entities.OCRCache> OCRCache { get; }
    IGenericRepository<Domain.Entities.ClassificationHistory> ClassificationHistories { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
