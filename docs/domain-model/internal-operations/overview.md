# 库内作业上下文

> 全局视角见 [`../user-journeys.md`](../user-journeys.md)、[`../bounded-contexts.md`](../bounded-contexts.md) 与 [`../strategic-ddd-design.md`](../strategic-ddd-design.md)。本文只记录库内作业上下文的本地知识。

## 1. 业务目标

在库存已经存在的前提下，对库存进行仓内处理，使库存位置、状态、结构与账面结果保持可追踪、可控制、可校正。

它解决的问题不是“有没有库存”，而是“已有库存如何在仓内被处理”。

## 2. 范围 / 非范围

### 范围内

- 移库
- 冻结 / 解冻
- 组合 / 拆分加工
- 盘点
- 调整

### 不在范围内

- 计划到货与上架形成库存
- 发货锁库、打包、出库、签收
- 用户权限与菜单授权
- 独立的库存解释展示

## 3. 主要角色

| 角色 | 主要目标 |
| --- | --- |
| 库内作业员 | 执行移库、冻结、加工、盘点等任务 |
| 库存控制员 | 处理差异、确认调整、维持账实一致 |

## 4. 子能力概览

| 子能力 | 主要模型 | 作用 |
| --- | --- | --- |
| 移库 | `StockmoveEntity` | 改变库存所在库位 |
| 冻结 / 解冻 | `StockfreezeEntity` | 改变库存可用性 |
| 组合 / 拆分加工 | `StockprocessEntity`、`StockprocessdetailEntity` | 改变库存结构或形态 |
| 盘点 | `StocktakingEntity` | 比较账面与实物 |
| 调整 | `StockadjustEntity` | 把差异正式入账 |

## 5. 共同作业模式

库内作业的共同建模方式不是“直接改库存”，而是：

1. 先形成作业单或任务
2. 再推进确认动作
3. 最后影响库存事实或库存可用性

这意味着库内作业是 **库存驱动** 而不是 **订单驱动**。

## 6. 关键规则 / 不变量

- **先有库存层，后有库内作业任务**
- **多数动作先建任务，再确认执行**
  - 例如移库先创建任务，再确认扣减源库位并累加目标库位
- **冻结前必须考虑其他锁定关系**
  - 库存可能已经被加工、出库拣货、移库等任务占用
- **盘点与调整是两个动作**
  - 盘点记录差异，调整负责正式入账
- **库内作业与库存可视化高度耦合**
  - 锁定量、冻结量、调整结果都会改变库存解释

## 7. 上下游与协作

### 上游依赖方

- [`../master-data/overview.md`](../master-data/overview.md)
- [`../inbound-execution/overview.md`](../inbound-execution/overview.md)

### 强协作方

- [`../inventory-visibility/overview.md`](../inventory-visibility/overview.md)
- [`../outbound-fulfillment/overview.md`](../outbound-fulfillment/overview.md)

### 协作说明

- 与库存可视化通过锁定量、冻结量和调整结果形成 Shared Kernel 关系
- 与出库履约共享同一库存事实，因此变更库存语义时要做跨上下文影响分析

## 8. 代码入口

### 后端服务

- `backend/ModernWMS.WMS/Services/Stockmove/StockmoveService.cs`
- `backend/ModernWMS.WMS/Services/Stockfreeze/StockfreezeService.cs`
- `backend/ModernWMS.WMS/Services/Stockprocess/StockprocessService.cs`
- `backend/ModernWMS.WMS/Services/Stocktaking/StocktakingService.cs`
- `backend/ModernWMS.WMS/Services/Stockadjust/StockadjustService.cs`

### 前端页面

- `frontend/src/view/warehouseWorking/warehouseMove/warehouseMove.vue`
- `frontend/src/view/warehouseWorking/warehouseTaking/warehouseTaking.vue`
- `frontend/src/view/warehouseWorking/*`

## 9. 相关阅读

- [`../bounded-contexts.md`](../bounded-contexts.md)
- [`../strategic-ddd-design.md`](../strategic-ddd-design.md)
- [`../inventory-visibility/overview.md`](../inventory-visibility/overview.md)
