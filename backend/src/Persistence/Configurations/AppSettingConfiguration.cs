using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class AppSettingConfiguration : IEntityTypeConfiguration<AppSetting>
{
    public void Configure(EntityTypeBuilder<AppSetting> builder)
    {
        builder.ToTable("AppSettings");
        builder.HasKey(s => s.Id);

        builder.Property(s => s.SettingKey).IsRequired().HasMaxLength(100);
        builder.Property(s => s.SettingValue).IsRequired();
        builder.Property(s => s.DataType).IsRequired().HasMaxLength(50).HasDefaultValue("String");
        builder.Property(s => s.Description).HasMaxLength(500);

        builder.Property(s => s.RowVersion).IsRowVersion();

        builder.HasOne(s => s.User)
            .WithMany(u => u.Settings)
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(s => new { s.UserId, s.SettingKey });
        builder.HasQueryFilter(s => !s.IsDeleted);
    }
}
