using System.Data;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Dapper;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Common.Models.Dapper;

namespace AI.ScreenshotOrganizer.Persistence.Dapper;

public class DapperContext : IDapperContext
{
    private readonly string _connectionString;

    public DapperContext(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection") 
            ?? "Server=localhost;Database=AIScreenshotOrganizerDb;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True";
    }

    public IDbConnection CreateConnection() => new SqlConnection(_connectionString);

    public async Task<ScanScreenshotResult?> ScanScreenshotAsync(
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
        bool isMock = false)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@UserId", userId);
        parameters.Add("@DeviceAssetId", deviceAssetId);
        parameters.Add("@ImageId", imageId);
        parameters.Add("@ImagePath", imagePath);
        parameters.Add("@ThumbnailPath", thumbnailPath);
        parameters.Add("@FileName", fileName);
        parameters.Add("@FileSize", fileSize);
        parameters.Add("@ContentUri", contentUri);
        parameters.Add("@CapturedDate", capturedDate);
        parameters.Add("@SourceApp", sourceApp);
        parameters.Add("@Width", width);
        parameters.Add("@Height", height);
        parameters.Add("@OCRText", ocrText);
        parameters.Add("@VisionDescription", visionDescription);
        parameters.Add("@OCRStatus", ocrStatus);
        parameters.Add("@CategoryId", categoryId);
        parameters.Add("@SubCategoryId", subCategoryId);
        parameters.Add("@Confidence", confidence);
        parameters.Add("@Hash", hash);
        parameters.Add("@IsMock", isMock);

        return await connection.QueryFirstOrDefaultAsync<ScanScreenshotResult>(
            "[dbo].[USP_ScanScreenshot]",
            parameters,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<(FolderContextResult? context, IEnumerable<SubcategoryItemResult> subcategories)> GetFolderContextAsync(Guid categoryId, Guid userId)
    {
        using var connection = CreateConnection();
        var parameters = new { CategoryId = categoryId, UserId = userId };

        using var multi = await connection.QueryMultipleAsync(
            "[dbo].[USP_GetFolderContext]",
            parameters,
            commandType: CommandType.StoredProcedure);

        var context = await multi.ReadFirstOrDefaultAsync<FolderContextResult>();
        var subcategories = await multi.ReadAsync<SubcategoryItemResult>();

        return (context, subcategories);
    }

    public async Task<(int totalCount, IEnumerable<SearchScreenshotResult> items)> SearchScreenshotsAsync(
        Guid userId,
        string query = "",
        Guid? categoryId = null,
        Guid? tagId = null,
        DateTime? startDate = null,
        DateTime? endDate = null,
        bool? isFavorite = null,
        int pageNumber = 1,
        int pageSize = 30)
    {
        using var connection = CreateConnection();
        var parameters = new
        {
            UserId = userId,
            Query = query,
            CategoryId = categoryId,
            TagId = tagId,
            StartDate = startDate,
            EndDate = endDate,
            IsFavorite = isFavorite,
            PageNumber = pageNumber,
            PageSize = pageSize
        };

        using var multi = await connection.QueryMultipleAsync(
            "[dbo].[USP_SearchScreenshots]",
            parameters,
            commandType: CommandType.StoredProcedure);

        var totalCount = await multi.ReadFirstAsync<int>();
        var items = await multi.ReadAsync<SearchScreenshotResult>();

        return (totalCount, items);
    }

    public async Task<ChatMessageResult?> SaveChatHistoryAsync(
        Guid sessionId,
        Guid userId,
        Guid? categoryId,
        Guid? screenshotId,
        string role,
        string message,
        string? referencedScreenshotIdsJson = null,
        int? promptTokens = null,
        int? completionTokens = null,
        Guid? aiModelId = null)
    {
        using var connection = CreateConnection();
        var parameters = new
        {
            SessionId = sessionId,
            UserId = userId,
            CategoryId = categoryId,
            ScreenshotId = screenshotId,
            Role = role,
            Message = message,
            ReferencedScreenshotIdsJson = referencedScreenshotIdsJson,
            PromptTokens = promptTokens,
            CompletionTokens = completionTokens,
            AIModelId = aiModelId
        };

        return await connection.QueryFirstOrDefaultAsync<ChatMessageResult>(
            "[dbo].[USP_SaveChatHistory]",
            parameters,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<FolderTimelineResult>> GetFolderTimelineAsync(
        Guid categoryId,
        Guid userId,
        int pageNumber = 1,
        int pageSize = 50)
    {
        using var connection = CreateConnection();
        return await connection.QueryAsync<FolderTimelineResult>(
            "[dbo].[USP_GetFolderTimeline]",
            new { CategoryId = categoryId, UserId = userId, PageNumber = pageNumber, PageSize = pageSize },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<UpdateCategoryResult?> UpdateScreenshotCategoryAsync(
        Guid screenshotId,
        Guid userId,
        Guid newCategoryId,
        Guid? newSubCategoryId = null,
        bool updatedByAi = false,
        string modelName = "UserManual")
    {
        using var connection = CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<UpdateCategoryResult>(
            "[dbo].[USP_UpdateScreenshotCategory]",
            new
            {
                ScreenshotId = screenshotId,
                UserId = userId,
                NewCategoryId = newCategoryId,
                NewSubCategoryId = newSubCategoryId,
                UpdatedByAI = updatedByAi,
                ModelName = modelName
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<PendingTaskResult>> GetPendingTasksAsync(
        Guid userId,
        bool includeCompleted = false,
        int limit = 50)
    {
        using var connection = CreateConnection();
        return await connection.QueryAsync<PendingTaskResult>(
            "[dbo].[USP_GetPendingTasks]",
            new { UserId = userId, IncludeCompleted = includeCompleted, Limit = limit },
            commandType: CommandType.StoredProcedure);
    }
}
