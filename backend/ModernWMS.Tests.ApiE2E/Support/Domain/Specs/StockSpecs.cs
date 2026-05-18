using System.Globalization;
using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Specs;

public sealed class AvailableStockSpec : DomainSpec
{
    private static readonly DateTime DefaultDate = new(1900, 1, 1);

    public override string Name => "可用库存";

    public override async Task CreateAsync(DomainSpecInput input, ScenarioDataContext context)
    {
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var row in input.Rows)
        {
            var normalized = WithMasterDefaults(row);
            var ids = await MasterDataBuilder.EnsureAsync(connection, normalized, context);
            var seriesNumber = Value(normalized, "series_number", string.Empty);
            var expiryDate = DateValue(normalized, "expiry_date", DefaultDate);
            var price = DecimalValue(normalized, "price", 0M);
            var putawayDate = DateValue(normalized, "putaway_date", DefaultDate);

            if (HasValue(normalized, "sku.price"))
            {
                await UpdateSkuPriceAsync(connection, ids.SkuId, DecimalValue(normalized, "sku.price", 0M));
            }

            if (IntValue(normalized, "qty", 0) > 0)
            {
                await InsertStockAsync(connection, normalized, ids, seriesNumber, expiryDate, price, putawayDate);
            }

            if (HasValue(normalized, "safety_stock_qty"))
            {
                await EnsureSafetyStockAsync(connection, ids.SkuId, ids.WarehouseId, IntValue(normalized, "safety_stock_qty", 0));
            }

            await MaybeInsertDispatchAsync(connection, normalized, ids, seriesNumber, expiryDate, price, putawayDate, context);
            await MaybeInsertProcessLockAsync(connection, normalized, ids, seriesNumber, expiryDate, price, putawayDate);
            await MaybeInsertMoveLockAsync(connection, normalized, ids, seriesNumber, expiryDate, price, putawayDate);
            context.Track("stock.sku.code", normalized["sku.code"]);
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

    private static async Task InsertStockAsync(
        MySqlConnection connection,
        IReadOnlyDictionary<string, string> row,
        MasterDataIds ids,
        string seriesNumber,
        DateTime expiryDate,
        decimal price,
        DateTime putawayDate)
    {
        await ExecuteAsync(
            connection,
            "insert into stock (sku_id, goods_location_id, qty, goods_owner_id, is_freeze, last_update_time, tenant_id, series_number, expiry_date, price, putaway_date) values (@skuId, @locationId, @qty, @ownerId, @isFreeze, now(), 1, @seriesNumber, @expiryDate, @price, @putawayDate);",
            ("@skuId", ids.SkuId),
            ("@locationId", ids.LocationId),
            ("@qty", IntValue(row, "qty", 0)),
            ("@ownerId", ids.GoodsOwnerId),
            ("@isFreeze", BoolValue(row, "is_freeze", false) ? 1 : 0),
            ("@seriesNumber", seriesNumber),
            ("@expiryDate", expiryDate),
            ("@price", price),
            ("@putawayDate", putawayDate));
    }

    private static async Task MaybeInsertDispatchAsync(
        MySqlConnection connection,
        IReadOnlyDictionary<string, string> row,
        MasterDataIds ids,
        string seriesNumber,
        DateTime expiryDate,
        decimal price,
        DateTime putawayDate,
        ScenarioDataContext context)
    {
        var qty = IntValue(row, "dispatch_qty", 0);
        var lockQty = IntValue(row, "dispatch_lock_qty", 0);
        var pickedQty = IntValue(row, "dispatch_picked_qty", 0);
        if (qty <= 0 && lockQty <= 0 && pickedQty <= 0)
        {
            return;
        }

        var dispatchNo = Value(row, "dispatch_no", $"DP-{Guid.NewGuid():N}"[..17]);
        var customerName = Value(row, "customer.name", $"客户-{row["sku.code"]}");
        var customerId = await EnsureCustomerAsync(connection, customerName);
        var createTime = DateValue(row, "delivery_date", new DateTime(2026, 5, 10, 9, 30, 0));
        var status = (byte)IntValue(row, "dispatch_status", pickedQty > 0 ? 6 : 2);
        var pickQty = Math.Max(Math.Max(qty, lockQty), pickedQty);
        var dispatchQty = Math.Max(qty, pickQty);

        var dispatchId = await InsertScalarAsync(
            connection,
            "insert into dispatchlist (dispatch_no, dispatch_status, customer_id, customer_name, sku_id, qty, lock_qty, picked_qty, creator, create_time, last_update_time, tenant_id) values (@dispatchNo, @status, @customerId, @customerName, @skuId, @qty, @lockQty, @pickedQty, 'e2e', @createTime, @createTime, 1); select last_insert_id();",
            ("@dispatchNo", dispatchNo),
            ("@status", status),
            ("@customerId", customerId),
            ("@customerName", customerName),
            ("@skuId", ids.SkuId),
            ("@qty", dispatchQty),
            ("@lockQty", lockQty),
            ("@pickedQty", pickedQty),
            ("@createTime", createTime));

        await ExecuteAsync(
            connection,
            "insert into dispatchpicklist (dispatchlist_id, goods_owner_id, goods_location_id, sku_id, pick_qty, picked_qty, is_update_stock, last_update_time, series_number, expiry_date, price, putaway_date) values (@dispatchId, @ownerId, @locationId, @skuId, @pickQty, @pickedQty, 0, now(), @seriesNumber, @expiryDate, @price, @putawayDate);",
            ("@dispatchId", dispatchId),
            ("@ownerId", ids.GoodsOwnerId),
            ("@locationId", ids.LocationId),
            ("@skuId", ids.SkuId),
            ("@pickQty", pickQty),
            ("@pickedQty", pickedQty),
            ("@seriesNumber", seriesNumber),
            ("@expiryDate", expiryDate),
            ("@price", price),
            ("@putawayDate", putawayDate));

        context.Track("dispatch.no", dispatchNo);
    }

    private static async Task MaybeInsertProcessLockAsync(
        MySqlConnection connection,
        IReadOnlyDictionary<string, string> row,
        MasterDataIds ids,
        string seriesNumber,
        DateTime expiryDate,
        decimal price,
        DateTime putawayDate)
    {
        var qty = IntValue(row, "process_locked_qty", 0);
        if (qty <= 0)
        {
            return;
        }

        await ExecuteAsync(
            connection,
            "insert into stockprocessdetail (stock_process_id, sku_id, goods_owner_id, goods_location_id, qty, last_update_time, tenant_id, is_source, is_update_stock, series_number, expiry_date, price, putaway_date) values (0, @skuId, @ownerId, @locationId, @qty, now(), 1, 1, 0, @seriesNumber, @expiryDate, @price, @putawayDate);",
            ("@skuId", ids.SkuId),
            ("@ownerId", ids.GoodsOwnerId),
            ("@locationId", ids.LocationId),
            ("@qty", qty),
            ("@seriesNumber", seriesNumber),
            ("@expiryDate", expiryDate),
            ("@price", price),
            ("@putawayDate", putawayDate));
    }

    private static async Task MaybeInsertMoveLockAsync(
        MySqlConnection connection,
        IReadOnlyDictionary<string, string> row,
        MasterDataIds ids,
        string seriesNumber,
        DateTime expiryDate,
        decimal price,
        DateTime putawayDate)
    {
        var qty = IntValue(row, "move_locked_qty", 0);
        if (qty <= 0)
        {
            return;
        }

        await ExecuteAsync(
            connection,
            "insert into stockmove (job_code, move_status, sku_id, orig_goods_location_id, dest_googs_location_id, qty, goods_owner_id, handler, handle_time, creator, create_time, last_update_time, tenant_id, series_number, expiry_date, price, putaway_date) values (@jobCode, 0, @skuId, @locationId, @locationId, @qty, @ownerId, 'e2e', now(), 'e2e', now(), now(), 1, @seriesNumber, @expiryDate, @price, @putawayDate);",
            ("@jobCode", $"MOVE-{Guid.NewGuid():N}"[..17]),
            ("@skuId", ids.SkuId),
            ("@locationId", ids.LocationId),
            ("@qty", qty),
            ("@ownerId", ids.GoodsOwnerId),
            ("@seriesNumber", seriesNumber),
            ("@expiryDate", expiryDate),
            ("@price", price),
            ("@putawayDate", putawayDate));
    }

    private static async Task EnsureSafetyStockAsync(MySqlConnection connection, int skuId, int warehouseId, int safetyStockQty)
    {
        var existingId = await ScalarIntOrNullAsync(
            connection,
            "select id from sku_safety_stock where sku_id = @skuId and warehouse_id = @warehouseId limit 1;",
            ("@skuId", skuId),
            ("@warehouseId", warehouseId));

        if (existingId.HasValue)
        {
            await ExecuteAsync(
                connection,
                "update sku_safety_stock set safety_stock_qty = @qty where id = @id;",
                ("@qty", safetyStockQty),
                ("@id", existingId.Value));
            return;
        }

        await ExecuteAsync(
            connection,
            "insert into sku_safety_stock (sku_id, warehouse_id, safety_stock_qty) values (@skuId, @warehouseId, @qty);",
            ("@skuId", skuId),
            ("@warehouseId", warehouseId),
            ("@qty", safetyStockQty));
    }

    private static async Task UpdateSkuPriceAsync(MySqlConnection connection, int skuId, decimal price)
    {
        await ExecuteAsync(connection, "update sku set price = @price where id = @skuId;", ("@price", price), ("@skuId", skuId));
    }

    private static async Task<int> EnsureCustomerAsync(MySqlConnection connection, string customerName)
    {
        var existingId = await ScalarIntOrNullAsync(
            connection,
            "select id from customer where customer_name = @name and tenant_id = 1 limit 1;",
            ("@name", customerName));
        if (existingId.HasValue)
        {
            return existingId.Value;
        }

        return await InsertScalarAsync(
            connection,
            "insert into customer (customer_name, city, address, creator, tenant_id, create_time, last_update_time, is_valid) values (@name, '测试城市', '测试地址', 'e2e', 1, now(), now(), 1); select last_insert_id();",
            ("@name", customerName));
    }

    private static string Value(IReadOnlyDictionary<string, string> row, string key, string fallback)
    {
        return row.TryGetValue(key, out var value) && !string.IsNullOrWhiteSpace(value) ? value : fallback;
    }

    private static bool HasValue(IReadOnlyDictionary<string, string> row, string key)
    {
        return row.TryGetValue(key, out var value) && !string.IsNullOrWhiteSpace(value);
    }

    private static int IntValue(IReadOnlyDictionary<string, string> row, string key, int fallback)
    {
        return HasValue(row, key) ? int.Parse(row[key], CultureInfo.InvariantCulture) : fallback;
    }

    private static decimal DecimalValue(IReadOnlyDictionary<string, string> row, string key, decimal fallback)
    {
        return HasValue(row, key) ? decimal.Parse(row[key], CultureInfo.InvariantCulture) : fallback;
    }

    private static bool BoolValue(IReadOnlyDictionary<string, string> row, string key, bool fallback)
    {
        return HasValue(row, key) ? bool.Parse(row[key]) : fallback;
    }

    private static DateTime DateValue(IReadOnlyDictionary<string, string> row, string key, DateTime fallback)
    {
        return HasValue(row, key)
            ? DateTime.Parse(row[key], CultureInfo.InvariantCulture, DateTimeStyles.AssumeLocal | DateTimeStyles.AllowWhiteSpaces)
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

    private static async Task<int?> ScalarIntOrNullAsync(MySqlConnection connection, string sql, params (string Name, object Value)[] parameters)
    {
        await using var command = new MySqlCommand(sql, connection);
        foreach (var parameter in parameters)
        {
            command.Parameters.AddWithValue(parameter.Name, parameter.Value);
        }

        var result = await command.ExecuteScalarAsync();
        return result is null or DBNull ? null : Convert.ToInt32(result, CultureInfo.InvariantCulture);
    }

    private static async Task ExecuteAsync(MySqlConnection connection, string sql, params (string Name, object Value)[] parameters)
    {
        await using var command = new MySqlCommand(sql, connection);
        foreach (var parameter in parameters)
        {
            command.Parameters.AddWithValue(parameter.Name, parameter.Value);
        }

        await command.ExecuteNonQueryAsync();
    }
}
