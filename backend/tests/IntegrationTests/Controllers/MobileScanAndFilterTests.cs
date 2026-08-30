using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;
using AI.ScreenshotOrganizer.Application.Features.Auth.Commands.Register;
using AI.ScreenshotOrganizer.Application.Features.Auth.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.IntegrationTests.Controllers;

public class MobileScanAndFilterTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;

    public MobileScanAndFilterTests(CustomWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    private async Task<string> AuthenticateAsync()
    {
        var email = $"mob_{Guid.NewGuid():N}@example.com";
        var reg = new RegisterCommand("Mobile User", email, "Password123!");
        var res = await _client.PostAsJsonAsync("/api/auth/register", reg);
        var body = await res.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>();
        return body!.Data!.AccessToken;
    }

    [Fact]
    public async Task HealthCheck_Returns200WithDatabaseStatus()
    {
        var response = await _client.GetAsync("/api/health");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var body = await response.Content.ReadFromJsonAsync<ApiResponse<object>>();
        body.Should().NotBeNull();
        body!.Success.Should().BeTrue();
    }

    [Fact]
    public async Task Scan_RepeatedWithSameAssetId_UpsertsWithoutDuplicate()
    {
        var token = await AuthenticateAsync();
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var assetId = $"asset_{Guid.NewGuid():N}";
        var scan1 = new ScanScreenshotRequestDto
        {
            DeviceAssetId = assetId,
            FileName = "First_Scan.png",
            ImagePath = "/storage/emulated/0/DCIM/1.png",
            CapturedDate = DateTime.UtcNow,
            OCRText = "Receipt total $15.00"
        };

        var res1 = await _client.PostAsJsonAsync("/api/screenshots/scan", scan1);
        res1.StatusCode.Should().Be(HttpStatusCode.OK);
        var body1 = await res1.Content.ReadFromJsonAsync<ApiResponse<ScreenshotDto>>();
        body1!.Data!.FileName.Should().Be("First_Scan.png");

        // Second scan of the same device asset ID with updated metadata
        var scan2 = new ScanScreenshotRequestDto
        {
            DeviceAssetId = assetId,
            FileName = "Second_Scan_Updated.png",
            ImagePath = "/storage/emulated/0/DCIM/1.png",
            CapturedDate = DateTime.UtcNow,
            OCRText = "Receipt total $15.00 Starbucks Coffee"
        };

        var res2 = await _client.PostAsJsonAsync("/api/screenshots/scan", scan2);
        res2.StatusCode.Should().Be(HttpStatusCode.OK);
        var body2 = await res2.Content.ReadFromJsonAsync<ApiResponse<ScreenshotDto>>();
        body2!.Data!.Id.Should().Be(body1.Data.Id); // Same persistent entity ID!
        body2.Data.FileName.Should().Be("Second_Scan_Updated.png");
    }

    [Fact]
    public async Task BatchScan_InsertsMultipleScreenshots()
    {
        var token = await AuthenticateAsync();
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var request = new BatchScanScreenshotRequestDto
        {
            Screenshots = new List<ScanScreenshotRequestDto>
            {
                new() { DeviceAssetId = $"batch_{Guid.NewGuid():N}", FileName = "Batch1.png", ImagePath = "/p1.png" },
                new() { DeviceAssetId = $"batch_{Guid.NewGuid():N}", FileName = "Batch2.png", ImagePath = "/p2.png" }
            }
        };

        var response = await _client.PostAsJsonAsync("/api/screenshots/batch", request);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<BatchScanResponseDto>>();
        body.Should().NotBeNull();
        body!.Data!.ProcessedCount.Should().Be(2);
    }
}
