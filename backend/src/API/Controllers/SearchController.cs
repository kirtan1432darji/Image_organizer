using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AI.ScreenshotOrganizer.Application.Features.Search.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Search.Queries.SearchScreenshots;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.API.Controllers;

[Authorize]
public class SearchController : ApiControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<SearchResultDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Search([FromQuery] string q, [FromQuery] Guid? categoryId = null, [FromQuery] string? sourceApp = null, [FromQuery] int limit = 50)
    {
        var result = await Mediator.Send(new SearchScreenshotsQuery(q, categoryId, sourceApp, limit));
        return Ok(ApiResponse<SearchResultDto>.SuccessResponse(result));
    }
}
