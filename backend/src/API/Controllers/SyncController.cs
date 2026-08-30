using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AI.ScreenshotOrganizer.Application.Features.Sync.Commands.SyncScreenshots;
using AI.ScreenshotOrganizer.Application.Features.Sync.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Sync.Queries.GetChangesSince;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.API.Controllers;

[Authorize]
public class SyncController : ApiControllerBase
{
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<SyncResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Sync([FromBody] SyncRequestDto request)
    {
        var result = await Mediator.Send(new SyncScreenshotsCommand(request));
        return Ok(ApiResponse<SyncResponseDto>.SuccessResponse(result, "Metadata synchronized successfully."));
    }

    [HttpGet("changes")]
    [ProducesResponseType(typeof(ApiResponse<ChangesSinceResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetChanges([FromQuery] DateTime since)
    {
        var result = await Mediator.Send(new GetChangesSinceQuery(since));
        return Ok(ApiResponse<ChangesSinceResponseDto>.SuccessResponse(result));
    }
}
