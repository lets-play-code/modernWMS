namespace ModernWMS.Tests.Unit.Support;

public sealed class ModernWmsServiceTestDatabase
{
    public string DatabaseName { get; } = $"modernwms_service_test_{Guid.NewGuid():N}";
}
