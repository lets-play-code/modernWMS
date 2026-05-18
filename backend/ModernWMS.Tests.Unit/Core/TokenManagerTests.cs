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

    [Fact]
    public void GetCurrentUserReadsBearerTokenFromHttpContextHeader()
    {
        var accessor = new HttpContextAccessor { HttpContext = new DefaultHttpContext() };
        var manager = CreateTokenManager(accessor);
        var user = new CurrentUser
        {
            user_id = 7,
            user_num = "u7",
            user_name = "Header User",
            user_role = "tester",
            tenant_id = 3
        };
        accessor.HttpContext!.Request.Headers["Authorization"] = $"Bearer {manager.GenerateToken(user).token}";

        var parsed = manager.GetCurrentUser();

        parsed.user_id.Should().Be(7);
        parsed.user_num.Should().Be("u7");
        parsed.tenant_id.Should().Be(3);
    }

    [Fact]
    public void GetCurrentUserReturnsDefaultUserWhenHeaderOrTokenIsMissing()
    {
        var noContextManager = CreateTokenManager(new HttpContextAccessor());
        var missingHeaderManager = CreateTokenManager(new HttpContextAccessor { HttpContext = new DefaultHttpContext() });
        var nonBearerContext = new DefaultHttpContext();
        nonBearerContext.Request.Headers["Authorization"] = "Token something";
        var nonBearerManager = CreateTokenManager(new HttpContextAccessor { HttpContext = nonBearerContext });

        noContextManager.GetCurrentUser().user_name.Should().Be("admin");
        missingHeaderManager.GetCurrentUser().user_name.Should().Be("admin");
        nonBearerManager.GetCurrentUser().user_role.Should().Be("admin");
        missingHeaderManager.GetCurrentUser(string.Empty).tenant_id.Should().Be(1);
    }

    [Fact]
    public void GenerateRefreshTokenReturnsBase64EncodedRandomBytes()
    {
        var refreshToken = CreateTokenManager().GenerateRefreshToken();

        refreshToken.Should().NotBeNullOrWhiteSpace();
        Convert.FromBase64String(refreshToken).Should().HaveCount(32);
    }

    private static TokenManager CreateTokenManager(IHttpContextAccessor? accessor = null)
    {
        var settings = Options.Create(new TokenSettings
        {
            Audience = "ModernWMS",
            Issuer = "ModernWMS",
            SigningKey = "ModernWMS_SigningKey",
            ExpireMinute = 15
        });
        return new TokenManager(settings, accessor ?? new HttpContextAccessor());
    }
}
