using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;
using AI.ScreenshotOrganizer.Application.Features.Classification.DTOs;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.IntegrationTests.Controllers;

public class ClassificationEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;

    public ClassificationEndpointsTests(CustomWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Post_Classify_ReturnsHierarchicalClassification()
    {
        var request = new ClassifyRequestDto
        {
            FileName = "Screenshot_Amazon_Shoes.png",
            OCRText = "Amazon.com: Nike Air Zoom Running Shoes Sneakers\nOrder placed successfully.\nTotal Price: $129.99",
            SourceApp = "Amazon"
        };

        var response = await _client.PostAsJsonAsync("/api/classification/classify", request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<ClassificationResponseDto>>();
        body.Should().NotBeNull();
        body!.Success.Should().BeTrue();
        body.Data!.CategoryName.Should().Be("Shopping");
        body.Data!.SubCategoryName.Should().Be("Shoes");
        body.Data!.FolderPath.Should().Equal(new List<string> { "Shopping", "Shoes" });
        body.Data!.DetectedApp.Should().Be("Amazon");
        body.Data!.IsAutoCategorized.Should().BeTrue();
    }

    [Fact]
    public async Task Post_Classify_WhatsAppPayroll_ReturnsDeepHierarchy()
    {
        var request = new ClassifyRequestDto
        {
            FileName = "Screenshot_WhatsApp_NHDC.jpg",
            OCRText = "WhatsApp Group: NHDC Project\nMonthly salary slip and payroll breakdown.\nTotal payout disbursed: $4,500",
            SourceApp = "WhatsApp"
        };

        var response = await _client.PostAsJsonAsync("/api/classification/classify", request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<ClassificationResponseDto>>();
        body.Should().NotBeNull();
        body!.Success.Should().BeTrue();
        body.Data!.CategoryName.Should().Be("Projects");
        body.Data!.FolderPath.Should().Contain("Projects");
        body.Data!.FolderPath.Should().Contain("Payroll");
    }

    [Fact]
    public async Task Get_History_ReturnsAuditList()
    {
        var dummyId = Guid.NewGuid();
        var response = await _client.GetAsync($"/api/classification/history/{dummyId}");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<IReadOnlyList<ClassificationHistoryDto>>>();
        body.Should().NotBeNull();
        body!.Success.Should().BeTrue();
        body.Data.Should().NotBeNull();
    }
}
