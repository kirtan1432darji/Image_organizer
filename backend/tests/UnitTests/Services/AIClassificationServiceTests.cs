using FluentAssertions;
using Xunit;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Infrastructure.Services;

namespace AI.ScreenshotOrganizer.UnitTests.Services;

public class AIClassificationServiceTests
{
    private readonly MockAIClassificationService _service;

    public AIClassificationServiceTests()
    {
        _service = new MockAIClassificationService();
    }

    [Theory]
    [InlineData("Starbucks Coffee Total $12.50 Amount Paid with Visa", "Receipts & Invoices", "Dining")]
    [InlineData("Walmart Supercenter Subtotal $45.20 Tax $3.10", "Receipts & Invoices", "Groceries")]
    [InlineData("Electric Utility Bill Account #12345 Due Date Amount $120.00", "Receipts & Invoices", "Utilities")]
    public async Task ClassifyScreenshot_ReceiptKeywords_ReturnsReceiptsCategory(string ocrText, string expectedCat, string expectedSubCat)
    {
        var request = new ClassifyScreenshotRequestDto
        {
            OCRText = ocrText,
            SourceApp = "Camera"
        };

        var result = await _service.ClassifyScreenshotAsync(request);

        result.Should().NotBeNull();
        result.Category.Should().Be(expectedCat);
        result.SubCategory.Should().Be(expectedSubCat);
        result.Confidence.Should().BeGreaterThan(0.8);
        result.Tags.Should().Contain("receipt");
    }

    [Theory]
    [InlineData("Bitcoin BTC Portfolio balance +15.4% Binance", "Finance & Banking", "Crypto")]
    [InlineData("Bank Account Balance Available $5,420.00 Chase", "Finance & Banking", "Bank Statements")]
    [InlineData("Sent to John Doe via UPI transaction successful", "Finance & Banking", "UPI & Transfers")]
    public async Task ClassifyScreenshot_FinanceKeywords_ReturnsFinanceCategory(string ocrText, string expectedCat, string expectedSubCat)
    {
        var request = new ClassifyScreenshotRequestDto
        {
            OCRText = ocrText,
            SourceApp = "BankApp"
        };

        var result = await _service.ClassifyScreenshotAsync(request);

        result.Should().NotBeNull();
        result.Category.Should().Be(expectedCat);
        result.SubCategory.Should().Be(expectedSubCat);
        result.Tags.Should().Contain("finance");
    }

    [Theory]
    [InlineData("public class Program { static void Main(string[] args) { } }", "Code & Tech", "Code Snippets")]
    [InlineData("Unhandled exception: NullReferenceException at Stack Trace line 45", "Code & Tech", "Error Logs")]
    [InlineData("npm install @angular/core git commit -m 'feat: update'", "Code & Tech", "Code Snippets")]
    public async Task ClassifyScreenshot_CodeKeywords_ReturnsCodeCategory(string ocrText, string expectedCat, string expectedSubCat)
    {
        var request = new ClassifyScreenshotRequestDto
        {
            OCRText = ocrText,
            SourceApp = "VS Code"
        };

        var result = await _service.ClassifyScreenshotAsync(request);

        result.Should().NotBeNull();
        result.Category.Should().Be(expectedCat);
        result.SubCategory.Should().Be(expectedSubCat);
        result.Tags.Should().Contain("developer");
    }

    [Fact]
    public async Task ClassifyScreenshot_SocialApp_ReturnsSocialCategory()
    {
        var request = new ClassifyScreenshotRequestDto
        {
            OCRText = "Hey, are you free tonight? Let's catch up!",
            SourceApp = "WhatsApp"
        };

        var result = await _service.ClassifyScreenshotAsync(request);

        result.Should().NotBeNull();
        result.Category.Should().Be("Social & Chat");
        result.SubCategory.Should().Be("WhatsApp");
        result.Tags.Should().Contain("social");
    }

    [Fact]
    public async Task ClassifyScreenshot_Unrecognized_ReturnsFallback()
    {
        var request = new ClassifyScreenshotRequestDto
        {
            OCRText = "random plain sentence with no triggers",
            SourceApp = "GenericApp"
        };

        var result = await _service.ClassifyScreenshotAsync(request);

        result.Should().NotBeNull();
        result.Category.Should().Be("General Screenshots");
        result.Confidence.Should().Be(0.70);
    }
}

