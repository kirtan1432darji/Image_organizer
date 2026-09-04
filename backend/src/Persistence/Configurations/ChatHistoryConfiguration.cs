using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class ChatHistoryConfiguration : IEntityTypeConfiguration<ChatHistory>
{
    public void Configure(EntityTypeBuilder<ChatHistory> builder)
    {
        builder.ToTable("ChatHistory");
        builder.HasKey(ch => ch.Id);

        builder.Property(ch => ch.Role).IsRequired().HasMaxLength(20);
        builder.Property(ch => ch.Message).IsRequired();

        builder.Property(ch => ch.RowVersion).IsRowVersion();

        builder.HasOne(ch => ch.User)
            .WithMany(u => u.ChatHistories)
            .HasForeignKey(ch => ch.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(ch => ch.Category)
            .WithMany(c => c.ChatHistories)
            .HasForeignKey(ch => ch.CategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(ch => ch.Screenshot)
            .WithMany(s => s.ChatHistories)
            .HasForeignKey(ch => ch.ScreenshotId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(ch => ch.AIModel)
            .WithMany(m => m.ChatHistories)
            .HasForeignKey(ch => ch.AIModelId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(ch => new { ch.UserId, ch.SessionId, ch.CreatedOn });
        builder.HasQueryFilter(ch => !ch.IsDeleted);
    }
}
