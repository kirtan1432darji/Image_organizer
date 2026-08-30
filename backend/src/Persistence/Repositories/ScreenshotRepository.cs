using Microsoft.EntityFrameworkCore;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Common.Models;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;
using AI.ScreenshotOrganizer.Persistence.Context;

namespace AI.ScreenshotOrganizer.Persistence.Repositories;

public class ScreenshotRepository : GenericRepository<Screenshot>, IScreenshotRepository
{
    public ScreenshotRepository(ApplicationDbContext context) : base(context)
    {
    }

    public async Task<Screenshot?> GetWithDetailsByIdAsync(Guid id, Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(s => s.Category)
            .Include(s => s.SubCategory)
            .Include(s => s.ScreenshotCategories)
                .ThenInclude(sc => sc.Category)
            .Include(s => s.ScreenshotTags)
                .ThenInclude(st => st.Tag)
            .Include(s => s.OCRCache)
            .Include(s => s.ClassificationHistories)
            .FirstOrDefaultAsync(s => s.Id == id && s.UserId == userId && !s.IsDeleted, cancellationToken);
    }

    public async Task<Screenshot?> GetByImageIdAsync(string imageId, Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(s => s.Category)
            .Include(s => s.SubCategory)
            .Include(s => s.ScreenshotCategories)
                .ThenInclude(sc => sc.Category)
            .Include(s => s.ScreenshotTags)
                .ThenInclude(st => st.Tag)
            .FirstOrDefaultAsync(s => s.ImageId == imageId && s.UserId == userId && !s.IsDeleted, cancellationToken);
    }

    public async Task<PagedResult<Screenshot>> GetPagedListAsync(Guid userId, ScreenshotFilterDto filter, CancellationToken cancellationToken = default)
    {
        var query = _dbSet
            .Include(s => s.Category)
            .Include(s => s.SubCategory)
            .Include(s => s.ScreenshotCategories)
                .ThenInclude(sc => sc.Category)
            .Include(s => s.ScreenshotTags)
                .ThenInclude(st => st.Tag)
            .Where(s => s.UserId == userId && !s.IsDeleted);

        if (filter.CategoryId.HasValue)
        {
            query = query.Where(s => s.CategoryId == filter.CategoryId || s.ScreenshotCategories.Any(sc => sc.CategoryId == filter.CategoryId));
        }

        if (filter.SubCategoryId.HasValue)
        {
            query = query.Where(s => s.SubCategoryId == filter.SubCategoryId);
        }

        if (!string.IsNullOrEmpty(filter.SourceApp))
        {
            query = query.Where(s => s.SourceApp.ToLower() == filter.SourceApp.ToLower());
        }

        if (filter.IsFavorite.HasValue)
        {
            query = query.Where(s => s.IsFavorite == filter.IsFavorite.Value);
        }

        if (filter.FromDate.HasValue)
        {
            query = query.Where(s => s.CapturedDate >= filter.FromDate.Value);
        }

        if (filter.ToDate.HasValue)
        {
            query = query.Where(s => s.CapturedDate <= filter.ToDate.Value);
        }

        if (!string.IsNullOrEmpty(filter.Tag))
        {
            query = query.Where(s => s.ScreenshotTags.Any(st => st.Tag.Name.ToLower() == filter.Tag.ToLower()));
        }

        if (!string.IsNullOrEmpty(filter.SearchTerm))
        {
            var term = filter.SearchTerm.ToLower();
            query = query.Where(s => s.OCRText.ToLower().Contains(term) ||
                                     (s.VisionDescription != null && s.VisionDescription.ToLower().Contains(term)) ||
                                     s.SourceApp.ToLower().Contains(term) ||
                                     s.ScreenshotTags.Any(st => st.Tag.Name.ToLower().Contains(term)));
        }

        // Sorting
        query = (filter.SortBy?.ToLower(), filter.SortDescending) switch
        {
            ("captureddate", false) => query.OrderBy(s => s.CapturedDate),
            ("createddate", false) => query.OrderBy(s => s.CreatedDate),
            ("createddate", true) => query.OrderByDescending(s => s.CreatedDate),
            ("confidence", true) => query.OrderByDescending(s => s.Confidence),
            ("confidence", false) => query.OrderBy(s => s.Confidence),
            _ => query.OrderByDescending(s => s.CapturedDate)
        };

        var totalCount = await query.CountAsync(cancellationToken);
        var pageNumber = filter.PageNumber > 0 ? filter.PageNumber : 1;
        var pageSize = filter.PageSize > 0 ? (filter.PageSize > 100 ? 100 : filter.PageSize) : 20;

        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<Screenshot>(items, totalCount, pageNumber, pageSize);
    }

    public async Task<IReadOnlyList<Screenshot>> SearchAsync(Guid userId, string keyword, Guid? categoryId, string? sourceApp, int limit = 50, CancellationToken cancellationToken = default)
    {
        var query = _dbSet
            .Include(s => s.Category)
            .Include(s => s.SubCategory)
            .Include(s => s.ScreenshotCategories)
                .ThenInclude(sc => sc.Category)
            .Include(s => s.ScreenshotTags)
                .ThenInclude(st => st.Tag)
            .Where(s => s.UserId == userId && !s.IsDeleted);

        if (categoryId.HasValue)
        {
            query = query.Where(s => s.CategoryId == categoryId || s.ScreenshotCategories.Any(sc => sc.CategoryId == categoryId));
        }

        if (!string.IsNullOrEmpty(sourceApp))
        {
            query = query.Where(s => s.SourceApp.ToLower() == sourceApp.ToLower());
        }

        var term = keyword.ToLower();
        query = query.Where(s => s.OCRText.ToLower().Contains(term) ||
                                 (s.VisionDescription != null && s.VisionDescription.ToLower().Contains(term)) ||
                                 s.SourceApp.ToLower().Contains(term) ||
                                 s.ScreenshotTags.Any(st => st.Tag.Name.ToLower().Contains(term)) ||
                                 (s.Category != null && s.Category.Name.ToLower().Contains(term)));

        return await query
            .OrderByDescending(s => s.CapturedDate)
            .Take(limit)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Screenshot>> GetChangesSinceAsync(Guid userId, DateTime since, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Include(s => s.Category)
            .Include(s => s.SubCategory)
            .Include(s => s.ScreenshotCategories)
                .ThenInclude(sc => sc.Category)
            .Include(s => s.ScreenshotTags)
                .ThenInclude(st => st.Tag)
            .Where(s => s.UserId == userId && (s.CreatedDate >= since || (s.UpdatedDate.HasValue && s.UpdatedDate >= since)))
            .ToListAsync(cancellationToken);
    }
}
