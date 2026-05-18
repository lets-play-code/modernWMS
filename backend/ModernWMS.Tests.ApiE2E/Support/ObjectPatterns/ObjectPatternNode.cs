namespace ModernWMS.Tests.ApiE2E.Support.ObjectPatterns;

public enum ObjectPatternOperator
{
    Equals,
    Contains
}

public sealed record ObjectPatternNode(ObjectPatternOperator Operator, object? Value);

public sealed class ObjectPatternWildcard
{
    public static readonly ObjectPatternWildcard Instance = new();

    private ObjectPatternWildcard()
    {
    }

    public override string ToString() => "*";
}
