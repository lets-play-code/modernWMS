using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Repositories;

public sealed class DispatchlistRepository : DomainRepository
{
    public override string ModelName => "发货单";

    public override async Task<object?> QueryAsync(ScenarioDataContext context)
    {
        var rows = new List<Dictionary<string, object?>>();
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var dispatchNo in context.GetTracked("dispatch.no").OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
        {
            await using var command = new MySqlCommand("""
                select dispatchlist.dispatch_no, sku.sku_code, dispatchlist.dispatch_status, dispatchlist.qty, dispatchlist.lock_qty
                from dispatchlist join sku on sku.id = dispatchlist.sku_id
                where dispatchlist.dispatch_no = @dispatchNo and dispatchlist.tenant_id = 1
                order by dispatchlist.id
                """, connection);
            command.Parameters.AddWithValue("@dispatchNo", dispatchNo);
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync()) rows.Add(Row(reader));
        }

        return rows;
    }

    private static Dictionary<string, object?> Row(MySqlDataReader reader) => new()
    {
        ["dispatch_no"] = reader.GetString("dispatch_no"),
        ["sku_code"] = reader.GetString("sku_code"),
        ["dispatch_status"] = Convert.ToInt64(reader["dispatch_status"]),
        ["qty"] = Convert.ToInt64(reader["qty"]),
        ["lock_qty"] = Convert.ToInt64(reader["lock_qty"])
    };
}

public sealed class DispatchpicklistRepository : DomainRepository
{
    public override string ModelName => "拣货明细";

    public override async Task<object?> QueryAsync(ScenarioDataContext context)
    {
        var rows = new List<Dictionary<string, object?>>();
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var dispatchNo in context.GetTracked("dispatch.no").OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
        {
            await using var command = new MySqlCommand("""
                select dispatchlist.dispatch_no, sku.sku_code, dispatchpicklist.pick_qty, dispatchpicklist.is_update_stock
                from dispatchpicklist
                join dispatchlist on dispatchlist.id = dispatchpicklist.dispatchlist_id
                join sku on sku.id = dispatchpicklist.sku_id
                where dispatchlist.dispatch_no = @dispatchNo
                order by dispatchpicklist.id
                """, connection);
            command.Parameters.AddWithValue("@dispatchNo", dispatchNo);
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                rows.Add(new Dictionary<string, object?>
                {
                    ["dispatch_no"] = reader.GetString("dispatch_no"),
                    ["sku_code"] = reader.GetString("sku_code"),
                    ["pick_qty"] = Convert.ToInt64(reader["pick_qty"]),
                    ["is_update_stock"] = Convert.ToBoolean(reader["is_update_stock"])
                });
            }
        }

        return rows;
    }
}
