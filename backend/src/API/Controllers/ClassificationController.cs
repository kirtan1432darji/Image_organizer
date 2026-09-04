using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Common.Models;
using AI.ScreenshotOrganizer.Application.Features.Classification.DTOs;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ClassificationController : ControllerBase
{
    private readonly IClassificationService _classificationService;

    public ClassificationController(IClassificationService classificationService)
    {
        _classificationService = classificationService;
    }

    [HttpPost("classify")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<ClassificationResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Classify([FromBody] ClassifyRequestDto request, CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var result = await _classificationService.ClassifyAsync(request, userId, cancellationToken);
        return Ok(ApiResponse<ClassificationResponseDto>.SuccessResponse(result, "Screenshot classified successfully."));
    }

    [HttpPost("reclassify")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<ClassificationResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Reclassify([FromBody] ReclassifyRequestDto request, CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var result = await _classificationService.ReclassifyAsync(request, userId, cancellationToken);
        return Ok(ApiResponse<ClassificationResponseDto>.SuccessResponse(result, "Screenshot reclassified successfully."));
    }

    [HttpGet("history/{screenshotId:guid}")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<ClassificationHistoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetHistory([FromRoute] Guid screenshotId, CancellationToken cancellationToken)
    {
        var result = await _classificationService.GetHistoryAsync(screenshotId, cancellationToken);
        return Ok(ApiResponse<IReadOnlyList<ClassificationHistoryDto>>.SuccessResponse(result));
    }

    private Guid? GetCurrentUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(claim, out var guid) ? guid : null;
    }
}
