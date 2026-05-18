using System.Data;
using System.Globalization;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Options;
using ModernWMS.Core;
using ModernWMS.Core.DBContext;
using ModernWMS.Core.JWT;
using ModernWMS.Core.Models;
using ModernWMS.Core.MultiTenancy;
using ModernWMS.Core.Services;
using ModernWMS.Core.Utility;
using ModernWMS.Tests.Unit.Support;
using Xunit;

namespace ModernWMS.Tests.Unit.Core;

public sealed class CoreInfrastructureTests
{
    [Fact]
    public void TenantProviderReturnsDefaultTenantForMissingAndPresentHeader()
    {
        var withoutContext = new TenantProvider(new HttpContextAccessor());
        var context = new DefaultHttpContext();
        context.Request.Headers["TenantName"] = "tenant-a";
        var withHeader = new TenantProvider(new HttpContextAccessor { HttpContext = context });

        withoutContext.GetCurrentTenantID().Should().Be(1);
        withHeader.GetCurrentTenantID().Should().Be(1);
    }

    [Fact]
    public async Task CallContextStoresValuesAcrossAsyncFlowAndMissingKeysReturnNull()
    {
        var key = $"core-{Guid.NewGuid():N}";

        CallContext.GetData(key).Should().BeNull();
        CallContext.SetData(key, "value");
        await Task.Yield();

        CallContext.GetData(key).Should().Be("value");
    }

    [Fact]
    public async Task SqlDbContextBuildsMappedModelAndConvertsDataTables()
    {
        await using var harness = await SqliteDbHarness.CreateAsync();
        var table = new DataTable();
        table.Columns.Add(nameof(SqlProjection.Name), typeof(string));
        table.Columns.Add(nameof(SqlProjection.IsEnabled), typeof(string));
        table.Columns.Add(nameof(SqlProjection.NullableText), typeof(string));
        table.Rows.Add("alpha", "1", DBNull.Value);
        table.Rows.Add("beta", "0", "note");

        harness.Context.EnsureCreated().Should().BeTrue();
        harness.Context.GetDatabase().Should().NotBeNull();
        harness.Context.GetDbSet<GlobalUniqueSerialEntity>().Should().NotBeNull();
        SqlDBContext.DataTableToIList<SqlProjection>(null!).Should().BeNull();

        var rows = SqlDBContext.DataTableToIList<SqlProjection>(table);
        Action getUnmapped = () => harness.Context.GetDbSet<UnmappedEntity>();

        rows.Should().HaveCount(2);
        rows[0].Should().BeEquivalentTo(new SqlProjection { Name = "alpha", IsEnabled = true, NullableText = null });
        rows[1].Should().BeEquivalentTo(new SqlProjection { Name = "beta", IsEnabled = false, NullableText = "note" });
        getUnmapped.Should().Throw<Exception>().WithMessage("*UnmappedEntity*");
    }

    [Fact]
    public async Task FunctionHelperUsesBearerTokenTenantAndAdvancesSequenceNumbers()
    {
        await using var harness = await SqliteDbHarness.CreateAsync();
        harness.Context.EnsureCreated();
        var today = DateTime.Now.ToString("yyyyMMdd");
        var currentUser = TestCurrentUser.Admin(tenantId: 7);
        var accessor = new HttpContextAccessor { HttpContext = new DefaultHttpContext() };
        var tokenManager = CreateTokenManager(accessor);
        accessor.HttpContext!.Request.Headers["Authorization"] = $"Bearer {tokenManager.GenerateToken(currentUser).token}";
        var helper = new FunctionHelper(harness.Context, accessor);

        helper.GetCurrentUser().tenant_id.Should().Be(7);
        var first = await helper.GetFormNoAsync("dispatch", "DP-", FunctionHelper.ResetRule.Day);
        var next = await helper.GetFormNoListAsync("dispatch", 2, currentUser.tenant_id, "DP-", FunctionHelper.ResetRule.Day);
        var entity = await harness.Context.GetDbSet<GlobalUniqueSerialEntity>().SingleAsync(t => t.table_name == "dispatch");

        first.Should().Be($"DP-{today}-0001");
        next.Should().Equal($"DP-{today}-0002", $"DP-{today}-0003");
        entity.tenant_id.Should().Be(7);
        entity.current_no.Should().Be(4);
    }

    [Fact]
    public async Task FunctionHelperResetsYearAndMonthCountersWhenWindowChanges()
    {
        await using var harness = await SqliteDbHarness.CreateAsync();
        harness.Context.EnsureCreated();
        harness.Context.tenant_id.Should().Be(1);
        harness.Context.GetDbSet<GlobalUniqueSerialEntity>().AddRange(
            new GlobalUniqueSerialEntity
            {
                table_name = "yearly",
                prefix_char = "YR-",
                reset_rule = "yyyy",
                current_no = 9,
                last_update_time = DateTime.Now.AddYears(-1),
                tenant_id = 1
            },
            new GlobalUniqueSerialEntity
            {
                table_name = "monthly",
                prefix_char = "MO-",
                reset_rule = "yyyyMM",
                current_no = 5,
                last_update_time = DateTime.Now.AddMonths(-1),
                tenant_id = 1
            });
        await harness.Context.SaveChangesAsync();
        var helper = new FunctionHelper(harness.Context, new HttpContextAccessor { HttpContext = new DefaultHttpContext() });

        helper.GetCurrentUser().tenant_id.Should().Be(1);
        var yearly = await helper.GetFormNoListAsync("yearly", 1, 1, "YR-", FunctionHelper.ResetRule.Year);
        var monthly = await helper.GetFormNoListAsync("monthly", 1, 1, "MO-", FunctionHelper.ResetRule.Month);

        yearly.Single().Should().Be($"YR-{DateTime.Now:yyyy}-0001");
        monthly.Single().Should().Be($"MO-{DateTime.Now:yyyyMM}-0001");
    }

    [Fact]
    public async Task AccountServiceLoginMatchesStoredCredentialsAndHelloWorldUsesLocalizer()
    {
        await using var harness = await SqliteDbHarness.CreateAsync();
        harness.Context.EnsureCreated();
        harness.Context.GetDbSet<UserroleEntity>().Add(new UserroleEntity
        {
            role_name = "administrator",
            tenant_id = 1,
            is_valid = true,
            create_time = DateTime.Now,
            last_update_time = DateTime.Now
        });
        harness.Context.GetDbSet<userEntity>().AddRange(
            new userEntity
            {
                user_num = "u001",
                user_name = "hashed-user",
                user_role = "administrator",
                auth_string = Md5Helper.Md5Encrypt32("secret"),
                creator = "unit",
                create_time = DateTime.Now,
                last_update_time = DateTime.Now,
                tenant_id = 1,
                is_valid = true
            },
            new userEntity
            {
                user_num = "u002",
                user_name = "plain-user",
                user_role = "administrator",
                auth_string = "plain",
                creator = "unit",
                create_time = DateTime.Now,
                last_update_time = DateTime.Now,
                tenant_id = 1,
                is_valid = true
            });
        await harness.Context.SaveChangesAsync();
        var service = new AccountService(harness.Context, new EchoLocalizer<MultiLanguage>());

        var hashed = await service.Login(new LoginInputViewModel { user_name = "u001", password = "secret" }, TestCurrentUser.Admin());
        var plain = await service.Login(new LoginInputViewModel { user_name = "plain-user", password = "plain" }, TestCurrentUser.Admin());
        var missing = await service.Login(new LoginInputViewModel { user_name = "plain-user", password = "wrong" }, TestCurrentUser.Admin());

        hashed.Should().NotBeNull();
        hashed!.user_name.Should().Be("hashed-user");
        plain.Should().NotBeNull();
        plain!.user_name.Should().Be("plain-user");
        missing.Should().BeNull();
        service.HelloWorld().Should().Be("hello word");
    }

    private static TokenManager CreateTokenManager(IHttpContextAccessor accessor)
    {
        var settings = Options.Create(new TokenSettings
        {
            Audience = "ModernWMS",
            Issuer = "ModernWMS",
            SigningKey = "ModernWMS_SigningKey",
            ExpireMinute = 15
        });
        return new TokenManager(settings, accessor);
    }

    private sealed class SqlProjection
    {
        public string Name { get; set; } = string.Empty;

        public bool IsEnabled { get; set; }

        public string? NullableText { get; set; }
    }

    private sealed class UnmappedEntity
    {
        public int Id { get; set; }
    }

    private sealed class SqliteDbHarness : IAsyncDisposable
    {
        private readonly SqliteConnection _connection;

        private SqliteDbHarness(SqliteConnection connection, SqlDBContext context)
        {
            _connection = connection;
            Context = context;
        }

        public SqlDBContext Context { get; }

        public static async Task<SqliteDbHarness> CreateAsync()
        {
            var connection = new SqliteConnection("Data Source=:memory:");
            await connection.OpenAsync();
            var options = new DbContextOptionsBuilder<SqlDBContext>()
                .UseSqlite(connection)
                .Options;
            return new SqliteDbHarness(connection, new SqlDBContext(options));
        }

        public async ValueTask DisposeAsync()
        {
            await Context.DisposeAsync();
            await _connection.DisposeAsync();
        }
    }

    private sealed class EchoLocalizer<T> : IStringLocalizer<T>
    {
        public LocalizedString this[string name] => new(name, name);

        public LocalizedString this[string name, params object[] arguments] =>
            new(name, string.Format(CultureInfo.InvariantCulture, name, arguments));

        public IEnumerable<LocalizedString> GetAllStrings(bool includeParentCultures) => Array.Empty<LocalizedString>();

        public IStringLocalizer WithCulture(CultureInfo culture) => this;
    }
}
