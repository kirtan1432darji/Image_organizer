using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;
using AI.ScreenshotOrganizer.Application.Features.Auth.Commands.Login;
using AI.ScreenshotOrganizer.Application.Features.Auth.Commands.Register;
using AI.ScreenshotOrganizer.Application.Features.Auth.DTOs;
using AI.ScreenshotOrganizer.Shared.Models;

namespace AI.ScreenshotOrganizer.IntegrationTests.Controllers;

public class AuthEndpointsTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;

    public AuthEndpointsTests(CustomWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Register_ValidPayload_Returns200WithTokens()
    {
        var email = $"user_{Guid.NewGuid():N}@example.com";
        var request = new RegisterCommand("Integration User", email, "SecurePassword123!");

        var response = await _client.PostAsJsonAsync("/api/auth/register", request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>();
        body.Should().NotBeNull();
        body!.Success.Should().BeTrue();
        body.Data!.AccessToken.Should().NotBeNullOrEmpty();
        body.Data.RefreshToken.Should().NotBeNullOrEmpty();
        body.Data.User.Email.Should().Be(email);
    }

    [Fact]
    public async Task Login_ValidCredentials_Returns200WithTokens()
    {
        var email = $"login_{Guid.NewGuid():N}@example.com";
        var regRequest = new RegisterCommand("Login Test", email, "Password123!");
        await _client.PostAsJsonAsync("/api/auth/register", regRequest);

        var loginRequest = new LoginCommand(email, "Password123!");
        var response = await _client.PostAsJsonAsync("/api/auth/login", loginRequest);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponseDto>>();
        body.Should().NotBeNull();
        body!.Success.Should().BeTrue();
        body.Data!.AccessToken.Should().NotBeNullOrEmpty();
    }
}

