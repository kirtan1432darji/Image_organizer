using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class ScreenshotTagConfiguration : IEntityTypeConfiguration<ScreenshotTag>
{
    public void Configure(EntityTypeBuilder<ScreenshotTag> builder)
    {
        builder.ToTable("ScreenshotTags");
        builder.HasKey(st => new { st.ScreenshotId, st.TagId });

        builder.HasOne(st => st.Screenshot)
            .WithMany(s => s.ScreenshotTags)
            .HasForeignKey(st => st.ScreenshotId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(st => st.Tag)
            .WithMany(t => t.ScreenshotTags)
            .HasForeignKey(st => st.TagId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
