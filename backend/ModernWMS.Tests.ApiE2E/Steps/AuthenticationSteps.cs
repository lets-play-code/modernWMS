using ModernWMS.Tests.ApiE2E.Support;
using Reqnroll;

namespace ModernWMS.Tests.ApiE2E.Steps;

[Binding]
public sealed class AuthenticationSteps
{
    private readonly ApiClient _apiClient;

    public AuthenticationSteps(ApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    [Given("以管理员登录")]
    public async Task LoginAsAdminAsync()
    {
        await _apiClient.SendAsync(HttpMethod.Post, "/login", "{ \"user_name\": \"admin\", \"password\": \"1\" }");
    }

    [Given("未登录")]
    public void ClearAuthentication()
    {
        _apiClient.ClearAuthentication();
    }
}
