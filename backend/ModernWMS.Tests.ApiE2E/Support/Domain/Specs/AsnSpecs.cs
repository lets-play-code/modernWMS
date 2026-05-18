using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Specs;

public sealed class SortedAsnSpec : DomainSpec
{
    public override string Name => "已分拣的 到货通知";

    public override async Task CreateAsync(DomainSpecInput input, ScenarioDataContext context)
    {
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var row in input.Rows)
        {
            var ids = await MasterDataBuilder.EnsureAsync(connection, WithMasterDefaults(row), context);
            var asnId = await InsertAsnAsync(connection, row, ids);
            await InsertAsnSortAsync(connection, row, asnId);
            context.Track("asn.no", row["asn_no"]);
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
        result.TryAdd("customer.name", $"客户-{skuCode}");
        result.TryAdd("category.name", $"分类-{skuCode}");
        result.TryAdd("spu.code", $"SPU-{skuCode}");
        return result;
    }

    private static async Task<int> InsertAsnAsync(MySqlConnection connection, IReadOnlyDictionary<string, string> row, MasterDataIds ids)
    {
        var asnNo = row["asn_no"];
        var asnQty = int.Parse(row["asn_qty"]);
        var sortedQty = int.Parse(row["sorted_qty"]);
        var masterId = await InsertScalarAsync(connection, """
            insert into asnmaster (asn_no, asn_batch, asn_status, goods_owner_id, goods_owner_name, creator, tenant_id)
            values (@asnNo, @asnNo, 3, @ownerId, @ownerName, 'e2e', 1);
            select last_insert_id();
            """, ("@asnNo", asnNo), ("@ownerId", ids.GoodsOwnerId), ("@ownerName", row["goods_owner.name"]));
        return await InsertScalarAsync(connection, """
            insert into asn (asnmaster_id, asn_no, asn_status, spu_id, sku_id, asn_qty, sorted_qty, supplier_id, supplier_name, goods_owner_id, goods_owner_name, creator, tenant_id)
            values (@masterId, @asnNo, 3, @spuId, @skuId, @asnQty, @sortedQty, @supplierId, @supplierName, @ownerId, @ownerName, 'e2e', 1);
            select last_insert_id();
            """, ("@masterId", masterId), ("@asnNo", asnNo), ("@spuId", ids.SpuId), ("@skuId", ids.SkuId), ("@asnQty", asnQty), ("@sortedQty", sortedQty), ("@supplierId", ids.SupplierId), ("@supplierName", row["supplier.name"]), ("@ownerId", ids.GoodsOwnerId), ("@ownerName", row["goods_owner.name"]));
    }

    private static async Task InsertAsnSortAsync(MySqlConnection connection, IReadOnlyDictionary<string, string> row, int asnId)
    {
        await using var command = new MySqlCommand("""
            insert into asnsort (asn_id, sorted_qty, creator, tenant_id, series_number, putaway_qty)
            values (@asnId, @sortedQty, 'e2e', 1, @seriesNumber, 0)
            """, connection);
        command.Parameters.AddWithValue("@asnId", asnId);
        command.Parameters.AddWithValue("@sortedQty", int.Parse(row["sorted_qty"]));
        command.Parameters.AddWithValue("@seriesNumber", row.GetValueOrDefault("series_number", ""));
        await command.ExecuteNonQueryAsync();
    }

    private static async Task<int> InsertScalarAsync(MySqlConnection connection, string sql, params (string Name, object Value)[] parameters)
    {
        await using var command = new MySqlCommand(sql, connection);
        foreach (var parameter in parameters)
        {
            command.Parameters.AddWithValue(parameter.Name, parameter.Value);
        }

        return Convert.ToInt32(await command.ExecuteScalarAsync());
    }
}
