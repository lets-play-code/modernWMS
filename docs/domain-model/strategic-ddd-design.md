# ModernWMS DDD 战略设计

> 本文不是把现有代码“硬包装成 DDD”，而是基于当前源码实际结构，总结出更适合长期维护的领域战略视角。
>
> 文档分工说明：本文只保留系统级战略判断。具体上下文的本地旅程、状态机、模型与规则，请转到各上下文子目录中的 `overview.md`；术语定义请看 [`ubiquitous-language.md`](./ubiquitous-language.md)。

## 1. 领域使命

ModernWMS 的核心使命可以概括为一句话：

**在中小仓储场景下，让库存从“计划收货”到“实际出库”全过程可执行、可追踪、可校正。**

从代码上看，系统不是围绕销售订单、采购订单或财务结算展开，而是围绕以下三件事展开：

1. 库存如何形成
2. 库存现在是否可用
3. 库存如何被消耗或校正

因此，它更像一个**执行型仓储系统（Execution-oriented WMS）**，而不是 ERP 中的订单主系统。

---

## 2. 核心域、支撑域、通用域划分

### 2.1 Core Domain（核心域）

这些能力最直接体现 ModernWMS 的业务价值：

| 子域 | 原因 | 关键组件 |
| --- | --- | --- |
| 入库执行 | 决定库存如何形成 | `AsnService.cs`、`stockAsn.vue` |
| 出库履约 | 决定库存如何被承诺、拣取、发出、签收 | `DispatchlistService.cs`、`deliveryManagement.vue` |
| 库存可用性计算 | 决定系统能否正确承诺库存 | `StockService.cs` |
| 库存准确性维护 | 决定账实一致与可运营性 | `StockmoveService.cs`、`StocktakingService.cs`、`StockprocessService.cs`、`StockfreezeService.cs` |

### 2.2 Supporting Subdomain（支撑域）

这些能力不是系统独特价值的核心，但没有它们核心域无法稳定运行：

| 子域 | 作用 | 关键组件 |
| --- | --- | --- |
| 基础主数据 | 提供仓、商品、货权、交易对象骨架 | `WarehouseService.cs`、`SpuService.cs`、`GoodsownerService.cs` 等 |
| 运费与承运信息 | 支撑发货后的物流信息维护 | `FreightfeeService.cs` |
| 打印方案 | 支撑标签 / 单据输出 | `PrintSolutionService.cs` |
| 统计分析 | 提供管理视角的二次信息 | `StockService.cs` 中的统计方法、前端 `statisticAnalysis/*` |

### 2.3 Generic Subdomain（通用域）

这些能力几乎所有业务系统都会有：

| 子域 | 关键组件 |
| --- | --- |
| 登录认证 / Token | `ModernWMS.Core.JWT/*` |
| 用户 / 角色 / 菜单 | `UserService.cs`、`RolemenuService.cs`、`UserroleService.cs` |
| 操作日志 | `ActionLogService.cs` |
| 公司信息 | `CompanyService.cs` |

---

## 3. 统一语言（摘要）

统一语言已独立整理到 [`ubiquitous-language.md`](./ubiquitous-language.md)。战略设计层面只强调两个最关键判断：

1. **团队应优先复用既有术语，而不是为同一概念反复发明新名字**
2. **`Stock` 不是简单库存余额，而是一层被多维度限定的库存事实**

其中第二点尤为关键。库存层通常由以下维度识别：

- `sku_id`
- `goods_location_id`
- `goods_owner_id`
- `series_number`
- `expiry_date`
- `price`
- `putaway_date`

这决定了 ModernWMS 的库存概念更接近“库存层 / 库存批次层”，而不是简单库存余额。后续讨论若出现术语歧义，应先回到 [`ubiquitous-language.md`](./ubiquitous-language.md) 统一概念。

---

## 4. 战略级聚合视角

虽然当前代码主要把行为写在 Service 层，但从领域角度仍然能识别出较稳定的聚合轮廓。

### 4.1 仓储空间聚合

**候选聚合：`Warehouse -> Warehouse Area -> Goods Location`**

业务意义：
- 定义物理空间结构
- 定义库位所属仓、所属库区、所属区域属性
- 由区域类型影响库存语义

证据：
- `WarehouseService.UpdateAsync()` 会联动更新下游区域 / 库位可用性与名称
- `WarehouseareaService.UpdateAsync()` 会联动更新库位的 `warehouse_area_name` 与 `warehouse_area_property`

这说明仓储空间不是三个毫无关系的主数据表，而是一个有层级语义的结构聚合。

### 4.2 商品目录聚合

**候选聚合：`Category -> SPU -> SKU -> Safety Stock`**

业务意义：
- 用分类组织商品
- 用 SPU 表示商品主档
- 用 SKU 表示实际库存和作业粒度
- 用安全库存定义仓级补货阈值

证据：
- `SpuEntity.detailList` 持有 `SkuEntity`
- `SkuEntity.detailList` 持有 `SkuSafetyStockEntity`
- `commodityManagement.vue` 直接以树状方式展示 SPU / SKU

### 4.3 入库执行聚合

**候选聚合：`Asnmaster -> Asn -> Asnsort`**

业务意义：
- 单头记录一批到货业务
- 明细行承载 SKU、数量、货主、供应商等具体事实
- 分拣记录承载更细的序列号 / 分拣 / 上架分摊信息

证据：
- `AsnmasterEntity.detailList`
- `AsnService` 里的 `Confirm -> Unload -> Sorting -> Sorted -> PutAway` 连续状态推进

关键不变量：
- 未完成分拣前不能上架
- 上架数量不能超过已分拣数量
- 上架后会产生或累加库存层

### 4.4 库存层聚合

**候选聚合：`Stock`**

业务意义：
- 它是多个业务过程共同读写的事实台账
- 是“可用库存”“冻结库存”“锁定库存”的计算基础

关键不变量：
- 同一库存层必须由固定维度组合识别
- 出库、移库、盘点、调整都不能破坏该层的可追踪性

### 4.5 出库履约聚合

**候选聚合：`Dispatch(no) -> Dispatchlist lines -> Dispatchpicklist`**

业务意义：
- 发货单号是逻辑聚合根标识
- 多行 `DispatchlistEntity` 构成业务单据内容
- `DispatchpicklistEntity` 负责物理库存分配与拣货事实

关键不变量：
- 只有锁定成功后才能进入待拣货
- 只有拣货确认后才能进入打包 / 称重 / 出库
- 真正扣减库存发生在 `Delivery()`，不是在锁库时

### 4.6 库内作业聚合

**候选聚合：作业任务类聚合**

包括：
- `Stockmove`
- `Stockfreeze`
- `Stockprocess`
- `Stocktaking`
- `Stockadjust`

共同特征：
- 都先生成作业单 / 任务
- 再推进确认动作
- 最后影响库存事实或库存可用性

这说明库内作业的核心建模不是“直接改库存”，而是“先形成可追踪任务，再落库存结果”。

---

## 5. 状态驱动是当前模型的主表达方式

从 `AsnService` 和 `DispatchlistService` 看，ModernWMS 当前最成熟的领域表达方式是：

**状态字段 + Service 方法 + 事务性更新**

### 入库状态机

- `0 -> 1 -> 2 -> 3 -> 4`
- 分别代表：通知 / 到货 / 卸货 / 分拣完成 / 上架完成

### 出库状态机

- `0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7`
- 分别代表：预发货 / 新发货 / 待拣货 / 已拣货 / 打包 / 称重 / 出库 / 已签收

### 这意味着什么

优点：
- 流程清晰
- 页面标签与后端状态基本一致
- 中小团队容易理解和维护

代价：
- 规则容易分散在多个方法里
- 新人理解业务时，往往必须沿着 Service 逐个看状态判断
- 聚合不变量没有被显式封装成领域对象方法

这不是对现状的否定，而是说明当前模型更接近：

**事务脚本 / Application Service 风格 + 强状态流驱动**

---

## 6. 为什么说这是“战略 DDD 视角”而不是“战术 DDD 落地”

### 当前已经具备的部分

- 有稳定的业务语言
- 有相对清晰的上下文边界
- 有稳定的状态流
- 有业务上清楚的重要实体

### 当前还没有显式做的部分

- 没有把聚合根做成强约束的领域对象
- 没有明显的 Domain Event 机制
- 没有通过仓储接口把业务与 ORM 明确隔离
- 多个上下文通过共享 DBContext 直接协作

所以，更准确的说法是：

> ModernWMS 已经有了可以被 DDD 战略化理解的业务边界，
> 但战术实现仍主要落在 Service + Entity + DBContext 上。

---

## 7. 对未来设计最有价值的战略判断

### 判断 1：库存层是系统真正的共享核心
未来无论做什么演进，`Stock` 的语义都不能轻易被破坏。

### 判断 2：入库、出库、库内作业应被视为三个不同执行域
即使代码还在一个项目里，设计讨论和影响分析应先按这三个域分开。

### 判断 3：基础主数据不应承载执行流程规则
主数据要稳定，流程规则应放在执行域里。

### 判断 4：系统管理应被视为通用支撑，而不是仓储核心逻辑的一部分
这样在做权限、菜单、审计时，才不会把业务讨论搅混。

---

## 8. 如果后续继续演进，最自然的方向是什么

这里只给方向，不代表当前必须马上重构。

### 优先级最高的方向

1. **把状态机文档化**
   - 先把 ASN / Dispatch 的状态转移图补齐
   - 这比直接做代码重构更立刻有价值

2. **把库存层身份定义文档化**
   - 统一说明哪些字段共同构成库存层
   - 避免后续新功能只按 `sku_id + location` 理解库存

3. **把共享规则收敛成领域规则文档**
   - 例如残次区、冻结、锁定、盘点调整的规则

### 更长期的方向

- 若业务复杂度继续提升，可逐步把：
  - ASN 流程
  - Dispatch 流程
  - Stock 作业规则
  提炼成更明确的聚合和领域服务

但在这之前，先有一套稳定、被团队接受的领域语言和边界，收益会更高。

---

## 9. 最终总结

用 DDD 战略视角看 ModernWMS，可以得到三个重要结论：

1. **核心竞争力不在“录单”，而在“库存执行与库存解释”**
2. **系统的真实中心不是订单，而是库存层及其状态演化**
3. **当前代码虽是单体实现，但已经能识别出清晰的领域边界**

这意味着后续无论写需求、做设计、做影响分析，最好都优先围绕以下主线组织：

- 主数据是否变化
- 入库如何形成库存
- 库内作业如何影响库存
- 出库如何承诺和消耗库存
- 系统管理如何提供全局支撑
