using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class ScreenshotEntityConfiguration : IEntityTypeConfiguration<ScreenshotEntity>
{
    public void Configure(EntityTypeBuilder<ScreenshotEntity> builder)
    {
        builder.ToTable("Entities");
        builder.HasKey(e => e.Id);

        builder.Property(e => e.EntityType).IsRequired().HasMaxLength(50);
        builder.Property(e => e.EntityValue).IsRequired().HasMaxLength(500);
        builder.Property(e => e.Confidence).HasDefaultValue(1.0);

        builder.Property(e => e.RowVersion).IsRowVersion();

        builder.HasOne(e => e.Screenshot)
            .WithMany(s => s.ExtractedEntities)
            .HasForeignKey(e => e.ScreenshotId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(e => e.User)
            .WithMany(u => u.ExtractedEntities)
            .HasForeignKey(e => e.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(e => new { e.ScreenshotId, e.EntityType });
        builder.HasIndex(e => new { e.UserId, e.EntityType, e.EntityValue });
        builder.HasQueryFilter(e => !e.IsDeleted);
    }
}
