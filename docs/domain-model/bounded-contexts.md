# ModernWMS 上下文划分

> 本文基于知识图谱中的 `Warehouse Domain Services` 层，以及关键服务 / 页面源码整理，用来描述当前系统中“哪些模型应该一起变化、哪些模型只是协作关系”。

## 1. 先给结论

从当前代码结构看，ModernWMS 至少可以稳定识别出 6 个业务上下文：

1. 基础主数据上下文
2. 入库执行上下文
3. 库存可视化上下文
4. 库内作业上下文
5. 出库履约上下文
6. 系统管理上下文

它们目前的实现方式不是严格的独立微服务或独立模块边界，而是：
- 共用同一个后端工程 `ModernWMS.WMS`
- 共用数据库上下文 `SqlDBContext`
- 在服务层中通过表查询和状态更新协作

因此，本文说的“上下文”更适合作为**领域理解边界**，而不是现有代码的物理隔离边界。

---

## 2. 上下文总览

| 上下文 | 主要职责 | 核心模型 | 主要入口 |
| --- | --- | --- | --- |
| 基础主数据 | 定义仓、货、客户、货主、供应商等静态骨架 | `Warehouse*`、`Goodslocation`、`Goodsowner`、`Supplier`、`Customer`、`Category`、`Spu`、`Sku` | `frontend/src/view/base/*` |
| 入库执行 | 把到货通知推进为已入库库存 | `Asnmaster`、`Asn`、`Asnsort` | `stockAsn.vue`、`AsnService.cs` |
| 库存可视化 | 汇总当前库存、可用量、冻结量、锁定量 | `Stock`、`SkuSafetyStock` | `stockManagement.vue`、`StockService.cs` |
| 库内作业 | 处理移库、冻结、加工、盘点、调整 | `Stockmove`、`Stockfreeze`、`Stockprocess`、`Stocktaking`、`Stockadjust` | `frontend/src/view/warehouseWorking/*` |
| 出库履约 | 把发货需求推进到签收完成 | `Dispatchlist`、`Dispatchpicklist`、`Freightfee` | `deliveryManagement.vue`、`DispatchlistService.cs` |
| 系统管理 | 用户、角色、菜单、日志、公司、打印 | `User`、`Rolemenu`、`Userrole`、`ActionLog`、`Company`、`PrintSolution` | `frontend/src/view/base/*` 的系统管理模块 |

---

## 3. 上下文详解

### 3.1 基础主数据上下文

### 责任
提供全系统共享的“静态业务字典”。

### 主要模型

- 仓储空间
  - `WarehouseEntity`
  - `WarehouseareaEntity`
  - `GoodslocationEntity`
- 货权与交易对象
  - `GoodsownerEntity`
  - `SupplierEntity`
  - `CustomerEntity`
- 商品目录
  - `CategoryEntity`
  - `SpuEntity`
  - `SkuEntity`
  - `SkuSafetyStockEntity`

### 为什么它是独立上下文
这些对象本身不直接推进入库/出库状态，但几乎所有执行流程都依赖它们。

例如：
- `AsnEntity` 依赖 `goods_owner_id`、`supplier_id`、`sku_id`
- `DispatchlistEntity` 依赖 `customer_id`、`sku_id`
- `StockEntity` 依赖 `goods_location_id`、`goods_owner_id`、`sku_id`

### 边界规则

- 它负责“定义对象”，不负责执行流程
- 其他上下文要**遵从**它提供的标识和语义
- 最关键的规则字段之一是 `warehouse_area_property`
  - 因为它会影响库存是否可用、是否计入破损等业务规则

---

### 3.2 入库执行上下文

### 责任
把“计划到货”推进为“已形成库存的实际收货结果”。

### 主要模型

- `AsnmasterEntity`：单头
- `AsnEntity`：单身 / 明细行
- `AsnsortEntity`：分拣记录
- `StockEntity`：上架后的库存结果

### 核心业务能力

`AsnService.cs` 中的流程方法构成了这个上下文的主线：

- `ConfirmAsync`
- `UnloadAsync`
- `SortingAsync`
- `SortedAsync`
- `PutAwayAsync`

### 边界判断
这个上下文关心的是：
- 到货是否发生
- 卸货是否完成
- 分拣数量是多少
- 上架到了哪个库位
- 最终形成了什么库存层

它**不关心**：
- 客户如何下单
- 出库如何拣货
- 菜单权限如何配置

### 对外输出
它的最终输出不是“入库完成”这句状态，而是：
- `StockEntity` 的新增或累加
- `actual_qty`、`shortage_qty`、`more_qty`、`damage_qty` 等事实数据

所以入库上下文本质上是库存形成器。

---

### 3.3 库存可视化上下文

### 责任
把分散在多个业务过程中的数量，折算成可以展示、承诺、分析的库存视图。

### 主要模型

- `StockEntity`
- `SkuSafetyStockEntity`
- 只读关联：`AsnEntity`、`DispatchlistEntity`、`DispatchpicklistEntity`、`StockprocessdetailEntity`、`StockmoveEntity`

### 为什么它单独成上下文
`StockService` 并不推进业务状态，而是做“库存语义计算”：

- 可用库存
- 冻结库存
- 锁定库存
- 库龄
- 发货统计
- 按 SKU / 按库位的库存视角

这类能力的重点不是事务更新，而是**统一解释库存**。

### 一个关键认知

在 ModernWMS 中：
- `Stock` 表示“库存事实”
- `StockService` 表示“库存解释器”

这两个角色不能混为一谈。

---

### 3.4 库内作业上下文

### 责任
在库存已经存在的前提下，对库存进行仓内处理。

### 主要模型

- `StockmoveEntity`：移库任务
- `StockfreezeEntity`：冻结 / 解冻任务
- `StockprocessEntity` + `StockprocessdetailEntity`：组合 / 拆分加工
- `StocktakingEntity`：盘点任务
- `StockadjustEntity`：调整凭证

### 子能力划分

| 子能力 | 作用 |
| --- | --- |
| 移库 | 改变库存所在库位 |
| 冻结/解冻 | 改变库存可用性 |
| 加工 | 改变库存结构或形态 |
| 盘点 | 比较账面与实物 |
| 调整 | 把差异正式入账 |

### 共同特点

这些能力都不是“订单驱动”，而是“库存驱动”：
- 先有库存层
- 再有库内作业任务
- 再决定是否修改库存事实

### 与库存上下文的关系

这是当前系统中最紧耦合的一组边界：
- 库内作业会锁定或修改库存
- 库存可视化必须把这些锁定量计算进去

所以它们在战略上应视为两个上下文，
但在实现上目前属于**共享内核（Shared Kernel）+ 共享数据库**关系。

---

### 3.5 出库履约上下文

### 责任
把“客户需求”推进为“已签收的履约结果”。

### 主要模型

- `DispatchlistEntity`
- `DispatchpicklistEntity`
- `FreightfeeEntity`
- 只读 / 协作：`StockEntity`

### 核心业务能力

`DispatchlistService.cs` 中的流程方法构成了这个上下文的主线：

- `ConfirmOrderCheck`
- `ConfirmOrder`
- `ConfirmPickByDispatchNo`
- `Package`
- `Weight`
- `Delivery`
- `SignForArrival`

### 边界判断
这个上下文关心的是：
- 发货需求能不能被库存满足
- 从哪些库存层拣货
- 货有没有打包、称重、出库、签收
- 什么时候真正扣减库存

它**不关心**：
- ASN 如何形成
- 仓库结构如何维护
- 用户菜单如何授权

### 一个关键建模事实

出库上下文没有单独的 `DispatchmasterEntity`，而是通过同一个 `dispatch_no` 聚合多行 `DispatchlistEntity`。

这表示当前实现更偏向：
- 逻辑聚合靠“单号”
- 物理执行靠“拣货明细”

这对理解查询、编辑、撤回逻辑很重要。

---

### 3.6 系统管理上下文

### 责任
为业务流程提供用户、菜单、权限、日志、打印等通用能力。

### 主要模型

- `User`
- `Rolemenu`
- `Userrole`
- `ActionLog`
- `Company`
- `PrintSolution`

### 边界判断
它不决定仓储业务规则，但决定：
- 谁能看到哪个入口
- 谁能执行哪个动作
- 操作能否被追踪

因此它是一个标准的**通用支撑上下文**。

---

## 4. 上下文之间的关系图

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

解释：
- **基础主数据**是所有执行上下文的上游
- **入库执行**负责形成库存
- **出库履约**负责消耗库存
- **库内作业**负责调整库存位置、状态和结构
- **库存可视化**负责统一解释库存当前状态
- **系统管理**是全局通用能力

---

## 5. 当前实现里的共享内核

从代码实现看，以下模型已经形成事实上的共享内核：

- `StockEntity`
- `SkuEntity`
- `GoodslocationEntity`
- `GoodsownerEntity`
- `tenant_id` + `CurrentUser` 过滤规则

### 为什么说它们是共享内核
因为多个上下文都依赖它们，而且依赖方式不是松耦合接口，而是：
- 直接查询同表
- 直接按相同字段组合定位数据
- 直接根据状态判断库存可用性

例如库存层的身份经常依赖同一组维度：
- `sku_id`
- `goods_location_id`
- `goods_owner_id`
- `series_number`
- `expiry_date`
- `price`
- `putaway_date`

这组维度几乎贯穿入库、出库、移库、盘点、调整多个上下文。

---

## 6. 用 DDD 关系语言描述当前上下文地图

如果用更接近 DDD Strategic Design 的说法，可以这样描述：

| 关系 | 说明 |
| --- | --- |
| 基础主数据 → 入库/出库/库内作业 | Conformist：执行上下文必须接受主数据的标识与定义 |
| 入库执行 ↔ 库存可视化 | Shared Kernel：通过 `StockEntity` 与库存层维度协作 |
| 出库履约 ↔ 库存可视化 | Shared Kernel：通过 `StockEntity` 与锁定量计算协作 |
| 库内作业 ↔ 库存可视化 | Shared Kernel：通过锁定量与调整结果协作 |
| 系统管理 → 所有上下文 | Generic Subdomain 支撑关系 |

这不是对现有代码分层的美化，而是帮助后续迭代时知道：
- 哪些地方可以拆
- 哪些地方不能随便改字段语义
- 哪些模型一改就会连锁影响多个流程

---

## 7. 当前边界的优点与风险

### 优点

- 单体实现下协作成本低
- 跨流程查询容易写
- 前后端状态推进一致性强
- 对中小型 WMS 场景足够直接

### 风险

- 多个上下文直接依赖同一库存表，耦合较高
- 状态流主要编码在 Service 层，规则分散在方法里
- `Dispatchlist` 以单号聚合、而非显式单头聚合，理解成本较高
- 如果未来做更复杂的多仓、多组织、多策略扩展，边界会更紧张

---

## 8. 实际使用这些边界时的建议

在后续写设计文档、需求文档或做影响分析时，可以直接用这套划分：

- 改“仓 / 货 / 货主 / 客户 / 供应商” → 基础主数据上下文
- 改“到货、卸货、分拣、上架” → 入库执行上下文
- 改“库存查询、可用量、安全库存、库龄” → 库存可视化上下文
- 改“移库、冻结、加工、盘点、调整” → 库内作业上下文
- 改“发货、拣货、打包、称重、出库、签收” → 出库履约上下文
- 改“账号、角色、菜单、日志、打印” → 系统管理上下文

这样做的价值是：即使当前代码还是单体，也能先让文档和思考方式具备明确边界。
