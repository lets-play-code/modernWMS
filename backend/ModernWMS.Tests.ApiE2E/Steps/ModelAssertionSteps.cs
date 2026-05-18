using ModernWMS.Tests.ApiE2E.Support;
using ModernWMS.Tests.ApiE2E.Support.Domain;
using ModernWMS.Tests.ApiE2E.Support.ObjectPatterns;
using Reqnroll;

namespace ModernWMS.Tests.ApiE2E.Steps;

[Binding]
public sealed class ModelAssertionSteps
{
    private readonly DomainRepositoryRegistry _repositories;
    private readonly ScenarioDataContext _context;

    public ModelAssertionSteps(DomainRepositoryRegistry repositories, ScenarioDataContext context)
    {
        _repositories = repositories;
        _context = context;
    }

    [Then("所有{string}应为:")]
    public async Task AllModelsShouldBeAsync(string modelName, string patternText)
    {
        var actual = await _repositories.Resolve(modelName).QueryAsync(_context);
        var pattern = ObjectPatternParser.Parse(patternText);
        ObjectPatternAssertions.AssertMatches(actual, pattern);
    }

    [Then("数据应为:")]
    public async Task DataShouldBeAsync(string patternText)
    {
        var pattern = ObjectPatternParser.Parse(patternText);
        if (pattern.Value is not IReadOnlyDictionary<string, object?> expectedModels)
        {
            throw new InvalidOperationException("组合数据断言的根节点必须是对象，key 为模型名。");
        }

        foreach (var (modelName, expectedPatternValue) in expectedModels)
        {
            var actual = await _repositories.Resolve(modelName).QueryAsync(_context);
            var modelPattern = new ObjectPatternNode(pattern.Operator, expectedPatternValue);
            ObjectPatternAssertions.AssertMatches(actual, modelPattern);
        }
    }
}
