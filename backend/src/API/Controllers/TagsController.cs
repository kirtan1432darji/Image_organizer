using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AI.ScreenshotOrganizer.Application.Features.Tags.Commands.CreateTag;
using AI.ScreenshotOrganizer.Application.Features.Tags.Commands.DeleteTag;
using AI.ScreenshotOrganizer.Application.Features.Tags.Commands.UpdateTag;
using AI.ScreenshotOrganizer.Application.Features.Tags.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Tags.Queries.GetTags;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.API.Controllers;

[Authorize]
public class TagsController : ApiControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<TagDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll()
    {
        var result = await Mediator.Send(new GetTagsQuery());
        return Ok(ApiResponse<IReadOnlyList<TagDto>>.SuccessResponse(result));
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<TagDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreateTagRequestDto request)
    {
        var result = await Mediator.Send(new CreateTagCommand(request));
        return Ok(ApiResponse<TagDto>.SuccessResponse(result, "Tag created successfully."));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<TagDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update([FromRoute] Guid id, [FromBody] UpdateTagRequestDto request)
    {
        var result = await Mediator.Send(new UpdateTagCommand(id, request));
        return Ok(ApiResponse<TagDto>.SuccessResponse(result, "Tag updated successfully."));
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete([FromRoute] Guid id)
    {
        var result = await Mediator.Send(new DeleteTagCommand(id));
        return Ok(ApiResponse<bool>.SuccessResponse(result, "Tag deleted successfully."));
    }
}
