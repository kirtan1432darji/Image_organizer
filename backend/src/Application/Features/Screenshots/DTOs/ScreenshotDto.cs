using AI.ScreenshotOrganizer.Application.Common.Models;

namespace AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;

public class TagSummaryDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class CategorySummaryDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Icon { get; set; }
    public string? Color { get; set; }
}

public class ScreenshotDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
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
    public CategorySummaryDto? Category { get; set; }

    public Guid? SubCategoryId { get; set; }
    public CategorySummaryDto? SubCategory { get; set; }

    public double Confidence { get; set; }
    public string Hash { get; set; } = string.Empty;
    public bool IsFavorite { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }

    public List<CategorySummaryDto> Categories { get; set; } = new();
    public List<TagSummaryDto> Tags { get; set; } = new();
}

public class ScanScreenshotRequestDto
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
    public string? Hash { get; set; }
    public bool? AutoClassify { get; set; } = true;
}

public class ClassifyScreenshotRequestDto
{
    public string OCRText { get; set; } = string.Empty;
    public string? VisionDescription { get; set; }
    public string SourceApp { get; set; } = string.Empty;
}

public class ClassificationResultDto
{
    public string Category { get; set; } = string.Empty;
    public string? SubCategory { get; set; }
    public List<string> Tags { get; set; } = new();
    public double Confidence { get; set; }
    public string ModelName { get; set; } = string.Empty;
}

public class UpdateScreenshotRequestDto
{
    public Guid? CategoryId { get; set; }
    public Guid? SubCategoryId { get; set; }
    public List<string>? Tags { get; set; }
    public bool? IsFavorite { get; set; }
}

public class ScreenshotFilterDto : PagedRequest
{
    public Guid? CategoryId { get; set; }
    public Guid? SubCategoryId { get; set; }
    public string? Tag { get; set; }
    public string? SourceApp { get; set; }
    public bool? IsFavorite { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public string? SearchTerm { get; set; }
}
