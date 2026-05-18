namespace ModernWMS.Tests.ApiE2E.Support.Domain;

public sealed class TestDataFactory
{
    public string NextCode(string prefix)
    {
        return $"{prefix}-{Guid.NewGuid():N}"[..Math.Min(prefix.Length + 13, prefix.Length + 33)];
    }

    public DateTime FixedNow { get; } = new(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);
}
