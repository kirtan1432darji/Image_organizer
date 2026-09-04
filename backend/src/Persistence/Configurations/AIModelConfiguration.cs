using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class AIModelConfiguration : IEntityTypeConfiguration<AIModel>
{
    public void Configure(EntityTypeBuilder<AIModel> builder)
    {
        builder.ToTable("AIModels");
        builder.HasKey(m => m.Id);

        builder.Property(m => m.ModelCode).IsRequired().HasMaxLength(100);
        builder.Property(m => m.DisplayName).IsRequired().HasMaxLength(100);
        builder.Property(m => m.Provider).IsRequired().HasMaxLength(100);
        builder.Property(m => m.Version).IsRequired().HasMaxLength(50).HasDefaultValue("1.0");
        builder.Property(m => m.MaxContextTokens).HasDefaultValue(8192);
        builder.Property(m => m.IsActive).HasDefaultValue(true);

        builder.Property(m => m.RowVersion).IsRowVersion();

        builder.HasIndex(m => m.ModelCode).IsUnique();
        builder.HasQueryFilter(m => !m.IsDeleted);
    }
}
