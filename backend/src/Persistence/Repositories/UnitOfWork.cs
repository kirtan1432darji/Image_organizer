using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Domain.Entities;
using AI.ScreenshotOrganizer.Persistence.Context;

namespace AI.ScreenshotOrganizer.Persistence.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly ApplicationDbContext _context;

    public IScreenshotRepository Screenshots { get; }
    public ICategoryRepository Categories { get; }
    public ITagRepository Tags { get; }
    public IGenericRepository<User> Users { get; }
    public IGenericRepository<RefreshToken> RefreshTokens { get; }
    public IGenericRepository<OCRCache> OCRCache { get; }
    public IGenericRepository<ClassificationHistory> ClassificationHistories { get; }

    public UnitOfWork(
        ApplicationDbContext context,
        IScreenshotRepository screenshots,
        ICategoryRepository categories,
        ITagRepository tags)
    {
        _context = context;
        Screenshots = screenshots;
        Categories = categories;
        Tags = tags;
        Users = new GenericRepository<User>(_context);
        RefreshTokens = new GenericRepository<RefreshToken>(_context);
        OCRCache = new GenericRepository<OCRCache>(_context);
        ClassificationHistories = new GenericRepository<ClassificationHistory>(_context);
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    public void Dispose()
    {
        _context.Dispose();
        GC.SuppressFinalize(this);
    }
}
