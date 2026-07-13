using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TapTableAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddQrTokenToRestaurantTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "QrToken",
                table: "RestaurantTables",
                type: "nvarchar(64)",
                maxLength: 64,
                nullable: false,
                defaultValue: "");
            migrationBuilder.Sql(@"
    UPDATE RestaurantTables
    SET QrToken = LOWER(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''))
    WHERE QrToken = '' OR QrToken IS NULL;
");

            migrationBuilder.CreateIndex(
                name: "IX_RestaurantTables_QrToken",
                table: "RestaurantTables",
                column: "QrToken",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_RestaurantTables_QrToken",
                table: "RestaurantTables");

            migrationBuilder.DropColumn(
                name: "QrToken",
                table: "RestaurantTables");
        }
    }
}
