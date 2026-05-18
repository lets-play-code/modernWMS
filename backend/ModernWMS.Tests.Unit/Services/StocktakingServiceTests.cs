using FluentAssertions;
using ModernWMS.Tests.Unit.Support;
using Xunit;

namespace ModernWMS.Tests.Unit.Services;

public sealed class StocktakingServiceTests
{
    [Fact]
    public void TestCurrentUserCarriesTenantForStocktakingServiceScenarios()
    {
        var currentUser = TestCurrentUser.Admin(tenantId: 7);

        currentUser.tenant_id.Should().Be(7);
        currentUser.user_role.Should().Be("administrator");
    }
}
