using System.Text.Json.Serialization;
using AI.ScreenshotOrganizer.Application.Common.Models;

namespace AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;

public class TagSummaryDto
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("color_hex")]
    public string ColorHex { get; set; } = "6366F1";
}

public class CategorySummaryDto
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("icon")]
    public string? Icon { get; set; }

    [JsonPropertyName("color")]
    public string? Color { get; set; }
}

public class ScreenshotDto
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("user_id")]
    public Guid UserId { get; set; }

    [JsonPropertyName("device_asset_id")]
    public string DeviceAssetId { get; set; } = string.Empty;

    [JsonPropertyName("image_id")]
    public string ImageId { get; set; } = string.Empty;

    [JsonPropertyName("image_path")]
    public string ImagePath { get; set; } = string.Empty;

    [JsonPropertyName("file_path")]
    public string FilePath => ImagePath;

    [JsonPropertyName("thumbnail_path")]
    public string? ThumbnailPath { get; set; }

    [JsonPropertyName("file_name")]
    public string FileName { get; set; } = string.Empty;

    [JsonPropertyName("file_size")]
    public long FileSize { get; set; }

    [JsonPropertyName("content_uri")]
    public string? ContentUri { get; set; }

    [JsonPropertyName("captured_date")]
    public DateTime CapturedDate { get; set; }

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt => CapturedDate;

    [JsonPropertyName("source_app")]
    public string SourceApp { get; set; } = string.Empty;

    [JsonPropertyName("width")]
    public int Width { get; set; }

    [JsonPropertyName("height")]
    public int Height { get; set; }

    [JsonPropertyName("ocr_text")]
    public string OCRText { get; set; } = string.Empty;

    [JsonPropertyName("vision_description")]
    public string? VisionDescription { get; set; }

    [JsonPropertyName("ocr_status")]
    public string OCRStatus { get; set; } = "none";
    
    [JsonPropertyName("category_id")]
    public Guid? CategoryId { get; set; }

    [JsonPropertyName("category_name")]
    public string CategoryName => Category?.Name ?? "Unsorted";

    [JsonPropertyName("category")]
    public CategorySummaryDto? Category { get; set; }

    [JsonPropertyName("sub_category_id")]
    public Guid? SubCategoryId { get; set; }

    [JsonPropertyName("subcategory")]
    public string Subcategory => SubCategory?.Name ?? string.Empty;

    [JsonPropertyName("sub_category")]
    public CategorySummaryDto? SubCategory { get; set; }

    [JsonPropertyName("confidence")]
    public double Confidence { get; set; }

    [JsonPropertyName("hash")]
    public string Hash { get; set; } = string.Empty;

    [JsonPropertyName("is_favorite")]
    public bool IsFavorite { get; set; }

    [JsonPropertyName("is_reviewed")]
    public bool IsReviewed { get; set; }

    [JsonPropertyName("is_synced")]
    public bool IsSynced { get; set; } = true;

    [JsonPropertyName("is_mock")]
    public bool IsMock { get; set; }

    [JsonPropertyName("last_scanned_at")]
    public DateTime? LastScannedAt { get; set; }

    [JsonPropertyName("created_date")]
    public DateTime CreatedDate { get; set; }

    [JsonPropertyName("updated_date")]
    public DateTime? UpdatedDate { get; set; }

    [JsonPropertyName("categories")]
    public List<CategorySummaryDto> Categories { get; set; } = new();

    [JsonPropertyName("tags")]
    public List<TagSummaryDto> Tags { get; set; } = new();
}

public class ScanScreenshotRequestDto
{
    [JsonPropertyName("device_asset_id")]
    public string? DeviceAssetId { get; set; }

    [JsonPropertyName("image_id")]
    public string? ImageId { get; set; }

    [JsonPropertyName("image_path")]
    public string? ImagePath { get; set; }

    [JsonPropertyName("file_path")]
    public string? FilePath { get; set; }

    [JsonPropertyName("thumbnail_path")]
    public string? ThumbnailPath { get; set; }

    [JsonPropertyName("file_name")]
    public string? FileName { get; set; }

    [JsonPropertyName("file_size")]
    public long FileSize { get; set; }

    [JsonPropertyName("content_uri")]
    public string? ContentUri { get; set; }

    [JsonPropertyName("captured_date")]
    public DateTime? CapturedDate { get; set; }

    [JsonPropertyName("created_at")]
    public DateTime? CreatedAt { get; set; }

    [JsonPropertyName("source_app")]
    public string? SourceApp { get; set; }

    [JsonPropertyName("width")]
    public int Width { get; set; }

    [JsonPropertyName("height")]
    public int Height { get; set; }

    [JsonPropertyName("ocr_text")]
    public string? OCRText { get; set; }

    [JsonPropertyName("vision_description")]
    public string? VisionDescription { get; set; }

    [JsonPropertyName("ocr_status")]
    public string? OCRStatus { get; set; }

    [JsonPropertyName("category_id")]
    public Guid? CategoryId { get; set; }

    [JsonPropertyName("category_name")]
    public string? CategoryName { get; set; }

    [JsonPropertyName("sub_category_name")]
    public string? SubCategoryName { get; set; }

    [JsonPropertyName("tags")]
    public List<string>? Tags { get; set; }

    [JsonPropertyName("is_favorite")]
    public bool? IsFavorite { get; set; }

    [JsonPropertyName("is_reviewed")]
    public bool? IsReviewed { get; set; }

    [JsonPropertyName("is_mock")]
    public bool? IsMock { get; set; }

    [JsonPropertyName("hash")]
    public string? Hash { get; set; }

    [JsonPropertyName("auto_classify")]
    public bool? AutoClassify { get; set; } = true;
}

public class BatchScanScreenshotRequestDto
{
    [JsonPropertyName("screenshots")]
    public List<ScanScreenshotRequestDto> Screenshots { get; set; } = new();
}

public class BatchScanResponseDto
{
    [JsonPropertyName("processed_count")]
    public int ProcessedCount { get; set; }

    [JsonPropertyName("upserted_count")]
    public int UpsertedCount { get; set; }

    [JsonPropertyName("screenshots")]
    public List<ScreenshotDto> Screenshots { get; set; } = new();

    [JsonPropertyName("errors")]
    public List<string> Errors { get; set; } = new();
}

public class ClassifyScreenshotRequestDto
{
    [JsonPropertyName("screenshot_id")]
    public string? ScreenshotId { get; set; }

    [JsonPropertyName("file_name")]
    public string? FileName { get; set; }

    [JsonPropertyName("ocr_text")]
    public string OCRText { get; set; } = string.Empty;

    [JsonPropertyName("vision_description")]
    public string? VisionDescription { get; set; }

    [JsonPropertyName("source_app")]
    public string? SourceApp { get; set; }

    [JsonPropertyName("existing_category")]
    public string? ExistingCategory { get; set; }
}

public class BatchClassifyRequestDto
{
    [JsonPropertyName("items")]
    public List<ClassifyScreenshotRequestDto> Items { get; set; } = new();
}

public class ClassificationResultDto
{
    [JsonPropertyName("screenshot_id")]
    public string ScreenshotId { get; set; } = string.Empty;

    [JsonPropertyName("category_id")]
    public string CategoryId { get; set; } = string.Empty;

    [JsonPropertyName("category")]
    public string Category { get; set; } = string.Empty;

    [JsonPropertyName("category_name")]
    public string CategoryName => Category;

    [JsonPropertyName("subcategory")]
    public string? SubCategory { get; set; }

    [JsonPropertyName("suggested_tags")]
    public List<string> Tags { get; set; } = new();

    [JsonPropertyName("confidence")]
    public double Confidence { get; set; }

    [JsonPropertyName("summary")]
    public string Summary { get; set; } = string.Empty;

    [JsonPropertyName("source_app")]
    public string? SourceApp { get; set; }

    [JsonPropertyName("model_name")]
    public string ModelName { get; set; } = string.Empty;
}

public class BatchClassifyResponseDto
{
    [JsonPropertyName("results")]
    public List<ClassificationResultDto> Results { get; set; } = new();
}

public class UpdateScreenshotRequestDto
{
    [JsonPropertyName("category_id")]
    public Guid? CategoryId { get; set; }

    [JsonPropertyName("category_name")]
    public string? CategoryName { get; set; }

    [JsonPropertyName("sub_category_id")]
    public Guid? SubCategoryId { get; set; }

    [JsonPropertyName("subcategory")]
    public string? SubCategory { get; set; }

    [JsonPropertyName("tags")]
    public List<string>? Tags { get; set; }

    [JsonPropertyName("is_favorite")]
    public bool? IsFavorite { get; set; }

    [JsonPropertyName("is_reviewed")]
    public bool? IsReviewed { get; set; }
}

public class ScreenshotFilterDto : PagedRequest
{
    public Guid? CategoryId { get; set; }
    public Guid? SubCategoryId { get; set; }
    public string? Tag { get; set; }
    public string? SourceApp { get; set; }
    public bool? IsFavorite { get; set; }
    public bool? IsReviewed { get; set; }
    public bool? NeedsReview { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public string? SearchTerm { get; set; }
    public int Limit { get; set; }
    public int Offset { get; set; }
}
