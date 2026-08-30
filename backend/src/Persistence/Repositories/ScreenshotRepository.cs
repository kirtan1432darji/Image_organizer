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
            .Include(s => s.OCRCache)
            .Include(s => s.ClassificationHistories)
            .FirstOrDefaultAsync(s => s.ImageId == imageId && s.UserId == userId && !s.IsDeleted, cancellationToken);
    }

    public async Task<Screenshot?> GetByDeviceAssetIdAsync(string deviceAssetId, Guid userId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(deviceAssetId)) return null;

        return await _dbSet
            .Include(s => s.Category)
            .Include(s => s.SubCategory)
            .Include(s => s.ScreenshotCategories)
                .ThenInclude(sc => sc.Category)
            .Include(s => s.ScreenshotTags)
                .ThenInclude(st => st.Tag)
            .Include(s => s.OCRCache)
            .Include(s => s.ClassificationHistories)
            .FirstOrDefaultAsync(s => (s.DeviceAssetId == deviceAssetId || s.ImageId == deviceAssetId) && s.UserId == userId && !s.IsDeleted, cancellationToken);
    }

    public async Task<Screenshot> UpsertAsync(Screenshot screenshot, CancellationToken cancellationToken = default)
    {
        var existing = !string.IsNullOrEmpty(screenshot.DeviceAssetId)
            ? await GetByDeviceAssetIdAsync(screenshot.DeviceAssetId, screenshot.UserId, cancellationToken)
            : await GetByImageIdAsync(screenshot.ImageId, screenshot.UserId, cancellationToken);

        if (existing == null)
        {
            await _dbSet.AddAsync(screenshot, cancellationToken);
            return screenshot;
        }

        // Update metadata
        existing.ImagePath = screenshot.ImagePath;
        existing.ThumbnailPath = screenshot.ThumbnailPath ?? existing.ThumbnailPath;
        existing.FileName = !string.IsNullOrEmpty(screenshot.FileName) ? screenshot.FileName : existing.FileName;
        existing.FileSize = screenshot.FileSize > 0 ? screenshot.FileSize : existing.FileSize;
        existing.ContentUri = screenshot.ContentUri ?? existing.ContentUri;
        existing.Width = screenshot.Width > 0 ? screenshot.Width : existing.Width;
        existing.Height = screenshot.Height > 0 ? screenshot.Height : existing.Height;
        existing.SourceApp = !string.IsNullOrEmpty(screenshot.SourceApp) ? screenshot.SourceApp : existing.SourceApp;
        existing.CapturedDate = screenshot.CapturedDate != default ? screenshot.CapturedDate : existing.CapturedDate;
        existing.LastScannedAt = screenshot.LastScannedAt ?? DateTime.UtcNow;
        existing.UpdatedDate = DateTime.UtcNow;
        existing.IsMock = screenshot.IsMock;

        if (!string.IsNullOrEmpty(screenshot.OCRText))
        {
            existing.OCRText = screenshot.OCRText;
            existing.OCRStatus = "completed";
        }

        if (!string.IsNullOrEmpty(screenshot.VisionDescription))
        {
            existing.VisionDescription = screenshot.VisionDescription;
        }

        if (screenshot.CategoryId.HasValue)
        {
            existing.CategoryId = screenshot.CategoryId;
        }

        if (screenshot.SubCategoryId.HasValue)
        {
            existing.SubCategoryId = screenshot.SubCategoryId;
        }

        if (screenshot.Confidence > 0)
        {
            existing.Confidence = screenshot.Confidence;
        }

        _dbSet.Update(existing);
        return existing;
    }

    public async Task<List<Screenshot>> BatchUpsertAsync(IEnumerable<Screenshot> screenshots, Guid userId, CancellationToken cancellationToken = default)
    {
        var result = new List<Screenshot>();
        foreach (var item in screenshots)
        {
            item.UserId = userId;
            var upserted = await UpsertAsync(item, cancellationToken);
            result.Add(upserted);
        }
        return result;
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
            .Where(s => s.UserId == userId && !s.IsDeleted && !s.IsMock);

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

        if (filter.IsReviewed.HasValue)
        {
            query = query.Where(s => s.IsReviewed == filter.IsReviewed.Value);
        }

        if (filter.NeedsReview.HasValue)
        {
            if (filter.NeedsReview.Value)
            {
                query = query.Where(s => !s.IsReviewed && (s.Confidence < 0.70 || s.CategoryId == null));
            }
            else
            {
                query = query.Where(s => s.IsReviewed || (s.Confidence >= 0.70 && s.CategoryId != null));
            }
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
                                     s.FileName.ToLower().Contains(term) ||
                                     s.SourceApp.ToLower().Contains(term) ||
                                     s.ScreenshotTags.Any(st => st.Tag.Name.ToLower().Contains(term)) ||
                                     (s.Category != null && s.Category.Name.ToLower().Contains(term)));
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
        
        // Support both pageNumber/pageSize and limit/offset
        var pageSize = filter.PageSize > 0 ? (filter.PageSize > 100 ? 100 : filter.PageSize) : (filter.Limit > 0 ? filter.Limit : 20);
        var pageNumber = filter.PageNumber > 0 ? filter.PageNumber : (filter.Offset > 0 ? (filter.Offset / pageSize) + 1 : 1);
        var skip = filter.Offset > 0 ? filter.Offset : (pageNumber - 1) * pageSize;

        var items = await query
            .Skip(skip)
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
            .Where(s => s.UserId == userId && !s.IsDeleted && !s.IsMock);

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
                                 s.FileName.ToLower().Contains(term) ||
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
