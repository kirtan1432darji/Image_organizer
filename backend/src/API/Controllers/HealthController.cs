using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.API.Controllers;

[AllowAnonymous]
[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    private readonly IApplicationDbContext _context;

    public HealthController(IApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        bool canConnect = false;
        try
        {
            if (_context is Microsoft.EntityFrameworkCore.DbContext dbContext)
            {
                canConnect = await dbContext.Database.CanConnectAsync();
            }
        }
        catch
        {
            canConnect = false;
        }

        var healthData = new
        {
            status = canConnect ? "Healthy" : "Degraded",
            database = canConnect ? "Connected" : "Unreachable",
            version = "1.0.0",
            serverTime = DateTime.UtcNow
        };

        return Ok(ApiResponse<object>.SuccessResponse(healthData, "System health status."));
    }
}
