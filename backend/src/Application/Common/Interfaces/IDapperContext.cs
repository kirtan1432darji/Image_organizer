using System.Data;
using AI.ScreenshotOrganizer.Application.Common.Models.Dapper;

namespace AI.ScreenshotOrganizer.Application.Common.Interfaces;

public interface IDapperContext
{
    IDbConnection CreateConnection();

    Task<ScanScreenshotResult?> ScanScreenshotAsync(
        Guid userId,
        string deviceAssetId,
        string imageId,
        string imagePath,
        string? thumbnailPath,
        string fileName,
        long fileSize,
        string? contentUri,
        DateTime capturedDate,
        string sourceApp,
        int width,
        int height,
        string ocrText,
        string? visionDescription,
        string ocrStatus,
        Guid? categoryId,
        Guid? subCategoryId,
        double confidence,
        string hash,
        bool isMock = false);

    Task<(FolderContextResult? context, IEnumerable<SubcategoryItemResult> subcategories)> GetFolderContextAsync(Guid categoryId, Guid userId);

    Task<(int totalCount, IEnumerable<SearchScreenshotResult> items)> SearchScreenshotsAsync(
        Guid userId,
        string query = "",
        Guid? categoryId = null,
        Guid? tagId = null,
        DateTime? startDate = null,
        DateTime? endDate = null,
        bool? isFavorite = null,
        int pageNumber = 1,
        int pageSize = 30);

    Task<ChatMessageResult?> SaveChatHistoryAsync(
        Guid sessionId,
        Guid userId,
        Guid? categoryId,
        Guid? screenshotId,
        string role,
        string message,
        string? referencedScreenshotIdsJson = null,
        int? promptTokens = null,
        int? completionTokens = null,
        Guid? aiModelId = null);

    Task<IEnumerable<FolderTimelineResult>> GetFolderTimelineAsync(
        Guid categoryId,
        Guid userId,
        int pageNumber = 1,
        int pageSize = 50);

    Task<UpdateCategoryResult?> UpdateScreenshotCategoryAsync(
        Guid screenshotId,
        Guid userId,
        Guid newCategoryId,
        Guid? newSubCategoryId = null,
        bool updatedByAi = false,
        string modelName = "UserManual");

    Task<IEnumerable<PendingTaskResult>> GetPendingTasksAsync(
        Guid userId,
        bool includeCompleted = false,
        int limit = 50);
}
