using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Common.Interfaces;

public interface ICategoryRepository : IGenericRepository<Category>
{
    Task<IReadOnlyList<Category>> GetUserCategoriesWithHierarchyAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<Category?> GetByNameAsync(string name, Guid? userId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Category>> GetChangesSinceAsync(Guid userId, DateTime since, CancellationToken cancellationToken = default);
}
