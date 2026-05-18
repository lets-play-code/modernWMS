namespace ModernWMS.Tests.ApiE2E.Support.Domain;

public sealed class FieldAliasMap
{
    private readonly Dictionary<string, string> _aliases = new(StringComparer.OrdinalIgnoreCase);

    public FieldAliasMap Add(string alias, string field)
    {
        _aliases[alias] = field;
        return this;
    }

    public string Resolve(string field)
    {
        return _aliases.TryGetValue(field, out var resolved) ? resolved : field;
    }

    public IReadOnlyDictionary<string, string> Apply(IReadOnlyDictionary<string, string> row)
    {
        return row.ToDictionary(pair => Resolve(pair.Key), pair => pair.Value);
    }
}
