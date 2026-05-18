using System.Globalization;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using ModernWMS.Core;
using ModernWMS.Core.DBContext;
using ModernWMS.Core.JWT;
using ModernWMS.Tests.Unit.Support;
using ModernWMS.WMS.Entities.Models;
using ModernWMS.WMS.Entities.ViewModels;
using ModernWMS.WMS.Services;
using MySqlConnector;
using Testcontainers.MySql;
using Xunit;

namespace ModernWMS.Tests.Unit.Services;

public sealed class AsnServiceTests : IClassFixture<AsnServiceTestFixture>
{
    private readonly AsnServiceTestFixture _fixture;

    public AsnServiceTests(AsnServiceTestFixture fixture)
    {
        _fixture = fixture;
    }

    [Theory]
    [InlineData(6, 0, 2)]
    [InlineData(10, 2, 0)]
    public async Task SortedAsyncSetsMoreAndShortageQuantitiesFromSortedQty(int sortedQty, int expectedMoreQty, int expectedShortageQty)
    {
        var prefix = $"sorted-{Guid.NewGuid():N}"[..14];
        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: false);
        var asnId = await AsnUnitSeedData.InsertAsnAsync(
            connection,
            master,
            asnNo: $"ASN-{prefix}",
            asnStatus: 2,
            asnQty: 8,
            sortedQty: sortedQty,
            price: 19.9M,
            expiryDate: new DateTime(2026, 12, 31));

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);

        var result = await service.SortedAsync(new List<int> { asnId });

        result.flag.Should().BeTrue();
        await using var verificationContext = _fixture.CreateDbContext();
        var entity = await verificationContext.GetDbSet<AsnEntity>().SingleAsync(t => t.id == asnId);
        entity.asn_status.Should().Be(3);
        entity.more_qty.Should().Be(expectedMoreQty);
        entity.shortage_qty.Should().Be(expectedShortageQty);
    }

    [Fact]
    public async Task PutAwayAsyncMergesExistingStockLayerAndTracksDamageQty()
    {
        var prefix = $"putaway-{Guid.NewGuid():N}"[..14];
        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: true);
        var asnId = await AsnUnitSeedData.InsertAsnAsync(
            connection,
            master,
            asnNo: $"ASN-{prefix}",
            asnStatus: 3,
            asnQty: 8,
            sortedQty: 8,
            price: 19.9M,
            expiryDate: new DateTime(2026, 12, 31));
        await AsnUnitSeedData.InsertAsnSortAsync(connection, asnId, "SN-UNIT-001", sortedQty: 8, putawayQty: 0);
        await AsnUnitSeedData.InsertStockAsync(
            connection,
            master.SkuId,
            master.NormalLocationId,
            master.GoodsOwnerId,
            "SN-UNIT-001",
            qty: 2,
            expiryDate: new DateTime(2026, 12, 31),
            price: 19.9M,
            putawayDate: DateTime.Today);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var currentUser = TestCurrentUser.Admin();

        var result = await service.PutAwayAsync(new List<AsnPutAwayInputViewModel>
        {
            new()
            {
                asn_id = asnId,
                goods_owner_id = master.GoodsOwnerId,
                series_number = "SN-UNIT-001",
                goods_location_id = master.NormalLocationId,
                putaway_qty = 3
            },
            new()
            {
                asn_id = asnId,
                goods_owner_id = master.GoodsOwnerId,
                series_number = "SN-UNIT-001",
                goods_location_id = master.DamageLocationId!.Value,
                putaway_qty = 2
            }
        }, currentUser);

        result.flag.Should().BeTrue();
        await using var verificationContext = _fixture.CreateDbContext();
        var entity = await verificationContext.GetDbSet<AsnEntity>().SingleAsync(t => t.id == asnId);
        var sort = await verificationContext.GetDbSet<AsnsortEntity>().SingleAsync(t => t.asn_id == asnId);
        var stocks = await verificationContext.GetDbSet<StockEntity>()
            .Where(t => t.sku_id == master.SkuId && t.goods_owner_id == master.GoodsOwnerId)
            .OrderBy(t => t.goods_location_id)
            .ToListAsync();

        entity.actual_qty.Should().Be(5);
        entity.asn_status.Should().Be(3);
        entity.damage_qty.Should().Be(2);
        sort.putaway_qty.Should().Be(5);
        stocks.Should().HaveCount(2);
        stocks.Should().ContainSingle(t => t.goods_location_id == master.NormalLocationId && t.qty == 5);
        stocks.Should().ContainSingle(t => t.goods_location_id == master.DamageLocationId && t.qty == 2);
    }

    private static AsnService CreateService(SqlDBContext dbContext)
    {
        return new AsnService(
            dbContext,
            new TestStringLocalizer<MultiLanguage>(),
            new FunctionHelper(dbContext, new HttpContextAccessor()));
    }
}

public sealed class AsnServiceTestFixture : IAsyncLifetime
{
    private readonly MySqlContainer _container;

    public AsnServiceTestFixture()
    {
        Environment.SetEnvironmentVariable("TESTCONTAINERS_RYUK_DISABLED", "true");
        _container = new MySqlBuilder()
            .WithImage("mysql:8.0.41")
            .WithCleanUp(false)
            .WithDatabase("wms")
            .WithUsername("modernwms")
            .WithPassword("modernwms_test")
            .Build();
    }

    public async Task InitializeAsync()
    {
        await _container.StartAsync();
        await ImportSeedAsync();
    }

    public async Task DisposeAsync()
    {
        await _container.DisposeAsync();
    }

    public SqlDBContext CreateDbContext()
    {
        var options = new DbContextOptionsBuilder<SqlDBContext>()
            .UseMySql(ConnectionString, ServerVersion.AutoDetect(ConnectionString))
            .Options;
        return new SqlDBContext(options);
    }

    public async Task<MySqlConnection> OpenConnectionAsync()
    {
        var connection = new MySqlConnection(ConnectionString);
        await connection.OpenAsync();
        return connection;
    }

    private string ConnectionString
    {
        get
        {
            var builder = new MySqlConnectionStringBuilder(_container.GetConnectionString())
            {
                AllowUserVariables = true,
                DefaultCommandTimeout = 120,
                ConnectionTimeout = 30
            };
            return builder.ConnectionString;
        }
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
}

internal static class AsnUnitSeedData
{
    public static async Task<AsnTestMasterData> SeedMasterDataAsync(MySqlConnection connection, string prefix, bool includeDamageLocation)
    {
        var warehouseId = await InsertAsync(connection, "insert into warehouse (warehouse_name, city, address, creator, tenant_id) values (@name, '测试城市', '测试地址', 'unit', 1); select last_insert_id();", ("@name", $"WH-{prefix}"));
        var normalAreaId = await InsertAsync(connection, "insert into warehousearea (warehouse_id, area_name, area_property, tenant_id) values (@warehouseId, @name, 1, 1); select last_insert_id();", ("@warehouseId", warehouseId), ("@name", $"AREA-N-{prefix}"));
        var normalLocationId = await InsertAsync(connection, "insert into goodslocation (warehouse_id, warehouse_name, warehouse_area_id, warehouse_area_name, warehouse_area_property, location_name, tenant_id, create_time, last_update_time, is_valid) values (@warehouseId, @warehouseName, @areaId, @areaName, 1, @locationName, 1, now(), now(), 1); select last_insert_id();", ("@warehouseId", warehouseId), ("@warehouseName", $"WH-{prefix}"), ("@areaId", normalAreaId), ("@areaName", $"AREA-N-{prefix}"), ("@locationName", $"LOC-N-{prefix}"));
        int? damageLocationId = null;
        if (includeDamageLocation)
        {
            var damageAreaId = await InsertAsync(connection, "insert into warehousearea (warehouse_id, area_name, area_property, tenant_id) values (@warehouseId, @name, 5, 1); select last_insert_id();", ("@warehouseId", warehouseId), ("@name", $"AREA-D-{prefix}"));
            damageLocationId = await InsertAsync(connection, "insert into goodslocation (warehouse_id, warehouse_name, warehouse_area_id, warehouse_area_name, warehouse_area_property, location_name, tenant_id, create_time, last_update_time, is_valid) values (@warehouseId, @warehouseName, @areaId, @areaName, 5, @locationName, 1, now(), now(), 1); select last_insert_id();", ("@warehouseId", warehouseId), ("@warehouseName", $"WH-{prefix}"), ("@areaId", damageAreaId), ("@areaName", $"AREA-D-{prefix}"), ("@locationName", $"LOC-D-{prefix}"));
        }

        var ownerId = await InsertAsync(connection, "insert into goodsowner (goods_owner_name, city, address, creator, tenant_id, create_time, last_update_time, is_valid) values (@name, '测试城市', '测试地址', 'unit', 1, now(), now(), 1); select last_insert_id();", ("@name", $"OWNER-{prefix}"));
        var supplierId = await InsertAsync(connection, "insert into supplier (supplier_name, city, address, creator, tenant_id, create_time, last_update_time, is_valid) values (@name, '测试城市', '测试地址', 'unit', 1, now(), now(), 1); select last_insert_id();", ("@name", $"SUP-{prefix}"));
        var categoryId = await InsertAsync(connection, "insert into category (category_name, creator, tenant_id, create_time, last_update_time, is_valid) values (@name, 'unit', 1, now(), now(), 1); select last_insert_id();", ("@name", $"CAT-{prefix}"));
        var spuId = await InsertAsync(connection, "insert into spu (spu_code, spu_name, category_id, supplier_id, supplier_name, creator, tenant_id, create_time, last_update_time, is_valid) values (@code, @code, @categoryId, @supplierId, @supplierName, 'unit', 1, now(), now(), 1); select last_insert_id();", ("@code", $"SPU-{prefix}"), ("@categoryId", categoryId), ("@supplierId", supplierId), ("@supplierName", $"SUP-{prefix}"));
        var skuId = await InsertAsync(connection, "insert into sku (spu_id, sku_code, sku_name, unit, bar_code, weight, volume, create_time, last_update_time) values (@spuId, @code, @code, 'EA', @code, 1, 1, now(), now()); select last_insert_id();", ("@spuId", spuId), ("@code", $"SKU-{prefix}"));
        return new AsnTestMasterData(warehouseId, normalLocationId, damageLocationId, ownerId, supplierId, spuId, skuId);
    }

    public static async Task<int> InsertAsnAsync(MySqlConnection connection, AsnTestMasterData master, string asnNo, byte asnStatus, int asnQty, int sortedQty, decimal price, DateTime expiryDate)
    {
        var masterId = await InsertAsync(connection, "insert into asnmaster (asn_no, asn_batch, estimated_arrival_time, asn_status, goods_owner_id, goods_owner_name, creator, tenant_id, create_time, last_update_time) values (@asnNo, @asnNo, @eta, @asnStatus, @ownerId, @ownerName, 'unit', 1, now(), now()); select last_insert_id();", ("@asnNo", asnNo), ("@eta", new DateTime(2026, 5, 18)), ("@asnStatus", asnStatus), ("@ownerId", master.GoodsOwnerId), ("@ownerName", $"OWNER-{asnNo[4..]}"));
        return await InsertAsync(connection, "insert into asn (asnmaster_id, asn_no, asn_status, spu_id, sku_id, asn_qty, actual_qty, arrival_time, unload_time, unload_person_id, unload_person, sorted_qty, shortage_qty, more_qty, damage_qty, supplier_id, supplier_name, goods_owner_id, goods_owner_name, creator, tenant_id, create_time, last_update_time, is_valid, expiry_date, price) values (@masterId, @asnNo, @asnStatus, @spuId, @skuId, @asnQty, 0, @arrivalTime, @unloadTime, 1, 'unit', @sortedQty, 0, 0, 0, @supplierId, @supplierName, @ownerId, @ownerName, 'unit', 1, now(), now(), 1, @expiryDate, @price); select last_insert_id();", ("@masterId", masterId), ("@asnNo", asnNo), ("@asnStatus", asnStatus), ("@spuId", master.SpuId), ("@skuId", master.SkuId), ("@asnQty", asnQty), ("@arrivalTime", new DateTime(2026, 5, 18, 8, 0, 0)), ("@unloadTime", new DateTime(2026, 5, 18, 9, 0, 0)), ("@sortedQty", sortedQty), ("@supplierId", master.SupplierId), ("@supplierName", $"SUP-{asnNo[4..]}"), ("@ownerId", master.GoodsOwnerId), ("@ownerName", $"OWNER-{asnNo[4..]}"), ("@expiryDate", expiryDate), ("@price", price));
    }

    public static async Task InsertAsnSortAsync(MySqlConnection connection, int asnId, string seriesNumber, int sortedQty, int putawayQty)
    {
        await ExecuteAsync(connection, "insert into asnsort (asn_id, sorted_qty, series_number, putaway_qty, creator, tenant_id, create_time, last_update_time, is_valid) values (@asnId, @sortedQty, @seriesNumber, @putawayQty, 'unit', 1, now(), now(), 1);", ("@asnId", asnId), ("@sortedQty", sortedQty), ("@seriesNumber", seriesNumber), ("@putawayQty", putawayQty));
    }

    public static async Task InsertStockAsync(MySqlConnection connection, int skuId, int locationId, int goodsOwnerId, string seriesNumber, int qty, DateTime expiryDate, decimal price, DateTime putawayDate)
    {
        await ExecuteAsync(connection, "insert into stock (sku_id, goods_location_id, qty, goods_owner_id, is_freeze, last_update_time, tenant_id, series_number, expiry_date, price, putaway_date) values (@skuId, @locationId, @qty, @ownerId, 0, now(), 1, @seriesNumber, @expiryDate, @price, @putawayDate);", ("@skuId", skuId), ("@locationId", locationId), ("@qty", qty), ("@ownerId", goodsOwnerId), ("@seriesNumber", seriesNumber), ("@expiryDate", expiryDate), ("@price", price), ("@putawayDate", putawayDate));
    }

    private static async Task<int> InsertAsync(MySqlConnection connection, string sql, params (string Name, object Value)[] parameters)
    {
        await using var command = new MySqlCommand(sql, connection);
        foreach (var parameter in parameters)
        {
            command.Parameters.AddWithValue(parameter.Name, parameter.Value);
        }
        return Convert.ToInt32(await command.ExecuteScalarAsync());
    }

    private static async Task ExecuteAsync(MySqlConnection connection, string sql, params (string Name, object Value)[] parameters)
    {
        await using var command = new MySqlCommand(sql, connection);
        foreach (var parameter in parameters)
        {
            command.Parameters.AddWithValue(parameter.Name, parameter.Value);
        }
        await command.ExecuteNonQueryAsync();
    }
}

internal sealed record AsnTestMasterData(
    int WarehouseId,
    int NormalLocationId,
    int? DamageLocationId,
    int GoodsOwnerId,
    int SupplierId,
    int SpuId,
    int SkuId);

internal sealed class TestStringLocalizer<T> : IStringLocalizer<T>
{
    public LocalizedString this[string name] => new(name, name);

    public LocalizedString this[string name, params object[] arguments] => new(name, string.Format(CultureInfo.InvariantCulture, name, arguments));

    public IEnumerable<LocalizedString> GetAllStrings(bool includeParentCultures) => Array.Empty<LocalizedString>();

    public IStringLocalizer WithCulture(CultureInfo culture) => this;
}
