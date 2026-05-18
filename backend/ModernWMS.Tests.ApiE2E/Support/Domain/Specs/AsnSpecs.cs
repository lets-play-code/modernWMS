using System.Globalization;
using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Specs
{
    public sealed class UnloadedAsnSpec : DomainSpec
    {
        public override string Name => "已卸货的 到货通知";

        public override async Task CreateAsync(DomainSpecInput input, ScenarioDataContext context)
        {
            await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
            foreach (var row in input.Rows)
            {
                var ids = await MasterDataBuilder.EnsureAsync(connection, AsnSpecBuilder.WithMasterDefaults(row), context);
                var (masterId, asnId) = await AsnSpecBuilder.InsertAsnAsync(
                    connection,
                    row,
                    ids,
                    asnStatus: 2,
                    defaultArrivalTime: new DateTime(2026, 5, 18, 8, 0, 0),
                    defaultUnloadTime: new DateTime(2026, 5, 18, 9, 0, 0));
                AsnSpecBuilder.TrackAsn(context, row, masterId, asnId);
            }
        }
    }

    public sealed class SortedAsnSpec : DomainSpec
    {
        public override string Name => "已分拣的 到货通知";

        public override async Task CreateAsync(DomainSpecInput input, ScenarioDataContext context)
        {
            await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
            foreach (var row in input.Rows)
            {
                var ids = await MasterDataBuilder.EnsureAsync(connection, AsnSpecBuilder.WithMasterDefaults(row), context);
                var (masterId, asnId) = await AsnSpecBuilder.InsertAsnAsync(
                    connection,
                    row,
                    ids,
                    asnStatus: 3,
                    defaultArrivalTime: new DateTime(2026, 5, 18, 8, 0, 0),
                    defaultUnloadTime: new DateTime(2026, 5, 18, 9, 0, 0));
                await AsnSpecBuilder.InsertAsnSortAsync(connection, row, asnId);
                AsnSpecBuilder.TrackAsn(context, row, masterId, asnId);
            }
        }
    }

    internal static class AsnSpecBuilder
    {
        public static IReadOnlyDictionary<string, string> WithMasterDefaults(IReadOnlyDictionary<string, string> row)
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

        public static async Task<(int MasterId, int AsnId)> InsertAsnAsync(
            MySqlConnection connection,
            IReadOnlyDictionary<string, string> row,
            MasterDataIds ids,
            byte asnStatus,
            DateTime defaultArrivalTime,
            DateTime defaultUnloadTime)
        {
            var asnNo = row["asn_no"];
            var asnBatch = row.GetValueOrDefault("asn_batch", asnNo);
            var estimatedArrivalTime = DateValue(row, "estimated_arrival_time", new DateTime(2026, 5, 18));
            var arrivalTime = DateValue(row, "arrival_time", defaultArrivalTime);
            var unloadTime = DateValue(row, "unload_time", defaultUnloadTime);
            var expiryDate = DateValue(row, "expiry_date", new DateTime(2026, 12, 31));
            var asnQty = IntValue(row, "asn_qty", 1);
            var actualQty = IntValue(row, "actual_qty", 0);
            var sortedQty = IntValue(row, "sorted_qty", 0);
            var shortageQty = IntValue(row, "shortage_qty", 0);
            var moreQty = IntValue(row, "more_qty", 0);
            var damageQty = IntValue(row, "damage_qty", 0);
            var weight = DecimalValue(row, "weight", 0M);
            var volume = DecimalValue(row, "volume", 0M);
            var price = DecimalValue(row, "price", 0M);
            var unloadPersonId = IntValue(row, "unload_person_id", 1);
            var unloadPerson = row.GetValueOrDefault("unload_person", "e2e-unload");

            var masterId = await InsertScalarAsync(connection, """
                insert into asnmaster (
                    asn_no, asn_batch, estimated_arrival_time, asn_status, weight, volume,
                    goods_owner_id, goods_owner_name, creator, create_time, last_update_time, tenant_id)
                values (
                    @asnNo, @asnBatch, @estimatedArrivalTime, @asnStatus, @weight, @volume,
                    @ownerId, @ownerName, 'e2e', now(), now(), 1);
                select last_insert_id();
                """,
                ("@asnNo", asnNo),
                ("@asnBatch", asnBatch),
                ("@estimatedArrivalTime", estimatedArrivalTime),
                ("@asnStatus", asnStatus),
                ("@weight", weight),
                ("@volume", volume),
                ("@ownerId", ids.GoodsOwnerId),
                ("@ownerName", row["goods_owner.name"]));

            var asnId = await InsertScalarAsync(connection, """
                insert into asn (
                    asnmaster_id, asn_no, asn_status, spu_id, sku_id, asn_qty, actual_qty,
                    arrival_time, unload_time, unload_person_id, unload_person,
                    sorted_qty, shortage_qty, more_qty, damage_qty,
                    weight, volume, supplier_id, supplier_name, goods_owner_id, goods_owner_name,
                    creator, create_time, last_update_time, is_valid, tenant_id, expiry_date, price)
                values (
                    @masterId, @asnNo, @asnStatus, @spuId, @skuId, @asnQty, @actualQty,
                    @arrivalTime, @unloadTime, @unloadPersonId, @unloadPerson,
                    @sortedQty, @shortageQty, @moreQty, @damageQty,
                    @weight, @volume, @supplierId, @supplierName, @ownerId, @ownerName,
                    'e2e', now(), now(), 1, 1, @expiryDate, @price);
                select last_insert_id();
                """,
                ("@masterId", masterId),
                ("@asnNo", asnNo),
                ("@asnStatus", asnStatus),
                ("@spuId", ids.SpuId),
                ("@skuId", ids.SkuId),
                ("@asnQty", asnQty),
                ("@actualQty", actualQty),
                ("@arrivalTime", arrivalTime),
                ("@unloadTime", unloadTime),
                ("@unloadPersonId", unloadPersonId),
                ("@unloadPerson", unloadPerson),
                ("@sortedQty", sortedQty),
                ("@shortageQty", shortageQty),
                ("@moreQty", moreQty),
                ("@damageQty", damageQty),
                ("@weight", weight),
                ("@volume", volume),
                ("@supplierId", ids.SupplierId),
                ("@supplierName", row["supplier.name"]),
                ("@ownerId", ids.GoodsOwnerId),
                ("@ownerName", row["goods_owner.name"]),
                ("@expiryDate", expiryDate),
                ("@price", price));

            return (masterId, asnId);
        }

        public static async Task InsertAsnSortAsync(MySqlConnection connection, IReadOnlyDictionary<string, string> row, int asnId)
        {
            await using var command = new MySqlCommand("""
                insert into asnsort (asn_id, sorted_qty, creator, tenant_id, series_number, putaway_qty, create_time, last_update_time, is_valid)
                values (@asnId, @sortedQty, 'e2e', 1, @seriesNumber, @putawayQty, now(), now(), 1)
                """, connection);
            command.Parameters.AddWithValue("@asnId", asnId);
            command.Parameters.AddWithValue("@sortedQty", IntValue(row, "sorted_qty", 1));
            command.Parameters.AddWithValue("@seriesNumber", row.GetValueOrDefault("series_number", string.Empty));
            command.Parameters.AddWithValue("@putawayQty", IntValue(row, "putaway_qty", 0));
            await command.ExecuteNonQueryAsync();
        }

        public static void TrackAsn(ScenarioDataContext context, IReadOnlyDictionary<string, string> row, int masterId, int asnId)
        {
            context.Track("asnmaster.id", masterId.ToString());
            context.Track("asn.id", asnId.ToString());
            context.Track("asn.no", row["asn_no"]);

            if (row.TryGetValue("asn.key", out var alias) && !string.IsNullOrWhiteSpace(alias))
            {
                context.Track($"asn.{alias}.id", asnId.ToString());
                context.Track($"asn.{alias}.no", row["asn_no"]);
            }
        }

        private static int IntValue(IReadOnlyDictionary<string, string> row, string key, int fallback)
        {
            return row.TryGetValue(key, out var value) && int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed)
                ? parsed
                : fallback;
        }

        private static decimal DecimalValue(IReadOnlyDictionary<string, string> row, string key, decimal fallback)
        {
            return row.TryGetValue(key, out var value) && decimal.TryParse(value, NumberStyles.Number, CultureInfo.InvariantCulture, out var parsed)
                ? parsed
                : fallback;
        }

        private static DateTime DateValue(IReadOnlyDictionary<string, string> row, string key, DateTime fallback)
        {
            return row.TryGetValue(key, out var value) && DateTime.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.AssumeLocal, out var parsed)
                ? parsed
                : fallback;
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
}
