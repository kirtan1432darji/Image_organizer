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

public class ScreenshotsEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;

    public ScreenshotsEndpointsTests(CustomWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    private async Task<string> AuthenticateAsync()
    {
        var email = $"test_{Guid.NewGuid():N}@example.com";
        var reg = new RegisterCommand("Test Tester", email, "Password123!");
        var res = await _client.PostAsJsonAsync("/api/auth/register", reg);
        var body = await res.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>();
        return body!.Data!.AccessToken;
    }

    [Fact]
    public async Task Classify_AnonymousAllowed_ReturnsClassification()
    {
        var request = new ClassifyScreenshotRequestDto
        {
            OCRText = "Total $24.99 Apple Store Purchase",
            SourceApp = "Apple"
        };

        var response = await _client.PostAsJsonAsync("/api/screenshots/classify", request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<ClassificationResultDto>>();
        body.Should().NotBeNull();
        body!.Success.Should().BeTrue();
        body.Data!.Category.Should().Be("Receipts & Invoices");
    }

    [Fact]
    public async Task Scan_Authenticated_IndexesScreenshot()
    {
        var token = await AuthenticateAsync();
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var scanRequest = new ScanScreenshotRequestDto
        {
            ImageId = $"img_{Guid.NewGuid():N}",
            ImagePath = "/storage/DCIM/screenshot.png",
            CapturedDate = DateTime.UtcNow,
            SourceApp = "GitHub",
            Width = 1080,
            Height = 1920,
            OCRText = "git commit -m 'Initial commit' function test()",
            AutoClassify = true
        };

        var response = await _client.PostAsJsonAsync("/api/screenshots/scan", scanRequest);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<ScreenshotDto>>();
        body.Should().NotBeNull();
        body!.Success.Should().BeTrue();
        body.Data!.ImageId.Should().Be(scanRequest.ImageId);
        body.Data.Category.Should().NotBeNull();
        body.Data.Category!.Name.Should().Be("Code & Tech");
    }
}

