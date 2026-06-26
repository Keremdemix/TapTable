using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TapTableAPI.Migrations
{
    /// <inheritdoc />
    public partial class CheckChanges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "StripeAccountId",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "StripeChargesEnabled",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "StripeOnboardingCompleted",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "StripePaymentIntentId",
                table: "Payments");

            migrationBuilder.AddColumn<bool>(
                name: "IyzicoSubMerchantApproved",
                table: "Restaurants",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "IyzicoSubMerchantKey",
                table: "Restaurants",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IyzicoPaymentId",
                table: "Payments",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IyzicoSubMerchantApproved",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "IyzicoSubMerchantKey",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "IyzicoPaymentId",
                table: "Payments");

            migrationBuilder.AddColumn<string>(
                name: "StripeAccountId",
                table: "Restaurants",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "StripeChargesEnabled",
                table: "Restaurants",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "StripeOnboardingCompleted",
                table: "Restaurants",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "StripePaymentIntentId",
                table: "Payments",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);
        }
    }
}
