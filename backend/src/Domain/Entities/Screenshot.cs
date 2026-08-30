using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class Screenshot : BaseEntity
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public string ImageId { get; set; } = string.Empty;
    public string ImagePath { get; set; } = string.Empty;
    public string? ThumbnailPath { get; set; }
    public DateTime CapturedDate { get; set; }
    public string SourceApp { get; set; } = string.Empty;
    public int Width { get; set; }
    public int Height { get; set; }
    public string OCRText { get; set; } = string.Empty;
    public string? VisionDescription { get; set; }
    
    public Guid? CategoryId { get; set; }
    public Category? Category { get; set; }

    public Guid? SubCategoryId { get; set; }
    public Category? SubCategory { get; set; }

    public double Confidence { get; set; }
    public string Hash { get; set; } = string.Empty;
    public bool IsFavorite { get; set; } = false;

    public ICollection<ScreenshotCategory> ScreenshotCategories { get; set; } = new List<ScreenshotCategory>();
    public ICollection<ScreenshotTag> ScreenshotTags { get; set; } = new List<ScreenshotTag>();
    public OCRCache? OCRCache { get; set; }
    public ICollection<ClassificationHistory> ClassificationHistories { get; set; } = new List<ClassificationHistory>();
}
