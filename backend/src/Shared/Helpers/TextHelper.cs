using System.Text.RegularExpressions;

namespace AI.ScreenshotOrganizer.Shared.Helpers;

public static class TextHelper
{
    public static string Truncate(string text, int maxLength)
    {
        if (string.IsNullOrEmpty(text) || text.Length <= maxLength) return text;
        return text[..maxLength] + "...";
    }

    public static string Sanitize(string text)
    {
        if (string.IsNullOrEmpty(text)) return string.Empty;
        return Regex.Replace(text, @"\s+", " ").Trim();
    }
}
