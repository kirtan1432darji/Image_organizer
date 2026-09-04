using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class FolderContextConfiguration : IEntityTypeConfiguration<FolderContext>
{
    public void Configure(EntityTypeBuilder<FolderContext> builder)
    {
        builder.ToTable("FolderContext");
        builder.HasKey(fc => fc.Id);

        builder.Property(fc => fc.Summary).IsRequired();
        builder.Property(fc => fc.KeyTopicsJson).IsRequired().HasDefaultValue("[]");
        builder.Property(fc => fc.ScreenshotCount).HasDefaultValue(0);

        builder.Property(fc => fc.RowVersion).IsRowVersion();

        builder.HasOne(fc => fc.Category)
            .WithMany(c => c.FolderContexts)
            .HasForeignKey(fc => fc.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(fc => fc.User)
            .WithMany(u => u.FolderContexts)
            .HasForeignKey(fc => fc.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(fc => fc.AIModel)
            .WithMany(m => m.FolderContexts)
            .HasForeignKey(fc => fc.AIModelId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(fc => new { fc.CategoryId, fc.UserId }).IsUnique();
        builder.HasQueryFilter(fc => !fc.IsDeleted);
    }
}
