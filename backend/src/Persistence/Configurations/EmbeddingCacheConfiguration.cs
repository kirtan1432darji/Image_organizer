using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class EmbeddingCacheConfiguration : IEntityTypeConfiguration<EmbeddingCache>
{
    public void Configure(EntityTypeBuilder<EmbeddingCache> builder)
    {
        builder.ToTable("EmbeddingCache");
        builder.HasKey(ec => ec.Id);

        builder.Property(ec => ec.EmbeddingModel).IsRequired().HasMaxLength(100);
        builder.Property(ec => ec.EmbeddingVector).IsRequired();
        builder.Property(ec => ec.Dimensions).HasDefaultValue(768);
        builder.Property(ec => ec.Checksum).IsRequired().HasMaxLength(128);

        builder.Property(ec => ec.RowVersion).IsRowVersion();

        builder.HasOne(ec => ec.Screenshot)
            .WithMany(s => s.EmbeddingCaches)
            .HasForeignKey(ec => ec.ScreenshotId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(ec => new { ec.ScreenshotId, ec.EmbeddingModel }).IsUnique();
        builder.HasQueryFilter(ec => !ec.IsDeleted);
    }
}
