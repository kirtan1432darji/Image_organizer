using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class OCRCacheConfiguration : IEntityTypeConfiguration<OCRCache>
{
    public void Configure(EntityTypeBuilder<OCRCache> builder)
    {
        builder.ToTable("OCRCache");
        builder.HasKey(o => o.Id);

        builder.Property(o => o.Language).HasMaxLength(10);
    }
}
