using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Repositories;

public sealed class StockViewRepository : DomainRepository
{
    public override string ModelName => "库存视图";

    public override async Task<object?> QueryAsync(ScenarioDataContext context)
    {
        var skuCodes = context.GetTracked("stock.sku.code").DefaultIfEmpty().Where(x => !string.IsNullOrWhiteSpace(x)).ToList();
        var rows = new List<Dictionary<string, object?>>();
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var skuCode in skuCodes.OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
        {
            rows.Add(await QueryStockAsync(connection, skuCode!));
        }

        return rows;
    }

    private static async Task<Dictionary<string, object?>> QueryStockAsync(MySqlConnection connection, string skuCode)
    {
        await using var command = new MySqlCommand("""
            select sku.sku_code,
                   coalesce(sum(stock.qty), 0) as qty,
                   coalesce(sum(case when stock.is_freeze = 1 then stock.qty else 0 end), 0) as qty_frozen,
                   coalesce((select sum(dp.pick_qty)
                             from dispatchpicklist dp
                             join sku lock_sku on lock_sku.id = dp.sku_id
                             where lock_sku.sku_code = @skuCode and dp.is_update_stock = 0), 0) as qty_locked,
                   coalesce(sum(case when stock.is_freeze = 0 and goodslocation.warehouse_area_property <> 5 then stock.qty else 0 end), 0)
                     - coalesce((select sum(dp.pick_qty)
                                 from dispatchpicklist dp
                                 join sku lock_sku on lock_sku.id = dp.sku_id
                                 where lock_sku.sku_code = @skuCode and dp.is_update_stock = 0), 0) as qty_available
            from stock
            join sku on sku.id = stock.sku_id
            join goodslocation on goodslocation.id = stock.goods_location_id
            where sku.sku_code = @skuCode and stock.tenant_id = 1
            group by sku.sku_code
            """, connection);
        command.Parameters.AddWithValue("@skuCode", skuCode);
        await using var reader = await command.ExecuteReaderAsync();
        if (!await reader.ReadAsync())
        {
            throw new InvalidOperationException($"Cannot find stock for SKU '{skuCode}'.");
        }

        return new Dictionary<string, object?>
        {
            ["sku_code"] = reader.GetString("sku_code"),
            ["qty"] = Convert.ToInt64(reader["qty"]),
            ["qty_frozen"] = Convert.ToInt64(reader["qty_frozen"]),
            ["qty_locked"] = Convert.ToInt64(reader["qty_locked"]),
            ["qty_available"] = Convert.ToInt64(reader["qty_available"])
        };
    }
}
