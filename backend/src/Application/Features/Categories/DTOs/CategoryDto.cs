namespace AI.ScreenshotOrganizer.Application.Features.Categories.DTOs;

public class CategoryDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public Guid? ParentCategoryId { get; set; }
    public string? Icon { get; set; }
    public string? Color { get; set; }
    public bool CreatedByAI { get; set; }
    public DateTime CreatedDate { get; set; }
    public List<CategoryDto> SubCategories { get; set; } = new();
}

public class CreateCategoryRequestDto
{
    public string Name { get; set; } = string.Empty;
    public Guid? ParentCategoryId { get; set; }
    public string? Icon { get; set; }
    public string? Color { get; set; }
}

public class UpdateCategoryRequestDto
{
    public string Name { get; set; } = string.Empty;
    public Guid? ParentCategoryId { get; set; }
    public string? Icon { get; set; }
    public string? Color { get; set; }
}
