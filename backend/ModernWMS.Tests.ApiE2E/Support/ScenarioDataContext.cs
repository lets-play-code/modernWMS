using System.Net;
using System.Text.Json;
using System.Text.RegularExpressions;
using ModernWMS.Core.Utility;

namespace ModernWMS.Tests.ApiE2E.Support;

public sealed class ScenarioDataContext
{
    private static readonly Regex PlaceholderPattern = new(@"\$\{(?<key>[^}]+)\}", RegexOptions.Compiled);

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

    public string ResolvePlaceholders(string text)
    {
        return PlaceholderPattern.Replace(text, match => GetSingleTracked(match.Groups["key"].Value));
    }

    private string GetSingleTracked(string key)
    {
        if (key.StartsWith("md5:", StringComparison.OrdinalIgnoreCase))
        {
            return Md5Helper.Md5Encrypt32(GetSingleTracked(key[4..]));
        }

        var values = GetTracked(key).ToList();
        return values.Count switch
        {
            1 => values[0],
            0 => throw new InvalidOperationException($"No tracked value exists for placeholder '${{{key}}}'."),
            _ => throw new InvalidOperationException($"Placeholder '${{{key}}}' is ambiguous: {string.Join(", ", values)}")
        };
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
