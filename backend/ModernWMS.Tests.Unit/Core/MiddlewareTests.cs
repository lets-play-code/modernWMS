using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Abstractions;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Routing;
using ModernWMS.Core.Middleware;
using ModernWMS.Core.Models;
using Xunit;

namespace ModernWMS.Tests.Unit.Core;

public sealed class MiddlewareTests
{
    [Fact]
    public void ViewModelActionFilterBuildsGetValidationMessageFromAttemptedValue()
    {
        var context = CreateExecutingContext("GET");
        context.ModelState.SetModelValue("keyword", "bad-value", "bad-value");
        context.ModelState.AddModelError("keyword", "Required");
        var filter = new ViewModelActionFiter();

        filter.OnActionExecuting(context);

        var result = context.Result.Should().BeOfType<JsonResult>().Subject;
        var model = result.Value.Should().BeOfType<ResultModel<object>>().Subject;
        model.Code.Should().Be(400);
        model.ErrorMessage.Should().Contain("parameter value");
        model.ErrorMessage.Should().Contain("bad-value");
    }

    [Fact]
    public void ViewModelActionFilterAggregatesCustomAndConversionErrorsForPost()
    {
        var context = CreateExecutingContext("POST");
        context.ModelState.AddModelError("qty", "Unexpected character encountered while parsing value");
        context.ModelState.AddModelError("name", "Name is required");
        var filter = new ViewModelActionFiter();

        filter.OnActionExecuting(context);

        var result = context.Result.Should().BeOfType<JsonResult>().Subject;
        var model = result.Value.Should().BeOfType<ResultModel<object>>().Subject;
        model.Code.Should().Be(400);
        model.ErrorMessage.Should().Contain("Name is required");
        model.ErrorMessage.Should().Contain("The data is of incorrect type or the value exceeds the type range");
    }

    [Fact]
    public void ViewModelActionFilterLeavesValidContextUntouched()
    {
        var context = CreateExecutingContext("POST");
        var filter = new ViewModelActionFiter();

        filter.OnActionExecuting(context);

        context.Result.Should().BeNull();
    }

    [Fact]
    public async Task CorsMiddlewareShortCircuitsOptionsRequests()
    {
        var nextCalled = false;
        var middleware = new CorsMiddleware(_ =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        });
        var context = new DefaultHttpContext();
        context.Request.Method = "OPTIONS";
        context.Request.Headers["Origin"] = "https://client.test";
        context.Request.Headers["Access-Control-Request-Headers"] = "content-type";

        await middleware.Invoke(context);

        nextCalled.Should().BeFalse();
        context.Response.StatusCode.Should().Be(StatusCodes.Status200OK);
        context.Response.Headers["Access-Control-Allow-Origin"].ToString().Should().Be("https://client.test");
        context.Response.Headers["Access-Control-Allow-Headers"].ToString().Should().Be("content-type");
    }

    [Fact]
    public async Task CorsMiddlewarePassesThroughAndOnlyEchoesOriginWhenPresent()
    {
        var withOrigin = CreateCorsContext("https://client.test");
        var withoutOrigin = CreateCorsContext(null);
        var middleware = new CorsMiddleware(_ => Task.CompletedTask);

        await middleware.Invoke(withOrigin);
        await middleware.Invoke(withoutOrigin);

        withOrigin.Response.Headers["Access-Control-Allow-Origin"].ToString().Should().Be("https://client.test");
        withOrigin.Response.Headers["Access-Control-Allow-Methods"].ToString().Should().Contain("PATCH");
        withoutOrigin.Response.Headers.ContainsKey("Access-Control-Allow-Origin").Should().BeFalse();
        withoutOrigin.Response.Headers["Access-Control-Allow-Headers"].ToString().Should().Be("content-type");
    }

    private static ActionExecutingContext CreateExecutingContext(string method)
    {
        var httpContext = new DefaultHttpContext();
        httpContext.Request.Method = method;
        var actionContext = new ActionContext(httpContext, new RouteData(), new ActionDescriptor(), new ModelStateDictionary());
        return new ActionExecutingContext(actionContext, new List<IFilterMetadata>(), new Dictionary<string, object?>(), controller: null);
    }

    private static DefaultHttpContext CreateCorsContext(string? origin)
    {
        var context = new DefaultHttpContext();
        context.Request.Method = "GET";
        context.Request.Headers["Access-Control-Request-Headers"] = "content-type";
        if (!string.IsNullOrWhiteSpace(origin))
        {
            context.Request.Headers["Origin"] = origin;
        }

        return context;
    }
}
