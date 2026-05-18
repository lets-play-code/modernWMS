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

    [Fact]
    public void OrElseConditionMatchesWhenAnyQuerySucceeds()
    {
        var queries = new QueryCollection
        {
            new() { Name = nameof(TestItem.Name), Operator = Operators.Contains, Text = "alp" },
            new() { Name = nameof(TestItem.Quantity), Operator = Operators.GreaterThan, Text = "9" }
        };

        var predicate = queries.AsExpression<TestItem>(Condition.OrElse).Compile();

        predicate(new TestItem { Name = "alpha", Quantity = 1 }).Should().BeTrue();
        predicate(new TestItem { Name = "beta", Quantity = 10 }).Should().BeTrue();
        predicate(new TestItem { Name = "beta", Quantity = 1 }).Should().BeFalse();
    }

    [Fact]
    public void DateTimePickerLessThanOrEqualIncludesEndOfSelectedDay()
    {
        var queries = new QueryCollection
        {
            new()
            {
                Name = nameof(TestItem.CreatedAt),
                Type = "datetimepicker",
                Operator = Operators.LessThanOrEqual,
                Text = "2026-05-19"
            }
        };

        var predicate = queries.AsExpression<TestItem>().Compile();

        predicate(new TestItem { CreatedAt = new DateTime(2026, 5, 19, 23, 59, 59) }).Should().BeTrue();
        predicate(new TestItem { CreatedAt = new DateTime(2026, 5, 20, 0, 0, 0) }).Should().BeFalse();
    }

    [Fact]
    public void EqualAndLessThanQueriesHandleNullableAndBoundaryValues()
    {
        var equalQueries = new QueryCollection
        {
            new() { Name = nameof(TestItem.NullableQuantity), Operator = Operators.Equal, Text = "5" }
        };
        var lessThanQueries = new QueryCollection
        {
            new() { Name = nameof(TestItem.Quantity), Operator = Operators.LessThan, Text = "10" }
        };

        var equalPredicate = equalQueries.AsExpression<TestItem>().Compile();
        var lessThanPredicate = lessThanQueries.AsExpression<TestItem>().Compile();

        equalPredicate(new TestItem { NullableQuantity = 5 }).Should().BeTrue();
        equalPredicate(new TestItem { NullableQuantity = 4 }).Should().BeFalse();
        lessThanPredicate(new TestItem { Quantity = 9 }).Should().BeTrue();
        lessThanPredicate(new TestItem { Quantity = 10 }).Should().BeFalse();
    }

    [Fact]
    public void InvalidQueriesReturnNullWhenNothingIsUsable()
    {
        var queries = new QueryCollection
        {
            new() { Name = "MissingProperty", Operator = Operators.Equal, Text = "1" },
            new() { Name = nameof(TestItem.Name), Operator = Operators.Equal, Text = "   " }
        };

        queries.AsExpression<TestItem>().Should().BeNull();
    }

    private sealed class TestItem
    {
        public string Name { get; set; } = string.Empty;

        public int Quantity { get; set; }

        public int? NullableQuantity { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}
