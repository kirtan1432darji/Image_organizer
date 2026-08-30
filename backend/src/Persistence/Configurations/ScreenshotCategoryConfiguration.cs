using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class ScreenshotCategoryConfiguration : IEntityTypeConfiguration<ScreenshotCategory>
{
    public void Configure(EntityTypeBuilder<ScreenshotCategory> builder)
    {
        builder.ToTable("ScreenshotCategories");
        builder.HasKey(sc => new { sc.ScreenshotId, sc.CategoryId });

        builder.HasOne(sc => sc.Screenshot)
            .WithMany(s => s.ScreenshotCategories)
            .HasForeignKey(sc => sc.ScreenshotId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(sc => sc.Category)
            .WithMany(c => c.ScreenshotCategories)
            .HasForeignKey(sc => sc.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
