using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Persistence.Configurations;

public class SearchHistoryConfiguration : IEntityTypeConfiguration<SearchHistory>
{
    public void Configure(EntityTypeBuilder<SearchHistory> builder)
    {
        builder.ToTable("SearchHistory");
        builder.HasKey(sh => sh.Id);

        builder.Property(sh => sh.Query).IsRequired().HasMaxLength(500);
        builder.Property(sh => sh.ResultsCount).HasDefaultValue(0);
        builder.Property(sh => sh.ExecutionTimeMs).HasDefaultValue(0);

        builder.Property(sh => sh.RowVersion).IsRowVersion();

        builder.HasOne(sh => sh.User)
            .WithMany(u => u.SearchHistories)
            .HasForeignKey(sh => sh.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(sh => sh.ClickedScreenshot)
            .WithMany(s => s.SearchClicks)
            .HasForeignKey(sh => sh.ClickedScreenshotId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(sh => new { sh.UserId, sh.CreatedOn });
        builder.HasQueryFilter(sh => !sh.IsDeleted);
    }
}
