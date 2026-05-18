using System.Text.Json;

namespace ModernWMS.Tests.ApiE2E.Support.ObjectPatterns;

public static class JsonProjection
{
    public static object? ProjectBody(string body, string path)
    {
        using var document = JsonDocument.Parse(body);
        return Project(document.RootElement, path);
    }

    public static object? Project(JsonElement root, string path)
    {
        const string prefix = "body.json";
        if (!path.StartsWith(prefix, StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"Unsupported projection path: {path}");
        }

        var current = root;
        var parts = path.Length == prefix.Length
            ? Array.Empty<string>()
            : path[(prefix.Length + 1)..].Split('.', StringSplitOptions.RemoveEmptyEntries);

        foreach (var part in parts)
        {
            if (part == "size")
            {
                return SizeOf(current);
            }

            if (current.ValueKind != JsonValueKind.Object || !current.TryGetProperty(part, out current))
            {
                throw new InvalidOperationException($"Projection path '{path}' cannot resolve segment '{part}'.");
            }
        }

        return ConvertJson(current);
    }

    private static int SizeOf(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.Array => element.GetArrayLength(),
            JsonValueKind.Object => element.EnumerateObject().Count(),
            JsonValueKind.String => element.GetString()?.Length ?? 0,
            _ => throw new InvalidOperationException($"Cannot get size of {element.ValueKind}.")
        };
    }

    private static object? ConvertJson(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.Object => element.EnumerateObject().ToDictionary(p => p.Name, p => ConvertJson(p.Value)),
            JsonValueKind.Array => element.EnumerateArray().Select(ConvertJson).ToList(),
            JsonValueKind.String => element.GetString(),
            JsonValueKind.Number when element.TryGetInt64(out var integer) => integer,
            JsonValueKind.Number => element.GetDecimal(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Null => null,
            _ => element.GetRawText()
        };
    }
}
