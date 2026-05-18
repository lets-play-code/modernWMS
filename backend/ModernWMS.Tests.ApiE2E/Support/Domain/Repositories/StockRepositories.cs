using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Repositories;

public sealed class StockViewRepository : DomainRepository
{
    public override string ModelName => "库存视图";

    public override async Task<object?> QueryAsync(ScenarioDataContext context)
    {
        var skuCodes = context.GetTracked("stock.sku.code")
            .Concat(context.GetTracked("sku.code"))
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(x => x, StringComparer.OrdinalIgnoreCase)
            .ToList();
        var rows = new List<Dictionary<string, object?>>();
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var skuCode in skuCodes)
        {
            rows.Add(await QueryStockAsync(connection, skuCode));
        }

        return rows;
    }

    private static async Task<Dictionary<string, object?>> QueryStockAsync(MySqlConnection connection, string skuCode)
    {
        await using var command = new MySqlCommand("""
            select sku.sku_code,
                   coalesce(sum(stock.qty), 0) as qty,
                   coalesce(sum(case when stock.is_freeze = 1 then stock.qty else 0 end), 0) as qty_frozen,
                   coalesce((select sum(dl.lock_qty)
                             from dispatchlist dl
                             join sku lock_sku on lock_sku.id = dl.sku_id
                             where lock_sku.sku_code = @skuCode and dl.tenant_id = 1), 0)
                     + coalesce((select sum(pd.qty)
                                 from stockprocessdetail pd
                                 join sku lock_sku on lock_sku.id = pd.sku_id
                                 where lock_sku.sku_code = @skuCode and pd.is_update_stock = 0 and pd.is_source = 1 and pd.tenant_id = 1), 0)
                     + coalesce((select sum(sm.qty)
                                 from stockmove sm
                                 join sku lock_sku on lock_sku.id = sm.sku_id
                                 where lock_sku.sku_code = @skuCode and sm.move_status = 0 and sm.tenant_id = 1), 0) as qty_locked,
                   coalesce(sum(case when goodslocation.warehouse_area_property <> 5 then stock.qty else 0 end), 0)
                     - coalesce(sum(case when goodslocation.warehouse_area_property <> 5 and stock.is_freeze = 1 then stock.qty else 0 end), 0)
                     - coalesce((select sum(dl.lock_qty)
                                 from dispatchlist dl
                                 join sku lock_sku on lock_sku.id = dl.sku_id
                                 where lock_sku.sku_code = @skuCode and dl.tenant_id = 1), 0)
                     - coalesce((select sum(pd.qty)
                                 from stockprocessdetail pd
                                 join goodslocation gl on gl.id = pd.goods_location_id
                                 join sku lock_sku on lock_sku.id = pd.sku_id
                                 where lock_sku.sku_code = @skuCode and pd.is_update_stock = 0 and pd.is_source = 1 and pd.tenant_id = 1 and gl.warehouse_area_property <> 5), 0)
                     - coalesce((select sum(sm.qty)
                                 from stockmove sm
                                 join goodslocation gl on gl.id = sm.orig_goods_location_id
                                 join sku lock_sku on lock_sku.id = sm.sku_id
                                 where lock_sku.sku_code = @skuCode and sm.move_status = 0 and sm.tenant_id = 1 and gl.warehouse_area_property <> 5), 0) as qty_available
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

public sealed class StockLayerRepository : DomainRepository
{
    public override string ModelName => "库存层";

    public override async Task<object?> QueryAsync(ScenarioDataContext context)
    {
        var rows = new List<Dictionary<string, object?>>();
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var asnNo in context.GetTracked("asn.no").OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
        {
            await using var command = new MySqlCommand("""
                select sku.sku_code,
                       goodslocation.location_name as location_code,
                       coalesce(goodsowner.goods_owner_name, '') as goods_owner_name,
                       stock.series_number,
                       stock.qty,
                       stock.is_freeze,
                       stock.expiry_date,
                       stock.price,
                       stock.putaway_date
                from stock
                join sku on sku.id = stock.sku_id
                join goodslocation on goodslocation.id = stock.goods_location_id
                left join goodsowner on goodsowner.id = stock.goods_owner_id
                where stock.tenant_id = 1
                  and sku.id = (select asn.sku_id from asn where asn.asn_no = @asnNo limit 1)
                  and stock.goods_owner_id = (select asn.goods_owner_id from asn where asn.asn_no = @asnNo limit 1)
                  and exists (
                      select 1
                      from asn a
                      join asnsort s on s.asn_id = a.id
                      where a.asn_no = @asnNo and s.series_number = stock.series_number)
                order by goodslocation.location_name, stock.series_number, stock.id
                """, connection);
            command.Parameters.AddWithValue("@asnNo", asnNo);
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                rows.Add(new Dictionary<string, object?>
                {
                    ["sku_code"] = reader.GetString("sku_code"),
                    ["location_code"] = reader.GetString("location_code"),
                    ["goods_owner_name"] = reader.GetString("goods_owner_name"),
                    ["series_number"] = reader.GetString("series_number"),
                    ["qty"] = Convert.ToInt64(reader["qty"]),
                    ["is_freeze"] = Convert.ToBoolean(reader["is_freeze"]),
                    ["expiry_date"] = reader.GetDateTime("expiry_date").ToString("yyyy-MM-dd"),
                    ["price"] = reader.GetDecimal("price"),
                    ["putaway_date"] = reader.GetDateTime("putaway_date").ToString("yyyy-MM-dd")
                });
            }
        }

        return rows;
    }
}
