# ModernWMS 用户旅程总览

> 本文只保留系统级的端到端旅程，帮助新人先建立业务闭环认知。具体上下文的本地旅程、状态机、模型和规则，请直接查看本目录下对应上下文子目录中的 `overview.md`。

## 1. 这套系统服务谁

ModernWMS 面向的是以仓储执行为中心的业务团队。系统中的“角色”更多是由菜单和作业分工体现，而不是独立的领域对象。

| 角色 | 主要目标 | 重点上下文 |
| --- | --- | --- |
| 基础资料管理员 | 维护仓库、库区、库位、货主、供应商、客户、商品 | [`基础主数据`](./master-data/overview.md) |
| 入库专员 | 创建到货通知、确认到货、卸货、分拣、上架 | [`入库执行`](./inbound-execution/overview.md) |
| 出库专员 | 创建发货单、锁定库存、拣货、打包、称重、出库、签收 | [`出库履约`](./outbound-fulfillment/overview.md) |
| 库内作业员 | 移库、冻结/解冻、加工、盘点 | [`库内作业`](./internal-operations/overview.md) |
| 库存控制员 | 查看库存、处理差异、确认调整 | [`库存可视化`](./inventory-visibility/overview.md) |
| 系统管理员 | 用户、角色、菜单、日志、公司信息、打印方案 | [`系统管理`](./system-management/overview.md) |

## 2. 端到端主闭环

ModernWMS 的主闭环可以概括为：

```text
[基础主数据]
      ↓
[入库执行] ──形成──> [库存事实 / Stock]
      │                    │
      │                    ├──> [库存可视化]
      │                    ├──> [库内作业]
      │                    └──> [出库履约]
      │
[系统管理] ───────────────> 所有上下文
```

如果从业务结果来理解，就是：

1. 先把仓、货、货主、客户等骨架建起来
2. 再把计划到货推进为实际上架后的库存
3. 持续解释库存、控制库存、调整库存
4. 最后把库存从发货需求推进到签收完成
5. 全过程由权限、菜单、日志和打印能力支撑

## 3. 六个主要旅程阶段

### 3.1 基础主数据：先建立业务骨架

在真正收货和发货前，系统要先具备：

- 仓库、库区、库位拓扑
- 商品分类、SPU、SKU
- 货主、供应商、客户
- 安全库存等控制参数

这一步的产出不是库存，而是后续所有执行流程都依赖的业务语义。

详见：[`master-data/overview.md`](./master-data/overview.md)

### 3.2 入库执行：把计划到货推进为库存事实

入库旅程的主线是：

- 到货通知
- 确认到货
- 卸货
- 分拣
- 上架

关键结果是形成 `StockEntity`，而不是仅仅把单据状态改成“已完成”。

详见：[`inbound-execution/overview.md`](./inbound-execution/overview.md)

### 3.3 库存可视化：把库存事实解释成可承诺视图

库存页面看到的不只是库存总量，还包括：

- 可用库存
- 冻结库存
- 锁定库存
- 安全库存
- 库龄与统计信息

也就是说，这个阶段更像“库存解释器”，而不是“库存录入器”。

详见：[`inventory-visibility/overview.md`](./inventory-visibility/overview.md)

### 3.4 库内作业：在已有库存上持续处理和校正

当库存已经存在后，仓内还会持续发生：

- 移库
- 冻结 / 解冻
- 组合 / 拆分加工
- 盘点
- 调整

这一步的核心价值是维持库存的可用性、准确性和可追踪性。

详见：[`internal-operations/overview.md`](./internal-operations/overview.md)

### 3.5 出库履约：把客户需求推进到签收结果

出库旅程的主线是：

- 创建发货单
- 锁定库存
- 拣货
- 打包
- 称重
- 出库
- 签收

一个关键点是：**锁库不等于扣库**，真正扣减库存发生在 `Delivery()`。

详见：[`outbound-fulfillment/overview.md`](./outbound-fulfillment/overview.md)

### 3.6 系统管理：为所有旅程提供统一支撑

系统管理不是仓储执行主线的一部分，但它横切所有旅程：

- 决定谁能进入哪个页面
- 决定谁能执行哪个动作
- 记录操作日志
- 提供公司信息和打印方案

详见：[`system-management/overview.md`](./system-management/overview.md)

## 4. 新人建议阅读路径

### 路径 A：先看全局再入模块

1. 阅读本文，建立业务闭环认知
2. 阅读 [`bounded-contexts.md`](./bounded-contexts.md)，理解边界与关系
3. 阅读 [`strategic-ddd-design.md`](./strategic-ddd-design.md)，理解核心域和共享内核
4. 阅读 [`ubiquitous-language.md`](./ubiquitous-language.md)，统一术语和概念
5. 进入目标上下文文档继续深入

### 路径 B：按当前负责模块进入

如果你已经知道自己负责哪个模块：

1. 先看对应上下文文档
2. 再回看 [`bounded-contexts.md`](./bounded-contexts.md)，确认它和其他上下文的关系
3. 遇到术语歧义时，看 [`ubiquitous-language.md`](./ubiquitous-language.md)
4. 涉及跨上下文规则时，再回看 [`strategic-ddd-design.md`](./strategic-ddd-design.md)

## 5. 常见问题导航

- 想知道“系统整体怎么跑起来” → 先看本文
- 想知道“这个需求属于哪个上下文” → 看 [`bounded-contexts.md`](./bounded-contexts.md)
- 想知道“为什么库存是系统中心” → 看 [`strategic-ddd-design.md`](./strategic-ddd-design.md)
- 想知道“某个模块具体有哪些状态和规则” → 直接看对应上下文目录下的 `overview.md`
- 想知道“同一个词在系统里到底是什么意思” → 看 [`ubiquitous-language.md`](./ubiquitous-language.md)
