using AI.ScreenshotOrganizer.Application.Features.Categories.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Tags.DTOs;

namespace AI.ScreenshotOrganizer.Application.Features.Sync.DTOs;

public class SyncScreenshotItemDto
{
    public string ImageId { get; set; } = string.Empty;
    public string ImagePath { get; set; } = string.Empty;
    public string? ThumbnailPath { get; set; }
    public DateTime CapturedDate { get; set; }
    public string SourceApp { get; set; } = string.Empty;
    public int Width { get; set; }
    public int Height { get; set; }
    public string OCRText { get; set; } = string.Empty;
    public string? VisionDescription { get; set; }
    public string? CategoryName { get; set; }
    public string? SubCategoryName { get; set; }
    public List<string> Tags { get; set; } = new();
    public bool IsFavorite { get; set; }
    public string? Hash { get; set; }
    public bool IsDeleted { get; set; }
}

public class SyncRequestDto
{
    public List<SyncScreenshotItemDto> Screenshots { get; set; } = new();
    public DateTime LastSyncTimestamp { get; set; }
}

public class SyncResponseDto
{
    public int ProcessedCount { get; set; }
    public DateTime ServerSyncTimestamp { get; set; } = DateTime.UtcNow;
    public List<string> Errors { get; set; } = new();
}

public class ChangesSinceResponseDto
{
    public DateTime ServerTimestamp { get; set; } = DateTime.UtcNow;
    public List<ScreenshotDto> Screenshots { get; set; } = new();
    public List<CategoryDto> Categories { get; set; } = new();
    public List<TagDto> Tags { get; set; } = new();
}
