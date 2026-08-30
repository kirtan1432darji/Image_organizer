using Microsoft.EntityFrameworkCore;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Domain.Entities;
using AI.ScreenshotOrganizer.Persistence.Context;

namespace AI.ScreenshotOrganizer.Persistence.Repositories;

public class CategoryRepository : GenericRepository<Category>, ICategoryRepository
{
    public CategoryRepository(ApplicationDbContext context) : base(context)
    {
    }

    public async Task<IReadOnlyList<Category>> GetUserCategoriesWithHierarchyAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(c => c.SubCategories.Where(sc => !sc.IsDeleted))
            .Where(c => (c.UserId == userId || c.UserId == null) && c.ParentCategoryId == null && !c.IsDeleted)
            .OrderBy(c => c.Name)
            .ToListAsync(cancellationToken);
    }

    public async Task<Category?> GetByNameAsync(string name, Guid? userId, CancellationToken cancellationToken = default)
    {
        var lowerName = name.ToLower();
        return await _dbSet
            .FirstOrDefaultAsync(c => c.Name.ToLower() == lowerName &&
                                      (c.UserId == userId || c.UserId == null) &&
                                      !c.IsDeleted, cancellationToken);
    }

    public async Task<IReadOnlyList<Category>> GetChangesSinceAsync(Guid userId, DateTime since, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Where(c => (c.UserId == userId || c.UserId == null) &&
                        (c.CreatedDate >= since || (c.UpdatedDate.HasValue && c.UpdatedDate >= since)))
            .ToListAsync(cancellationToken);
    }
}
