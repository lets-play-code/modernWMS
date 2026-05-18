using FluentAssertions;
using ModernWMS.Core.Models;
using Xunit;

namespace ModernWMS.Tests.Unit.Core;

public sealed class ResultModelTests
{
    [Fact]
    public void SuccessWrapsNonNullDataWithSuccessCode()
    {
        var result = ResultModel<string>.Success("ok");

        result.IsSuccess.Should().BeTrue();
        result.Code.Should().Be(200);
        result.Data.Should().Be("ok");
        result.ErrorMessage.Should().BeEmpty();
    }

    [Fact]
    public void SuccessWithNullDataReturnsErrorModel()
    {
        var result = ResultModel<string?>.Success(null);

        result.IsSuccess.Should().BeFalse();
        result.Code.Should().Be(400);
        result.ErrorMessage.Should().Be("Some errors have occurred");
    }

    [Fact]
    public void ErrorKeepsCodeMessageAndData()
    {
        var result = ResultModel<int>.Error("bad request", 422, 7);

        result.IsSuccess.Should().BeFalse();
        result.Code.Should().Be(422);
        result.ErrorMessage.Should().Be("bad request");
        result.Data.Should().Be(7);
    }
}
