using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class Screenshot : BaseEntity
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public string DeviceAssetId { get; set; } = string.Empty;
    public string ImageId { get; set; } = string.Empty; // Synced with DeviceAssetId for backwards compatibility
    public string ImagePath { get; set; } = string.Empty;
    public string? ThumbnailPath { get; set; }
    public string FileName { get; set; } = string.Empty;
    public long FileSize { get; set; }
    public string? ContentUri { get; set; }
    public DateTime CapturedDate { get; set; }
    public string SourceApp { get; set; } = string.Empty;
    public int Width { get; set; }
    public int Height { get; set; }
    public string OCRText { get; set; } = string.Empty;
    public string? VisionDescription { get; set; }
    public string OCRStatus { get; set; } = "none"; // none, pending, processing, completed, failed
    
    public Guid? CategoryId { get; set; }
    public Category? Category { get; set; }

    public Guid? SubCategoryId { get; set; }
    public Category? SubCategory { get; set; }

    public double Confidence { get; set; }
    public double ClassificationConfidence { get => Confidence; set => Confidence = value; }
    public string? DetectedApp { get; set; }
    public string KeywordsJson { get; set; } = "[]";
    public bool IsAutoCategorized { get; set; } = false;
    public string Hash { get; set; } = string.Empty;
    public bool IsFavorite { get; set; } = false;
    public bool IsReviewed { get; set; } = false;
    public bool IsSynced { get; set; } = true;
    public bool IsMock { get; set; } = false;
    public DateTime? LastScannedAt { get; set; }

    public ICollection<ScreenshotCategory> ScreenshotCategories { get; set; } = new List<ScreenshotCategory>();
    public ICollection<ScreenshotTag> ScreenshotTags { get; set; } = new List<ScreenshotTag>();
    public OCRCache? OCRCache { get; set; }
    public ICollection<ClassificationHistory> ClassificationHistories { get; set; } = new List<ClassificationHistory>();

    // ContextVault AI Workspace Relations
    public ICollection<ScreenshotEntity> ExtractedEntities { get; set; } = new List<ScreenshotEntity>();
    public ICollection<TaskItem> Tasks { get; set; } = new List<TaskItem>();
    public ICollection<ChatHistory> ChatHistories { get; set; } = new List<ChatHistory>();
    public ICollection<SearchHistory> SearchClicks { get; set; } = new List<SearchHistory>();
    public ICollection<CollectionScreenshot> CollectionScreenshots { get; set; } = new List<CollectionScreenshot>();
    public ICollection<EmbeddingCache> EmbeddingCaches { get; set; } = new List<EmbeddingCache>();
}
