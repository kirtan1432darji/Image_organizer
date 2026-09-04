using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class ScreenshotConfiguration : IEntityTypeConfiguration<Screenshot>
{
    public void Configure(EntityTypeBuilder<Screenshot> builder)
    {
        builder.ToTable("Screenshots");
        builder.HasKey(s => s.Id);

        builder.Property(s => s.DeviceAssetId).HasMaxLength(256);
        builder.Property(s => s.ImageId).IsRequired().HasMaxLength(256);
        builder.Property(s => s.ImagePath).IsRequired().HasMaxLength(1024);
        builder.Property(s => s.ThumbnailPath).HasMaxLength(1024);
        builder.Property(s => s.FileName).HasMaxLength(256);
        builder.Property(s => s.ContentUri).HasMaxLength(1024);
        builder.Property(s => s.SourceApp).HasMaxLength(100);
        builder.Property(s => s.DetectedApp).HasMaxLength(100);
        builder.Property(s => s.KeywordsJson).IsUnicode(true);
        builder.Property(s => s.IsAutoCategorized).HasDefaultValue(false);
        builder.Ignore(s => s.ClassificationConfidence);
        builder.Property(s => s.OCRStatus).HasMaxLength(30);
        builder.Property(s => s.OCRText).IsUnicode(true);
        builder.Property(s => s.VisionDescription).IsUnicode(true);
        builder.Property(s => s.Hash).HasMaxLength(64);

        // Unique filtered index on (UserId, DeviceAssetId) for idempotent mobile scanning
        builder.HasIndex(s => new { s.UserId, s.DeviceAssetId })
            .IsUnique()
            .HasFilter("[DeviceAssetId] IS NOT NULL AND [DeviceAssetId] <> ''");

        builder.HasIndex(s => new { s.UserId, s.ImageId });
        builder.HasIndex(s => s.Hash);
        builder.HasIndex(s => s.CapturedDate);
        builder.HasIndex(s => s.IsFavorite);
        builder.HasIndex(s => s.IsReviewed);
        builder.HasIndex(s => s.CategoryId);

        // Restrict delete behavior to prevent SQL Server multiple cascade paths
        builder.HasOne(s => s.Category)
            .WithMany()
            .HasForeignKey(s => s.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(s => s.SubCategory)
            .WithMany()
            .HasForeignKey(s => s.SubCategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(s => s.OCRCache)
            .WithOne(o => o.Screenshot)
            .HasForeignKey<OCRCache>(o => o.ScreenshotId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(s => s.ClassificationHistories)
            .WithOne(c => c.Screenshot)
            .HasForeignKey(c => c.ScreenshotId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
