using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AI.ScreenshotOrganizer.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddDeviceAssetIdAndMetadata : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "ImageId",
                table: "Screenshots",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(128)",
                oldMaxLength: 128);

            migrationBuilder.AddColumn<string>(
                name: "ContentUri",
                table: "Screenshots",
                type: "nvarchar(1024)",
                maxLength: 1024,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DeviceAssetId",
                table: "Screenshots",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "FileName",
                table: "Screenshots",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<long>(
                name: "FileSize",
                table: "Screenshots",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<bool>(
                name: "IsMock",
                table: "Screenshots",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsReviewed",
                table: "Screenshots",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsSynced",
                table: "Screenshots",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastScannedAt",
                table: "Screenshots",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "OCRStatus",
                table: "Screenshots",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_Screenshots_IsReviewed",
                table: "Screenshots",
                column: "IsReviewed");

            migrationBuilder.CreateIndex(
                name: "IX_Screenshots_UserId_DeviceAssetId",
                table: "Screenshots",
                columns: new[] { "UserId", "DeviceAssetId" },
                unique: true,
                filter: "[DeviceAssetId] IS NOT NULL AND [DeviceAssetId] <> ''");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Screenshots_IsReviewed",
                table: "Screenshots");

            migrationBuilder.DropIndex(
                name: "IX_Screenshots_UserId_DeviceAssetId",
                table: "Screenshots");

            migrationBuilder.DropColumn(
                name: "ContentUri",
                table: "Screenshots");

            migrationBuilder.DropColumn(
                name: "DeviceAssetId",
                table: "Screenshots");

            migrationBuilder.DropColumn(
                name: "FileName",
                table: "Screenshots");

            migrationBuilder.DropColumn(
                name: "FileSize",
                table: "Screenshots");

            migrationBuilder.DropColumn(
                name: "IsMock",
                table: "Screenshots");

            migrationBuilder.DropColumn(
                name: "IsReviewed",
                table: "Screenshots");

            migrationBuilder.DropColumn(
                name: "IsSynced",
                table: "Screenshots");

            migrationBuilder.DropColumn(
                name: "LastScannedAt",
                table: "Screenshots");

            migrationBuilder.DropColumn(
                name: "OCRStatus",
                table: "Screenshots");

            migrationBuilder.AlterColumn<string>(
                name: "ImageId",
                table: "Screenshots",
                type: "nvarchar(128)",
                maxLength: 128,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(256)",
                oldMaxLength: 256);
        }
    }
}
