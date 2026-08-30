using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;
using AI.ScreenshotOrganizer.Application.Features.Auth.Commands.Register;
using AI.ScreenshotOrganizer.Application.Features.Auth.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Categories.DTOs;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.IntegrationTests.Controllers;

public class CategoriesEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;

    public CategoriesEndpointsTests(CustomWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    private async Task<string> AuthenticateAsync()
    {
        var email = $"cat_user_{Guid.NewGuid():N}@example.com";
        var reg = new RegisterCommand("Cat User", email, "Password123!");
        var res = await _client.PostAsJsonAsync("/api/auth/register", reg);
        var body = await res.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>();
        return body!.Data!.AccessToken;
    }

    [Fact]
    public async Task GetCategories_Authenticated_ReturnsDefaultCategories()
    {
        var token = await AuthenticateAsync();
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _client.GetAsync("/api/categories");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<IReadOnlyList<CategoryDto>>>();
        body.Should().NotBeNull();
        body!.Success.Should().BeTrue();
        body.Data.Should().NotBeEmpty();
    }

    [Fact]
    public async Task CreateCategory_Authenticated_AddsCategory()
    {
        var token = await AuthenticateAsync();
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var request = new CreateCategoryRequestDto
        {
            Name = $"Custom Folder {Guid.NewGuid():N}",
            Icon = "folder",
            Color = "#FF5722"
        };

        var response = await _client.PostAsJsonAsync("/api/categories", request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<CategoryDto>>();
        body.Should().NotBeNull();
        body!.Success.Should().BeTrue();
        body.Data!.Name.Should().Be(request.Name);
    }
}

