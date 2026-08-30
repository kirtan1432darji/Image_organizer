using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AI.ScreenshotOrganizer.Application.Features.Categories.Commands.CreateCategory;
using AI.ScreenshotOrganizer.Application.Features.Categories.Commands.DeleteCategory;
using AI.ScreenshotOrganizer.Application.Features.Categories.Commands.UpdateCategory;
using AI.ScreenshotOrganizer.Application.Features.Categories.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Categories.Queries.GetCategories;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.API.Controllers;

[Authorize]
public class CategoriesController : ApiControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<CategoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll()
    {
        var result = await Mediator.Send(new GetCategoriesQuery());
        return Ok(ApiResponse<IReadOnlyList<CategoryDto>>.SuccessResponse(result));
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<CategoryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromBody] CreateCategoryRequestDto request)
    {
        var result = await Mediator.Send(new CreateCategoryCommand(request));
        return Ok(ApiResponse<CategoryDto>.SuccessResponse(result, "Category created successfully."));
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<CategoryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update([FromRoute] Guid id, [FromBody] UpdateCategoryRequestDto request)
    {
        var result = await Mediator.Send(new UpdateCategoryCommand(id, request));
        return Ok(ApiResponse<CategoryDto>.SuccessResponse(result, "Category updated successfully."));
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete([FromRoute] Guid id)
    {
        var result = await Mediator.Send(new DeleteCategoryCommand(id));
        return Ok(ApiResponse<bool>.SuccessResponse(result, "Category deleted successfully."));
    }
}
