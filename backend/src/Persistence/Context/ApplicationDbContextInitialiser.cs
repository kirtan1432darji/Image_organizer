using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using AI.ScreenshotOrganizer.Domain.Entities;
using AI.ScreenshotOrganizer.Shared.Constants;

namespace AI.ScreenshotOrganizer.Persistence.Context;

public class ApplicationDbContextInitialiser
{
    private readonly ILogger<ApplicationDbContextInitialiser> _logger;
    private readonly ApplicationDbContext _context;

    public ApplicationDbContextInitialiser(ILogger<ApplicationDbContextInitialiser> logger, ApplicationDbContext context)
    {
        _logger = logger;
        _context = context;
    }

    public async Task InitialiseAsync()
    {
        try
        {
            if (_context.Database.IsSqlServer())
            {
                await _context.Database.MigrateAsync();
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An error occurred while migrating the database.");
            throw;
        }
    }

    public async Task SeedAsync()
    {
        try
        {
            await TrySeedAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An error occurred while seeding the database.");
            throw;
        }
    }

    public async Task TrySeedAsync()
    {
        if (!await _context.Categories.AnyAsync(c => c.UserId == null))
        {
            foreach (var (name, icon, color, subCategories) in SystemCategories.Defaults)
            {
                var parent = new Category
                {
                    Id = Guid.NewGuid(),
                    Name = name,
                    Icon = icon,
                    Color = color,
                    CreatedByAI = false,
                    UserId = null,
                    CreatedDate = DateTime.UtcNow
                };

                await _context.Categories.AddAsync(parent);

                foreach (var sub in subCategories)
                {
                    var subCat = new Category
                    {
                        Id = Guid.NewGuid(),
                        Name = sub,
                        ParentCategoryId = parent.Id,
                        CreatedByAI = false,
                        UserId = null,
                        CreatedDate = DateTime.UtcNow
                    };
                    await _context.Categories.AddAsync(subCat);
                }
            }

            await _context.SaveChangesAsync();
            _logger.LogInformation("Seeded default system categories.");
        }
    }
}
