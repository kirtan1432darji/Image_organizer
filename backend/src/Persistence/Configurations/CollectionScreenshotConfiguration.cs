using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class CollectionScreenshotConfiguration : IEntityTypeConfiguration<CollectionScreenshot>
{
    public void Configure(EntityTypeBuilder<CollectionScreenshot> builder)
    {
        builder.ToTable("CollectionScreenshots");
        builder.HasKey(cs => new { cs.CollectionId, cs.ScreenshotId });

        builder.Property(cs => cs.OrderIndex).HasDefaultValue(0);

        builder.HasOne(cs => cs.Collection)
            .WithMany(c => c.CollectionScreenshots)
            .HasForeignKey(cs => cs.CollectionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(cs => cs.Screenshot)
            .WithMany(s => s.CollectionScreenshots)
            .HasForeignKey(cs => cs.ScreenshotId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
