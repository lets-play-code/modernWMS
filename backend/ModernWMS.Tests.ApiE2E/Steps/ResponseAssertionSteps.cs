using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;
using FluentAssertions;
using ModernWMS.Tests.ApiE2E.Support;
using Reqnroll;

namespace ModernWMS.Tests.ApiE2E.Steps;

[Binding]
public sealed class ResponseAssertionSteps
{
    private static readonly Regex AssertionLine = new(
        @"^(?<path>[\w\.]+)\s*(?<operator>>=|<=|=|>|<)\s*(?<expected>.+)$",
        RegexOptions.Compiled);

    private readonly ScenarioDataContext _context;

    public ResponseAssertionSteps(ScenarioDataContext context)
    {
        _context = context;
    }

    [Then("response should be:")]
    public void ResponseShouldBe(string assertions)
    {
        foreach (var line in assertions.Split('\n', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries))
        {
            AssertLine(line);
        }
    }

    private void AssertLine(string line)
    {
        var match = AssertionLine.Match(line);
        match.Success.Should().BeTrue($"response assertion line should be parseable: {line}");

        var actual = ResolvePath(match.Groups["path"].Value);
        var op = match.Groups["operator"].Value;
        var expectedText = match.Groups["expected"].Value.Trim();

        if (expectedText == "*")
        {
            actual.Should().NotBeNull($"{line} should resolve to an existing value");
            if (actual is string text)
            {
                text.Should().NotBeEmpty($"{line} should resolve to a non-empty string");
            }
            return;
        }

        var expected = ParseExpected(expectedText);
        Compare(actual, op, expected, line);
    }

    private object? ResolvePath(string path)
    {
        if (path == "status")
        {
            return (int)_context.LatestStatusCode;
        }

        if (path == "body")
        {
            return _context.LatestBody;
        }

        const string jsonPrefix = "body.json";
        if (!path.StartsWith(jsonPrefix, StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"Unsupported response assertion path: {path}");
        }

        _context.LatestJson.Should().NotBeNull("response body should be JSON for body.json assertions");
        var current = _context.LatestJson!.RootElement;
        var parts = path.Length == jsonPrefix.Length
            ? Array.Empty<string>()
            : path[(jsonPrefix.Length + 1)..].Split('.', StringSplitOptions.RemoveEmptyEntries);

        foreach (var part in parts)
        {
            if (part == "size")
            {
                return GetSize(current);
            }

            current.ValueKind.Should().Be(JsonValueKind.Object, $"path segment '{part}' requires an object");
            current.TryGetProperty(part, out current).Should().BeTrue($"JSON property '{part}' should exist in path '{path}'");
        }

        return ConvertJsonElement(current);
    }

    private static int GetSize(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.Array => element.GetArrayLength(),
            JsonValueKind.Object => element.EnumerateObject().Count(),
            JsonValueKind.String => element.GetString()?.Length ?? 0,
            _ => throw new InvalidOperationException($"Cannot read size from JSON {element.ValueKind}.")
        };
    }

    private static object? ConvertJsonElement(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.String => element.GetString(),
            JsonValueKind.Number when element.TryGetInt64(out var integer) => integer,
            JsonValueKind.Number => element.GetDecimal(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Null => null,
            JsonValueKind.Array => element.GetRawText(),
            JsonValueKind.Object => element.GetRawText(),
            _ => element.GetRawText()
        };
    }

    private static object? ParseExpected(string value)
    {
        if (value.Equals("null", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        if (bool.TryParse(value, out var boolean))
        {
            return boolean;
        }

        if ((value.StartsWith('"') && value.EndsWith('"')) || (value.StartsWith('\'') && value.EndsWith('\'')))
        {
            return value[1..^1];
        }

        if (long.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var integer))
        {
            return integer;
        }

        if (decimal.TryParse(value, NumberStyles.Number, CultureInfo.InvariantCulture, out var number))
        {
            return number;
        }

        return value;
    }

    private static void Compare(object? actual, string op, object? expected, string line)
    {
        if (op == "=")
        {
            if (IsNumeric(actual) && IsNumeric(expected))
            {
                ToDecimal(actual).Should().Be(ToDecimal(expected), line);
                return;
            }

            actual.Should().Be(expected, line);
            return;
        }

        IsNumeric(actual).Should().BeTrue($"actual value should be numeric for assertion: {line}");
        IsNumeric(expected).Should().BeTrue($"expected value should be numeric for assertion: {line}");

        var actualNumber = ToDecimal(actual);
        var expectedNumber = ToDecimal(expected);
        switch (op)
        {
            case ">": actualNumber.Should().BeGreaterThan(expectedNumber, line); break;
            case "<": actualNumber.Should().BeLessThan(expectedNumber, line); break;
            case ">=": actualNumber.Should().BeGreaterThanOrEqualTo(expectedNumber, line); break;
            case "<=": actualNumber.Should().BeLessThanOrEqualTo(expectedNumber, line); break;
            default: throw new InvalidOperationException($"Unsupported assertion operator: {op}");
        }
    }

    private static bool IsNumeric(object? value)
    {
        return value is byte or sbyte or short or ushort or int or uint or long or ulong or float or double or decimal;
    }

    private static decimal ToDecimal(object? value)
    {
        return Convert.ToDecimal(value, CultureInfo.InvariantCulture);
    }
}
