using Iyzipay;

namespace TapTable.Api.Helpers;

public static class IyzicoOptionsFactory
{
    public static Options Build(IConfiguration configuration) => new()
    {
        ApiKey = configuration["Iyzico:ApiKey"],
        SecretKey = configuration["Iyzico:SecretKey"],
        BaseUrl = configuration["Iyzico:BaseUrl"] ?? "https://sandbox-api.iyzipay.com"
    };
}