using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using ModernWMS.Core;
using ModernWMS.Core.DBContext;
using ModernWMS.Core.DynamicSearch;
using ModernWMS.Core.Models;
using ModernWMS.Tests.Unit.Support;
using ModernWMS.WMS.Entities.Models;
using ModernWMS.WMS.Services;
using MySqlConnector;
using Xunit;

namespace ModernWMS.Tests.Unit.Services;

public sealed class StockServiceTests : IClassFixture<AsnServiceTestFixture>
{
    private readonly AsnServiceTestFixture _fixture;

    public StockServiceTests(AsnServiceTestFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task StockPageAsyncAggregatesFrozenDamageAndTaskLocksIntoAvailableQty()
    {
        var prefix = $"stock-{Guid.NewGuid():N}"[..14];
        var skuCode = $"SKU-{prefix}";
        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: true);
        var customerId = await InsertCustomerAsync(connection, $"CUSTOMER-{prefix}");
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);

        await InsertStockAsync(connection, master.SkuId, master.NormalLocationId, master.GoodsOwnerId, "SER-NORMAL", 20, false, expiryDate, 10M, putawayDate);
        await InsertStockAsync(connection, master.SkuId, master.NormalLocationId, master.GoodsOwnerId, "SER-FROZEN", 3, true, expiryDate, 10M, putawayDate);
        await InsertStockAsync(connection, master.SkuId, master.DamageLocationId!.Value, master.GoodsOwnerId, "SER-DAMAGE", 4, false, expiryDate, 10M, putawayDate);
        await InsertDispatchAsync(connection, $"DP-{prefix}", customerId, $"CUSTOMER-{prefix}", master.SkuId, master.GoodsOwnerId, master.NormalLocationId, "SER-NORMAL", 5, 5, 0, 2, new DateTime(2026, 5, 10, 9, 0, 0), expiryDate, 10M, putawayDate);
        await InsertProcessLockAsync(connection, master.SkuId, master.GoodsOwnerId, master.NormalLocationId, "SER-NORMAL", 2, expiryDate, 10M, putawayDate);
        await InsertMoveLockAsync(connection, master.SkuId, master.GoodsOwnerId, master.NormalLocationId, "SER-NORMAL", 1, expiryDate, 10M, putawayDate);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var (data, totals) = await service.StockPageAsync(CreatePageSearch("sku_code", skuCode), TestCurrentUser.Admin());

        totals.Should().Be(1);
        data.Should().ContainSingle();
        var row = data.Single();
        row.sku_code.Should().Be(skuCode);
        row.qty.Should().Be(27);
        row.qty_frozen.Should().Be(3);
        row.qty_locked.Should().Be(8);
        row.qty_available.Should().Be(12);
    }

    [Fact]
    public async Task SelectPageAsyncFiltersDefaultAllAndFrozenBuckets()
    {
        var prefix = $"select-{Guid.NewGuid():N}"[..14];
        await using var connection = await _fixture.OpenConnectionAsync();
        var masterA = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}a", includeDamageLocation: false);
        var masterB = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}b", includeDamageLocation: false);
        var masterC = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}c", includeDamageLocation: false);
        var customerId = await InsertCustomerAsync(connection, $"CUSTOMER-{prefix}");
        var ownerName = $"OWNER-{prefix}";
        var ownerId = await InsertGoodsOwnerAsync(connection, ownerName);
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 4, 1);

        await UpdateGoodsOwnerAsync(connection, masterA.GoodsOwnerId, ownerId);
        await UpdateGoodsOwnerAsync(connection, masterB.GoodsOwnerId, ownerId);
        await UpdateGoodsOwnerAsync(connection, masterC.GoodsOwnerId, ownerId);

        await InsertStockAsync(connection, masterA.SkuId, masterA.NormalLocationId, ownerId, "SER-AVL", 5, false, expiryDate, 10M, putawayDate);
        await InsertStockAsync(connection, masterB.SkuId, masterB.NormalLocationId, ownerId, "SER-LCK", 6, false, expiryDate, 10M, putawayDate);
        await InsertStockAsync(connection, masterC.SkuId, masterC.NormalLocationId, ownerId, "SER-FRZ", 4, true, expiryDate, 10M, putawayDate);
        await InsertDispatchAsync(connection, $"DP-{prefix}", customerId, $"CUSTOMER-{prefix}", masterB.SkuId, ownerId, masterB.NormalLocationId, "SER-LCK", 6, 6, 0, 2, new DateTime(2026, 5, 11, 10, 0, 0), expiryDate, 10M, putawayDate);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var currentUser = TestCurrentUser.Admin();
        var search = CreatePageSearch("goods_owner_name", ownerName);

        var (availableRows, availableTotals) = await service.SelectPageAsync(search, currentUser);
        availableTotals.Should().Be(1);
        availableRows.Should().ContainSingle();
        availableRows.Single().series_number.Should().Be("SER-AVL");
        availableRows.Single().qty_available.Should().Be(5);

        var (allRows, allTotals) = await service.SelectPageAsync(CreatePageSearch("goods_owner_name", ownerName, sqlTitle: "all"), currentUser);
        allTotals.Should().Be(3);
        allRows.Select(t => t.series_number).Should().BeEquivalentTo("SER-AVL", "SER-LCK", "SER-FRZ");
        allRows.Should().ContainSingle(t => t.series_number == "SER-LCK" && t.qty_available == 0 && t.is_freeze == false);
        allRows.Should().ContainSingle(t => t.series_number == "SER-FRZ" && t.qty_available == 0 && t.is_freeze == true);

        var (frozenRows, frozenTotals) = await service.SelectPageAsync(CreatePageSearch("goods_owner_name", ownerName, sqlTitle: "frozen"), currentUser);
        frozenTotals.Should().Be(1);
        frozenRows.Should().ContainSingle();
        frozenRows.Single().series_number.Should().Be("SER-FRZ");
        frozenRows.Single().is_freeze.Should().BeTrue();
    }

    [Fact]
    public async Task SafetyStockPageAsyncAggregatesWarehouseAvailabilityAndThreshold()
    {
        var prefix = $"safety-{Guid.NewGuid():N}"[..14];
        var skuCode = $"SKU-{prefix}";
        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: true);
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);

        await InsertStockAsync(connection, master.SkuId, master.NormalLocationId, master.GoodsOwnerId, "SER-NORMAL", 10, false, expiryDate, 10M, putawayDate);
        await InsertStockAsync(connection, master.SkuId, master.NormalLocationId, master.GoodsOwnerId, "SER-FROZEN", 2, true, expiryDate, 10M, putawayDate);
        await InsertStockAsync(connection, master.SkuId, master.DamageLocationId!.Value, master.GoodsOwnerId, "SER-DAMAGE", 3, false, expiryDate, 10M, putawayDate);
        await InsertSafetyStockAsync(connection, master.SkuId, master.WarehouseId, 15);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var (data, totals) = await service.SafetyStockPageAsync(CreatePageSearch("sku_code", skuCode), TestCurrentUser.Admin());

        totals.Should().Be(1);
        data.Should().ContainSingle();
        var row = data.Single();
        row.sku_code.Should().Be(skuCode);
        row.qty.Should().Be(15);
        row.qty_frozen.Should().Be(2);
        row.qty_locked.Should().Be(0);
        row.qty_available.Should().Be(10);
        row.safety_stock_qty.Should().Be(15);
    }

    private static StockService CreateService(SqlDBContext dbContext)
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Database:db"] = "MySql"
            })
            .Build();

        return new StockService(dbContext, new TestStringLocalizer<MultiLanguage>(), configuration);
    }

    private static PageSearch CreatePageSearch(string name, string value, string sqlTitle = "")
    {
        return new PageSearch
        {
            pageIndex = 1,
            pageSize = 20,
            sqlTitle = sqlTitle,
            searchObjects = new List<SearchObject>
            {
                new()
                {
                    Name = name,
                    Operator = Operators.Equal,
                    Text = value,
                    Value = value
                }
            }
        };
    }

    private static async Task InsertStockAsync(MySqlConnection connection, int skuId, int locationId, int goodsOwnerId, string seriesNumber, int qty, bool isFreeze, DateTime expiryDate, decimal price, DateTime putawayDate)
    {
        await ExecuteAsync(
            connection,
            "insert into stock (sku_id, goods_location_id, qty, goods_owner_id, is_freeze, last_update_time, tenant_id, series_number, expiry_date, price, putaway_date) values (@skuId, @locationId, @qty, @ownerId, @isFreeze, now(), 1, @seriesNumber, @expiryDate, @price, @putawayDate);",
            ("@skuId", skuId),
            ("@locationId", locationId),
            ("@qty", qty),
            ("@ownerId", goodsOwnerId),
            ("@isFreeze", isFreeze ? 1 : 0),
            ("@seriesNumber", seriesNumber),
            ("@expiryDate", expiryDate),
            ("@price", price),
            ("@putawayDate", putawayDate));
    }

    private static async Task InsertDispatchAsync(MySqlConnection connection, string dispatchNo, int customerId, string customerName, int skuId, int goodsOwnerId, int locationId, string seriesNumber, int qty, int lockQty, int pickedQty, byte status, DateTime createTime, DateTime expiryDate, decimal price, DateTime putawayDate)
    {
        var dispatchId = await InsertScalarAsync(
            connection,
            "insert into dispatchlist (dispatch_no, dispatch_status, customer_id, customer_name, sku_id, qty, lock_qty, picked_qty, creator, create_time, last_update_time, tenant_id) values (@dispatchNo, @status, @customerId, @customerName, @skuId, @qty, @lockQty, @pickedQty, 'unit', @createTime, @createTime, 1); select last_insert_id();",
            ("@dispatchNo", dispatchNo),
            ("@status", status),
            ("@customerId", customerId),
            ("@customerName", customerName),
            ("@skuId", skuId),
            ("@qty", qty),
            ("@lockQty", lockQty),
            ("@pickedQty", pickedQty),
            ("@createTime", createTime));

        await ExecuteAsync(
            connection,
            "insert into dispatchpicklist (dispatchlist_id, goods_owner_id, goods_location_id, sku_id, pick_qty, picked_qty, is_update_stock, last_update_time, series_number, expiry_date, price, putaway_date) values (@dispatchId, @ownerId, @locationId, @skuId, @pickQty, @pickedQty, 0, now(), @seriesNumber, @expiryDate, @price, @putawayDate);",
            ("@dispatchId", dispatchId),
            ("@ownerId", goodsOwnerId),
            ("@locationId", locationId),
            ("@skuId", skuId),
            ("@pickQty", Math.Max(lockQty, pickedQty)),
            ("@pickedQty", pickedQty),
            ("@seriesNumber", seriesNumber),
            ("@expiryDate", expiryDate),
            ("@price", price),
            ("@putawayDate", putawayDate));
    }

    private static async Task InsertProcessLockAsync(MySqlConnection connection, int skuId, int goodsOwnerId, int locationId, string seriesNumber, int qty, DateTime expiryDate, decimal price, DateTime putawayDate)
    {
        await ExecuteAsync(
            connection,
            "insert into stockprocessdetail (stock_process_id, sku_id, goods_owner_id, goods_location_id, qty, last_update_time, tenant_id, is_source, is_update_stock, series_number, expiry_date, price, putaway_date) values (0, @skuId, @ownerId, @locationId, @qty, now(), 1, 1, 0, @seriesNumber, @expiryDate, @price, @putawayDate);",
            ("@skuId", skuId),
            ("@ownerId", goodsOwnerId),
            ("@locationId", locationId),
            ("@qty", qty),
            ("@seriesNumber", seriesNumber),
            ("@expiryDate", expiryDate),
            ("@price", price),
            ("@putawayDate", putawayDate));
    }

    private static async Task InsertMoveLockAsync(MySqlConnection connection, int skuId, int goodsOwnerId, int locationId, string seriesNumber, int qty, DateTime expiryDate, decimal price, DateTime putawayDate)
    {
        await ExecuteAsync(
            connection,
            "insert into stockmove (job_code, move_status, sku_id, orig_goods_location_id, dest_googs_location_id, qty, goods_owner_id, handler, handle_time, creator, create_time, last_update_time, tenant_id, series_number, expiry_date, price, putaway_date) values (@jobCode, 0, @skuId, @locationId, @locationId, @qty, @ownerId, 'unit', now(), 'unit', now(), now(), 1, @seriesNumber, @expiryDate, @price, @putawayDate);",
            ("@jobCode", $"MOVE-{Guid.NewGuid():N}"[..16]),
            ("@skuId", skuId),
            ("@locationId", locationId),
            ("@qty", qty),
            ("@ownerId", goodsOwnerId),
            ("@seriesNumber", seriesNumber),
            ("@expiryDate", expiryDate),
            ("@price", price),
            ("@putawayDate", putawayDate));
    }

    private static async Task InsertSafetyStockAsync(MySqlConnection connection, int skuId, int warehouseId, int safetyStockQty)
    {
        await ExecuteAsync(
            connection,
            "insert into sku_safety_stock (sku_id, warehouse_id, safety_stock_qty) values (@skuId, @warehouseId, @safetyStockQty);",
            ("@skuId", skuId),
            ("@warehouseId", warehouseId),
            ("@safetyStockQty", safetyStockQty));
    }

    private static async Task<int> InsertCustomerAsync(MySqlConnection connection, string customerName)
    {
        return await InsertScalarAsync(
            connection,
            "insert into customer (customer_name, city, address, creator, tenant_id, create_time, last_update_time, is_valid) values (@name, '测试城市', '测试地址', 'unit', 1, now(), now(), 1); select last_insert_id();",
            ("@name", customerName));
    }

    private static async Task<int> InsertGoodsOwnerAsync(MySqlConnection connection, string goodsOwnerName)
    {
        return await InsertScalarAsync(
            connection,
            "insert into goodsowner (goods_owner_name, city, address, creator, tenant_id, create_time, last_update_time, is_valid) values (@name, '测试城市', '测试地址', 'unit', 1, now(), now(), 1); select last_insert_id();",
            ("@name", goodsOwnerName));
    }

    private static async Task UpdateGoodsOwnerAsync(MySqlConnection connection, int sourceOwnerId, int targetOwnerId)
    {
        await ExecuteAsync(
            connection,
            "update stock set goods_owner_id = @targetOwnerId where goods_owner_id = @sourceOwnerId;",
            ("@targetOwnerId", targetOwnerId),
            ("@sourceOwnerId", sourceOwnerId));
    }

    private static async Task<int> InsertScalarAsync(MySqlConnection connection, string sql, params (string Name, object Value)[] parameters)
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
