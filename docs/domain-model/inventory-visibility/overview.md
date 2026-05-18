# 库存可视化上下文

> 全局视角见 [`../user-journeys.md`](../user-journeys.md)、[`../bounded-contexts.md`](../bounded-contexts.md) 与 [`../strategic-ddd-design.md`](../strategic-ddd-design.md)。本文只记录库存可视化上下文的本地知识。

## 1. 业务目标

把分散在入库、出库和库内作业中的库存数量，统一解释成可以展示、承诺、预警和分析的库存视图。

这里的重点不是推进业务状态，而是回答：

- 当前到底有多少库存
- 其中多少可用、冻结、锁定
- 哪些库存正在被任务占用
- 哪些 SKU 触发了安全库存风险

## 2. 范围 / 非范围

### 范围内

- 库位库存视角
- SKU 汇总库存视角
- 可用量、冻结量、锁定量计算
- 库龄、安全库存、统计分析
- 对库存事实进行统一解释

### 不在范围内

- 直接创建 ASN 或发货单
- 直接修改库存层事实
- 用户权限与菜单授权

## 3. 主要角色

| 角色 | 主要目标 |
| --- | --- |
| 库存控制员 | 了解库存现状、识别风险、处理差异 |
| 出库专员 | 判断库存能否被承诺 |
| 管理者 | 查看库存汇总、库龄与安全库存信息 |

## 4. 主要视角

| 视角 | 含义 | 主要后端能力 |
| --- | --- | --- |
| 库位库存 | 按库位查看库存层分布 | `LocationStockPageAsync` |
| 库存汇总 | 按 SKU 汇总库存与控制信息 | `StockPageAsync` |

## 5. 核心模型

| 模型 | 业务含义 |
| --- | --- |
| `StockEntity` | 库存事实台账层 |
| `SkuSafetyStockEntity` | 安全库存阈值 |
| `StockService` | 对库存事实做统一解释的服务 |
| 只读协作模型 | `AsnEntity`、`DispatchlistEntity`、`DispatchpicklistEntity`、`StockprocessdetailEntity`、`StockmoveEntity` |

## 6. 关键规则 / 不变量

- **`Stock` 表示库存事实，`StockService` 表示库存解释器**
  - 两者职责不能混为一谈
- **可用库存不是库存总数**
  - 一个关键公式是：
  - `qty_available = stock - frozen - dispatch_locked - process_locked - move_locked`
- **库存解释必须考虑跨流程占用**
  - 仅看 `stock` 表本身不足以回答“还能不能承诺”
- **库存层维度必须保持一致**
  - 包括 `sku_id`、`goods_location_id`、`goods_owner_id`、`series_number`、`expiry_date`、`price`、`putaway_date`

## 7. 上下游与协作

### 上游输入方

- [`../inbound-execution/overview.md`](../inbound-execution/overview.md)：形成库存
- [`../internal-operations/overview.md`](../internal-operations/overview.md)：改变库存位置、状态和结构
- [`../outbound-fulfillment/overview.md`](../outbound-fulfillment/overview.md)：锁定并消耗库存

### 下游使用方

- 出库履约要依赖这里的可承诺解释
- 库存控制与分析页面依赖这里的统一视图

### 协作说明

与入库、出库、库内作业之间都属于基于 `StockEntity` 的 Shared Kernel 协作关系。

## 8. 代码入口

### 后端服务

- `backend/ModernWMS.WMS/Services/Stock/StockService.cs`

### 前端页面

- `frontend/src/view/wms/stockManagement/stockManagement.vue`
- `frontend/src/view/statisticAnalysis/*`

## 9. 相关阅读

- [`../bounded-contexts.md`](../bounded-contexts.md)
- [`../strategic-ddd-design.md`](../strategic-ddd-design.md)
- [`../internal-operations/overview.md`](../internal-operations/overview.md)
- [`../outbound-fulfillment/overview.md`](../outbound-fulfillment/overview.md)
