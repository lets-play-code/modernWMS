using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using ModernWMS.Core;
using ModernWMS.Core.DBContext;
using ModernWMS.Core.JWT;
using ModernWMS.Core.Utility;
using ModernWMS.Tests.Unit.Support;
using ModernWMS.WMS.Entities.Models;
using ModernWMS.WMS.Entities.ViewModels;
using ModernWMS.WMS.Services;
using Xunit;

namespace ModernWMS.Tests.Unit.Services;

public sealed class StockmoveServiceTests : IClassFixture<AsnServiceTestFixture>
{
    private readonly AsnServiceTestFixture _fixture;

    public StockmoveServiceTests(AsnServiceTestFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task ConfirmMovesQuantityIntoExistingDestinationLayer()
    {
        var prefix = $"move-merge-{Guid.NewGuid():N}"[..20];
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);
        const string seriesNumber = "SN-MOVE-MERGE-01";

        await using var connection = await _fixture.OpenConnectionAsync();
        var sourceMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}a", includeDamageLocation: false);
        var destinationMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}b", includeDamageLocation: false);
        await AsnUnitSeedData.InsertStockAsync(connection, sourceMaster.SkuId, sourceMaster.NormalLocationId, sourceMaster.GoodsOwnerId, seriesNumber, 7, expiryDate, 10.5M, putawayDate);
        await AsnUnitSeedData.InsertStockAsync(connection, sourceMaster.SkuId, destinationMaster.NormalLocationId, sourceMaster.GoodsOwnerId, seriesNumber, 3, expiryDate, 10.5M, putawayDate);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var currentUser = TestCurrentUser.Admin();
        var addResult = await service.AddAsync(
            CreateMoveViewModel(sourceMaster, destinationMaster.NormalLocationId, 4, seriesNumber, expiryDate, 10.5M, putawayDate),
            currentUser);

        addResult.id.Should().BeGreaterThan(0);

        var confirmResult = await service.Confirm(addResult.id, currentUser);

        confirmResult.flag.Should().BeTrue();
        await using var verificationContext = _fixture.CreateDbContext();
        var move = await verificationContext.GetDbSet<StockmoveEntity>().SingleAsync(t => t.id == addResult.id);
        var stocks = await verificationContext.GetDbSet<StockEntity>()
            .Where(t => t.sku_id == sourceMaster.SkuId
                        && t.goods_owner_id == sourceMaster.GoodsOwnerId
                        && t.series_number == seriesNumber)
            .OrderBy(t => t.goods_location_id)
            .ToListAsync();

        move.move_status.Should().Be(1);
        stocks.Should().HaveCount(2);
        stocks.Should().ContainSingle(t => t.goods_location_id == sourceMaster.NormalLocationId && t.qty == 3);
        stocks.Should().ContainSingle(t => t.goods_location_id == destinationMaster.NormalLocationId && t.qty == 7);
    }

    [Fact]
    public async Task ConfirmRejectsAlreadyConfirmedMove()
    {
        var prefix = $"move-repeat-{Guid.NewGuid():N}"[..20];
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 2);
        const string seriesNumber = "SN-MOVE-REPEAT-01";

        await using var connection = await _fixture.OpenConnectionAsync();
        var sourceMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}a", includeDamageLocation: false);
        var destinationMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}b", includeDamageLocation: false);
        await AsnUnitSeedData.InsertStockAsync(connection, sourceMaster.SkuId, sourceMaster.NormalLocationId, sourceMaster.GoodsOwnerId, seriesNumber, 5, expiryDate, 9.9M, putawayDate);

        await using var dbContext = _fixture.CreateDbContext();
        var service = CreateService(dbContext);
        var currentUser = TestCurrentUser.Admin();
        var addResult = await service.AddAsync(
            CreateMoveViewModel(sourceMaster, destinationMaster.NormalLocationId, 2, seriesNumber, expiryDate, 9.9M, putawayDate),
            currentUser);

        addResult.id.Should().BeGreaterThan(0);
        (await service.Confirm(addResult.id, currentUser)).flag.Should().BeTrue();

        var secondConfirm = await service.Confirm(addResult.id, currentUser);

        secondConfirm.flag.Should().BeFalse();
        secondConfirm.msg.Should().Be("status_changed");
        await using var verificationContext = _fixture.CreateDbContext();
        var stocks = await verificationContext.GetDbSet<StockEntity>()
            .Where(t => t.sku_id == sourceMaster.SkuId
                        && t.goods_owner_id == sourceMaster.GoodsOwnerId
                        && t.series_number == seriesNumber)
            .OrderBy(t => t.goods_location_id)
            .ToListAsync();

        stocks.Should().HaveCount(2);
        stocks.Should().ContainSingle(t => t.goods_location_id == sourceMaster.NormalLocationId && t.qty == 3);
        stocks.Should().ContainSingle(t => t.goods_location_id == destinationMaster.NormalLocationId && t.qty == 2);
    }

    private static StockmoveService CreateService(SqlDBContext dbContext)
    {
        return new StockmoveService(
            dbContext,
            new TestStringLocalizer<MultiLanguage>(),
            new FunctionHelper(dbContext, new HttpContextAccessor()));
    }

    private static StockmoveViewModel CreateMoveViewModel(
        AsnTestMasterData sourceMaster,
        int destinationLocationId,
        int qty,
        string seriesNumber,
        DateTime expiryDate,
        decimal price,
        DateTime putawayDate)
    {
        return new StockmoveViewModel
        {
            sku_id = sourceMaster.SkuId,
            orig_goods_location_id = sourceMaster.NormalLocationId,
            dest_googs_location_id = destinationLocationId,
            qty = qty,
            goods_owner_id = sourceMaster.GoodsOwnerId,
            series_number = seriesNumber,
            expiry_date = expiryDate,
            price = price,
            putaway_date = putawayDate,
            handle_time = UtilConvert.MinDate,
            create_time = UtilConvert.MinDate,
            last_update_time = UtilConvert.MinDate
        };
    }
}
