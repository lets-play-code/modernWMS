using ModernWMS.Tests.ApiE2E.Support.Domain.Repositories;

namespace ModernWMS.Tests.ApiE2E.Support.Domain;

public sealed class DomainRepositoryRegistry
{
    private readonly Dictionary<string, DomainRepository> _repositories = new(StringComparer.OrdinalIgnoreCase);

    public DomainRepositoryRegistry()
    {
        Register(new MasterDataSkeletonRepository());
        Register(new StockViewRepository());
        Register(new AsnRepository());
        Register(new AsnSortRepository());
        Register(new DispatchlistRepository());
        Register(new DispatchpicklistRepository());
        Register(new StockFreezeTaskRepository());
    }

    public void Register(DomainRepository repository)
    {
        _repositories[repository.ModelName] = repository;
    }

    public DomainRepository Resolve(string modelName)
    {
        if (_repositories.TryGetValue(modelName, out var repository))
        {
            return repository;
        }

        throw new InvalidOperationException($"No domain repository registered for '{modelName}'. Add a repository class instead of a new step definition.");
    }
}
