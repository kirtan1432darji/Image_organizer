using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;

namespace AI.ScreenshotOrganizer.Application.Features.Search.DTOs;

public class SearchResultDto
{
    public List<ScreenshotDto> Screenshots { get; set; } = new();
    public string Query { get; set; } = string.Empty;
    public int TotalResults { get; set; }
}
