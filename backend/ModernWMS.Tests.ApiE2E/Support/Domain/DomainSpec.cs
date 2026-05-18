using Reqnroll;

namespace ModernWMS.Tests.ApiE2E.Support.Domain;

public sealed record DomainSpecInput(
    IReadOnlyList<IReadOnlyDictionary<string, string>> Rows,
    string? Document);

public abstract class DomainSpec
{
    public abstract string Name { get; }

    public abstract Task CreateAsync(DomainSpecInput input, ScenarioDataContext context);

    public static DomainSpecInput FromTable(Table table)
    {
        var rows = table.Rows
            .Select(row => table.Header.ToDictionary(header => header, header => row[header]))
            .Select(row => (IReadOnlyDictionary<string, string>)row)
            .ToList();
        return new DomainSpecInput(rows, null);
    }

    public static DomainSpecInput FromDocument(string document)
    {
        return new DomainSpecInput(Array.Empty<IReadOnlyDictionary<string, string>>(), document);
    }
}
