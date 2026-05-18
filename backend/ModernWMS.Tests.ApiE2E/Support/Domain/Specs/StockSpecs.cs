using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Specs;

public sealed class AvailableStockSpec : DomainSpec
{
    public override string Name => "可用库存";

    public override async Task CreateAsync(DomainSpecInput input, ScenarioDataContext context)
    {
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var row in input.Rows)
        {
            var ids = await MasterDataBuilder.EnsureAsync(connection, WithMasterDefaults(row), context);
            await InsertStockAsync(connection, row, ids);
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
        result.TryAdd("supplier.name", $"供应商-{skuCode}");
        result.TryAdd("customer.name", $"客户-{skuCode}");
        result.TryAdd("category.name", $"分类-{skuCode}");
        result.TryAdd("spu.code", $"SPU-{skuCode}");
        return result;
    }

    private static async Task InsertStockAsync(MySqlConnection connection, IReadOnlyDictionary<string, string> row, MasterDataIds ids)
    {
        await using var command = new MySqlCommand("""
            insert into stock (sku_id, goods_location_id, qty, goods_owner_id, is_freeze, tenant_id, series_number)
            values (@skuId, @locationId, @qty, @ownerId, @isFreeze, 1, @seriesNumber)
            """, connection);
        command.Parameters.AddWithValue("@skuId", ids.SkuId);
        command.Parameters.AddWithValue("@locationId", ids.LocationId);
        command.Parameters.AddWithValue("@qty", int.Parse(row["qty"]));
        command.Parameters.AddWithValue("@ownerId", ids.GoodsOwnerId);
        command.Parameters.AddWithValue("@isFreeze", bool.Parse(row.GetValueOrDefault("is_freeze", "false")) ? 1 : 0);
        command.Parameters.AddWithValue("@seriesNumber", row.GetValueOrDefault("series_number", ""));
        await command.ExecuteNonQueryAsync();
    }
}
