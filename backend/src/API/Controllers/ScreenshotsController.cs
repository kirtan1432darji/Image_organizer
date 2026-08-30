using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AI.ScreenshotOrganizer.Application.Common.Models;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.ClassifyScreenshot;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.DeleteScreenshot;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.ScanScreenshot;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.ToggleFavorite;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.UpdateScreenshot;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.Queries.GetScreenshotById;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.Queries.GetScreenshots;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.API.Controllers;

[Authorize]
public class ScreenshotsController : ApiControllerBase
{
    [HttpPost("scan")]
    [ProducesResponseType(typeof(ApiResponse<ScreenshotDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Scan([FromBody] ScanScreenshotRequestDto request)
    {
        var result = await Mediator.Send(new ScanScreenshotCommand(request));
        return Ok(ApiResponse<ScreenshotDto>.SuccessResponse(result, "Screenshot scanned and indexed successfully."));
    }

    [HttpPost("classify")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<ClassificationResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Classify([FromBody] ClassifyScreenshotRequestDto request)
    {
        var result = await Mediator.Send(new ClassifyScreenshotCommand(request));
        return Ok(ApiResponse<ClassificationResultDto>.SuccessResponse(result, "Screenshot classified successfully."));
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<ScreenshotDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetScreenshots([FromQuery] ScreenshotFilterDto filter)
    {
        var result = await Mediator.Send(new GetScreenshotsQuery(filter));
        return Ok(ApiResponse<PagedResult<ScreenshotDto>>.SuccessResponse(result));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ScreenshotDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById([FromRoute] Guid id)
    {
        var result = await Mediator.Send(new GetScreenshotByIdQuery(id));
        return Ok(ApiResponse<ScreenshotDto>.SuccessResponse(result));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ScreenshotDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update([FromRoute] Guid id, [FromBody] UpdateScreenshotRequestDto request)
    {
        var result = await Mediator.Send(new UpdateScreenshotCommand(id, request));
        return Ok(ApiResponse<ScreenshotDto>.SuccessResponse(result, "Screenshot updated successfully."));
    }

    [HttpPatch("{id:guid}/favorite")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ToggleFavorite([FromRoute] Guid id, [FromQuery] bool? isFavorite = null)
    {
        var result = await Mediator.Send(new ToggleFavoriteCommand(id, isFavorite));
        return Ok(ApiResponse<bool>.SuccessResponse(result, $"Favorite status updated to: {result}"));
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete([FromRoute] Guid id)
    {
        var result = await Mediator.Send(new DeleteScreenshotCommand(id));
        return Ok(ApiResponse<bool>.SuccessResponse(result, "Screenshot metadata deleted successfully."));
    }
}
