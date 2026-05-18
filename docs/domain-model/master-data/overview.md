# 基础主数据上下文

> 全局视角见 [`../bounded-contexts.md`](../bounded-contexts.md) 与 [`../strategic-ddd-design.md`](../strategic-ddd-design.md)。本文只记录基础主数据上下文的本地知识。

## 1. 业务目标

为整个 ModernWMS 提供稳定的业务骨架：仓储空间、商品目录、货权归属以及交易对象定义。

这个上下文的价值不在于推进入库或出库状态，而在于为执行流程提供统一、可复用、可被依赖的标识与语义。

## 2. 范围 / 非范围

### 范围内

- 仓库、库区、库位拓扑
- 商品分类、SPU、SKU
- 货主、供应商、客户
- 安全库存阈值
- 会影响业务语义的主数据属性，例如库区类型

### 不在范围内

- 到货、卸货、分拣、上架
- 锁库、拣货、出库、签收
- 移库、冻结、盘点、调整
- 用户权限与菜单授权

## 3. 主要角色

| 角色 | 主要目标 |
| --- | --- |
| 基础资料管理员 | 建立仓储空间结构与业务主数据 |
| 库存控制员 | 维护安全库存等控制参数 |
| 其他执行岗位 | 读取这些主数据并按其语义执行流程 |

## 4. 关键旅程

1. **建立仓库拓扑**
   - `Warehouse -> Warehouse Area -> Goods Location`
   - 为后续上架、移库、拣货提供空间结构
2. **定义库区属性**
   - 例如拣货区、存储区、收货区、残次区、盘点区
   - 这些属性会影响库存语义，而不仅是前端展示
3. **建立商品目录**
   - `Category -> SPU -> SKU`
   - 让系统能以 SKU 作为入库、库存、出库的执行粒度
4. **建立货权与交易对象**
   - 货主、供应商、客户分别承担不同语义角色
5. **维护控制参数**
   - 例如 `SkuSafetyStockEntity` 的安全库存阈值

## 5. 核心模型

| 模型 | 业务含义 |
| --- | --- |
| `WarehouseEntity` | 仓库 |
| `WarehouseareaEntity` | 仓库中的功能区域 |
| `GoodslocationEntity` | 具体库位 |
| `GoodsownerEntity` | 库存货权归属方 |
| `SupplierEntity` | 入库来源方 |
| `CustomerEntity` | 出库去向方 |
| `CategoryEntity` | 商品分类 |
| `SpuEntity` | 商品主档 |
| `SkuEntity` | 实际库存管理与作业粒度 |
| `SkuSafetyStockEntity` | 安全库存阈值 |

## 6. 关键规则 / 不变量

- **库区属性是业务规则入口，不是装饰字段**
  - 例如残次区会影响库存可用性和破损统计语义
- **Goods Owner 不等于 Supplier 或 Customer**
  - 货主定义库存归属，供应商和客户分别定义入库来源与出库去向
- **SKU 才是执行粒度**
  - SPU 更偏商品目录组织；入库、库存、出库通常以 SKU 为核心
- **执行上下文对主数据是 Conformist 关系**
  - 入库、出库、库内作业必须接受这里定义的标识和语义

## 7. 上下游与协作

### 下游依赖方

- [`../inbound-execution/overview.md`](../inbound-execution/overview.md)
- [`../inventory-visibility/overview.md`](../inventory-visibility/overview.md)
- [`../internal-operations/overview.md`](../internal-operations/overview.md)
- [`../outbound-fulfillment/overview.md`](../outbound-fulfillment/overview.md)

### 协作方式

- 其他上下文直接引用主数据标识，例如 `goods_owner_id`、`sku_id`、`goods_location_id`
- 库区与库位语义会影响库存形成、库存解释和库存消耗规则
- 系统管理上下文决定谁能维护这些主数据

## 8. 代码入口

### 后端服务

- `backend/ModernWMS.WMS/Services/Warehouse/WarehouseService.cs`
- `backend/ModernWMS.WMS/Services/Warehousearea/WarehouseareaService.cs`
- `backend/ModernWMS.WMS/Services/Goodslocation/GoodslocationService.cs`
- `backend/ModernWMS.WMS/Services/GoodsOwner/GoodsownerService.cs`
- `backend/ModernWMS.WMS/Services/Sku/SpuService.cs`

### 前端页面

- `frontend/src/view/base/warehouseSetting/warehouseSetting.vue`
- `frontend/src/view/base/commodityManagement/commodityManagement.vue`
- `frontend/src/view/base/ownerOfCargo/*`
- `frontend/src/view/base/supplier/*`
- `frontend/src/view/base/customer/*`

## 9. 相关阅读

- [`../user-journeys.md`](../user-journeys.md)
- [`../bounded-contexts.md`](../bounded-contexts.md)
- [`../strategic-ddd-design.md`](../strategic-ddd-design.md)
