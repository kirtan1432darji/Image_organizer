using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Common.Interfaces;

public interface ITagRepository : IGenericRepository<Tag>
{
    Task<IReadOnlyList<Tag>> GetUserTagsAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<Tag?> GetByNameAsync(string name, Guid userId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Tag>> GetOrCreateTagsAsync(IEnumerable<string> tagNames, Guid userId, CancellationToken cancellationToken = default);
}
