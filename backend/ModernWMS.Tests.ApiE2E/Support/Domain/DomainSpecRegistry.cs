using ModernWMS.Tests.ApiE2E.Support.Domain.Specs;

namespace ModernWMS.Tests.ApiE2E.Support.Domain;

public sealed class DomainSpecRegistry
{
    private readonly Dictionary<string, DomainSpec> _specs = new(StringComparer.OrdinalIgnoreCase);

    public DomainSpecRegistry()
    {
        Register(new WarehouseAndSkuSpec());
        Register(new AvailableStockSpec());
        Register(new UnloadedAsnSpec());
        Register(new SortedAsnSpec());
        Register(new LockedDispatchlistSpec());
        Register(new StockFreezeTaskSpec());
    }

    public void Register(DomainSpec spec)
    {
        _specs[spec.Name] = spec;
    }

    public DomainSpec Resolve(string name)
    {
        if (_specs.TryGetValue(name, out var spec))
        {
            return spec;
        }

        throw new InvalidOperationException($"No domain spec registered for '{name}'. Add a spec class instead of a new step definition.");
    }
}
