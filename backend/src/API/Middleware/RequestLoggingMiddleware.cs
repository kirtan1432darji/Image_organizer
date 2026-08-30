using System.Diagnostics;

namespace AI.ScreenshotOrganizer.API.Middleware;

public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var timer = Stopwatch.StartNew();
        var request = context.Request;

        _logger.LogInformation("HTTP {Method} {Path} started", request.Method, request.Path);

        try
        {
            await _next(context);
        }
        finally
        {
            timer.Stop();
            _logger.LogInformation("HTTP {Method} {Path} responded {StatusCode} in {Elapsed}ms",
                request.Method, request.Path, context.Response.StatusCode, timer.ElapsedMilliseconds);
        }
    }
}
