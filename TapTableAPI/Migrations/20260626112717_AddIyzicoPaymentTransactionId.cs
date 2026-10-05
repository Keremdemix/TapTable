using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TapTableAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddIyzicoPaymentTransactionId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "IyzicoPaymentTransactionId",
                table: "Payments",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IyzicoPaymentTransactionId",
                table: "Payments");
        }
    }
}
