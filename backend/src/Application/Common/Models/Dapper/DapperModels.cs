namespace AI.ScreenshotOrganizer.Application.Common.Models.Dapper;

public class ScanScreenshotResult
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string DeviceAssetId { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public long FileSize { get; set; }
    public DateTime CapturedDate { get; set; }
    public string SourceApp { get; set; } = string.Empty;
    public int Width { get; set; }
    public int Height { get; set; }
    public string OCRText { get; set; } = string.Empty;
    public string? VisionDescription { get; set; }
    public string OCRStatus { get; set; } = string.Empty;
    public Guid? CategoryId { get; set; }
    public Guid? SubCategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? SubCategoryName { get; set; }
    public double Confidence { get; set; }
    public bool IsFavorite { get; set; }
    public bool IsReviewed { get; set; }
    public DateTime? LastScannedAt { get; set; }
    public DateTime CreatedOn { get; set; }
}

public class FolderContextResult
{
    public Guid CategoryId { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public Guid? ParentCategoryId { get; set; }
    public string? Icon { get; set; }
    public string? Color { get; set; }
    public string? Summary { get; set; }
    public string? KeyTopicsJson { get; set; }
    public int ScreenshotCount { get; set; }
    public DateTime? LastGeneratedAt { get; set; }
    public string? AIModelName { get; set; }
}

public class SubcategoryItemResult
{
    public Guid SubCategoryId { get; set; }
    public string SubCategoryName { get; set; } = string.Empty;
    public string? Icon { get; set; }
    public int DisplayOrder { get; set; }
    public int ItemCount { get; set; }
}

public class SearchScreenshotResult
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string DeviceAssetId { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public long FileSize { get; set; }
    public string ImagePath { get; set; } = string.Empty;
    public string? ThumbnailPath { get; set; }
    public DateTime CapturedDate { get; set; }
    public string SourceApp { get; set; } = string.Empty;
    public int Width { get; set; }
    public int Height { get; set; }
    public string OCRText { get; set; } = string.Empty;
    public string? VisionDescription { get; set; }
    public string OCRStatus { get; set; } = string.Empty;
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public Guid? SubCategoryId { get; set; }
    public string? SubCategoryName { get; set; }
    public double Confidence { get; set; }
    public bool IsFavorite { get; set; }
    public bool IsReviewed { get; set; }
    public DateTime CreatedOn { get; set; }
}

public class ChatMessageResult
{
    public Guid Id { get; set; }
    public Guid SessionId { get; set; }
    public Guid UserId { get; set; }
    public Guid? CategoryId { get; set; }
    public Guid? ScreenshotId { get; set; }
    public string Role { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? ReferencedScreenshotIdsJson { get; set; }
    public int? PromptTokens { get; set; }
    public int? CompletionTokens { get; set; }
    public DateTime CreatedOn { get; set; }
    public string? AIModelName { get; set; }
}

public class FolderTimelineResult
{
    public Guid Id { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string DeviceAssetId { get; set; } = string.Empty;
    public string ImagePath { get; set; } = string.Empty;
    public string? ThumbnailPath { get; set; }
    public DateTime CapturedDate { get; set; }
    public string SourceApp { get; set; } = string.Empty;
    public string? OCRPreview { get; set; }
    public string? VisionDescription { get; set; }
    public double Confidence { get; set; }
    public bool IsFavorite { get; set; }
    public string? CategoryName { get; set; }
    public string? SubCategoryName { get; set; }
}

public class UpdateCategoryResult
{
    public Guid Id { get; set; }
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public Guid? SubCategoryId { get; set; }
    public string? SubCategoryName { get; set; }
    public bool IsReviewed { get; set; }
    public DateTime? UpdatedOn { get; set; }
}

public class PendingTaskResult
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime? DueDate { get; set; }
    public string Priority { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
    public Guid? ScreenshotId { get; set; }
    public string? ScreenshotFileName { get; set; }
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public DateTime CreatedOn { get; set; }
}
