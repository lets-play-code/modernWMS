using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Repositories;

public sealed class StockFreezeTaskRepository : DomainRepository
{
    public override string ModelName => "冻结任务";

    public override async Task<object?> QueryAsync(ScenarioDataContext context)
    {
        var rows = new List<Dictionary<string, object?>>();
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var jobCode in context.GetTracked("stockfreeze.job_code").OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
        {
            await using var command = new MySqlCommand("""
                select stockfreeze.job_code, sku.sku_code, stock.qty, stockfreeze.job_type
                from stockfreeze
                join sku on sku.id = stockfreeze.sku_id
                join stock on stock.sku_id = stockfreeze.sku_id
                          and stock.goods_location_id = stockfreeze.goods_location_id
                          and stock.goods_owner_id = stockfreeze.goods_owner_id
                where stockfreeze.job_code = @jobCode and stockfreeze.tenant_id = 1
                limit 1
                """, connection);
            command.Parameters.AddWithValue("@jobCode", jobCode);
            await using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                rows.Add(new Dictionary<string, object?>
                {
                    ["job_code"] = reader.GetString("job_code"),
                    ["sku_code"] = reader.GetString("sku_code"),
                    ["qty"] = Convert.ToInt64(reader["qty"]),
                    ["job_type"] = Convert.ToBoolean(reader["job_type"])
                });
            }
        }

        return rows;
    }
}
