using AI.ScreenshotOrganizer.Application.Common.Models;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Common.Interfaces;

public interface IScreenshotRepository : IGenericRepository<Screenshot>
{
    Task<Screenshot?> GetWithDetailsByIdAsync(Guid id, Guid userId, CancellationToken cancellationToken = default);
    Task<Screenshot?> GetByImageIdAsync(string imageId, Guid userId, CancellationToken cancellationToken = default);
    Task<PagedResult<Screenshot>> GetPagedListAsync(Guid userId, ScreenshotFilterDto filter, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Screenshot>> SearchAsync(Guid userId, string keyword, Guid? categoryId, string? sourceApp, int limit = 50, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Screenshot>> GetChangesSinceAsync(Guid userId, DateTime since, CancellationToken cancellationToken = default);
}
