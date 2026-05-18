using FluentAssertions;
using ModernWMS.Core.DynamicSearch;
using Xunit;

namespace ModernWMS.Tests.Unit.Core;

public sealed class DynamicSearchTests
{
    [Fact]
    public void EmptyQueryMatchesAllItems()
    {
        var predicate = new QueryCollection().AsExpression<TestItem>().Compile();

        predicate(new TestItem { Name = "anything", Quantity = 1 }).Should().BeTrue();
    }

    [Fact]
    public void ContainsQueryFiltersStringProperties()
    {
        var queries = new QueryCollection
        {
            new() { Name = nameof(TestItem.Name), Operator = Operators.Contains, Text = "alp" }
        };

        var predicate = queries.AsExpression<TestItem>().Compile();

        predicate(new TestItem { Name = "alpha", Quantity = 1 }).Should().BeTrue();
        predicate(new TestItem { Name = "beta", Quantity = 1 }).Should().BeFalse();
    }

    [Fact]
    public void NumericQuerySupportsGreaterThanOrEqual()
    {
        var queries = new QueryCollection
        {
            new() { Name = nameof(TestItem.Quantity), Operator = Operators.GreaterThanOrEqual, Text = "10" }
        };

        var predicate = queries.AsExpression<TestItem>().Compile();

        predicate(new TestItem { Name = "a", Quantity = 10 }).Should().BeTrue();
        predicate(new TestItem { Name = "b", Quantity = 9 }).Should().BeFalse();
    }

    private sealed class TestItem
    {
        public string Name { get; set; } = string.Empty;

        public int Quantity { get; set; }
    }
}
