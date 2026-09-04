using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Xunit;
using AI.ScreenshotOrganizer.Application.Features.Classification.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;
using AI.ScreenshotOrganizer.Infrastructure.Services;
using AI.ScreenshotOrganizer.Persistence.Context;

namespace AI.ScreenshotOrganizer.UnitTests.Features.Classification;

public class ClassificationServiceTests
{
    private ApplicationDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: $"ContextVault_Test_{Guid.NewGuid()}")
            .Options;

        return new ApplicationDbContext(options);
    }

    [Fact]
    public async Task ClassifyAsync_WhatsAppPayroll_ClassifiesToProjectsNHDCPayroll()
    {
        using var context = CreateInMemoryDbContext();
        var service = new ClassificationService(context);

        var request = new ClassifyRequestDto
        {
            FileName = "Screenshot_20260904_WhatsApp.jpg",
            FilePath = "/storage/emulated/0/Pictures/Screenshots/Screenshot_WhatsApp.jpg",
            OCRText = "WhatsApp Group: NHDC Project\nMonthly salary slip and payroll breakdown.\nTotal payout disbursed: $4,500",
            SourceApp = "WhatsApp"
        };

        var result = await service.ClassifyAsync(request);

        result.Should().NotBeNull();
        result.FolderPath.Should().Contain("Projects");
        result.FolderPath.Should().Contain("Payroll");
        result.CategoryName.Should().Be("Projects");
        result.Confidence.Should().BeGreaterThan(0.9);
        result.DetectedApp.Should().Be("WhatsApp");
        result.IsAutoCategorized.Should().BeTrue();

        // Verify categories created in DB
        var categories = await context.Categories.ToListAsync();
        categories.Should().Contain(c => c.Name == "Projects");
        categories.Should().Contain(c => c.Name == "Payroll");
    }

    [Fact]
    public async Task ClassifyAsync_AmazonShoes_ClassifiesToShoppingShoes()
    {
        using var context = CreateInMemoryDbContext();
        var service = new ClassificationService(context);

        var request = new ClassifyRequestDto
        {
            FileName = "Screenshot_Amazon.png",
            OCRText = "Amazon.com: Nike Air Zoom Running Shoes Sneakers\nOrder placed successfully.\nTotal Price: $129.99",
            SourceApp = "Amazon"
        };

        var result = await service.ClassifyAsync(request);

        result.Should().NotBeNull();
        result.FolderPath.Should().Equal(new List<string> { "Shopping", "Shoes" });
        result.CategoryName.Should().Be("Shopping");
        result.SubCategoryName.Should().Be("Shoes");
        result.DetectedApp.Should().Be("Amazon");
        result.Confidence.Should().BeGreaterThan(0.9);
    }

    [Fact]
    public async Task ClassifyAsync_FlutterTutorial_ClassifiesToLearningFlutter()
    {
        using var context = CreateInMemoryDbContext();
        var service = new ClassificationService(context);

        var request = new ClassifyRequestDto
        {
            FileName = "Screenshot_YouTube.png",
            OCRText = "YouTube: Flutter Tutorial 2026 - State Management with Riverpod Course Lecture",
            SourceApp = "YouTube"
        };

        var result = await service.ClassifyAsync(request);

        result.Should().NotBeNull();
        result.FolderPath.Should().Equal(new List<string> { "Learning", "Flutter" });
        result.CategoryName.Should().Be("Learning");
        result.SubCategoryName.Should().Be("Flutter");
        result.DetectedApp.Should().Be("YouTube");
    }

    [Fact]
    public async Task ClassifyAsync_UPIPayment_ClassifiesToFinancePayments()
    {
        using var context = CreateInMemoryDbContext();
        var service = new ClassificationService(context);

        var request = new ClassifyRequestDto
        {
            FileName = "Screenshot_GPay.png",
            OCRText = "Google Pay: Paid to Merchant. UPI Transaction ID: 123456789. Amount: $45.00",
            SourceApp = "Google Pay"
        };

        var result = await service.ClassifyAsync(request);

        result.Should().NotBeNull();
        result.FolderPath.Should().Equal(new List<string> { "Finance", "Payments" });
        result.CategoryName.Should().Be("Finance");
        result.SubCategoryName.Should().Be("Payments");
    }

    [Fact]
    public async Task ClassifyAsync_UpdatesScreenshotAndAddsClassificationHistory()
    {
        using var context = CreateInMemoryDbContext();
        var screenshotId = Guid.NewGuid();
        var userId = Guid.NewGuid();

        var screenshot = new Screenshot
        {
            Id = screenshotId,
            UserId = userId,
            FileName = "test.png",
            ImagePath = "/test.png",
            CapturedDate = DateTime.UtcNow,
            OCRText = "Nike running shoes on Amazon cart"
        };
        context.Screenshots.Add(screenshot);
        await context.SaveChangesAsync();

        var service = new ClassificationService(context);
        var request = new ClassifyRequestDto
        {
            ScreenshotId = screenshotId.ToString(),
            FileName = "test.png",
            OCRText = screenshot.OCRText,
            SourceApp = "Amazon"
        };

        var result = await service.ClassifyAsync(request, userId);

        result.Should().NotBeNull();
        screenshot.CategoryId.Should().NotBeNull();
        screenshot.IsAutoCategorized.Should().BeTrue();
        screenshot.DetectedApp.Should().Be("Amazon");

        var history = await service.GetHistoryAsync(screenshotId);
        history.Should().HaveCount(1);
        history[0].Category.Should().Be("Shopping");
        history[0].SubCategory.Should().Be("Shoes");
    }
}
