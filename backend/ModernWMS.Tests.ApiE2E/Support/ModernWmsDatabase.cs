using Testcontainers.MySql;

namespace ModernWMS.Tests.ApiE2E.Support;

public sealed class ModernWmsDatabase : IAsyncDisposable
{
    private readonly MySqlContainer _container;
    private bool _started;

    public ModernWmsDatabase()
    {
        _container = new MySqlBuilder()
            .WithImage("mysql:8.0.41")
            .WithCleanUp(true)
            .WithDatabase("wms")
            .WithUsername("modernwms")
            .WithPassword("modernwms_test")
            .Build();
    }

    public string ConnectionString => AddEfOptions(_container.GetConnectionString());

    public async Task StartAsync()
    {
        if (_started)
        {
            return;
        }

        await _container.StartAsync();
        await ImportSeedAsync();
        _started = true;
    }

    public async ValueTask DisposeAsync()
    {
        await _container.DisposeAsync();
    }

    private async Task ImportSeedAsync()
    {
        var seedPath = Path.GetFullPath(Path.Combine(
            AppContext.BaseDirectory,
            "..", "..", "..", "..", "..", "scripts", "seeds", "database_mysql.sql"));
        var seedSql = await File.ReadAllTextAsync(seedPath);
        seedSql = seedSql.Replace("CREATE DATABASE wms;\nUSE wms;", "USE wms;");
        await _container.ExecScriptAsync(seedSql);
    }

    private static string AddEfOptions(string connectionString)
    {
        var builder = new MySqlConnector.MySqlConnectionStringBuilder(connectionString)
        {
            AllowUserVariables = true,
            DefaultCommandTimeout = 120,
            ConnectionTimeout = 30,
        };

        return builder.ConnectionString;
    }
}
