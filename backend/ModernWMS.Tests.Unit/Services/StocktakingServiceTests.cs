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

public sealed class StocktakingServiceTests : IClassFixture<AsnServiceTestFixture>
{
    private readonly AsnServiceTestFixture _fixture;

    public StocktakingServiceTests(AsnServiceTestFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task PutAsyncStoresCountedQuantityAndDifference()
    {
        var prefix = $"taking-put-{Guid.NewGuid():N}"[..20];
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);
        const string seriesNumber = "SN-TAKING-PUT-01";

        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: false);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var currentUser = TestCurrentUser.Admin();
        var addResult = await service.AddAsync(CreateBasicViewModel(master, 8, seriesNumber, expiryDate, 9.9M, putawayDate), currentUser);

        addResult.id.Should().BeGreaterThan(0);
        var putResult = await service.PutAsync(new StocktakingConfirmViewModel { id = addResult.id, counted_qty = 5 }, currentUser);

        putResult.flag.Should().BeTrue();
        await using var verificationContext = _fixture.CreateDbContext();
        var entity = await verificationContext.GetDbSet<StocktakingEntity>().SingleAsync(t => t.id == addResult.id);

        entity.job_status.Should().BeTrue();
        entity.counted_qty.Should().Be(5);
        entity.difference_qty.Should().Be(-3);
        entity.handler.Should().Be("admin");
    }

    [Fact]
    public async Task ConfirmAsyncAppliesDifferenceOnceAndRejectsDuplicateAdjustment()
    {
        var prefix = $"taking-confirm-{Guid.NewGuid():N}"[..20];
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);
        const string seriesNumber = "SN-TAKING-CONFIRM-01";

        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: false);
        await InsertStockAsync(connection, master.SkuId, master.NormalLocationId, master.GoodsOwnerId, seriesNumber, 8, expiryDate, 9.9M, putawayDate);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var currentUser = TestCurrentUser.Admin();
        var addResult = await service.AddAsync(CreateBasicViewModel(master, 8, seriesNumber, expiryDate, 9.9M, putawayDate), currentUser);

        addResult.id.Should().BeGreaterThan(0);
        (await service.PutAsync(new StocktakingConfirmViewModel { id = addResult.id, counted_qty = 5 }, currentUser)).flag.Should().BeTrue();

        var firstConfirm = await service.ConfirmAsync(addResult.id, currentUser);

        firstConfirm.flag.Should().BeTrue();
        await using var verificationContext = _fixture.CreateDbContext();
        var stock = await verificationContext.GetDbSet<StockEntity>()
            .SingleAsync(t => t.sku_id == master.SkuId
                           && t.goods_location_id == master.NormalLocationId
                           && t.goods_owner_id == master.GoodsOwnerId
                           && t.series_number == seriesNumber);
        var adjusts = await verificationContext.GetDbSet<StockadjustEntity>()
            .Where(t => t.job_type == 1 && t.source_table_id == addResult.id)
            .ToListAsync();

        stock.qty.Should().Be(5);
        adjusts.Should().ContainSingle();
        adjusts.Single().qty.Should().Be(-3);

        await using var repeatContext = _fixture.CreateDbContext();
        var repeatService = CreateService(repeatContext);
        var secondConfirm = await repeatService.ConfirmAsync(addResult.id, currentUser);

        secondConfirm.flag.Should().BeFalse();
        secondConfirm.msg.Should().Be("status_changed");
        await using var afterRepeatContext = _fixture.CreateDbContext();
        (await afterRepeatContext.GetDbSet<StockEntity>()
            .SingleAsync(t => t.sku_id == master.SkuId
                           && t.goods_location_id == master.NormalLocationId
                           && t.goods_owner_id == master.GoodsOwnerId
                           && t.series_number == seriesNumber))
            .qty.Should().Be(5);
        (await afterRepeatContext.GetDbSet<StockadjustEntity>()
            .CountAsync(t => t.job_type == 1 && t.source_table_id == addResult.id))
            .Should().Be(1);
    }

    private static StocktakingService CreateService(SqlDBContext dbContext)
    {
        return new StocktakingService(
            dbContext,
            new TestStringLocalizer<MultiLanguage>(),
            new FunctionHelper(dbContext, new HttpContextAccessor()));
    }

    private static StocktakingBasicViewModel CreateBasicViewModel(
        AsnTestMasterData master,
        int bookQty,
        string seriesNumber,
        DateTime expiryDate,
        decimal price,
        DateTime putawayDate)
    {
        return new StocktakingBasicViewModel
        {
            sku_id = master.SkuId,
            goods_owner_id = master.GoodsOwnerId,
            goods_location_id = master.NormalLocationId,
            book_qty = bookQty,
            series_number = seriesNumber,
            expiry_date = expiryDate,
            price = price,
            putaway_date = putawayDate
        };
    }

    private static async Task InsertStockAsync(
        MySqlConnection connection,
        int skuId,
        int locationId,
        int goodsOwnerId,
        string seriesNumber,
        int qty,
        DateTime expiryDate,
        decimal price,
        DateTime putawayDate)
    {
        await ExecuteAsync(
            connection,
            "insert into stock (sku_id, goods_location_id, qty, goods_owner_id, is_freeze, last_update_time, tenant_id, series_number, expiry_date, price, putaway_date) values (@skuId, @locationId, @qty, @ownerId, 0, now(), 1, @seriesNumber, @expiryDate, @price, @putawayDate);",
            ("@skuId", skuId),
            ("@locationId", locationId),
            ("@qty", qty),
            ("@ownerId", goodsOwnerId),
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
