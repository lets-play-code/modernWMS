using System.Net;
using System.Text.Json;

namespace ModernWMS.Tests.ApiE2E.Support;

public sealed class ScenarioDataContext
{
    private readonly Dictionary<string, HashSet<string>> _trackedValues = new(StringComparer.OrdinalIgnoreCase);

    public HttpStatusCode LatestStatusCode { get; set; }

    public string LatestBody { get; set; } = string.Empty;

    public JsonDocument? LatestJson { get; set; }

    public string? AccessToken { get; set; }

    public void SetLatestResponse(HttpStatusCode statusCode, string body)
    {
        LatestStatusCode = statusCode;
        LatestBody = body;
        LatestJson?.Dispose();
        LatestJson = TryParseJson(body);
    }

    public void ClearAuthentication()
    {
        AccessToken = null;
    }

    public void Track(string key, string value)
    {
        if (!_trackedValues.TryGetValue(key, out var values))
        {
            values = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            _trackedValues[key] = values;
        }

        values.Add(value);
    }

    public IReadOnlyCollection<string> GetTracked(string key)
    {
        return _trackedValues.TryGetValue(key, out var values) ? values : Array.Empty<string>();
    }

    private static JsonDocument? TryParseJson(string body)
    {
        if (string.IsNullOrWhiteSpace(body))
        {
            return null;
        }

        try
        {
            return JsonDocument.Parse(body);
        }
        catch (JsonException)
        {
            return null;
        }
    }
}
