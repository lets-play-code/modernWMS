using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Repositories;

public sealed class AsnRepository : DomainRepository
{
    public override string ModelName => "到货通知";

    public override async Task<object?> QueryAsync(ScenarioDataContext context)
    {
        var rows = new List<Dictionary<string, object?>>();
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var asnNo in context.GetTracked("asn.no").OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
        {
            await using var command = new MySqlCommand("""
                select asn.asn_no, sku.sku_code, asn.asn_status, asn.asn_qty, asn.sorted_qty
                from asn join sku on sku.id = asn.sku_id
                where asn.asn_no = @asnNo and asn.tenant_id = 1
                limit 1
                """, connection);
            command.Parameters.AddWithValue("@asnNo", asnNo);
            await using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                rows.Add(Row(reader));
            }
        }

        return rows;
    }

    private static Dictionary<string, object?> Row(MySqlDataReader reader) => new()
    {
        ["asn_no"] = reader.GetString("asn_no"),
        ["sku_code"] = reader.GetString("sku_code"),
        ["asn_status"] = Convert.ToInt64(reader["asn_status"]),
        ["asn_qty"] = Convert.ToInt64(reader["asn_qty"]),
        ["sorted_qty"] = Convert.ToInt64(reader["sorted_qty"])
    };
}

public sealed class AsnSortRepository : DomainRepository
{
    public override string ModelName => "分拣记录";

    public override async Task<object?> QueryAsync(ScenarioDataContext context)
    {
        var rows = new List<Dictionary<string, object?>>();
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var asnNo in context.GetTracked("asn.no").OrderBy(x => x, StringComparer.OrdinalIgnoreCase))
        {
            await using var command = new MySqlCommand("""
                select asn.asn_no, sku.sku_code, asnsort.sorted_qty, asnsort.putaway_qty
                from asnsort
                join asn on asn.id = asnsort.asn_id
                join sku on sku.id = asn.sku_id
                where asn.asn_no = @asnNo and asnsort.tenant_id = 1
                order by asnsort.id
                """, connection);
            command.Parameters.AddWithValue("@asnNo", asnNo);
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                rows.Add(new Dictionary<string, object?>
                {
                    ["asn_no"] = reader.GetString("asn_no"),
                    ["sku_code"] = reader.GetString("sku_code"),
                    ["sorted_qty"] = Convert.ToInt64(reader["sorted_qty"]),
                    ["putaway_qty"] = Convert.ToInt64(reader["putaway_qty"])
                });
            }
        }

        return rows;
    }
}
