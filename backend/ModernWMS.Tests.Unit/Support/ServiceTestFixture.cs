namespace ModernWMS.Tests.Unit.Support;

public sealed class ServiceTestFixture
{
    public ModernWmsServiceTestDatabase Database { get; } = new();
}
