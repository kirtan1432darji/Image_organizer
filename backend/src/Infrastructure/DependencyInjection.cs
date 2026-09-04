using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Infrastructure.Authentication;
using AI.ScreenshotOrganizer.Infrastructure.Services;

namespace AI.ScreenshotOrganizer.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddHttpContextAccessor();

        services.AddTransient<IDateTimeProvider, DateTimeProvider>();
        services.AddTransient<IPasswordHasherService, PasswordHasherService>();
        services.AddTransient<IJwtTokenGenerator, JwtTokenGenerator>();
        services.AddScoped<ICurrentUserService, CurrentUserService>();
        services.AddScoped<IAIClassificationService, MockAIClassificationService>();
        services.AddScoped<IClassificationService, ClassificationService>();

        var jwtSecret = configuration["JwtSettings:Secret"] ?? "SuperSecretKeyForScreenshotOrganizerApp2026_Minimum32CharsLong!";
        var jwtIssuer = configuration["JwtSettings:Issuer"] ?? "AI.ScreenshotOrganizer";
        var jwtAudience = configuration["JwtSettings:Audience"] ?? "AI.ScreenshotOrganizer.Mobile";

        services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.SaveToken = true;
            options.RequireHttpsMetadata = false;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = jwtIssuer,
                ValidAudience = jwtAudience,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
                ClockSkew = TimeSpan.Zero
            };
        });

        return services;
    }
}
