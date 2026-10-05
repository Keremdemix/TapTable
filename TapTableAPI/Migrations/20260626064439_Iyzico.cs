using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TapTableAPI.Migrations
{
    /// <inheritdoc />
    public partial class Iyzico : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IyzicoSubMerchantApproved",
                table: "Restaurants");

            migrationBuilder.AlterColumn<string>(
                name: "IyzicoSubMerchantKey",
                table: "Restaurants",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsIyzicoApproved",
                table: "Restaurants",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "IyzicoSubMerchantExternalId",
                table: "Restaurants",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "IyzicoPaymentId",
                table: "Payments",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsIyzicoApproved",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "IyzicoSubMerchantExternalId",
                table: "Restaurants");

            migrationBuilder.AlterColumn<string>(
                name: "IyzicoSubMerchantKey",
                table: "Restaurants",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(200)",
                oldMaxLength: 200,
                oldNullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IyzicoSubMerchantApproved",
                table: "Restaurants",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AlterColumn<string>(
                name: "IyzicoPaymentId",
                table: "Payments",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(200)",
                oldMaxLength: 200,
                oldNullable: true);
        }
    }
}
