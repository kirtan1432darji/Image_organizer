using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class DeviceInfoConfiguration : IEntityTypeConfiguration<DeviceInfo>
{
    public void Configure(EntityTypeBuilder<DeviceInfo> builder)
    {
        builder.ToTable("DeviceInfo");
        builder.HasKey(d => d.Id);

        builder.Property(d => d.DeviceIdentifier).IsRequired().HasMaxLength(256);
        builder.Property(d => d.DeviceName).IsRequired().HasMaxLength(100);
        builder.Property(d => d.Platform).IsRequired().HasMaxLength(50);
        builder.Property(d => d.OSVersion).HasMaxLength(50);
        builder.Property(d => d.AppVersion).HasMaxLength(50);
        builder.Property(d => d.IsActive).HasDefaultValue(true);

        builder.Property(d => d.RowVersion).IsRowVersion();

        builder.HasOne(d => d.User)
            .WithMany(u => u.Devices)
            .HasForeignKey(d => d.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(d => new { d.UserId, d.DeviceIdentifier }).IsUnique();
        builder.HasQueryFilter(d => !d.IsDeleted);
    }
}
