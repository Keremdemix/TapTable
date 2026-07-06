namespace TapTable.Api.Extensions;

public static class QrTokenExtensions
{
    public static string? GetQrToken(this HttpRequest request)
    {
        var authHeader = request.Headers.Authorization.ToString();
        if (!string.IsNullOrWhiteSpace(authHeader) &&
            authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            return authHeader["Bearer ".Length..].Trim();
        }

        if (request.Headers.TryGetValue("X-QR-Token", out var headerToken) &&
            !string.IsNullOrWhiteSpace(headerToken))
        {
            return headerToken.ToString();
        }

        if (request.Query.TryGetValue("token", out var qToken) && !string.IsNullOrWhiteSpace(qToken))
            return qToken.ToString();

        if (request.Query.TryGetValue("t", out var qT) && !string.IsNullOrWhiteSpace(qT))
            return qT.ToString();

        return null;
    }
}