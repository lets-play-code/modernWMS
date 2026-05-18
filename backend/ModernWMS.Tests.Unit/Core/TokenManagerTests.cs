using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;
using ModernWMS.Core.JWT;
using Xunit;

namespace ModernWMS.Tests.Unit.Core;

public sealed class TokenManagerTests
{
    [Fact]
    public void GeneratedTokenCanBeReadBackAsCurrentUser()
    {
        var manager = CreateTokenManager();
        var user = new CurrentUser
        {
            user_id = 99,
            user_num = "u99",
            user_name = "Unit User",
            user_role = "tester",
            tenant_id = 7
        };

        var token = manager.GenerateToken(user);
        var parsed = manager.GetCurrentUser(token.token);

        token.expire.Should().Be(15);
        parsed.user_id.Should().Be(99);
        parsed.user_num.Should().Be("u99");
        parsed.user_name.Should().Be("Unit User");
        parsed.user_role.Should().Be("tester");
        parsed.tenant_id.Should().Be(7);
    }

    [Fact]
    public void RefreshTokenExpireMinuteIsAccessTokenExpirePlusOne()
    {
        CreateTokenManager().GetRefreshTokenExpireMinute().Should().Be(16);
    }

    private static TokenManager CreateTokenManager()
    {
        var settings = Options.Create(new TokenSettings
        {
            Audience = "ModernWMS",
            Issuer = "ModernWMS",
            SigningKey = "ModernWMS_SigningKey",
            ExpireMinute = 15
        });
        return new TokenManager(settings, new HttpContextAccessor());
    }
}
