using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Repositories;

public sealed class MasterDataSkeletonRepository : DomainRepository
{
    public override string ModelName => "主数据骨架";

    public override async Task<object?> QueryAsync(ScenarioDataContext context)
    {
        var skuCodes = context.GetTracked("sku.code");
        var rows = new List<Dictionary<string, object?>>();
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var skuCode in skuCodes.OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
        {
            rows.Add(await QueryRowAsync(connection, context, skuCode));
        }

        return rows;
    }

    private static async Task<Dictionary<string, object?>> QueryRowAsync(MySqlConnection connection, ScenarioDataContext context, string skuCode)
    {
        await using var command = new MySqlCommand("""
            select sku.sku_code, spu.spu_code, category.category_name, supplier.supplier_name
            from sku
            join spu on spu.id = sku.spu_id
            join category on category.id = spu.category_id
            join supplier on supplier.id = spu.supplier_id
            where sku.sku_code = @skuCode
            limit 1
            """, connection);
        command.Parameters.AddWithValue("@skuCode", skuCode);
        await using var reader = await command.ExecuteReaderAsync();
        if (!await reader.ReadAsync())
        {
            throw new InvalidOperationException($"Cannot find SKU '{skuCode}'.");
        }

        return new Dictionary<string, object?>
        {
            ["warehouse_name"] = context.GetTracked("warehouse.name").Single(),
            ["location_code"] = context.GetTracked("location.code").Single(),
            ["goods_owner_name"] = context.GetTracked("goods_owner.name").Single(),
            ["supplier_name"] = reader.GetString("supplier_name"),
            ["customer_name"] = context.GetTracked("customer.name").Single(),
            ["category_name"] = reader.GetString("category_name"),
            ["spu_code"] = reader.GetString("spu_code"),
            ["sku_code"] = reader.GetString("sku_code")
        };
    }
}
