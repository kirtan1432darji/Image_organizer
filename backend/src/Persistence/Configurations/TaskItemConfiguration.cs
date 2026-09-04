using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class TaskItemConfiguration : IEntityTypeConfiguration<TaskItem>
{
    public void Configure(EntityTypeBuilder<TaskItem> builder)
    {
        builder.ToTable("Tasks");
        builder.HasKey(t => t.Id);

        builder.Property(t => t.Title).IsRequired().HasMaxLength(255);
        builder.Property(t => t.Priority).IsRequired().HasMaxLength(20).HasDefaultValue("Medium");
        builder.Property(t => t.Status).IsRequired().HasMaxLength(20).HasDefaultValue("Pending");
        builder.Property(t => t.IsCompleted).HasDefaultValue(false);

        builder.Property(t => t.RowVersion).IsRowVersion();

        builder.HasOne(t => t.Screenshot)
            .WithMany(s => s.Tasks)
            .HasForeignKey(t => t.ScreenshotId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(t => t.Category)
            .WithMany(c => c.Tasks)
            .HasForeignKey(t => t.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(t => t.User)
            .WithMany(u => u.Tasks)
            .HasForeignKey(t => t.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(t => new { t.UserId, t.Status, t.DueDate });
        builder.HasIndex(t => new { t.UserId, t.IsCompleted });
        builder.HasQueryFilter(t => !t.IsDeleted);
    }
}
