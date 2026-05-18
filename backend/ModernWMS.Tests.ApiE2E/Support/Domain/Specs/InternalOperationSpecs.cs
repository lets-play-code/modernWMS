using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Specs;

public sealed class StockFreezeTaskSpec : DomainSpec
{
    public override string Name => "冻结库存任务";

    public override async Task CreateAsync(DomainSpecInput input, ScenarioDataContext context)
    {
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var row in input.Rows)
        {
            var ids = await MasterDataBuilder.EnsureAsync(connection, WithMasterDefaults(row), context);
            await InsertFrozenStockAsync(connection, row, ids);
            await InsertFreezeTaskAsync(connection, row, ids);
            context.Track("stockfreeze.job_code", row["job_code"]);
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
        result.TryAdd("customer.name", $"客户-{skuCode}");
        result.TryAdd("category.name", $"分类-{skuCode}");
        result.TryAdd("spu.code", $"SPU-{skuCode}");
        return result;
    }

    private static async Task InsertFrozenStockAsync(MySqlConnection connection, IReadOnlyDictionary<string, string> row, MasterDataIds ids)
    {
        await using var command = new MySqlCommand("""
            insert into stock (sku_id, goods_location_id, qty, goods_owner_id, is_freeze, tenant_id, series_number)
            values (@skuId, @locationId, @qty, @ownerId, 1, 1, '')
            """, connection);
        command.Parameters.AddWithValue("@skuId", ids.SkuId);
        command.Parameters.AddWithValue("@locationId", ids.LocationId);
        command.Parameters.AddWithValue("@qty", int.Parse(row["qty"]));
        command.Parameters.AddWithValue("@ownerId", ids.GoodsOwnerId);
        await command.ExecuteNonQueryAsync();
    }

    private static async Task InsertFreezeTaskAsync(MySqlConnection connection, IReadOnlyDictionary<string, string> row, MasterDataIds ids)
    {
        await using var command = new MySqlCommand("""
            insert into stockfreeze (job_code, job_type, sku_id, goods_owner_id, goods_location_id, handler, tenant_id, series_number)
            values (@jobCode, 1, @skuId, @ownerId, @locationId, 'e2e', 1, '')
            """, connection);
        command.Parameters.AddWithValue("@jobCode", row["job_code"]);
        command.Parameters.AddWithValue("@skuId", ids.SkuId);
        command.Parameters.AddWithValue("@ownerId", ids.GoodsOwnerId);
        command.Parameters.AddWithValue("@locationId", ids.LocationId);
        await command.ExecuteNonQueryAsync();
    }
}
