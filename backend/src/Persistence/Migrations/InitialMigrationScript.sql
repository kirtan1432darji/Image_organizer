IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
CREATE TABLE [Users] (
    [Id] uniqueidentifier NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [Email] nvarchar(256) NOT NULL,
    [PasswordHash] nvarchar(max) NOT NULL,
    [IsActive] bit NOT NULL,
    [CreatedDate] datetime2 NOT NULL,
    [UpdatedDate] datetime2 NULL,
    [IsDeleted] bit NOT NULL,
    CONSTRAINT [PK_Users] PRIMARY KEY ([Id])
);

CREATE TABLE [Categories] (
    [Id] uniqueidentifier NOT NULL,
    [Name] nvarchar(100) NOT NULL,
    [ParentCategoryId] uniqueidentifier NULL,
    [Icon] nvarchar(50) NULL,
    [Color] nvarchar(20) NULL,
    [CreatedByAI] bit NOT NULL,
    [UserId] uniqueidentifier NULL,
    [CreatedDate] datetime2 NOT NULL,
    [UpdatedDate] datetime2 NULL,
    [IsDeleted] bit NOT NULL,
    CONSTRAINT [PK_Categories] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Categories_Categories_ParentCategoryId] FOREIGN KEY ([ParentCategoryId]) REFERENCES [Categories] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Categories_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE SET NULL
);

CREATE TABLE [RefreshTokens] (
    [Id] uniqueidentifier NOT NULL,
    [UserId] uniqueidentifier NOT NULL,
    [Token] nvarchar(256) NOT NULL,
    [JwtId] nvarchar(128) NOT NULL,
    [IsUsed] bit NOT NULL,
    [IsRevoked] bit NOT NULL,
    [ExpiryDate] datetime2 NOT NULL,
    [CreatedDate] datetime2 NOT NULL,
    [UpdatedDate] datetime2 NULL,
    [IsDeleted] bit NOT NULL,
    CONSTRAINT [PK_RefreshTokens] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_RefreshTokens_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [Tags] (
    [Id] uniqueidentifier NOT NULL,
    [Name] nvarchar(50) NOT NULL,
    [UserId] uniqueidentifier NULL,
    [CreatedDate] datetime2 NOT NULL,
    [UpdatedDate] datetime2 NULL,
    [IsDeleted] bit NOT NULL,
    CONSTRAINT [PK_Tags] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Tags_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [Screenshots] (
    [Id] uniqueidentifier NOT NULL,
    [UserId] uniqueidentifier NOT NULL,
    [ImageId] nvarchar(128) NOT NULL,
    [ImagePath] nvarchar(1024) NOT NULL,
    [ThumbnailPath] nvarchar(1024) NULL,
    [CapturedDate] datetime2 NOT NULL,
    [SourceApp] nvarchar(100) NOT NULL,
    [Width] int NOT NULL,
    [Height] int NOT NULL,
    [OCRText] nvarchar(max) NOT NULL,
    [VisionDescription] nvarchar(max) NULL,
    [CategoryId] uniqueidentifier NULL,
    [SubCategoryId] uniqueidentifier NULL,
    [Confidence] float NOT NULL,
    [Hash] nvarchar(64) NOT NULL,
    [IsFavorite] bit NOT NULL,
    [CreatedDate] datetime2 NOT NULL,
    [UpdatedDate] datetime2 NULL,
    [IsDeleted] bit NOT NULL,
    CONSTRAINT [PK_Screenshots] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Screenshots_Categories_CategoryId] FOREIGN KEY ([CategoryId]) REFERENCES [Categories] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Screenshots_Categories_SubCategoryId] FOREIGN KEY ([SubCategoryId]) REFERENCES [Categories] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Screenshots_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [ClassificationHistory] (
    [Id] uniqueidentifier NOT NULL,
    [ScreenshotId] uniqueidentifier NOT NULL,
    [Category] nvarchar(100) NOT NULL,
    [SubCategory] nvarchar(100) NULL,
    [TagsJson] nvarchar(max) NOT NULL,
    [Confidence] float NOT NULL,
    [ModelName] nvarchar(100) NOT NULL,
    [CreatedDate] datetime2 NOT NULL,
    [UpdatedDate] datetime2 NULL,
    [IsDeleted] bit NOT NULL,
    CONSTRAINT [PK_ClassificationHistory] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_ClassificationHistory_Screenshots_ScreenshotId] FOREIGN KEY ([ScreenshotId]) REFERENCES [Screenshots] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [OCRCache] (
    [Id] uniqueidentifier NOT NULL,
    [ScreenshotId] uniqueidentifier NOT NULL,
    [OCRText] nvarchar(max) NOT NULL,
    [Language] nvarchar(10) NOT NULL,
    [Confidence] float NOT NULL,
    [CreatedDate] datetime2 NOT NULL,
    [UpdatedDate] datetime2 NULL,
    [IsDeleted] bit NOT NULL,
    CONSTRAINT [PK_OCRCache] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_OCRCache_Screenshots_ScreenshotId] FOREIGN KEY ([ScreenshotId]) REFERENCES [Screenshots] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [ScreenshotCategories] (
    [ScreenshotId] uniqueidentifier NOT NULL,
    [CategoryId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_ScreenshotCategories] PRIMARY KEY ([ScreenshotId], [CategoryId]),
    CONSTRAINT [FK_ScreenshotCategories_Categories_CategoryId] FOREIGN KEY ([CategoryId]) REFERENCES [Categories] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_ScreenshotCategories_Screenshots_ScreenshotId] FOREIGN KEY ([ScreenshotId]) REFERENCES [Screenshots] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [ScreenshotTags] (
    [ScreenshotId] uniqueidentifier NOT NULL,
    [TagId] uniqueidentifier NOT NULL,
    CONSTRAINT [PK_ScreenshotTags] PRIMARY KEY ([ScreenshotId], [TagId]),
    CONSTRAINT [FK_ScreenshotTags_Screenshots_ScreenshotId] FOREIGN KEY ([ScreenshotId]) REFERENCES [Screenshots] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ScreenshotTags_Tags_TagId] FOREIGN KEY ([TagId]) REFERENCES [Tags] ([Id]) ON DELETE NO ACTION
);

CREATE INDEX [IX_Categories_Name_UserId] ON [Categories] ([Name], [UserId]);

CREATE INDEX [IX_Categories_ParentCategoryId] ON [Categories] ([ParentCategoryId]);

CREATE INDEX [IX_Categories_UserId] ON [Categories] ([UserId]);

CREATE INDEX [IX_ClassificationHistory_ScreenshotId] ON [ClassificationHistory] ([ScreenshotId]);

CREATE UNIQUE INDEX [IX_OCRCache_ScreenshotId] ON [OCRCache] ([ScreenshotId]);

CREATE UNIQUE INDEX [IX_RefreshTokens_Token] ON [RefreshTokens] ([Token]);

CREATE INDEX [IX_RefreshTokens_UserId] ON [RefreshTokens] ([UserId]);

CREATE INDEX [IX_ScreenshotCategories_CategoryId] ON [ScreenshotCategories] ([CategoryId]);

CREATE INDEX [IX_Screenshots_CapturedDate] ON [Screenshots] ([CapturedDate]);

CREATE INDEX [IX_Screenshots_CategoryId] ON [Screenshots] ([CategoryId]);

CREATE INDEX [IX_Screenshots_Hash] ON [Screenshots] ([Hash]);

CREATE INDEX [IX_Screenshots_IsFavorite] ON [Screenshots] ([IsFavorite]);

CREATE INDEX [IX_Screenshots_SubCategoryId] ON [Screenshots] ([SubCategoryId]);

CREATE INDEX [IX_Screenshots_UserId_ImageId] ON [Screenshots] ([UserId], [ImageId]);

CREATE INDEX [IX_ScreenshotTags_TagId] ON [ScreenshotTags] ([TagId]);

CREATE INDEX [IX_Tags_Name_UserId] ON [Tags] ([Name], [UserId]);

CREATE INDEX [IX_Tags_UserId] ON [Tags] ([UserId]);

CREATE UNIQUE INDEX [IX_Users_Email] ON [Users] ([Email]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260830190845_InitialCreate', N'9.0.0');

DROP INDEX [IX_Screenshots_UserId_ImageId] ON [Screenshots];
DECLARE @var0 sysname;
SELECT @var0 = [d].[name]
FROM [sys].[default_constraints] [d]
INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Screenshots]') AND [c].[name] = N'ImageId');
IF @var0 IS NOT NULL EXEC(N'ALTER TABLE [Screenshots] DROP CONSTRAINT [' + @var0 + '];');
ALTER TABLE [Screenshots] ALTER COLUMN [ImageId] nvarchar(256) NOT NULL;
CREATE INDEX [IX_Screenshots_UserId_ImageId] ON [Screenshots] ([UserId], [ImageId]);

ALTER TABLE [Screenshots] ADD [ContentUri] nvarchar(1024) NULL;

ALTER TABLE [Screenshots] ADD [DeviceAssetId] nvarchar(256) NOT NULL DEFAULT N'';

ALTER TABLE [Screenshots] ADD [FileName] nvarchar(256) NOT NULL DEFAULT N'';

ALTER TABLE [Screenshots] ADD [FileSize] bigint NOT NULL DEFAULT CAST(0 AS bigint);

ALTER TABLE [Screenshots] ADD [IsMock] bit NOT NULL DEFAULT CAST(0 AS bit);

ALTER TABLE [Screenshots] ADD [IsReviewed] bit NOT NULL DEFAULT CAST(0 AS bit);

ALTER TABLE [Screenshots] ADD [IsSynced] bit NOT NULL DEFAULT CAST(0 AS bit);

ALTER TABLE [Screenshots] ADD [LastScannedAt] datetime2 NULL;

ALTER TABLE [Screenshots] ADD [OCRStatus] nvarchar(30) NOT NULL DEFAULT N'';

CREATE INDEX [IX_Screenshots_IsReviewed] ON [Screenshots] ([IsReviewed]);

CREATE UNIQUE INDEX [IX_Screenshots_UserId_DeviceAssetId] ON [Screenshots] ([UserId], [DeviceAssetId]) WHERE [DeviceAssetId] IS NOT NULL AND [DeviceAssetId] <> '';

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260830203324_AddDeviceAssetIdAndMetadata', N'9.0.0');

COMMIT;
GO

