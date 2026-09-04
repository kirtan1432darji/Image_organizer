using AI.ScreenshotOrganizer.Domain.Common;

namespace AI.ScreenshotOrganizer.Domain.Entities;

public class AppSetting : BaseEntity
{
    public Guid? UserId { get; set; }
    public User? User { get; set; }

    public string SettingKey { get; set; } = string.Empty;
    public string SettingValue { get; set; } = string.Empty;
    public string DataType { get; set; } = "String"; // String, Boolean, Integer, Decimal, Json
    public string? Description { get; set; }
}
