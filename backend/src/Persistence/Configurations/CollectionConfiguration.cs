using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class CollectionConfiguration : IEntityTypeConfiguration<Collection>
{
    public void Configure(EntityTypeBuilder<Collection> builder)
    {
        builder.ToTable("Collections");
        builder.HasKey(c => c.Id);

        builder.Property(c => c.Title).IsRequired().HasMaxLength(150);
        builder.Property(c => c.Description).HasMaxLength(500);
        builder.Property(c => c.IsPublic).HasDefaultValue(false);

        builder.Property(c => c.RowVersion).IsRowVersion();

        builder.HasOne(c => c.User)
            .WithMany(u => u.Collections)
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(c => c.CoverScreenshot)
            .WithMany()
            .HasForeignKey(c => c.CoverScreenshotId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(c => new { c.UserId, c.Title });
        builder.HasQueryFilter(c => !c.IsDeleted);
    }
}
