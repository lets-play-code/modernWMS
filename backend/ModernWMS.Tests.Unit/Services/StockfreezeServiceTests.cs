using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using ModernWMS.Core;
using ModernWMS.Core.DBContext;
using ModernWMS.Core.Utility;
using ModernWMS.Tests.Unit.Support;
using ModernWMS.WMS.Entities.Models;
using ModernWMS.WMS.Entities.ViewModels;
using ModernWMS.WMS.Services;
using MySqlConnector;
using Xunit;

namespace ModernWMS.Tests.Unit.Services;

public sealed class StockfreezeServiceTests : IClassFixture<AsnServiceTestFixture>
{
    private readonly AsnServiceTestFixture _fixture;

    public StockfreezeServiceTests(AsnServiceTestFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task AddAsyncFreezesThenUnfreezesMatchingStocks()
    {
        var prefix = $"freeze-flow-{Guid.NewGuid():N}"[..20];
        const string seriesNumber = "SN-FREEZE-01";
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);

        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: false);
        await InsertStockAsync(connection, master.SkuId, master.NormalLocationId, master.GoodsOwnerId, seriesNumber, 5, false, expiryDate, 8.8M, putawayDate);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var currentUser = TestCurrentUser.Admin();

        var freezeResult = await service.AddAsync(CreateViewModel(master, true, seriesNumber), currentUser);
        freezeResult.id.Should().BeGreaterThan(0);

        await using var verifyAfterFreeze = _fixture.CreateDbContext();
        var frozenStock = await verifyAfterFreeze.GetDbSet<StockEntity>().SingleAsync(t => t.sku_id == master.SkuId && t.goods_owner_id == master.GoodsOwnerId);
        var freezeTasks = await verifyAfterFreeze.GetDbSet<StockfreezeEntity>()
            .Where(t => t.sku_id == master.SkuId && t.goods_owner_id == master.GoodsOwnerId)
            .OrderBy(t => t.id)
            .ToListAsync();

        frozenStock.is_freeze.Should().BeTrue();
        freezeTasks.Should().ContainSingle(t => t.job_type);

        await using var unfreezeContext = _fixture.CreateDbContext();
        var unfreezeService = CreateService(unfreezeContext);
        var unfreezeResult = await unfreezeService.AddAsync(CreateViewModel(master, false, seriesNumber), currentUser);
        unfreezeResult.id.Should().BeGreaterThan(0);

        await using var verifyAfterUnfreeze = _fixture.CreateDbContext();
        var unfrozenStock = await verifyAfterUnfreeze.GetDbSet<StockEntity>().SingleAsync(t => t.sku_id == master.SkuId && t.goods_owner_id == master.GoodsOwnerId);
        var allTasks = await verifyAfterUnfreeze.GetDbSet<StockfreezeEntity>()
            .Where(t => t.sku_id == master.SkuId && t.goods_owner_id == master.GoodsOwnerId)
            .OrderBy(t => t.id)
            .ToListAsync();

        unfrozenStock.is_freeze.Should().BeFalse();
        allTasks.Should().HaveCount(2);
        allTasks.Select(t => t.job_type).Should().Equal(true, false);
    }

    [Theory]
    [InlineData("process", "process_not_comfirm")]
    [InlineData("dispatch", "dispatch_not_comfirm")]
    [InlineData("move", "move_not_comfirm")]
    public async Task AddAsyncRejectsWhenBlockingTasksExist(string blockingKind, string expectedMessage)
    {
        var prefix = $"freeze-lock-{Guid.NewGuid():N}"[..20];
        const string seriesNumber = "SN-FREEZE-LOCK-01";
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);

        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}a", includeDamageLocation: false);
        var destination = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}b", includeDamageLocation: false);
        await InsertStockAsync(connection, master.SkuId, master.NormalLocationId, master.GoodsOwnerId, seriesNumber, 5, false, expiryDate, 7.7M, putawayDate);
        await InsertBlockingTaskAsync(connection, blockingKind, master, destination.NormalLocationId, seriesNumber, expiryDate, 7.7M, putawayDate);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var result = await service.AddAsync(CreateViewModel(master, true, seriesNumber), TestCurrentUser.Admin());

        result.id.Should().Be(0);
        result.msg.Should().Be(expectedMessage);
        await using var verificationContext = _fixture.CreateDbContext();
        var stock = await verificationContext.GetDbSet<StockEntity>().SingleAsync(t => t.sku_id == master.SkuId && t.goods_owner_id == master.GoodsOwnerId);
        var tasks = await verificationContext.GetDbSet<StockfreezeEntity>()
            .CountAsync(t => t.sku_id == master.SkuId && t.goods_owner_id == master.GoodsOwnerId);

        stock.is_freeze.Should().BeFalse();
        tasks.Should().Be(0);
    }

    private static StockfreezeService CreateService(SqlDBContext dbContext)
    {
        return new StockfreezeService(
            dbContext,
            new TestStringLocalizer<MultiLanguage>(),
            new FunctionHelper(dbContext, new HttpContextAccessor()));
    }

    private static StockfreezeViewModel CreateViewModel(AsnTestMasterData master, bool jobType, string seriesNumber)
    {
        return new StockfreezeViewModel
        {
            job_type = jobType,
            sku_id = master.SkuId,
            goods_owner_id = master.GoodsOwnerId,
            goods_location_id = master.NormalLocationId,
            series_number = seriesNumber,
            handle_time = UtilConvert.MinDate,
            last_update_time = UtilConvert.MinDate
        };
    }

    private static async Task InsertBlockingTaskAsync(
        MySqlConnection connection,
        string blockingKind,
        AsnTestMasterData master,
        int destinationLocationId,
        string seriesNumber,
        DateTime expiryDate,
        decimal price,
        DateTime putawayDate)
    {
        switch (blockingKind)
        {
            case "process":
                await ExecuteAsync(
                    connection,
                    "insert into stockprocessdetail (stock_process_id, sku_id, goods_owner_id, goods_location_id, qty, last_update_time, tenant_id, is_source, is_update_stock, series_number, expiry_date, price, putaway_date) values (0, @skuId, @ownerId, @locationId, 2, now(), 1, 1, 0, @seriesNumber, @expiryDate, @price, @putawayDate);",
                    ("@skuId", master.SkuId),
                    ("@ownerId", master.GoodsOwnerId),
                    ("@locationId", master.NormalLocationId),
                    ("@seriesNumber", seriesNumber),
                    ("@expiryDate", expiryDate),
                    ("@price", price),
                    ("@putawayDate", putawayDate));
                break;
            case "dispatch":
                var customerId = await InsertScalarAsync(
                    connection,
                    "insert into customer (customer_name, city, address, creator, tenant_id, create_time, last_update_time, is_valid) values (@name, '测试城市', '测试地址', 'unit', 1, now(), now(), 1); select last_insert_id();",
                    ("@name", $"CUSTOMER-{Guid.NewGuid():N}"[..18]));
                var dispatchId = await InsertScalarAsync(
                    connection,
                    "insert into dispatchlist (dispatch_no, dispatch_status, customer_id, customer_name, sku_id, qty, lock_qty, picked_qty, creator, create_time, last_update_time, tenant_id) values (@dispatchNo, 2, @customerId, @customerName, @skuId, 2, 2, 0, 'unit', now(), now(), 1); select last_insert_id();",
                    ("@dispatchNo", $"DP-{Guid.NewGuid():N}"[..18]),
                    ("@customerId", customerId),
                    ("@customerName", $"CUSTOMER-{Guid.NewGuid():N}"[..18]),
                    ("@skuId", master.SkuId));
                await ExecuteAsync(
                    connection,
                    "insert into dispatchpicklist (dispatchlist_id, goods_owner_id, goods_location_id, sku_id, pick_qty, picked_qty, is_update_stock, last_update_time, series_number, expiry_date, price, putaway_date) values (@dispatchId, @ownerId, @locationId, @skuId, 2, 0, 0, now(), @seriesNumber, @expiryDate, @price, @putawayDate);",
                    ("@dispatchId", dispatchId),
                    ("@ownerId", master.GoodsOwnerId),
                    ("@locationId", master.NormalLocationId),
                    ("@skuId", master.SkuId),
                    ("@seriesNumber", seriesNumber),
                    ("@expiryDate", expiryDate),
                    ("@price", price),
                    ("@putawayDate", putawayDate));
                break;
            case "move":
                await ExecuteAsync(
                    connection,
                    "insert into stockmove (job_code, move_status, sku_id, orig_goods_location_id, dest_googs_location_id, qty, goods_owner_id, handler, handle_time, creator, create_time, last_update_time, tenant_id, series_number, expiry_date, price, putaway_date) values (@jobCode, 0, @skuId, @origLocationId, @destLocationId, 2, @ownerId, 'unit', now(), 'unit', now(), now(), 1, @seriesNumber, @expiryDate, @price, @putawayDate);",
                    ("@jobCode", $"MOVE-{Guid.NewGuid():N}"[..18]),
                    ("@skuId", master.SkuId),
                    ("@origLocationId", master.NormalLocationId),
                    ("@destLocationId", destinationLocationId),
                    ("@ownerId", master.GoodsOwnerId),
                    ("@seriesNumber", seriesNumber),
                    ("@expiryDate", expiryDate),
                    ("@price", price),
                    ("@putawayDate", putawayDate));
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(blockingKind), blockingKind, null);
        }
    }

    private static async Task InsertStockAsync(
        MySqlConnection connection,
        int skuId,
        int locationId,
        int goodsOwnerId,
        string seriesNumber,
        int qty,
        bool isFreeze,
        DateTime expiryDate,
        decimal price,
        DateTime putawayDate)
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
