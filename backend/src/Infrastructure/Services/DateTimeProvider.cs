using AI.ScreenshotOrganizer.Application.Common.Interfaces;

namespace AI.ScreenshotOrganizer.Infrastructure.Services;

public class DateTimeProvider : IDateTimeProvider
{
    public DateTime UtcNow => DateTime.UtcNow;
}
