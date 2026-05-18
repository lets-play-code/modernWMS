using Reqnroll;

namespace ModernWMS.Tests.ApiE2E.Support;

[Binding]
public sealed class ScenarioHooks
{
    [BeforeScenario]
    public async Task EnsureApiHostStarted()
    {
        await ModernWmsApiHost.GetOrCreateAsync();
    }

    [AfterTestRun]
    public static async Task DisposeApiHost()
    {
        await ModernWmsApiHost.DisposeSharedAsync();
    }
}
