using System.Reflection;
using FluentAssertions;
using ModernWMS.WMS.Services;
using Xunit;

namespace ModernWMS.Tests.Unit.Services;

public sealed class SpuServiceTests
{
    [Theory]
    [InlineData(0, 0, "0.1")]
    [InlineData(1, 0, "1")]
    [InlineData(2, 0, "10")]
    [InlineData(3, 0, "100")]
    [InlineData(0, 1, "0.01")]
    [InlineData(1, 1, "0.1")]
    [InlineData(2, 1, "1")]
    [InlineData(3, 1, "10")]
    [InlineData(0, 2, "0.001")]
    [InlineData(1, 2, "0.01")]
    [InlineData(2, 2, "0.1")]
    [InlineData(3, 2, "1")]
    [InlineData(1, 9, "1")]
    public void ChangeLengthUnitReturnsMultiplierUsedBySkuVolumeCalculation(byte lengthUnit, byte volumeUnit, string expectedText)
    {
        var service = new SpuService(null!, null!, null!);
        var method = typeof(SpuService).GetMethod("ChangeLengthUnit", BindingFlags.Instance | BindingFlags.NonPublic);

        method.Should().NotBeNull("SPU volume calculation should keep an explicit unit conversion rule");
        var multiplier = (decimal)method!.Invoke(service, new object[] { lengthUnit, volumeUnit })!;

        multiplier.Should().Be(decimal.Parse(expectedText));
    }
}
