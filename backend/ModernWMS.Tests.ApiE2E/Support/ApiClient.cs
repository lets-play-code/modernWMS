using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace ModernWMS.Tests.ApiE2E.Support;

public sealed class ApiClient
{
    private readonly ScenarioDataContext _context;
    private HttpClient? _client;

    public ApiClient(ScenarioDataContext context)
    {
        _context = context;
    }

    public async Task SendAsync(HttpMethod method, string path, string? body = null)
    {
        var client = await GetClientAsync();
        var resolvedPath = _context.ResolvePlaceholders(path);
        using var request = new HttpRequestMessage(method, resolvedPath);

        if (!string.IsNullOrWhiteSpace(body))
        {
            var resolvedBody = _context.ResolvePlaceholders(body);
            request.Content = new StringContent(resolvedBody, Encoding.UTF8, "application/json");
        }

        if (!string.IsNullOrWhiteSpace(_context.AccessToken))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _context.AccessToken);
        }

        using var response = await client.SendAsync(request);
        var responseBody = await response.Content.ReadAsStringAsync();
        _context.SetLatestResponse(response.StatusCode, responseBody);
        CaptureLoginToken(path);
    }

    public void ClearAuthentication()
    {
        _context.ClearAuthentication();
    }

    private async Task<HttpClient> GetClientAsync()
    {
        if (_client is not null)
        {
            return _client;
        }

        var host = await ModernWmsApiHost.GetOrCreateAsync();
        _client = host.CreateClient();
        return _client;
    }

    private void CaptureLoginToken(string path)
    {
        if (!path.Equals("/login", StringComparison.OrdinalIgnoreCase) || _context.LatestJson is null)
        {
            return;
        }

        if (_context.LatestJson.RootElement.TryGetProperty("data", out var data)
            && data.TryGetProperty("access_token", out var token)
            && token.ValueKind == JsonValueKind.String)
        {
            _context.AccessToken = token.GetString();
        }
    }
}
