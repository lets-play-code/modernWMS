namespace ModernWMS.Tests.ApiE2E.Support.Domain;

public abstract class DomainRepository
{
    public abstract string ModelName { get; }

    public abstract Task<object?> QueryAsync(ScenarioDataContext context);
}
