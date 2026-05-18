using ModernWMS.Tests.ApiE2E.Support;
using ModernWMS.Tests.ApiE2E.Support.Domain;
using Reqnroll;

namespace ModernWMS.Tests.ApiE2E.Steps;

[Binding]
public sealed class DataPreparationSteps
{
    private readonly DomainSpecRegistry _registry;
    private readonly ScenarioDataContext _context;

    public DataPreparationSteps(DomainSpecRegistry registry, ScenarioDataContext context)
    {
        _registry = registry;
        _context = context;
    }

    [Given("存在{string}:")]
    public async Task GivenTableSpecAsync(string specName, Table table)
    {
        await _registry.Resolve(specName).CreateAsync(DomainSpec.FromTable(table), _context);
    }

    [Given("存在{string}:")]
    public async Task GivenDocumentSpecAsync(string specName, string document)
    {
        await _registry.Resolve(specName).CreateAsync(DomainSpec.FromDocument(document), _context);
    }
}
