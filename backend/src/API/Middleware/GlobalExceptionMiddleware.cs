using System.Net;
using System.Text.Json;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Domain.Exceptions;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.API.Middleware;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception occurred: {Message}", ex.Message);
            await HandleExceptionAsync(context, ex);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";

        var (statusCode, message, errors) = exception switch
        {
            ValidationException valEx => (
                (int)HttpStatusCode.BadRequest,
                "Validation error.",
                valEx.Errors.SelectMany(kvp => kvp.Value).ToList()
            ),
            NotFoundException notFoundEx => (
                (int)HttpStatusCode.NotFound,
                notFoundEx.Message,
                new List<string> { notFoundEx.Message }
            ),
            UnauthorizedException unauthEx => (
                (int)HttpStatusCode.Unauthorized,
                unauthEx.Message,
                new List<string> { unauthEx.Message }
            ),
            ConflictException conflictEx => (
                (int)HttpStatusCode.Conflict,
                conflictEx.Message,
                new List<string> { conflictEx.Message }
            ),
            DomainException domainEx => (
                (int)HttpStatusCode.BadRequest,
                domainEx.Message,
                new List<string> { domainEx.Message }
            ),
            _ => (
                (int)HttpStatusCode.InternalServerError,
                "An unexpected internal error occurred on the server.",
                new List<string> { exception.Message }
            )
        };

        context.Response.StatusCode = statusCode;
        var response = ApiResponse<object>.FailureResponse(message, errors);
        var json = JsonSerializer.Serialize(response, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        await context.Response.WriteAsync(json);
    }
}
