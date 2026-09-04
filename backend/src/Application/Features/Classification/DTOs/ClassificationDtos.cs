using System.Text.Json.Serialization;

namespace AI.ScreenshotOrganizer.Application.Features.Classification.DTOs;

public class ClassifyRequestDto
{
    [JsonPropertyName("screenshot_id")]
    public string? ScreenshotId { get; set; }

    [JsonPropertyName("file_name")]
    public string? FileName { get; set; }

    [JsonPropertyName("file_path")]
    public string? FilePath { get; set; }

    [JsonPropertyName("ocr_text")]
    public string OCRText { get; set; } = string.Empty;

    [JsonPropertyName("vision_description")]
    public string? VisionDescription { get; set; }

    [JsonPropertyName("source_app")]
    public string? SourceApp { get; set; }

    [JsonPropertyName("existing_category")]
    public string? ExistingCategory { get; set; }
}

public class ReclassifyRequestDto
{
    [JsonPropertyName("screenshot_id")]
    public string ScreenshotId { get; set; } = string.Empty;

    [JsonPropertyName("force_reclassify")]
    public bool ForceReclassify { get; set; } = true;

    [JsonPropertyName("user_hint")]
    public string? UserHint { get; set; }
}

public class ClassificationResponseDto
{
    [JsonPropertyName("screenshot_id")]
    public string ScreenshotId { get; set; } = string.Empty;

    [JsonPropertyName("category_id")]
    public string CategoryId { get; set; } = string.Empty;

    [JsonPropertyName("category_name")]
    public string CategoryName { get; set; } = string.Empty;

    [JsonPropertyName("subcategory_id")]
    public string? SubCategoryId { get; set; }

    [JsonPropertyName("subcategory")]
    public string? SubCategory { get; set; }

    [JsonPropertyName("sub_category_name")]
    public string? SubCategoryName { get; set; }

    [JsonPropertyName("folder_path")]
    public List<string> FolderPath { get; set; } = new();

    [JsonPropertyName("detected_app")]
    public string? DetectedApp { get; set; }

    [JsonPropertyName("suggested_tags")]
    public List<string> Tags { get; set; } = new();

    [JsonPropertyName("keywords")]
    public List<string> Keywords { get; set; } = new();

    [JsonPropertyName("confidence")]
    public double Confidence { get; set; }

    [JsonPropertyName("summary")]
    public string Summary { get; set; } = string.Empty;

    [JsonPropertyName("model_name")]
    public string ModelName { get; set; } = string.Empty;

    [JsonPropertyName("is_auto_categorized")]
    public bool IsAutoCategorized { get; set; } = true;
}

public class ClassificationHistoryDto
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("screenshot_id")]
    public Guid ScreenshotId { get; set; }

    [JsonPropertyName("category")]
    public string Category { get; set; } = string.Empty;

    [JsonPropertyName("subcategory")]
    public string? SubCategory { get; set; }

    [JsonPropertyName("tags")]
    public List<string> Tags { get; set; } = new();

    [JsonPropertyName("confidence")]
    public double Confidence { get; set; }

    [JsonPropertyName("model_name")]
    public string ModelName { get; set; } = string.Empty;

    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; }
}
