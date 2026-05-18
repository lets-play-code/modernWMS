using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ModernWMS;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support;

public sealed class ModernWmsApiHost : IAsyncDisposable
{
    private static readonly SemaphoreSlim Lock = new(1, 1);
    private static ModernWmsApiHost? _shared;

    private readonly ModernWmsDatabase _database = new();
    private WebApplicationFactory<Program>? _factory;

    public static async Task<ModernWmsApiHost> GetOrCreateAsync()
    {
        if (_shared is not null)
        {
            return _shared;
        }

        await Lock.WaitAsync();
        try
        {
            if (_shared is null)
            {
                _shared = new ModernWmsApiHost();
                try
                {
                    await _shared.StartAsync();
                }
                catch
                {
                    await _shared.DisposeAsync();
                    _shared = null;
                    throw;
                }
            }

            return _shared;
        }
        finally
        {
            Lock.Release();
        }
    }

    public static async Task<MySqlConnection> OpenDatabaseConnectionAsync()
    {
        var host = await GetOrCreateAsync();
        var connection = new MySqlConnection(host._database.ConnectionString);
        await connection.OpenAsync();
        return connection;
    }

    public HttpClient CreateClient()
    {
        if (_factory is null)
        {
            throw new InvalidOperationException("ModernWMS API host has not been started.");
        }

        return _factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false
        });
    }

    public static async Task DisposeSharedAsync()
    {
        if (_shared is null)
        {
            return;
        }

        await Lock.WaitAsync();
        try
        {
            if (_shared is not null)
            {
                await _shared.DisposeAsync();
                _shared = null;
            }
        }
        finally
        {
            Lock.Release();
        }
    }

    public async ValueTask DisposeAsync()
    {
        _factory?.Dispose();
        await _database.DisposeAsync();
    }

    private async Task StartAsync()
    {
        await _database.StartAsync();

        _factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.UseEnvironment("Testing");
                builder.ConfigureAppConfiguration((_, config) =>
                {
                    config.AddInMemoryCollection(new Dictionary<string, string?>
                    {
                        ["Database:db"] = "MySql",
                        ["ConnectionStrings:MySqlConn"] = _database.ConnectionString
                    });
                });

                builder.ConfigureTestServices(_ => { });
            });
    }
}
