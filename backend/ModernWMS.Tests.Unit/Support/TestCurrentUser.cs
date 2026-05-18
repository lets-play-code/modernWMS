using ModernWMS.Core.JWT;

namespace ModernWMS.Tests.Unit.Support;

public static class TestCurrentUser
{
    public static CurrentUser Admin(long tenantId = 1) => new()
    {
        user_id = 1,
        user_num = "admin",
        user_name = "admin",
        user_role = "administrator",
        tenant_id = tenantId
    };
}
