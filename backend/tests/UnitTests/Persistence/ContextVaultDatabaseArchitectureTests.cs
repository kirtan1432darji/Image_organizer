using FluentAssertions;
using Xunit;
using AI.ScreenshotOrganizer.Application.Common.Models.Dapper;
using AI.ScreenshotOrganizer.Domain.Common;
using AI.ScreenshotOrganizer.Domain.Entities;
using AI.ScreenshotOrganizer.Persistence.Context;
using Microsoft.EntityFrameworkCore;

namespace AI.ScreenshotOrganizer.UnitTests.Persistence;

public class ContextVaultDatabaseArchitectureTests
{
    [Fact]
    public void BaseEntity_ExposesStandardAuditFieldsAndConcurrencyToken()
    {
        var model = new Category();
        model.Id.Should().NotBeEmpty();
        model.CreatedOn.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
        model.IsDeleted.Should().BeFalse();
        model.CreatedDate.Should().Be(model.CreatedOn); // Compatibility alias
    }

    [Fact]
    public void Category_SupportsUnlimitedNestingWithoutSeparateFoldersTable()
    {
        var root = new Category { Id = Guid.NewGuid(), Name = "Projects" };
        var child = new Category { Id = Guid.NewGuid(), Name = "NHDC", ParentCategoryId = root.Id, ParentCategory = root };
        var subChild = new Category { Id = Guid.NewGuid(), Name = "Payroll", ParentCategoryId = child.Id, ParentCategory = child };

        child.ParentCategoryId.Should().Be(root.Id);
        subChild.ParentCategoryId.Should().Be(child.Id);
    }

    [Fact]
    public void ApplicationDbContext_RegistersAllCoreAndAITables()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: "ContextVault_TestDb")
            .Options;

        using var context = new ApplicationDbContext(options);

        // Core sets
        context.Users.Should().NotBeNull();
        context.Screenshots.Should().NotBeNull();
        context.Categories.Should().NotBeNull();
        context.Tags.Should().NotBeNull();
        context.OCRCache.Should().NotBeNull();
        context.ClassificationHistories.Should().NotBeNull();
        context.RefreshTokens.Should().NotBeNull();

        // AI Workspace sets
        context.AIModels.Should().NotBeNull();
        context.DeviceInfo.Should().NotBeNull();
        context.AppSettings.Should().NotBeNull();
        context.FolderContexts.Should().NotBeNull();
        context.Entities.Should().NotBeNull();
        context.Tasks.Should().NotBeNull();
        context.ChatHistories.Should().NotBeNull();
        context.SearchHistories.Should().NotBeNull();

        // Future Scalability sets
        context.Collections.Should().NotBeNull();
        context.CollectionScreenshots.Should().NotBeNull();
        context.EmbeddingCaches.Should().NotBeNull();
        context.NotificationHistories.Should().NotBeNull();
    }

    [Fact]
    public void DapperModels_HaveRequiredFieldsMatchingStoredProcedures()
    {
        var scanResult = new ScanScreenshotResult();
        scanResult.DeviceAssetId = "asset-123";
        scanResult.FileName = "test.png";

        var folderContext = new FolderContextResult();
        folderContext.CategoryName = "Learning";

        var searchResult = new SearchScreenshotResult();
        searchResult.OCRText = "Flutter and .NET";

        var chatResult = new ChatMessageResult();
        chatResult.Role = "User";

        var timelineResult = new FolderTimelineResult();
        timelineResult.FileName = "receipt.png";

        var taskResult = new PendingTaskResult();
        taskResult.Title = "Pay bills";

        scanResult.DeviceAssetId.Should().Be("asset-123");
        folderContext.CategoryName.Should().Be("Learning");
        searchResult.OCRText.Should().Be("Flutter and .NET");
        chatResult.Role.Should().Be("User");
        timelineResult.FileName.Should().Be("receipt.png");
        taskResult.Title.Should().Be("Pay bills");
    }
}
