using System.Collections;
using System.Globalization;
using System.Reflection;
using System.Text.Json;
using FluentAssertions;

namespace ModernWMS.Tests.ApiE2E.Support.ObjectPatterns;

public static class ObjectPatternAssertions
{
    public static void AssertMatches(object? actual, ObjectPatternNode pattern)
    {
        var exact = pattern.Operator == ObjectPatternOperator.Equals;
        Match(Normalize(actual), pattern.Value, exact, "$");
    }

    private static void Match(object? actual, object? expected, bool exact, string path)
    {
        if (ReferenceEquals(expected, ObjectPatternWildcard.Instance))
        {
            actual.Should().NotBeNull($"{path} should match wildcard");
            return;
        }

        if (expected is IReadOnlyDictionary<string, object?> expectedObject)
        {
            MatchObject(actual, expectedObject, exact, path);
            return;
        }

        if (expected is IReadOnlyList<object?> expectedList)
        {
            MatchList(actual, expectedList, exact, path);
            return;
        }

        if (IsNumeric(actual) && IsNumeric(expected))
        {
            ToDecimal(actual).Should().Be(ToDecimal(expected), path);
            return;
        }

        actual.Should().Be(expected, path);
    }

    private static void MatchObject(object? actual, IReadOnlyDictionary<string, object?> expected, bool exact, string path)
    {
        var actualObject = actual.Should().BeAssignableTo<IReadOnlyDictionary<string, object?>>($"{path} should be an object").Subject;
        if (exact)
        {
            actualObject.Keys.Should().BeEquivalentTo(expected.Keys, $"{path} should have exactly the expected keys");
        }

        foreach (var (key, expectedValue) in expected)
        {
            actualObject.ContainsKey(key).Should().BeTrue($"{path}.{key} should exist");
            Match(actualObject[key], expectedValue, exact, $"{path}.{key}");
        }
    }

    private static void MatchList(object? actual, IReadOnlyList<object?> expected, bool exact, string path)
    {
        var actualList = actual.Should().BeAssignableTo<IReadOnlyList<object?>>($"{path} should be a list").Subject;
        if (exact)
        {
            actualList.Should().HaveCount(expected.Count, $"{path} should have exactly the expected item count");
        }
        else
        {
            actualList.Count.Should().BeGreaterThanOrEqualTo(expected.Count, $"{path} should contain expected items");
        }

        for (var index = 0; index < expected.Count; index++)
        {
            Match(actualList[index], expected[index], exact, $"{path}[{index}]");
        }
    }

    private static object? Normalize(object? value)
    {
        return value switch
        {
            null => null,
            JsonElement json => NormalizeJson(json),
            IReadOnlyDictionary<string, object?> dictionary => NormalizeDictionary(dictionary),
            IDictionary dictionary => NormalizeDictionary(dictionary),
            string => value,
            IEnumerable enumerable => NormalizeEnumerable(enumerable),
            _ when IsSimple(value) => value,
            _ => NormalizeObject(value)
        };
    }

    private static IReadOnlyDictionary<string, object?> NormalizeDictionary(IReadOnlyDictionary<string, object?> dictionary)
    {
        return dictionary.ToDictionary(pair => pair.Key, pair => Normalize(pair.Value));
    }

    private static IReadOnlyDictionary<string, object?> NormalizeDictionary(IDictionary dictionary)
    {
        return dictionary.Keys.Cast<object>().ToDictionary(key => key.ToString()!, key => Normalize(dictionary[key]));
    }

    private static IReadOnlyList<object?> NormalizeEnumerable(IEnumerable enumerable)
    {
        return enumerable.Cast<object?>().Select(Normalize).ToList();
    }

    private static IReadOnlyDictionary<string, object?> NormalizeObject(object value)
    {
        return value.GetType()
            .GetProperties(BindingFlags.Instance | BindingFlags.Public)
            .Where(property => property.GetIndexParameters().Length == 0)
            .ToDictionary(property => property.Name, property => Normalize(property.GetValue(value)));
    }

    private static object? NormalizeJson(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.Object => element.EnumerateObject().ToDictionary(p => p.Name, p => NormalizeJson(p.Value)),
            JsonValueKind.Array => element.EnumerateArray().Select(NormalizeJson).ToList(),
            JsonValueKind.String => element.GetString(),
            JsonValueKind.Number when element.TryGetInt64(out var integer) => integer,
            JsonValueKind.Number => element.GetDecimal(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Null => null,
            _ => element.GetRawText()
        };
    }

    private static bool IsSimple(object value)
    {
        return value is string or bool or byte or sbyte or short or ushort or int or uint or long or ulong or float or double or decimal;
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
