using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class ClassificationHistoryConfiguration : IEntityTypeConfiguration<ClassificationHistory>
{
    public void Configure(EntityTypeBuilder<ClassificationHistory> builder)
    {
        builder.ToTable("ClassificationHistory");
        builder.HasKey(c => c.Id);

        builder.Property(c => c.Category).IsRequired().HasMaxLength(100);
        builder.Property(c => c.SubCategory).HasMaxLength(100);
        builder.Property(c => c.ModelName).HasMaxLength(100);
    }
}
