using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using ModernWMS.Core;
using ModernWMS.Core.DBContext;
using ModernWMS.Core.DynamicSearch;
using ModernWMS.Core.JWT;
using ModernWMS.Core.Models;
using ModernWMS.Core.Utility;
using ModernWMS.Tests.Unit.Support;
using ModernWMS.WMS.Entities.Models;
using ModernWMS.WMS.Entities.ViewModels;
using ModernWMS.WMS.Services;
using Xunit;

namespace ModernWMS.Tests.Unit.Services;

public sealed class DispatchlistServiceTests : IClassFixture<AsnServiceTestFixture>
{
    private readonly AsnServiceTestFixture _fixture;

    public DispatchlistServiceTests(AsnServiceTestFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task AddUpdateDeleteAndQueryDraftDispatchAsync()
    {
        var currentUser = TestCurrentUser.Admin();
        var seed = await CreateDraftDispatchAsync($"disp-draft-{Guid.NewGuid():N}"[..20], stockQty: 0, dispatchQty: 6);

        await using var queryContext = _fixture.CreateDbContext();
        var service = CreateDispatchService(queryContext);

        var (rows, totals) = await service.PageAsync(CreatePageSearch("customer_name", seed.CustomerName), currentUser);
        totals.Should().Be(1);
        rows.Should().ContainSingle(t => t.dispatch_no == seed.DispatchNo && t.qty == 6);

        var (groups, groupTotals) = await service.AdvancedDispatchlistPageAsync(
            CreatePageSearch("customer_name", seed.CustomerName, "dispatch_status=0"),
            currentUser);
        groupTotals.Should().Be(1);
        groups.Should().ContainSingle(t => t.dispatch_no == seed.DispatchNo && t.qty == 6);

        var byDispatchNo = await service.GetByDispatchlistNo(seed.DispatchNo, currentUser);
        byDispatchNo.Should().ContainSingle(t => t.id == seed.DispatchId && t.qty == 6);

        var updateResult = await service.UpdateAsycn(
            new List<DispatchlistViewModel>
            {
                new()
                {
                    id = seed.DispatchId,
                    dispatch_no = seed.DispatchNo,
                    dispatch_status = 0,
                    customer_id = 1,
                    customer_name = seed.CustomerName,
                    sku_id = seed.Master.SkuId,
                    qty = 5
                }
            },
            currentUser);

        updateResult.flag.Should().BeTrue();
        (await service.GetByDispatchlistNo(seed.DispatchNo, currentUser)).Should().ContainSingle(t => t.qty == 5);

        await using var deleteContext = _fixture.CreateDbContext();
        var deleteService = CreateDispatchService(deleteContext);
        var deleteResult = await deleteService.DeleteAsync(seed.DispatchNo, currentUser);
        deleteResult.flag.Should().BeTrue();
        (await deleteService.GetByDispatchlistNo(seed.DispatchNo, currentUser)).Should().BeEmpty();
    }

    [Fact]
    public async Task ConfirmOrderLocksInventoryWithoutDeductingStockAsync()
    {
        var currentUser = TestCurrentUser.Admin();
        var seed = await CreateDraftDispatchAsync($"disp-lock-{Guid.NewGuid():N}"[..20], stockQty: 12, dispatchQty: 8);

        await using var context = _fixture.CreateDbContext();
        var service = CreateDispatchService(context);

        var details = await service.ConfirmOrderCheck(seed.DispatchNo, currentUser);
        details.Should().ContainSingle();
        details[0].confirm.Should().BeTrue();
        details[0].qty_available.Should().Be(12);
        details[0].pick_list.Should().ContainSingle(t => t.pick_qty == 8 && t.series_number == seed.SeriesNumber);

        var confirmResult = await service.ConfirmOrder(details, currentUser);
        confirmResult.flag.Should().BeTrue();

        await using var verifyContext = _fixture.CreateDbContext();
        var dispatch = await verifyContext.GetDbSet<DispatchlistEntity>().SingleAsync(t => t.id == seed.DispatchId);
        var stock = await verifyContext.GetDbSet<StockEntity>().SingleAsync(t => t.sku_id == seed.Master.SkuId);
        var pick = await verifyContext.GetDbSet<DispatchpicklistEntity>().SingleAsync(t => t.dispatchlist_id == seed.DispatchId);

        dispatch.dispatch_status.Should().Be(2);
        dispatch.lock_qty.Should().Be(8);
        dispatch.qty.Should().Be(8);
        stock.qty.Should().Be(12);
        pick.pick_qty.Should().Be(8);
        pick.picked_qty.Should().Be(0);
        pick.is_update_stock.Should().BeFalse();

        var pickList = await service.GetPickListByDispatchID(seed.DispatchId);
        pickList.Should().ContainSingle(t => t.pick_qty == 8 && t.picked_qty == 0 && t.series_number == seed.SeriesNumber);
    }

    [Fact]
    public async Task GetPickingSheetAggregatesSameStockLayerAcrossDispatchesAsync()
    {
        var prefix = $"disp-sheet-{Guid.NewGuid():N}"[..20];
        const string seriesNumber = "SN-SHEET-01";
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);
        const decimal price = 11.5M;

        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: false);

        await using var seedContext = _fixture.CreateDbContext();
        var firstDispatch = CreateDispatchEntity($"DP-SHEET-{Guid.NewGuid():N}"[..18], master.SkuId, qty: 3, status: 2, lockQty: 3);
        var secondDispatch = CreateDispatchEntity($"DP-SHEET-{Guid.NewGuid():N}"[..18], master.SkuId, qty: 5, status: 2, lockQty: 5);
        seedContext.GetDbSet<DispatchlistEntity>().AddRange(firstDispatch, secondDispatch);
        await seedContext.SaveChangesAsync();

        var firstPick = CreateDispatchPickEntity(firstDispatch.id, master.GoodsOwnerId, master.NormalLocationId, master.SkuId, 3, 0, seriesNumber, expiryDate, price, putawayDate);
        var secondPick = CreateDispatchPickEntity(secondDispatch.id, master.GoodsOwnerId, master.NormalLocationId, master.SkuId, 5, 0, seriesNumber, expiryDate, price, putawayDate);
        seedContext.GetDbSet<DispatchpicklistEntity>().AddRange(firstPick, secondPick);
        await seedContext.SaveChangesAsync();

        await using var context = _fixture.CreateDbContext();
        var service = CreateDispatchService(context);
        var sheet = await service.GetPickingSheet(
            new DispatchlistPickingSheetQueryViewModel { dispatchlist_ids = new List<int> { firstDispatch.id, secondDispatch.id } },
            TestCurrentUser.Admin());

        sheet.dispatch_nos.Should().BeEquivalentTo(new[] { firstDispatch.dispatch_no, secondDispatch.dispatch_no });
        sheet.lines.Should().ContainSingle();
        sheet.lines[0].group_key.Should().NotBeNullOrWhiteSpace();
        sheet.lines[0].pick_qty.Should().Be(8);
        sheet.lines[0].picked_qty.Should().Be(0);
        sheet.lines[0].pick_detail_ids.Should().BeEquivalentTo(new[] { firstPick.id, secondPick.id });
        sheet.lines[0].related_dispatches.Should().BeEquivalentTo(
            new[]
            {
                new { dispatch_no = firstDispatch.dispatch_no, dispatchlist_id = firstDispatch.id, pick_qty = 3, picked_qty = 0 },
                new { dispatch_no = secondDispatch.dispatch_no, dispatchlist_id = secondDispatch.id, pick_qty = 5, picked_qty = 0 }
            },
            options => options.WithoutStrictOrdering());
    }

    [Fact]
    public async Task GetPickingSheetSplitsDifferentLocationsIntoSeparateLinesAsync()
    {
        var prefix = $"disp-sheet-{Guid.NewGuid():N}"[..20];
        const string seriesNumber = "SN-SHEET-02";
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);
        const decimal price = 11.5M;

        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: false);

        await using var seedContext = _fixture.CreateDbContext();
        var primaryLocation = await seedContext.GetDbSet<GoodslocationEntity>().SingleAsync(t => t.id == master.NormalLocationId);
        var secondaryLocation = CreateSiblingLocation(primaryLocation, $"{primaryLocation.location_name}-ALT");
        seedContext.GetDbSet<GoodslocationEntity>().Add(secondaryLocation);

        var firstDispatch = CreateDispatchEntity($"DP-SHEET-{Guid.NewGuid():N}"[..18], master.SkuId, qty: 3, status: 2, lockQty: 3);
        var secondDispatch = CreateDispatchEntity($"DP-SHEET-{Guid.NewGuid():N}"[..18], master.SkuId, qty: 4, status: 2, lockQty: 4);
        seedContext.GetDbSet<DispatchlistEntity>().AddRange(firstDispatch, secondDispatch);
        await seedContext.SaveChangesAsync();

        var firstPick = CreateDispatchPickEntity(firstDispatch.id, master.GoodsOwnerId, primaryLocation.id, master.SkuId, 3, 0, seriesNumber, expiryDate, price, putawayDate);
        var secondPick = CreateDispatchPickEntity(secondDispatch.id, master.GoodsOwnerId, secondaryLocation.id, master.SkuId, 4, 0, seriesNumber, expiryDate, price, putawayDate);
        seedContext.GetDbSet<DispatchpicklistEntity>().AddRange(firstPick, secondPick);
        await seedContext.SaveChangesAsync();

        await using var context = _fixture.CreateDbContext();
        var service = CreateDispatchService(context);
        var sheet = await service.GetPickingSheet(
            new DispatchlistPickingSheetQueryViewModel { dispatchlist_ids = new List<int> { firstDispatch.id, secondDispatch.id } },
            TestCurrentUser.Admin());

        sheet.lines.Should().HaveCount(2);

        var primaryLine = sheet.lines.Single(t => t.location_name == primaryLocation.location_name);
        primaryLine.pick_qty.Should().Be(3);
        primaryLine.pick_detail_ids.Should().BeEquivalentTo(new[] { firstPick.id });
        primaryLine.related_dispatches.Should().ContainSingle(t => t.dispatch_no == firstDispatch.dispatch_no && t.dispatchlist_id == firstDispatch.id && t.pick_qty == 3);

        var secondaryLine = sheet.lines.Single(t => t.location_name == secondaryLocation.location_name);
        secondaryLine.pick_qty.Should().Be(4);
        secondaryLine.pick_detail_ids.Should().BeEquivalentTo(new[] { secondPick.id });
        secondaryLine.related_dispatches.Should().ContainSingle(t => t.dispatch_no == secondDispatch.dispatch_no && t.dispatchlist_id == secondDispatch.id && t.pick_qty == 4);
    }

    [Fact]
    public async Task ConfirmPickItemsMarksSelectedDetailsWithPickerAndKeepsDispatchWaitingAsync()
    {
        var currentUser = CreateCurrentUser(7, "picker01");
        var seed = await CreateConfirmedDispatchAsync($"disp-pick-{Guid.NewGuid():N}"[..20], stockQty: 8, dispatchQty: 5);

        await using var context = _fixture.CreateDbContext();
        var service = CreateDispatchService(context);
        var pickId = await context.GetDbSet<DispatchpicklistEntity>()
            .Where(t => t.dispatchlist_id == seed.DispatchId)
            .Select(t => t.id)
            .SingleAsync();

        (await service.ConfirmPickItems(new DispatchlistPickItemsOperationViewModel { pick_detail_ids = new List<int> { pickId } }, currentUser)).flag.Should().BeTrue();

        await using var verifyContext = _fixture.CreateDbContext();
        var dispatch = await verifyContext.GetDbSet<DispatchlistEntity>().SingleAsync(t => t.id == seed.DispatchId);
        var pick = await verifyContext.GetDbSet<DispatchpicklistEntity>().SingleAsync(t => t.id == pickId);
        dispatch.dispatch_status.Should().Be(2);
        dispatch.picked_qty.Should().Be(0);
        pick.picked_qty.Should().Be(pick.pick_qty);
        pick.picker_id.Should().Be(currentUser.user_id);
        pick.picker.Should().Be(currentUser.user_name);

        var pickList = await CreateDispatchService(verifyContext).GetPickListByDispatchID(seed.DispatchId);
        pickList.Should().ContainSingle(t => t.id == pickId && t.picker_id == currentUser.user_id && t.picker == currentUser.user_name);
    }

    [Fact]
    public async Task RevokePickItemsClearsPickerAndKeepsDispatchWaitingAsync()
    {
        var currentUser = CreateCurrentUser(7, "picker01");
        var seed = await CreateConfirmedDispatchAsync($"disp-pick-{Guid.NewGuid():N}"[..20], stockQty: 8, dispatchQty: 5);
        int pickId;

        await using (var confirmContext = _fixture.CreateDbContext())
        {
            var confirmService = CreateDispatchService(confirmContext);
            pickId = await confirmContext.GetDbSet<DispatchpicklistEntity>()
                .Where(t => t.dispatchlist_id == seed.DispatchId)
                .Select(t => t.id)
                .SingleAsync();
            (await confirmService.ConfirmPickItems(new DispatchlistPickItemsOperationViewModel { pick_detail_ids = new List<int> { pickId } }, currentUser)).flag.Should().BeTrue();
        }

        await using (var revokeContext = _fixture.CreateDbContext())
        {
            var revokeService = CreateDispatchService(revokeContext);
            (await revokeService.RevokePickItems(new DispatchlistPickItemsOperationViewModel { pick_detail_ids = new List<int> { pickId } }, currentUser)).flag.Should().BeTrue();
        }

        await using var verifyContext = _fixture.CreateDbContext();
        var dispatch = await verifyContext.GetDbSet<DispatchlistEntity>().SingleAsync(t => t.id == seed.DispatchId);
        var pick = await verifyContext.GetDbSet<DispatchpicklistEntity>().SingleAsync(t => t.id == pickId);
        dispatch.dispatch_status.Should().Be(2);
        dispatch.picked_qty.Should().Be(0);
        pick.picked_qty.Should().Be(0);
        pick.picker_id.Should().Be(0);
        pick.picker.Should().BeEmpty();
    }

    [Fact]
    public async Task ConfirmPickByDispatchNoRecordsCheckerAndOnlyAutofillsUnconfirmedRowsAsync()
    {
        var prefix = $"disp-check-{Guid.NewGuid():N}"[..20];
        var picker = CreateCurrentUser(7, "picker01");
        var checker = CreateCurrentUser(9, "checker01");
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);
        const decimal price = 11.5M;

        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: false);

        await using var seedContext = _fixture.CreateDbContext();
        var dispatch = CreateDispatchEntity($"DP-CHECK-{Guid.NewGuid():N}"[..18], master.SkuId, qty: 8, status: 2, lockQty: 8);
        seedContext.GetDbSet<DispatchlistEntity>().Add(dispatch);
        await seedContext.SaveChangesAsync();

        var confirmedPick = CreateDispatchPickEntity(dispatch.id, master.GoodsOwnerId, master.NormalLocationId, master.SkuId, 3, 3, "SN-CHECK-01", expiryDate, price, putawayDate);
        confirmedPick.picker_id = picker.user_id;
        confirmedPick.picker = picker.user_name;
        var pendingPick = CreateDispatchPickEntity(dispatch.id, master.GoodsOwnerId, master.NormalLocationId, master.SkuId, 5, 0, "SN-CHECK-02", expiryDate, price, putawayDate);
        seedContext.GetDbSet<DispatchpicklistEntity>().AddRange(confirmedPick, pendingPick);
        await seedContext.SaveChangesAsync();

        await using var context = _fixture.CreateDbContext();
        var service = CreateDispatchService(context);
        (await service.ConfirmPickByDispatchNo(dispatch.dispatch_no, checker)).flag.Should().BeTrue();

        await using var verifyContext = _fixture.CreateDbContext();
        var dispatchAfter = await verifyContext.GetDbSet<DispatchlistEntity>().SingleAsync(t => t.id == dispatch.id);
        var picksAfter = await verifyContext.GetDbSet<DispatchpicklistEntity>()
            .Where(t => t.dispatchlist_id == dispatch.id)
            .OrderBy(t => t.id)
            .ToListAsync();

        dispatchAfter.dispatch_status.Should().Be(3);
        dispatchAfter.picked_qty.Should().Be(8);
        dispatchAfter.pick_checker_id.Should().Be(checker.user_id);
        dispatchAfter.pick_checker.Should().Be(checker.user_name);
        picksAfter.Should().ContainSingle(t => t.pick_qty == 3 && t.picked_qty == 3 && t.picker_id == picker.user_id && t.picker == picker.user_name);
        picksAfter.Should().ContainSingle(t => t.pick_qty == 5 && t.picked_qty == 5 && t.picker_id == checker.user_id && t.picker == checker.user_name);
    }

    [Fact]
    public async Task ConfirmPickByDispatchNoStillSupportsDirectReviewFallbackAsync()
    {
        var checker = CreateCurrentUser(9, "checker01");
        var seed = await CreateConfirmedDispatchAsync($"disp-check-{Guid.NewGuid():N}"[..20], stockQty: 8, dispatchQty: 5);

        await using var context = _fixture.CreateDbContext();
        var service = CreateDispatchService(context);
        (await service.ConfirmPickByDispatchNo(seed.DispatchNo, checker)).flag.Should().BeTrue();

        await using var verifyContext = _fixture.CreateDbContext();
        var dispatch = await verifyContext.GetDbSet<DispatchlistEntity>().SingleAsync(t => t.id == seed.DispatchId);
        var pick = await verifyContext.GetDbSet<DispatchpicklistEntity>().SingleAsync(t => t.dispatchlist_id == seed.DispatchId);

        dispatch.dispatch_status.Should().Be(3);
        dispatch.picked_qty.Should().Be(5);
        dispatch.pick_checker_id.Should().Be(checker.user_id);
        dispatch.pick_checker.Should().Be(checker.user_name);
        pick.picked_qty.Should().Be(pick.pick_qty);
        pick.picker_id.Should().Be(checker.user_id);
        pick.picker.Should().Be(checker.user_name);
    }

    [Fact]
    public async Task PackageWeightDeliveryAndFreightFlowUpdatesDispatchAndStockAsync()
    {
        var currentUser = TestCurrentUser.Admin();
        var seed = await CreateConfirmedDispatchAsync($"disp-flow-{Guid.NewGuid():N}"[..20], stockQty: 8, dispatchQty: 5);

        await using (var pickContext = _fixture.CreateDbContext())
        {
            var pickService = CreateDispatchService(pickContext);
            (await pickService.ConfirmPickByDispatchNo(seed.DispatchNo, currentUser)).flag.Should().BeTrue();
        }

        await using (var packageContext = _fixture.CreateDbContext())
        {
            var packageService = CreateDispatchService(packageContext);
            (await packageService.Package(new List<DispatchlistPackageViewModel>
            {
                new() { id = seed.DispatchId, dispatch_no = seed.DispatchNo, dispatch_status = 3, package_qty = 5, picked_qty = 5 }
            }, currentUser)).flag.Should().BeTrue();
        }

        await using (var weightContext = _fixture.CreateDbContext())
        {
            var weightService = CreateDispatchService(weightContext);
            (await weightService.Weight(new List<DispatchlistWeightViewModel>
            {
                new() { id = seed.DispatchId, dispatch_no = seed.DispatchNo, dispatch_status = 4, weighing_qty = 5, weighing_weight = 12.5M, picked_qty = 5 }
            }, currentUser)).flag.Should().BeTrue();
        }

        int freightId;
        await using (var freightContext = _fixture.CreateDbContext())
        {
            var freightService = CreateFreightfeeService(freightContext);
            var dispatchService = CreateDispatchService(freightContext);
            var freight = await freightService.AddAsync(new FreightfeeViewModel
            {
                carrier = $"承运-{seed.CustomerName}",
                departure_city = "上海",
                arrival_city = "杭州",
                price_per_weight = 2.5M,
                price_per_volume = 1.2M,
                min_payment = 10M,
                is_valid = true
            }, currentUser);
            freight.id.Should().BeGreaterThan(0);
            freightId = freight.id;

            (await dispatchService.SetFreightfee(new List<DispatchlistFreightfeeViewModel>
            {
                new() { id = seed.DispatchId, dispatch_no = seed.DispatchNo, dispatch_status = 5, freightfee_id = freightId, carrier = string.Empty, waybill_no = $"WB-{seed.DispatchId}" }
            })).flag.Should().BeTrue();
        }

        await using (var deliveryContext = _fixture.CreateDbContext())
        {
            var deliveryService = CreateDispatchService(deliveryContext);
            (await deliveryService.Delivery(new List<DispatchlistDeliveryViewModel>
            {
                new() { id = seed.DispatchId, dispatch_no = seed.DispatchNo, dispatch_status = 5, picked_qty = 5 }
            }, currentUser)).flag.Should().BeTrue();
        }

        await using var verifyContext = _fixture.CreateDbContext();
        var dispatch = await verifyContext.GetDbSet<DispatchlistEntity>().SingleAsync(t => t.id == seed.DispatchId);
        var stock = await verifyContext.GetDbSet<StockEntity>().SingleAsync(t => t.sku_id == seed.Master.SkuId);
        var pick = await verifyContext.GetDbSet<DispatchpicklistEntity>().SingleAsync(t => t.dispatchlist_id == seed.DispatchId);

        dispatch.dispatch_status.Should().Be(6);
        dispatch.actual_qty.Should().Be(5);
        dispatch.intrasit_qty.Should().Be(5);
        dispatch.lock_qty.Should().Be(0);
        dispatch.carrier.Should().Be($"承运-{seed.CustomerName}");
        dispatch.waybill_no.Should().Be($"WB-{seed.DispatchId}");
        dispatch.freightfee.Should().Be(31.25M);
        stock.qty.Should().Be(3);
        pick.is_update_stock.Should().BeTrue();

        await using var detailContext = _fixture.CreateDbContext();
        var details = await CreateDispatchService(detailContext).GetAllAsync(seed.DispatchNo, currentUser);
        details.Should().ContainSingle(t => t.package_qty == 5 && t.weighing_qty == 5 && t.actual_qty == 5 && t.freightfee == 31.25M);
    }

    [Fact]
    public async Task SignForArrivalUsesMatchingViewModelPerDispatchIdAsync()
    {
        var prefix = $"disp-sign-{Guid.NewGuid():N}"[..20];
        await using var connection = await _fixture.OpenConnectionAsync();
        var firstMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}a", includeDamageLocation: false);
        var secondMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}b", includeDamageLocation: false);

        await using var seedContext = _fixture.CreateDbContext();
        var first = CreateDispatchEntity($"DP-SIGN-{Guid.NewGuid():N}"[..18], skuId: firstMaster.SkuId, qty: 4, status: 6, actualQty: 4);
        var second = CreateDispatchEntity($"DP-SIGN-{Guid.NewGuid():N}"[..18], skuId: secondMaster.SkuId, qty: 3, status: 6, actualQty: 3);
        seedContext.GetDbSet<DispatchlistEntity>().AddRange(first, second);
        await seedContext.SaveChangesAsync();

        await using var context = _fixture.CreateDbContext();
        var service = CreateDispatchService(context);
        var result = await service.SignForArrival(new List<DispatchlistSignViewModel>
        {
            new() { id = first.id, dispatch_no = first.dispatch_no, dispatch_status = 6, damage_qty = 1 },
            new() { id = second.id, dispatch_no = second.dispatch_no, dispatch_status = 6, damage_qty = 0 }
        });

        result.flag.Should().BeTrue();
        await using var verifyContext = _fixture.CreateDbContext();
        var signed = await verifyContext.GetDbSet<DispatchlistEntity>()
            .Where(t => t.id == first.id || t.id == second.id)
            .OrderBy(t => t.id)
            .ToListAsync();

        signed.Should().ContainSingle(t => t.id == first.id && t.damage_qty == 1 && t.sign_qty == 3 && t.dispatch_status == 7);
        signed.Should().ContainSingle(t => t.id == second.id && t.damage_qty == 0 && t.sign_qty == 3 && t.dispatch_status == 7);
    }

    [Fact]
    public async Task CancelOrderOperationCanRevertPickedDispatchBackToDraftAsync()
    {
        var prefix = $"disp-cancel-{Guid.NewGuid():N}"[..20];
        const string seriesNumber = "SN-CANCEL-01";
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);

        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: false);

        await using var seedContext = _fixture.CreateDbContext();
        var dispatch = CreateDispatchEntity($"DP-CAN-{Guid.NewGuid():N}"[..18], master.SkuId, qty: 5, status: 3, lockQty: 5, pickedQty: 5);
        seedContext.GetDbSet<DispatchlistEntity>().Add(dispatch);
        await seedContext.SaveChangesAsync();
        seedContext.GetDbSet<DispatchpicklistEntity>().Add(new DispatchpicklistEntity
        {
            dispatchlist_id = dispatch.id,
            goods_owner_id = master.GoodsOwnerId,
            goods_location_id = master.NormalLocationId,
            sku_id = master.SkuId,
            pick_qty = 5,
            picked_qty = 5,
            is_update_stock = false,
            last_update_time = DateTime.Now,
            series_number = seriesNumber,
            expiry_date = expiryDate,
            price = 11.5M,
            putaway_date = putawayDate
        });
        await seedContext.SaveChangesAsync();

        await using var context = _fixture.CreateDbContext();
        var service = CreateDispatchService(context);
        (await service.CancelOrderOpration(new CancelOrderOprationViewModel { dispatch_no = dispatch.dispatch_no, dispatch_status = 3 }, TestCurrentUser.Admin())).flag.Should().BeTrue();
        (await service.CancelOrderOpration(new CancelOrderOprationViewModel { dispatch_no = dispatch.dispatch_no, dispatch_status = 2 }, TestCurrentUser.Admin())).flag.Should().BeTrue();

        await using var verifyContext = _fixture.CreateDbContext();
        var entity = await verifyContext.GetDbSet<DispatchlistEntity>().SingleAsync(t => t.id == dispatch.id);
        entity.dispatch_status.Should().Be(1);
        entity.lock_qty.Should().Be(0);
        entity.picked_qty.Should().Be(0);
        (await verifyContext.GetDbSet<DispatchpicklistEntity>().CountAsync(t => t.dispatchlist_id == dispatch.id)).Should().Be(0);
    }

    [Fact]
    public async Task CancelDispatchlistDetailOperationRollsBackPackageAndWeightStagesAsync()
    {
        var prefix = $"disp-detail-{Guid.NewGuid():N}"[..20];
        await using var connection = await _fixture.OpenConnectionAsync();
        var packagedMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}a", includeDamageLocation: false);
        var weighedMaster = await AsnUnitSeedData.SeedMasterDataAsync(connection, $"{prefix}b", includeDamageLocation: false);

        await using var seedContext = _fixture.CreateDbContext();
        var packaged = CreateDispatchEntity($"DP-PKG-{Guid.NewGuid():N}"[..18], skuId: packagedMaster.SkuId, qty: 4, status: 4, pickedQty: 4, packageQty: 4, packageNo: "PK-001");
        var weighed = CreateDispatchEntity($"DP-WGT-{Guid.NewGuid():N}"[..18], skuId: weighedMaster.SkuId, qty: 3, status: 5, pickedQty: 3, packageQty: 3, weighingQty: 3, packageNo: "PK-002", weighingNo: "WG-002", weighingWeight: 6.6M);
        seedContext.GetDbSet<DispatchlistEntity>().AddRange(packaged, weighed);
        await seedContext.SaveChangesAsync();

        await using var context = _fixture.CreateDbContext();
        var service = CreateDispatchService(context);
        (await service.CancelDispatchlistDetailOpration(packaged.id)).flag.Should().BeTrue();
        (await service.CancelDispatchlistDetailOpration(weighed.id)).flag.Should().BeTrue();

        await using var verifyContext = _fixture.CreateDbContext();
        var packagedAfter = await verifyContext.GetDbSet<DispatchlistEntity>().SingleAsync(t => t.id == packaged.id);
        var weighedAfter = await verifyContext.GetDbSet<DispatchlistEntity>().SingleAsync(t => t.id == weighed.id);

        packagedAfter.dispatch_status.Should().Be(3);
        packagedAfter.package_no.Should().BeEmpty();
        packagedAfter.package_qty.Should().Be(0);
        weighedAfter.dispatch_status.Should().Be(4);
        weighedAfter.weighing_no.Should().BeEmpty();
        weighedAfter.weighing_qty.Should().Be(0);
        weighedAfter.package_no.Should().Be("PK-002");
    }

    [Fact]
    public async Task FreightfeeCrudAndExcelImportSupportQueriesAsync()
    {
        await using var seedContext = _fixture.CreateDbContext();
        var existing = new FreightfeeEntity
        {
            carrier = $"CARRIER-{Guid.NewGuid():N}"[..16],
            departure_city = "上海",
            arrival_city = "苏州",
            price_per_weight = 1.5M,
            price_per_volume = 2.5M,
            min_payment = 8M,
            creator = "seed",
            create_time = DateTime.Now,
            last_update_time = DateTime.Now,
            is_valid = true,
            tenant_id = 1
        };
        seedContext.GetDbSet<FreightfeeEntity>().Add(existing);
        await seedContext.SaveChangesAsync();

        await using var context = _fixture.CreateDbContext();
        var service = CreateFreightfeeService(context);
        var currentUser = TestCurrentUser.Admin();

        (await service.GetAsync(existing.id))!.carrier.Should().Be(existing.carrier);
        (await service.UpdateAsync(new FreightfeeViewModel
        {
            id = existing.id,
            carrier = existing.carrier,
            departure_city = "上海",
            arrival_city = "无锡",
            price_per_weight = 2.2M,
            price_per_volume = 3.1M,
            min_payment = 12M,
            is_valid = false
        })).flag.Should().BeTrue();

        var addedCarrier = $"ADD-{Guid.NewGuid():N}"[..16];
        var added = await service.AddAsync(new FreightfeeViewModel
        {
            carrier = addedCarrier,
            departure_city = "深圳",
            arrival_city = "广州",
            price_per_weight = 1.1M,
            price_per_volume = 0.9M,
            min_payment = 6M,
            is_valid = true
        }, currentUser);
        added.id.Should().BeGreaterThan(0);

        var excelCarrier = $"EXCEL-{Guid.NewGuid():N}"[..16];
        (await service.ExcelAsync(new List<FreightfeeExcelmportViewModel>
        {
            new()
            {
                carrier = excelCarrier,
                departure_city = "北京",
                arrival_city = "天津",
                price_per_weight = 3M,
                price_per_volume = 1.8M,
                min_payment = 15M
            }
        }, currentUser)).flag.Should().BeTrue();

        var (rows, totals) = await service.PageAsync(CreatePageSearch("carrier", existing.carrier), currentUser);
        totals.Should().Be(1);
        rows.Should().ContainSingle(t => t.arrival_city == "无锡" && t.min_payment == 12M && t.is_valid == false);

        var allCarriers = (await service.GetAllAsync(currentUser)).Select(t => t.carrier).ToList();
        allCarriers.Should().Contain(new[] { existing.carrier, addedCarrier, excelCarrier });
        (await service.DeleteAsync(added.id)).flag.Should().BeTrue();
        (await service.GetAllAsync(currentUser)).Select(t => t.carrier).Should().NotContain(addedCarrier);
    }

    [Fact]
    public void GetPackageOrWeightCodeUsesTodayPrefixAndDigits()
    {
        using var context = _fixture.CreateDbContext();
        var service = CreateDispatchService(context);

        var code = service.GetPackageOrWeightCode();

        code.Should().StartWith(DateTime.Now.ToString("yyyyMMdd"));
        code.Should().MatchRegex("^[0-9]{18,}$");
    }

    private async Task<DispatchSeed> CreateDraftDispatchAsync(string prefix, int stockQty, int dispatchQty)
    {
        var seriesNumber = $"SN-{prefix}"[..Math.Min(24, $"SN-{prefix}".Length)];
        var customerName = $"CUSTOMER-{prefix}";
        var expiryDate = new DateTime(2026, 12, 31);
        var putawayDate = new DateTime(2026, 5, 1);
        const decimal price = 11.5M;

        await using var connection = await _fixture.OpenConnectionAsync();
        var master = await AsnUnitSeedData.SeedMasterDataAsync(connection, prefix, includeDamageLocation: false);
        if (stockQty > 0)
        {
            await AsnUnitSeedData.InsertStockAsync(connection, master.SkuId, master.NormalLocationId, master.GoodsOwnerId, seriesNumber, stockQty, expiryDate, price, putawayDate);
        }

        await using var addContext = _fixture.CreateDbContext();
        var service = CreateDispatchService(addContext);
        var result = await service.AddAsync(new List<DispatchlistAddViewModel>
        {
            new()
            {
                customer_id = 1,
                customer_name = customerName,
                sku_id = master.SkuId,
                qty = dispatchQty
            }
        }, TestCurrentUser.Admin());
        result.flag.Should().BeTrue();

        await using var verifyContext = _fixture.CreateDbContext();
        var dispatch = await verifyContext.GetDbSet<DispatchlistEntity>()
            .SingleAsync(t => t.customer_name == customerName && t.sku_id == master.SkuId && t.tenant_id == 1);
        return new DispatchSeed(master, customerName, dispatch.dispatch_no, dispatch.id, seriesNumber, expiryDate, price, putawayDate);
    }

    private async Task<DispatchSeed> CreateConfirmedDispatchAsync(string prefix, int stockQty, int dispatchQty)
    {
        var seed = await CreateDraftDispatchAsync(prefix, stockQty, dispatchQty);
        await using var context = _fixture.CreateDbContext();
        var service = CreateDispatchService(context);
        var details = await service.ConfirmOrderCheck(seed.DispatchNo, TestCurrentUser.Admin());
        details.Should().OnlyContain(t => t.confirm);
        (await service.ConfirmOrder(details, TestCurrentUser.Admin())).flag.Should().BeTrue();
        return seed;
    }

    private static DispatchlistService CreateDispatchService(SqlDBContext dbContext)
    {
        return new DispatchlistService(
            dbContext,
            new TestStringLocalizer<MultiLanguage>(),
            new FunctionHelper(dbContext, new HttpContextAccessor()));
    }

    private static FreightfeeService CreateFreightfeeService(SqlDBContext dbContext)
    {
        return new FreightfeeService(
            dbContext,
            new TestStringLocalizer<MultiLanguage>());
    }

    private static PageSearch CreatePageSearch(string name, object value, string sqlTitle = "")
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
                    Text = value.ToString() ?? string.Empty,
                    Value = value
                }
            }
        };
    }

    private static CurrentUser CreateCurrentUser(int userId, string userName, long tenantId = 1)
    {
        return new CurrentUser
        {
            user_id = userId,
            user_num = userName,
            user_name = userName,
            user_role = "administrator",
            tenant_id = tenantId
        };
    }

    private static DispatchpicklistEntity CreateDispatchPickEntity(
        int dispatchId,
        int goodsOwnerId,
        int locationId,
        int skuId,
        int pickQty,
        int pickedQty,
        string seriesNumber,
        DateTime expiryDate,
        decimal price,
        DateTime putawayDate)
    {
        return new DispatchpicklistEntity
        {
            dispatchlist_id = dispatchId,
            goods_owner_id = goodsOwnerId,
            goods_location_id = locationId,
            sku_id = skuId,
            pick_qty = pickQty,
            picked_qty = pickedQty,
            is_update_stock = false,
            last_update_time = DateTime.Now,
            series_number = seriesNumber,
            expiry_date = expiryDate,
            price = price,
            putaway_date = putawayDate
        };
    }

    private static GoodslocationEntity CreateSiblingLocation(GoodslocationEntity source, string locationName)
    {
        return new GoodslocationEntity
        {
            warehouse_id = source.warehouse_id,
            warehouse_name = source.warehouse_name,
            warehouse_area_id = source.warehouse_area_id,
            warehouse_area_name = source.warehouse_area_name,
            warehouse_area_property = source.warehouse_area_property,
            location_name = locationName,
            create_time = DateTime.Now,
            last_update_time = DateTime.Now,
            is_valid = true,
            tenant_id = source.tenant_id
        };
    }

    private static DispatchlistEntity CreateDispatchEntity(
        string dispatchNo,
        int skuId,
        int qty,
        byte status,
        int lockQty = 0,
        int pickedQty = 0,
        int packageQty = 0,
        int weighingQty = 0,
        int actualQty = 0,
        string packageNo = "",
        string weighingNo = "",
        decimal weighingWeight = 0M)
    {
        return new DispatchlistEntity
        {
            dispatch_no = dispatchNo,
            dispatch_status = status,
            customer_id = 1,
            customer_name = "customer",
            sku_id = skuId,
            qty = qty,
            weight = qty,
            volume = qty,
            creator = "unit",
            create_time = DateTime.Now,
            last_update_time = DateTime.Now,
            tenant_id = 1,
            lock_qty = lockQty,
            picked_qty = pickedQty,
            package_qty = packageQty,
            weighing_qty = weighingQty,
            actual_qty = actualQty,
            package_no = packageNo,
            package_person = string.IsNullOrEmpty(packageNo) ? string.Empty : "packer",
            package_time = string.IsNullOrEmpty(packageNo) ? UtilConvert.MinDate : DateTime.Now,
            weighing_no = weighingNo,
            weighing_person = string.IsNullOrEmpty(weighingNo) ? string.Empty : "weigher",
            weighing_weight = weighingWeight
        };
    }

    private sealed record DispatchSeed(
        AsnTestMasterData Master,
        string CustomerName,
        string DispatchNo,
        int DispatchId,
        string SeriesNumber,
        DateTime ExpiryDate,
        decimal Price,
        DateTime PutawayDate);
}
