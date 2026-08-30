namespace AI.ScreenshotOrganizer.Application.Features.Tags.DTOs;

public class TagDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
}

public class CreateTagRequestDto
{
    public string Name { get; set; } = string.Empty;
}

public class UpdateTagRequestDto
{
    public string Name { get; set; } = string.Empty;
}
