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

public sealed class StockprocessServiceTests : IClassFixture<AsnServiceTestFixture>
{
    private readonly AsnServiceTestFixture _fixture;

    public StockprocessServiceTests(AsnServiceTestFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task AddAsyncRejectsFrozenSourceStock()
    {
        var prefix = $"proc-freeze-{Guid.NewGuid():N}"[..20];
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);
        const string sourceSeries = "SN-PROC-SRC-01";

        await using var connection = await _fixture.OpenConnectionAsync();
        var sourceMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}a", includeDamageLocation: false);
        var targetMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}b", includeDamageLocation: false);
        await InsertStockAsync(connection, sourceMaster.SkuId, sourceMaster.NormalLocationId, sourceMaster.GoodsOwnerId, sourceSeries, 6, true, expiryDate, 12.5M, putawayDate);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var result = await service.AddAsync(
            CreateProcessViewModel(sourceMaster, targetMaster, 4, sourceSeries, expiryDate, putawayDate),
            TestCurrentUser.Admin());

        result.id.Should().Be(0);
        result.msg.Should().Be("stock_frozen");
        await using var verificationContext = _fixture.CreateDbContext();
        var processCount = await verificationContext.GetDbSet<StockprocessEntity>().CountAsync();
        processCount.Should().Be(0);
    }

    [Fact]
    public async Task ConfirmAdjustmentMovesInventoryAndRejectsRepeatAdjustment()
    {
        var prefix = $"proc-adjust-{Guid.NewGuid():N}"[..20];
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);
        const string sourceSeries = "SN-PROC-SRC-02";

        await using var connection = await _fixture.OpenConnectionAsync();
        var sourceMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}a", includeDamageLocation: false);
        var targetMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}b", includeDamageLocation: false);
        await InsertStockAsync(connection, sourceMaster.SkuId, sourceMaster.NormalLocationId, sourceMaster.GoodsOwnerId, sourceSeries, 6, false, expiryDate, 12.5M, putawayDate);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var currentUser = TestCurrentUser.Admin();
        var addResult = await service.AddAsync(
            CreateProcessViewModel(sourceMaster, targetMaster, 4, sourceSeries, expiryDate, putawayDate),
            currentUser);

        addResult.id.Should().BeGreaterThan(0);
        (await service.ConfirmProcess(addResult.id, currentUser)).flag.Should().BeTrue();

        var firstAdjustment = await service.ConfirmAdjustment(addResult.id, currentUser);

        firstAdjustment.flag.Should().BeTrue();
        await using var verificationContext = _fixture.CreateDbContext();
        var process = await verificationContext.GetDbSet<StockprocessEntity>().SingleAsync(t => t.id == addResult.id);
        var sourceStock = await verificationContext.GetDbSet<StockEntity>()
            .SingleAsync(t => t.sku_id == sourceMaster.SkuId && t.goods_location_id == sourceMaster.NormalLocationId && t.goods_owner_id == sourceMaster.GoodsOwnerId);
        var targetStock = await verificationContext.GetDbSet<StockEntity>()
            .SingleAsync(t => t.sku_id == targetMaster.SkuId && t.goods_location_id == targetMaster.NormalLocationId && t.goods_owner_id == sourceMaster.GoodsOwnerId);
        var detailFlags = await verificationContext.GetDbSet<StockprocessdetailEntity>()
            .Where(t => t.stock_process_id == addResult.id)
            .Select(t => t.is_update_stock)
            .ToListAsync();
        var adjusts = await verificationContext.GetDbSet<StockadjustEntity>()
            .Where(t => t.job_type == 2)
            .OrderBy(t => t.qty)
            .ToListAsync();

        process.process_status.Should().BeTrue();
        sourceStock.qty.Should().Be(2);
        targetStock.qty.Should().Be(4);
        detailFlags.Should().AllSatisfy(flag => flag.Should().BeTrue());
        adjusts.Should().HaveCount(2);
        adjusts.Select(t => t.qty).Should().Equal(-4, 4);

        await using var repeatContext = _fixture.CreateDbContext();
        var repeatService = CreateService(repeatContext);
        var secondAdjustment = await repeatService.ConfirmAdjustment(addResult.id, currentUser);

        secondAdjustment.flag.Should().BeFalse();
        secondAdjustment.msg.Should().Be("status_changed");
        await using var afterRepeatContext = _fixture.CreateDbContext();
        (await afterRepeatContext.GetDbSet<StockadjustEntity>().CountAsync(t => t.job_type == 2)).Should().Be(2);
        (await afterRepeatContext.GetDbSet<StockEntity>()
            .SingleAsync(t => t.sku_id == sourceMaster.SkuId && t.goods_location_id == sourceMaster.NormalLocationId && t.goods_owner_id == sourceMaster.GoodsOwnerId))
            .qty.Should().Be(2);
    }

    private static StockprocessService CreateService(SqlDBContext dbContext)
    {
        return new StockprocessService(
            dbContext,
            new TestStringLocalizer<MultiLanguage>(),
            new FunctionHelper(dbContext, new HttpContextAccessor()));
    }

    private static StockprocessViewModel CreateProcessViewModel(
        AsnTestMasterData sourceMaster,
        AsnTestMasterData targetMaster,
        int qty,
        string sourceSeries,
        DateTime expiryDate,
        DateTime putawayDate)
    {
        return new StockprocessViewModel
        {
            job_type = false,
            process_status = false,
            process_time = UtilConvert.MinDate,
            create_time = UtilConvert.MinDate,
            last_update_time = UtilConvert.MinDate,
            detailList = new List<StockprocessdetailViewModel>
            {
                new()
                {
                    sku_id = sourceMaster.SkuId,
                    goods_owner_id = sourceMaster.GoodsOwnerId,
                    goods_location_id = sourceMaster.NormalLocationId,
                    qty = qty,
                    is_source = true,
                    series_number = sourceSeries,
                    expiry_date = expiryDate,
                    price = 12.5M,
                    putaway_date = putawayDate
                },
                new()
                {
                    sku_id = targetMaster.SkuId,
                    goods_owner_id = sourceMaster.GoodsOwnerId,
                    goods_location_id = targetMaster.NormalLocationId,
                    qty = qty,
                    is_source = false,
                    series_number = "SN-PROC-TARGET-02",
                    expiry_date = new DateTime(2027, 12, 31),
                    price = 22.5M,
                    putaway_date = DateTime.Today,
                    location_name = $"LOC-{Guid.NewGuid():N}"[..12]
                }
            }
        };
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
