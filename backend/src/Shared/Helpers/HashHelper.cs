using System.Security.Cryptography;
using System.Text;

namespace AI.ScreenshotOrganizer.Shared.Helpers;

public static class HashHelper
{
    public static string ComputeSha256Hash(string rawData)
    {
        if (string.IsNullOrEmpty(rawData)) return string.Empty;
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(rawData));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }

    public static string ComputeSha256Hash(byte[] bytes)
    {
        if (bytes == null || bytes.Length == 0) return string.Empty;
        var hash = SHA256.HashData(bytes);
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}
