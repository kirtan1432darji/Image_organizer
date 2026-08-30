using Microsoft.EntityFrameworkCore;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Domain.Entities;
using AI.ScreenshotOrganizer.Persistence.Context;

namespace AI.ScreenshotOrganizer.Persistence.Repositories;

public class TagRepository : GenericRepository<Tag>, ITagRepository
{
    public TagRepository(ApplicationDbContext context) : base(context)
    {
    }

    public async Task<IReadOnlyList<Tag>> GetUserTagsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Where(t => (t.UserId == userId || t.UserId == null) && !t.IsDeleted)
            .OrderBy(t => t.Name)
            .ToListAsync(cancellationToken);
    }

    public async Task<Tag?> GetByNameAsync(string name, Guid userId, CancellationToken cancellationToken = default)
    {
        var lower = name.ToLower();
        return await _dbSet.FirstOrDefaultAsync(t => t.Name.ToLower() == lower &&
                                                     (t.UserId == userId || t.UserId == null) &&
                                                     !t.IsDeleted, cancellationToken);
    }

    public async Task<IReadOnlyList<Tag>> GetOrCreateTagsAsync(IEnumerable<string> tagNames, Guid userId, CancellationToken cancellationToken = default)
    {
        var result = new List<Tag>();
        var distinctNames = tagNames
            .Where(n => !string.IsNullOrWhiteSpace(n))
            .Select(n => n.Trim().ToLowerInvariant())
            .Distinct()
            .ToList();

        foreach (var name in distinctNames)
        {
            var existing = await GetByNameAsync(name, userId, cancellationToken);
            if (existing != null)
            {
                result.Add(existing);
            }
            else
            {
                var newTag = new Tag
                {
                    Id = Guid.NewGuid(),
                    Name = name,
                    UserId = userId,
                    CreatedDate = DateTime.UtcNow
                };
                await _dbSet.AddAsync(newTag, cancellationToken);
                result.Add(newTag);
            }
        }

        return result;
    }
}
