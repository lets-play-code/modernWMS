# ModernWMS 上下文概览

> 本文只保留系统级的上下文地图与边界说明，帮助读者先知道“系统有哪些上下文、彼此如何协作、哪些地方不能随便改”。具体上下文的本地旅程、状态、模型和规则，请直接查看本目录下对应上下文子目录中的 `overview.md`。

## 1. 先给结论

从当前代码结构和业务流程看，ModernWMS 至少可以稳定识别出 6 个业务上下文：

1. 基础主数据
2. 入库执行
3. 库存可视化
4. 库内作业
5. 出库履约
6. 系统管理

这些上下文当前仍共用：

- 后端工程 `ModernWMS.WMS`
- 数据库上下文 `SqlDBContext`
- 多张共享业务表

因此，这里的“上下文”首先是 **领域理解边界**，而不是已经物理拆分好的部署边界。

## 2. 上下文总览

| 上下文 | 主要职责 | 典型核心模型 | 本地文档 |
| --- | --- | --- | --- |
| 基础主数据 | 定义仓储空间、商品目录、货权和交易对象骨架 | `Warehouse*`、`Goodslocation`、`Goodsowner`、`Supplier`、`Customer`、`Category`、`Spu`、`Sku` | [`master-data/overview.md`](./master-data/overview.md) |
| 入库执行 | 把计划到货推进为实际上架库存 | `Asnmaster`、`Asn`、`Asnsort`、`Stock` | [`inbound-execution/overview.md`](./inbound-execution/overview.md) |
| 库存可视化 | 统一解释当前库存、可用量、冻结量、锁定量 | `Stock`、`SkuSafetyStock` | [`inventory-visibility/overview.md`](./inventory-visibility/overview.md) |
| 库内作业 | 在已有库存上执行移库、冻结、加工、盘点、调整 | `Stockmove`、`Stockfreeze`、`Stockprocess`、`Stocktaking`、`Stockadjust` | [`internal-operations/overview.md`](./internal-operations/overview.md) |
| 出库履约 | 把客户发货需求推进到签收结果 | `Dispatchlist`、`Dispatchpicklist`、`Freightfee` | [`outbound-fulfillment/overview.md`](./outbound-fulfillment/overview.md) |
| 系统管理 | 提供用户、权限、日志、公司、打印等通用能力 | `User`、`Rolemenu`、`Userrole`、`ActionLog`、`Company`、`PrintSolution` | [`system-management/overview.md`](./system-management/overview.md) |

## 3. 上下文关系图

```text
基础主数据
   │
   ├──> 入库执行 ───┐
   │                │
   ├──> 出库履约 ───┼──> 库存可视化
   │                │
   └──> 库内作业 ───┘

系统管理 ───────────> 所有上下文
```

### 关系解释

- **基础主数据**是所有执行上下文的上游
- **入库执行**负责形成库存
- **出库履约**负责承诺、锁定并消耗库存
- **库内作业**负责改变库存位置、状态和结构
- **库存可视化**负责统一解释库存当前状态
- **系统管理**为所有上下文提供通用支撑能力

## 4. 用 DDD 关系语言描述当前上下文地图

| 关系 | 说明 |
| --- | --- |
| 基础主数据 → 入库 / 出库 / 库内作业 | Conformist：执行上下文接受主数据的标识与定义 |
| 入库执行 ↔ 库存可视化 | Shared Kernel：通过 `StockEntity` 与库存层维度协作 |
| 出库履约 ↔ 库存可视化 | Shared Kernel：通过 `StockEntity` 与锁定量计算协作 |
| 库内作业 ↔ 库存可视化 | Shared Kernel：通过锁定量、冻结量和调整结果协作 |
| 系统管理 → 所有上下文 | Generic Subdomain：提供统一支撑能力 |

## 5. 当前实现中的共享核心

从代码实现看，以下概念已经形成事实上的共享核心：

- `StockEntity`
- `SkuEntity`
- `GoodslocationEntity`
- `GoodsownerEntity`
- `tenant_id` + `CurrentUser` 过滤规则

### 为什么要特别强调它们

因为多个上下文都直接依赖这些概念，而且依赖方式往往不是松耦合接口，而是：

- 直接查询同一张表
- 直接按同一组维度定位库存层
- 直接根据状态字段判断库存可用性

这意味着：

- 这些字段语义不能轻易变更
- 一个上下文里的小改动，可能会引发跨流程连锁影响
- 涉及库存层身份的变更，必须做跨上下文影响分析

## 6. 哪些需求通常归到哪个上下文

- 改“仓 / 库区 / 库位 / 货主 / 客户 / 供应商 / 商品” → [`基础主数据`](./master-data/overview.md)
- 改“到货、卸货、分拣、上架” → [`入库执行`](./inbound-execution/overview.md)
- 改“库存查询、可用量、安全库存、库龄、统计” → [`库存可视化`](./inventory-visibility/overview.md)
- 改“移库、冻结、加工、盘点、调整” → [`库内作业`](./internal-operations/overview.md)
- 改“发货、拣货、打包、称重、出库、签收” → [`出库履约`](./outbound-fulfillment/overview.md)
- 改“账号、角色、菜单、日志、打印” → [`系统管理`](./system-management/overview.md)

## 7. 新人阅读建议

### 如果你想先理解系统全景

1. 先看 [`user-journeys.md`](./user-journeys.md)
2. 再看本文，建立上下文地图
3. 然后看 [`strategic-ddd-design.md`](./strategic-ddd-design.md)
4. 遇到术语歧义时，再看 [`ubiquitous-language.md`](./ubiquitous-language.md)
5. 最后进入目标上下文文档

### 如果你已经知道自己要改哪个模块

1. 先看对应上下文文档
2. 再回看本文确认它与其他上下文的关系
3. 如果涉及共享内核，再看 [`strategic-ddd-design.md`](./strategic-ddd-design.md)
4. 如果涉及术语边界，再看 [`ubiquitous-language.md`](./ubiquitous-language.md)
