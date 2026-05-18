using FluentAssertions;
using Xunit;

namespace ModernWMS.Tests.ApiE2E.Support.ObjectPatterns;

public sealed class ObjectPatternParserTests
{
    [Fact]
    public void ParsesExactArrayWithUnquotedKeysAndWildcard()
    {
        var pattern = ObjectPatternParser.Parse("""
            = [{ sku_code: 'SKU-001' qty: 8 active: true note: null token: * }]
            """);

        pattern.Operator.Should().Be(ObjectPatternOperator.Equals);
        var rows = pattern.Value.Should().BeAssignableTo<IReadOnlyList<object?>>().Subject;
        rows.Should().HaveCount(1);
        var row = rows[0].Should().BeAssignableTo<IReadOnlyDictionary<string, object?>>().Subject;
        row["sku_code"].Should().Be("SKU-001");
        row["qty"].Should().Be(8L);
        row["active"].Should().Be(true);
        row["note"].Should().BeNull();
        row["token"].Should().Be(ObjectPatternWildcard.Instance);
    }

    [Fact]
    public void MatchesExactObjectsWithWildcardFields()
    {
        var pattern = ObjectPatternParser.Parse("""
            = [{ dispatch_no: 'DP-E2E-001' qty: 8 token: * }]
            """);
        var actual = new[]
        {
            new Dictionary<string, object?>
            {
                ["dispatch_no"] = "DP-E2E-001",
                ["qty"] = 8,
                ["token"] = "generated-token"
            }
        };

        ObjectPatternAssertions.AssertMatches(actual, pattern);
    }

    [Fact]
    public void MatchesPartialObjectPattern()
    {
        var pattern = ObjectPatternParser.Parse("""
            : { body: { json: { isSuccess: true } } }
            """);
        var actual = new Dictionary<string, object?>
        {
            ["body"] = new Dictionary<string, object?>
            {
                ["json"] = new Dictionary<string, object?>
                {
                    ["isSuccess"] = true,
                    ["code"] = 200L
                }
            }
        };

        ObjectPatternAssertions.AssertMatches(actual, pattern);
    }

    [Fact]
    public void ProjectsJsonFieldPathAndCollectionSize()
    {
        var body = """
            { "data": { "rows": [{ "id": 1 }, { "id": 2 }] } }
            """;

        JsonProjection.ProjectBody(body, "body.json.data.rows.size").Should().Be(2);
    }
}
