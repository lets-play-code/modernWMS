# ModernWMS 统一语言

> 本文沉淀 ModernWMS 中应长期稳定使用的业务术语。写需求、设计、任务说明、评审意见和长期文档时，应尽量复用这里的词汇，而不是为同一概念反复发明新名字。

## 1. 使用原则

- **一个概念尽量只用一个名字**
  - 例如已经使用 `Goods Owner`，就不要在别处混写成“库存所属客户”或“货权客户”而不加说明
- **术语优先沿用现有代码和页面语义**
  - 文档应帮助理解系统，而不是重新定义系统
- **目录名、文件名、章节名都应使用稳定术语**
  - 例如 `user-journeys.md`、`bounded-contexts.md`、`overview.md`
- **`README.md` 只用于目录级元信息**
  - 实际业务内容应使用有语义的文件名

## 2. 核心术语总表

| 术语 | 建议中文 | 在系统中的含义 | 主要代码映射 | 易混点 |
| --- | --- | --- | --- | --- |
| Warehouse | 仓库 | 仓储物理空间的最高层级 | `WarehouseEntity` | 不是库区，也不是库位 |
| Warehouse Area / Reservoir | 库区 / 功能区域 | 仓库中的功能区域，如拣货区、存储区、残次区 | `WarehouseareaEntity` | 前端有时会出现 `Reservoir`，语义上仍指库区 |
| Goods Location | 库位 | 具体存放货物的位置 | `GoodslocationEntity` | 不是仓库整体，也不是库区 |
| Goods Owner | 货主 | 库存货权归属方 | `GoodsownerEntity` | 不等于供应商，也不等于客户 |
| Supplier | 供应商 | 入库来源方 | `SupplierEntity` | 不负责定义库存归属 |
| Customer | 客户 | 出库去向方 | `CustomerEntity` | 不必然拥有库存 |
| Category | 商品分类 | 商品目录层级 | `CategoryEntity` | 不直接作为库存作业粒度 |
| SPU | 商品主档 | 商品抽象定义 | `SpuEntity` | 不等于实际库存管理粒度 |
| SKU | 商品规格 | 最小库存管理与作业粒度 | `SkuEntity` | 与 SPU 是上下层关系 |
| Safety Stock | 安全库存 | 库存预警阈值 | `SkuSafetyStockEntity` | 不是当前库存数量 |
| ASN / Arrival Notice | 到货通知明细 | 计划收货的明细行 | `AsnEntity` | 不等于已形成库存 |
| ASN Master | 到货通知单头 | 组织多条 ASN 明细的单头 | `AsnmasterEntity` | 与 `AsnEntity` 是主从关系 |
| ASN Sort | 分拣记录 | 分拣 / 批次 / 上架前细分记录 | `AsnsortEntity` | 不是库存层本身 |
| Stock | 库存层 / 库存事实 | 一层被多维度限定的库存事实 | `StockEntity` | 不是简单汇总库存 |
| Available Stock | 可用库存 | 扣除冻结与锁定后的可承诺库存 | `StockService` 计算结果 | 不是 `qty` 原值 |
| Frozen Stock | 冻结库存 | 由于冻结动作不可直接承诺的库存 | `StockEntity.is_freeze` 等语义 | 与锁定库存不同 |
| Locked Stock | 锁定库存 | 被出库、移库、加工等任务占用的库存 | `Dispatchpicklist`、`Stockmove`、`Stockprocess` 等 | 与冻结库存不同 |
| Dispatch List | 发货明细 / 出库明细 | 出库履约主工作单元 | `DispatchlistEntity` | 当前没有独立 `DispatchmasterEntity` |
| Dispatch Pick List | 拣货明细 | 从哪一层库存拣了多少的事实记录 | `DispatchpicklistEntity` | 不是发货单头 |
| Freight Fee | 运费信息 | 承运与运费相关信息 | `FreightfeeEntity` | 不属于库存核心语义 |
| Stock Move | 移库任务 | 将库存从一个库位移动到另一个库位的任务 | `StockmoveEntity` | 先建任务，再确认执行 |
| Stock Freeze | 冻结任务 | 改变库存可用性的任务 | `StockfreezeEntity` | 不等于锁库 |
| Stock Taking | 盘点任务 | 对比账面与实物的任务 | `StocktakingEntity` | 盘点本身不等于正式入账 |
| Stock Adjust | 调整凭证 | 把盘点等差异正式入账 | `StockadjustEntity` | 通常是盘点后的后续动作 |
| Stock Process | 加工任务 | 组合 / 拆分等库存结构变换任务 | `StockprocessEntity` | 不是直接改库存的随手动作 |
| Action Log | 操作日志 | 审计关键业务动作的记录 | `ActionLog` | 不承载业务规则 |
| Print Solution | 打印方案 | 标签 / 单据输出配置 | `PrintSolution` | 是支撑能力，不是领域核心 |

## 3. 最重要的几个概念边界

### 3.1 Goods Owner ≠ Supplier ≠ Customer

这三个词在日常交流里最容易被混用，但在系统里语义不同：

| 术语 | 语义 |
| --- | --- |
| Goods Owner | 库存归谁所有 |
| Supplier | 这批货从哪里来 |
| Customer | 这批货将发到哪里去 |

因此：

- 同一个供应商不一定是货主
- 同一个客户不一定拥有库存
- 讨论库存归属时，应优先说 **Goods Owner / 货主**

### 3.2 SPU ≠ SKU

| 术语 | 语义 |
| --- | --- |
| SPU | 商品主档，偏目录组织 |
| SKU | 规格层级，偏库存与作业执行 |

在 ModernWMS 中，真正与入库、库存、出库强相关的是 **SKU**。

### 3.3 Stock 不是“库存总数”

在 ModernWMS 中，`Stock` 更接近“库存层 / 库存事实”，而不是简单余额。

库存层通常由以下维度共同识别：

- `sku_id`
- `goods_location_id`
- `goods_owner_id`
- `series_number`
- `expiry_date`
- `price`
- `putaway_date`

因此在讨论库存时，要区分：

- **库存事实层**：`StockEntity`
- **库存汇总视图**：按 SKU 或库位聚合后的展示结果
- **可用库存**：经过冻结和锁定计算后的承诺结果

### 3.4 冻结（Freeze）≠ 锁定（Lock）

| 术语 | 语义 |
| --- | --- |
| Freeze | 改变库存可用性，通常是显式控制动作 |
| Lock | 被某个执行任务暂时占用 |

所以：

- 冻结是库存状态控制
- 锁定是库存任务占用
- 两者都会影响可用库存，但原因不同

### 3.5 Dispatch List ≠ Dispatch Pick List

| 术语 | 语义 |
| --- | --- |
| Dispatch List | 发货需求明细 |
| Dispatch Pick List | 实际从哪些库存层拣货 |

当前系统里：

- `dispatch_no` 承担逻辑聚合作用
- `DispatchlistEntity` 代表业务需求明细
- `DispatchpicklistEntity` 代表库存分配与拣货事实

### 3.6 盘点（Taking）≠ 调整（Adjust）

| 术语 | 语义 |
| --- | --- |
| Stock Taking | 记录账面与实物的差异 |
| Stock Adjust | 把差异正式入账 |

写需求和设计时，不应把“盘点完成”和“调整入账”混成同一个动作。

## 4. 推荐在文档中如何称呼

### 4.1 推荐写法

- 仓库 / Warehouse
- 库区 / Warehouse Area
- 库位 / Goods Location
- 货主 / Goods Owner
- 到货通知单头 / ASN Master
- 到货通知明细 / ASN
- 分拣记录 / ASN Sort
- 库存层 / Stock
- 发货明细 / Dispatch List
- 拣货明细 / Dispatch Pick List
- 移库任务 / Stock Move
- 盘点任务 / Stock Taking
- 调整凭证 / Stock Adjust

### 4.2 不推荐写法

- 用“库存”同时指代库存层、库存汇总、可用库存三种概念
- 用“客户”代替“货主”
- 用“商品”代替 `SKU` 而不区分 SPU / SKU
- 用“出库单”泛指 `dispatch_no`、`DispatchlistEntity`、`DispatchpicklistEntity`

## 5. 文件与章节命名建议

当文档是内容文档时，优先使用有语义的名字：

- `overview.md`
- `user-journeys.md`
- `bounded-contexts.md`
- `strategic-ddd-design.md`
- `state-machine.md`
- `rules.md`
- `aggregates-and-invariants.md`

当文档是目录级元信息时，再使用 `README.md`：

- 说明本目录放什么
- 说明推荐阅读顺序
- 说明文档如何拆分和维护

## 6. 什么时候应该回看这份文档

遇到以下情况时，应优先回看本文：

- 同一个词在不同文档里好像含义不一致
- 需求描述里混用了“货主 / 供应商 / 客户”
- 讨论库存时分不清“库存层 / 汇总库存 / 可用库存”
- 新建文档时不确定文件名是否应该用 `README.md`
- 评审时发现命名含糊，难以判断是否是同一个概念
