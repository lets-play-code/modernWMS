using FluentAssertions;
using ModernWMS.Core.JWT;
using Xunit;

namespace ModernWMS.Tests.Unit.Core;

public sealed class CacheManagerTests
{
    [Fact]
    public void CacheOperationsRejectBlankKeys()
    {
        var cache = new CacheManager();

        Action get = () => cache.Get<string>(" ");
        Action set = () => cache.Set_NotExpire(" ", "value");
        Action sliding = () => cache.Set_SlidingExpire(" ", "value", TimeSpan.FromMinutes(1));
        Action absolute = () => cache.Set_AbsoluteExpire(" ", "value", TimeSpan.FromMinutes(1));
        Action combo = () => cache.Set_SlidingAndAbsoluteExpire(" ", "value", TimeSpan.FromMinutes(1), TimeSpan.FromMinutes(1));
        Action remove = () => cache.Remove(" ");

        get.Should().Throw<ArgumentNullException>();
        set.Should().Throw<ArgumentNullException>();
        sliding.Should().Throw<ArgumentNullException>();
        absolute.Should().Throw<ArgumentNullException>();
        combo.Should().Throw<ArgumentNullException>();
        remove.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task CacheSetVariantsAndTokenHelperRoundTripValues()
    {
        var cache = new CacheManager();

        cache.Set_NotExpire("plain", "v1");
        cache.Set_NotExpire("plain", "v2");
        cache.Set_SlidingExpire("sliding", 1, TimeSpan.FromMinutes(1));
        cache.Set_AbsoluteExpire("absolute", 2, TimeSpan.FromMinutes(1));
        cache.Set_SlidingAndAbsoluteExpire("combo", 3, TimeSpan.FromMinutes(1), TimeSpan.FromMinutes(1));
        cache.Set_SlidingAndAbsoluteExpire("combo", 4, TimeSpan.FromMinutes(1), TimeSpan.FromMinutes(1));
        cache.Set_NotExpire<string?>("ModernWMS_refresh_8", null);

        cache.Get<string>("plain").Should().Be("v2");
        cache.Get<int>("sliding").Should().Be(1);
        cache.Get<int>("absolute").Should().Be(2);
        cache.Get<int>("combo").Should().Be(4);
        cache.Is_Token_Exist<string?>(8, "refresh", 1).Should().BeFalse();
        cache.Is_Token_Exist<string>(999, "refresh", 1).Should().BeFalse();

        (await cache.TokenSet(7, "refresh", "token-1", 1)).Should().BeTrue();
        cache.Is_Token_Exist<string>(7, "refresh", 1).Should().BeTrue();
        cache.Is_Token_Exist<string>(7, "refresh", 1, "token-1").Should().BeTrue();
        cache.Is_Token_Exist<string>(7, "refresh", 1, "other").Should().BeFalse();

        cache.Remove("plain");
        cache.Get<string>("plain").Should().BeNull();
    }

    [Fact]
    public async Task DisposedCacheMakesTokenSetReturnFalse()
    {
        var cache = new CacheManager();
        cache.Dispose();

        var result = await cache.TokenSet(1, "refresh", "token", 1);

        result.Should().BeFalse();
    }
}
