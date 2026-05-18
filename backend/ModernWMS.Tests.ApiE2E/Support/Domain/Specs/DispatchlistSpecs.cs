using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Specs;

public sealed class LockedDispatchlistSpec : DomainSpec
{
    public override string Name => "已锁库 发货单";

    public override async Task CreateAsync(DomainSpecInput input, ScenarioDataContext context)
    {
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var row in input.Rows)
        {
            var ids = await MasterDataBuilder.EnsureAsync(connection, WithMasterDefaults(row), context);
            await InsertStockAsync(connection, row, ids);
            var dispatchId = await InsertDispatchAsync(connection, row, ids);
            await InsertPickAsync(connection, row, ids, dispatchId);
            context.Track("dispatch.no", row["dispatch_no"]);
            context.Track("stock.sku.code", row["sku.code"]);
        }
    }

    private static IReadOnlyDictionary<string, string> WithMasterDefaults(IReadOnlyDictionary<string, string> row)
    {
        var result = new Dictionary<string, string>(row, StringComparer.OrdinalIgnoreCase);
        var skuCode = row["sku.code"];
        var locationCode = row["location.code"];
        result.TryAdd("warehouse.name", $"WH-{locationCode}");
        result.TryAdd("area.name", $"AREA-{locationCode}");
        result.TryAdd("area.property", "1");
        result.TryAdd("supplier.name", $"供应商-{skuCode}");
        result.TryAdd("category.name", $"分类-{skuCode}");
        result.TryAdd("spu.code", $"SPU-{skuCode}");
        return result;
    }

    private static async Task InsertStockAsync(MySqlConnection connection, IReadOnlyDictionary<string, string> row, MasterDataIds ids)
    {
        await using var command = new MySqlCommand("""
            insert into stock (sku_id, goods_location_id, qty, goods_owner_id, is_freeze, tenant_id, series_number)
            values (@skuId, @locationId, @qty, @ownerId, 0, 1, '')
            """, connection);
        command.Parameters.AddWithValue("@skuId", ids.SkuId);
        command.Parameters.AddWithValue("@locationId", ids.LocationId);
        command.Parameters.AddWithValue("@qty", int.Parse(row["stock_qty"]));
        command.Parameters.AddWithValue("@ownerId", ids.GoodsOwnerId);
        await command.ExecuteNonQueryAsync();
    }

    private static async Task<int> InsertDispatchAsync(MySqlConnection connection, IReadOnlyDictionary<string, string> row, MasterDataIds ids)
    {
        await using var command = new MySqlCommand("""
            insert into dispatchlist (dispatch_no, dispatch_status, customer_id, customer_name, sku_id, qty, lock_qty, creator, tenant_id)
            values (@dispatchNo, 2, @customerId, @customerName, @skuId, @qty, @lockQty, 'e2e', 1);
            select last_insert_id();
            """, connection);
        command.Parameters.AddWithValue("@dispatchNo", row["dispatch_no"]);
        command.Parameters.AddWithValue("@customerId", ids.CustomerId);
        command.Parameters.AddWithValue("@customerName", row["customer.name"]);
        command.Parameters.AddWithValue("@skuId", ids.SkuId);
        command.Parameters.AddWithValue("@qty", int.Parse(row["qty"]));
        command.Parameters.AddWithValue("@lockQty", int.Parse(row["lock_qty"]));
        return Convert.ToInt32(await command.ExecuteScalarAsync());
    }

    private static async Task InsertPickAsync(MySqlConnection connection, IReadOnlyDictionary<string, string> row, MasterDataIds ids, int dispatchId)
    {
        await using var command = new MySqlCommand("""
            insert into dispatchpicklist (dispatchlist_id, goods_owner_id, goods_location_id, sku_id, pick_qty, picked_qty, is_update_stock, series_number)
            values (@dispatchId, @ownerId, @locationId, @skuId, @pickQty, 0, 0, '')
            """, connection);
        command.Parameters.AddWithValue("@dispatchId", dispatchId);
        command.Parameters.AddWithValue("@ownerId", ids.GoodsOwnerId);
        command.Parameters.AddWithValue("@locationId", ids.LocationId);
        command.Parameters.AddWithValue("@skuId", ids.SkuId);
        command.Parameters.AddWithValue("@pickQty", int.Parse(row["lock_qty"]));
        await command.ExecuteNonQueryAsync();
    }
}
