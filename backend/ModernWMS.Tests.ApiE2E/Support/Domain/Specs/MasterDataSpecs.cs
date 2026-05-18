using ModernWMS.Tests.ApiE2E.Support;
using MySqlConnector;

namespace ModernWMS.Tests.ApiE2E.Support.Domain.Specs;

public sealed class WarehouseAndSkuSpec : DomainSpec
{
    public override string Name => "仓库和SKU";

    public override async Task CreateAsync(DomainSpecInput input, ScenarioDataContext context)
    {
        await using var connection = await ModernWmsApiHost.OpenDatabaseConnectionAsync();
        foreach (var row in input.Rows)
        {
            await MasterDataBuilder.EnsureAsync(connection, row, context);
        }
    }
}

internal static class MasterDataBuilder
{
    public static async Task<MasterDataIds> EnsureAsync(
        MySqlConnection connection,
        IReadOnlyDictionary<string, string> row,
        ScenarioDataContext context)
    {
        var warehouse = Value(row, "warehouse.name", $"WH-{Guid.NewGuid():N}"[..10]);
        var area = Value(row, "area.name", $"AREA-{Guid.NewGuid():N}"[..12]);
        var location = Value(row, "location.code", $"LOC-{Guid.NewGuid():N}"[..12]);
        var owner = Value(row, "goods_owner.name", "练习货主");
        var supplier = Value(row, "supplier.name", "练习供应商");
        var customer = Value(row, "customer.name", "练习客户");
        var category = Value(row, "category.name", "练习分类");
        var spu = Value(row, "spu.code", $"SPU-{Guid.NewGuid():N}"[..12]);
        var sku = Value(row, "sku.code", $"SKU-{Guid.NewGuid():N}"[..12]);
        var areaProperty = int.Parse(Value(row, "area.property", "1"));

        var warehouseId = await EnsureWarehouseAsync(connection, warehouse);
        var areaId = await EnsureAreaAsync(connection, warehouseId, area, areaProperty);
        var locationId = await EnsureLocationAsync(connection, warehouseId, warehouse, areaId, area, areaProperty, location);
        var ownerId = await EnsureNamedAsync(connection, "goodsowner", "goods_owner_name", owner);
        var supplierId = await EnsureNamedAsync(connection, "supplier", "supplier_name", supplier);
        var customerId = await EnsureNamedAsync(connection, "customer", "customer_name", customer);
        var categoryId = await EnsureCategoryAsync(connection, category);
        var spuId = await EnsureSpuAsync(connection, spu, categoryId, supplierId, supplier);
        var skuId = await EnsureSkuAsync(connection, sku, spuId);

        var ids = new MasterDataIds(warehouseId, areaId, locationId, ownerId, supplierId, customerId, categoryId, spuId, skuId);
        Track(context, row, ids, warehouse, area, location, owner, supplier, customer, category, spu, sku);
        return ids;
    }

    private static void Track(
        ScenarioDataContext context,
        IReadOnlyDictionary<string, string> row,
        MasterDataIds ids,
        string warehouse,
        string area,
        string location,
        string owner,
        string supplier,
        string customer,
        string category,
        string spu,
        string sku)
    {
        TrackValue(context, "warehouse.id", ids.WarehouseId);
        TrackValue(context, "warehouse.name", warehouse);
        TrackValue(context, "area.id", ids.AreaId);
        TrackValue(context, "area.name", area);
        TrackValue(context, "location.id", ids.LocationId);
        TrackValue(context, "location.code", location);
        TrackValue(context, "goods_owner.id", ids.GoodsOwnerId);
        TrackValue(context, "goods_owner.name", owner);
        TrackValue(context, "supplier.id", ids.SupplierId);
        TrackValue(context, "supplier.name", supplier);
        TrackValue(context, "customer.id", ids.CustomerId);
        TrackValue(context, "customer.name", customer);
        TrackValue(context, "category.id", ids.CategoryId);
        TrackValue(context, "category.name", category);
        TrackValue(context, "spu.id", ids.SpuId);
        TrackValue(context, "spu.code", spu);
        TrackValue(context, "sku.id", ids.SkuId);
        TrackValue(context, "sku.code", sku);

        TrackAlias(context, row, "warehouse.key", "warehouse", ("id", ids.WarehouseId.ToString()), ("name", warehouse));
        TrackAlias(context, row, "area.key", "area", ("id", ids.AreaId.ToString()), ("name", area));
        TrackAlias(context, row, "location.key", "location", ("id", ids.LocationId.ToString()), ("code", location));
        TrackAlias(context, row, "goods_owner.key", "goods_owner", ("id", ids.GoodsOwnerId.ToString()), ("name", owner));
        TrackAlias(context, row, "supplier.key", "supplier", ("id", ids.SupplierId.ToString()), ("name", supplier));
        TrackAlias(context, row, "customer.key", "customer", ("id", ids.CustomerId.ToString()), ("name", customer));
        TrackAlias(context, row, "category.key", "category", ("id", ids.CategoryId.ToString()), ("name", category));
        TrackAlias(context, row, "spu.key", "spu", ("id", ids.SpuId.ToString()), ("code", spu));
        TrackAlias(context, row, "sku.key", "sku", ("id", ids.SkuId.ToString()), ("code", sku));
    }

    private static void TrackValue(ScenarioDataContext context, string key, object value)
    {
        context.Track(key, value.ToString()!);
    }

    private static void TrackAlias(
        ScenarioDataContext context,
        IReadOnlyDictionary<string, string> row,
        string aliasKey,
        string prefix,
        params (string Suffix, string Value)[] values)
    {
        if (!row.TryGetValue(aliasKey, out var alias) || string.IsNullOrWhiteSpace(alias))
        {
            return;
        }

        foreach (var (suffix, value) in values)
        {
            context.Track($"{prefix}.{alias}.{suffix}", value);
        }
    }

    private static async Task<int> EnsureWarehouseAsync(MySqlConnection connection, string name)
    {
        var id = await FindIdAsync(connection, "select id from warehouse where warehouse_name=@name and tenant_id=1", Param("@name", name));
        if (id > 0) return id;
        return await InsertAsync(connection, "insert into warehouse (warehouse_name, city, address, creator, tenant_id) values (@name, '测试城市', '测试地址', 'e2e', 1); select last_insert_id();", Param("@name", name));
    }

    private static async Task<int> EnsureAreaAsync(MySqlConnection connection, int warehouseId, string name, int property)
    {
        var id = await FindIdAsync(connection, "select id from warehousearea where warehouse_id=@warehouseId and area_name=@name and tenant_id=1", Param("@warehouseId", warehouseId), Param("@name", name));
        if (id > 0) return id;
        return await InsertAsync(connection, "insert into warehousearea (warehouse_id, area_name, area_property, tenant_id) values (@warehouseId, @name, @property, 1); select last_insert_id();", Param("@warehouseId", warehouseId), Param("@name", name), Param("@property", property));
    }

    private static async Task<int> EnsureLocationAsync(MySqlConnection connection, int warehouseId, string warehouse, int areaId, string area, int property, string location)
    {
        var id = await FindIdAsync(connection, "select id from goodslocation where location_name=@location and tenant_id=1", Param("@location", location));
        if (id > 0) return id;
        return await InsertAsync(connection, "insert into goodslocation (warehouse_id, warehouse_name, warehouse_area_id, warehouse_area_name, warehouse_area_property, location_name, tenant_id) values (@warehouseId, @warehouse, @areaId, @area, @property, @location, 1); select last_insert_id();", Param("@warehouseId", warehouseId), Param("@warehouse", warehouse), Param("@areaId", areaId), Param("@area", area), Param("@property", property), Param("@location", location));
    }

    private static async Task<int> EnsureNamedAsync(MySqlConnection connection, string table, string column, string name)
    {
        var id = await FindIdAsync(connection, $"select id from {table} where {column}=@name and tenant_id=1", Param("@name", name));
        if (id > 0) return id;
        return await InsertAsync(connection, $"insert into {table} ({column}, city, address, creator, tenant_id) values (@name, '测试城市', '测试地址', 'e2e', 1); select last_insert_id();", Param("@name", name));
    }

    private static async Task<int> EnsureCategoryAsync(MySqlConnection connection, string name)
    {
        var id = await FindIdAsync(connection, "select id from category where category_name=@name and tenant_id=1", Param("@name", name));
        if (id > 0) return id;
        return await InsertAsync(connection, "insert into category (category_name, creator, tenant_id) values (@name, 'e2e', 1); select last_insert_id();", Param("@name", name));
    }

    private static async Task<int> EnsureSpuAsync(MySqlConnection connection, string code, int categoryId, int supplierId, string supplier)
    {
        var id = await FindIdAsync(connection, "select id from spu where spu_code=@code and tenant_id=1", Param("@code", code));
        if (id > 0) return id;
        return await InsertAsync(connection, "insert into spu (spu_code, spu_name, category_id, supplier_id, supplier_name, creator, tenant_id) values (@code, @code, @categoryId, @supplierId, @supplier, 'e2e', 1); select last_insert_id();", Param("@code", code), Param("@categoryId", categoryId), Param("@supplierId", supplierId), Param("@supplier", supplier));
    }

    private static async Task<int> EnsureSkuAsync(MySqlConnection connection, string code, int spuId)
    {
        var id = await FindIdAsync(connection, "select id from sku where sku_code=@code", Param("@code", code));
        if (id > 0) return id;
        return await InsertAsync(connection, "insert into sku (spu_id, sku_code, sku_name, unit, bar_code) values (@spuId, @code, @code, 'EA', @code); select last_insert_id();", Param("@spuId", spuId), Param("@code", code));
    }

    private static string Value(IReadOnlyDictionary<string, string> row, string key, string fallback)
    {
        return row.TryGetValue(key, out var value) && !string.IsNullOrWhiteSpace(value) ? value : fallback;
    }

    private static async Task<int> FindIdAsync(MySqlConnection connection, string sql, params MySqlParameter[] parameters)
    {
        await using var command = new MySqlCommand(sql, connection);
        command.Parameters.AddRange(parameters);
        var result = await command.ExecuteScalarAsync();
        return result is null ? 0 : Convert.ToInt32(result);
    }

    private static async Task<int> InsertAsync(MySqlConnection connection, string sql, params MySqlParameter[] parameters)
    {
        await using var command = new MySqlCommand(sql, connection);
        command.Parameters.AddRange(parameters);
        return Convert.ToInt32(await command.ExecuteScalarAsync());
    }

    private static MySqlParameter Param(string name, object value) => new(name, value);
}

internal sealed record MasterDataIds(
    int WarehouseId,
    int AreaId,
    int LocationId,
    int GoodsOwnerId,
    int SupplierId,
    int CustomerId,
    int CategoryId,
    int SpuId,
    int SkuId);
