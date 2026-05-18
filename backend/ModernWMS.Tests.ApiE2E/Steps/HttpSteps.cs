using ModernWMS.Tests.ApiE2E.Support;
using Reqnroll;

namespace ModernWMS.Tests.ApiE2E.Steps;

[Binding]
public sealed class HttpSteps
{
    private readonly ApiClient _apiClient;

    public HttpSteps(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [When("GET {string}")]
    public async Task GetAsync(string path)
    {
        await _apiClient.SendAsync(HttpMethod.Get, path);
    }

    [When("POST {string}:")]
    public async Task PostAsync(string path, string body)
    {
        await _apiClient.SendAsync(HttpMethod.Post, path, body);
    }

    [When("PUT {string}:")]
    public async Task PutAsync(string path, string body)
    {
        await _apiClient.SendAsync(HttpMethod.Put, path, body);
    }

    [When("DELETE {string}")]
    public async Task DeleteAsync(string path)
    {
        await _apiClient.SendAsync(HttpMethod.Delete, path);
    }
}
