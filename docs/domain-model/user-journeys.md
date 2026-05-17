# ModernWMS 用户旅程

> 本文基于 `.understand-anything/knowledge-graph.json` 中的 `Warehouse Domain Services` 与 `Frontend Application` 层节点，以及关键源码组件的阅读结果整理。
>
> 重点参考组件：
> - 入库：`backend/ModernWMS.WMS/Services/Asn/AsnService.cs`、`frontend/src/view/wms/stockAsn/stockAsn.vue`
> - 出库：`backend/ModernWMS.WMS/Services/Dispatchlist/DispatchlistService.cs`、`frontend/src/view/deliveryManagement/deliveryManagement/deliveryManagement.vue`
> - 库存与库内作业：`StockService.cs`、`StockmoveService.cs`、`StocktakingService.cs`
> - 基础资料：`WarehouseService.cs`、`WarehouseareaService.cs`、`GoodslocationService.cs`、`GoodsownerService.cs`、`SpuService.cs`

## 1. 这套系统服务谁

ModernWMS 面向的是以仓储执行为中心的业务团队。代码里没有把“角色旅程”抽象成独立模型，但从前后端菜单、页面和服务可以稳定识别出以下用户群：

| 角色 | 主要目标 | 主要入口 |
| --- | --- | --- |
| 基础资料管理员 | 维护仓库、库区、库位、货主、供应商、客户、商品 | `frontend/src/view/base/*` |
| 入库专员 | 创建到货通知、确认到货、卸货、分拣、上架 | `frontend/src/view/wms/stockAsn/*` |
| 出库专员 | 创建发货单、锁定库存、拣货、打包、称重、出库、签收 | `frontend/src/view/deliveryManagement/deliveryManagement/*` |
| 库内作业员 | 移库、冻结/解冻、加工、盘点 | `frontend/src/view/warehouseWorking/*` |
| 库存控制员 | 查看库存、处理差异、确认调整 | `frontend/src/view/wms/stockManagement/*`、`warehouseTaking.vue` |
| 系统管理员 | 用户、角色、菜单、日志、公司信息 | `frontend/src/view/base/userManagement/*`、`roleMenu/*`、`userRoleSetting/*` |

这些角色不一定是一人一岗；在中小仓储团队里，一个用户账号往往会覆盖多个菜单模块。

---

## 2. 旅程一：启仓与基础资料建模

### 用户目标
在系统真正开始收货、发货前，先把仓、货、客户与货主的“主数据骨架”搭起来。

### 典型步骤

1. **建立仓库拓扑**
   - 页面入口：`frontend/src/view/base/warehouseSetting/warehouseSetting.vue`
   - 三层结构由页面标签直接体现：`Warehouse -> Reservoir(库区) -> Location(库位)`
   - 后端模型对应：
     - `WarehouseEntity`
     - `WarehouseareaEntity`
     - `GoodslocationEntity`

2. **定义库区类型**
   - 前端 `AreaProperty` 枚举定义了库区语义：
     - `1 picking_area`
     - `2 stocking_area`
     - `3 receiving_area`
     - `4 return_area`
     - `5 defective_area`
     - `6 inventory_area`
   - 这个枚举不是纯展示字段，而是后续库存规则的一部分
   - 例如 `warehouse_area_property = 5`（残次区）会影响可用库存与破损数量统计

3. **建立商品与货权主数据**
   - 商品主数据入口：`frontend/src/view/base/commodityManagement/commodityManagement.vue`
   - 货主入口：`ownerOfCargo/*`
   - 供应商入口：`supplier/*`
   - 客户入口：`customer/*`
   - 后端模型对应：
     - 商品分类：`CategoryEntity`
     - 商品主档：`SpuEntity`
     - 商品规格：`SkuEntity`
     - 安全库存：`SkuSafetyStockEntity`
     - 货主：`GoodsownerEntity`
     - 供应商：`SupplierEntity`
     - 客户：`CustomerEntity`

### 业务结果
完成这一步后，系统才具备“货可以入、货可以出、库存可以算”的基本条件。

### 关键领域理解

- **Warehouse / WarehouseArea / GoodsLocation** 共同定义了物理仓储空间
- **SPU / SKU** 定义了商品层级
- **Goods Owner** 定义库存归属人，不等同于供应商或客户
- **Supplier** 主要用于入库来源
- **Customer** 主要用于出库去向

---

## 3. 旅程二：入库执行

### 用户目标
把“计划要到的货”变成“已经入库并可管理的库存”。

### 前端工作台
`frontend/src/view/wms/stockAsn/stockAsn.vue` 直接把入库旅程拆成 6 个标签：

| 标签 | 业务含义 | 主要后端能力 |
| --- | --- | --- |
| 到货通知 | 维护入库单头和明细 | `Asnmaster` 列表与增删改 |
| 待到货 | 确认实际到货 | `ConfirmAsync` |
| 待卸货 | 记录卸货 | `UnloadAsync` |
| 待分拣 | 生成分拣批次 / SN | `SortingAsync`、`SortedAsync` |
| 待上架 | 把分拣结果放入库位 | `PutAwayAsync` |
| 收货明细 | 查看已完成入库结果 | `asn_status=4` 结果集 |

### 核心模型

| 模型 | 角色 |
| --- | --- |
| `AsnmasterEntity` | 到货通知单头，负责把多行明细组织成一个业务单据 |
| `AsnEntity` | 到货通知明细行，承载 SKU、数量、货主、供应商、状态 |
| `AsnsortEntity` | 分拣记录，承载分拣数量、序列号、已上架数量 |
| `StockEntity` | 最终库存台账，入库完成后被创建或累加 |

### 关键状态流

从 `AsnService` 的方法与注释可以直接读出入库状态流：

- `0`：到货通知 / 待到货
- `1`：已确认到货，待卸货
- `2`：已卸货，待分拣
- `3`：已分拣，待上架
- `4`：已上架，进入收货明细 / 库存视图

### 业务步骤

1. **创建 ASN 单据**
   - `AsnmasterEntity` 保存单头
   - `detailList` 保存多个 `AsnEntity`
   - 每行有 `sku_id`、`asn_qty`、`supplier_id`、`goods_owner_id`、`price` 等业务字段

2. **确认到货**
   - `ConfirmAsync` 把 `asn_status` 从 `0 -> 1`
   - 写入 `arrival_time`
   - 同步更新 `AsnmasterEntity.last_update_time`

3. **卸货**
   - `UnloadAsync` 把 `asn_status` 从 `1 -> 2`
   - 写入 `unload_time`、`unload_person`

4. **分拣**
   - `SortingAsync` 新增 `AsnsortEntity`
   - 如果开启自动编号，会为每个件数生成系列号 `series_number`
   - `SortedAsync` 把 `asn_status` 从 `2 -> 3`
   - 同时根据 `sorted_qty` 与 `asn_qty` 的差异计算：
     - `more_qty`
     - `shortage_qty`

5. **上架**
   - `PutAwayAsync` 是入库旅程的关键落点
   - 它会：
     - 校验目标库位存在
     - 校验状态必须为 `3`
     - 把本次上架数量回写到 `AsnsortEntity.putaway_qty`
     - 更新 `AsnEntity.actual_qty`
     - 在 `StockEntity` 中创建或累加库存

### 上架后的库存身份

从 `PutAwayAsync` 可知，库存不是只靠 `sku_id + location` 唯一确定，而是按以下业务维度合并：

- `sku_id`
- `goods_location_id`
- `goods_owner_id`
- `series_number`
- `expiry_date`
- `price`
- `putaway_date`

这说明 ModernWMS 的库存模型天然支持：
- 货主隔离
- 批次 / 序列管理
- 保质期管理
- 单价维度区分
- 按上架日期追踪库存层

### 一个重要规则：残次区会改变库存语义

`PutAwayAsync` 中如果目标库位的 `warehouse_area_property == 5`，系统会累加 `damage_qty`。

这意味着：
- 残次库存仍然被记录为库存
- 但它不应被视为正常可用库存
- 库区类型不是装饰字段，而是业务规则入口

---

## 4. 旅程三：库存可视化与库内作业

### 用户目标
在货已经入仓之后，持续维持库存准确、可用、可追踪。

### 4.1 库存查看

库存工作台入口：`frontend/src/view/wms/stockManagement/stockManagement.vue`

页面分为两个视角：

| 标签 | 含义 | 后端能力 |
| --- | --- | --- |
| 库位库存 | 按库位查看库存 | `LocationStockPageAsync` |
| 库存汇总 | 按 SKU 汇总库存 | `StockPageAsync` |

`StockService` 会同时考虑以下数量：
- 总库存 `qty`
- 可用库存 `qty_available`
- 冻结库存 `qty_frozen`
- 锁定库存 `qty_locked`
- 待到货 / 待卸货 / 待分拣 / 已分拣数量

也就是说，库存视图不是简单查 `stock` 表，而是把多个业务过程一起折算后得到“当前可承诺库存”。

### 4.2 移库

核心组件：
- 前端：`frontend/src/view/warehouseWorking/warehouseMove/warehouseMove.vue`
- 后端：`backend/ModernWMS.WMS/Services/Stockmove/StockmoveService.cs`

业务步骤：
1. 创建移库任务 `StockmoveEntity`
2. 创建时先检查源库存是否可用
3. 系统把未确认移库视为“锁库”之一
4. 确认移库时：
   - 源库位库存扣减
   - 目标库位库存新增或累加
   - 状态从 `move_status = 0` 变成 `1`

这表示移库不是即时修改，而是**先建任务、后确认执行**。

### 4.3 冻结 / 解冻

核心组件：`StockfreezeService.cs`

冻结会直接改变 `StockEntity.is_freeze`，但系统在冻结前会检查该库存是否已经被：
- 加工任务占用
- 出库拣货占用
- 移库任务占用

所以冻结不是独立动作，而是库存可用性控制的一部分。

### 4.4 加工 / 拆分 / 组合

核心组件：`StockprocessService.cs`

从前端常量与服务方法可以看出，该模块支持：
- `PROCESS_JOB_COMBINE`：组合加工
- `PROCESS_JOB_SPLIT`：拆分加工

业务特征：
- 有 `source_detail_list` 与 `target_detail_list`
- 先形成加工任务，再确认加工，再进入库存调整确认
- 说明系统把“物理变换”与“库存入账”拆成了两个动作

### 4.5 盘点与调整

核心组件：
- `StocktakingService.cs`
- `StockadjustService.cs`
- 前端：`warehouseTaking.vue`

业务步骤：
1. 创建盘点任务，记录账面数量 `book_qty`
2. 录入实盘数量 `counted_qty`
3. 计算差异 `difference_qty`
4. 确认盘点后：
   - 更新对应 `StockEntity`
   - 新增一条 `StockadjustEntity`

这说明盘点既是现场作业，也是库存纠偏凭证来源。

---

## 5. 旅程四：出库履约

### 用户目标
把“客户要的货”从发货计划一路推进到签收完成。

### 前端工作台
`frontend/src/view/deliveryManagement/deliveryManagement/deliveryManagement.vue` 把出库履约拆成多个连续标签：

| 标签 | 状态 / 含义 |
| --- | --- |
| 发货单 | 全局视图 |
| 预发货 | `dispatch_status = 0` |
| 新发货 | `dispatch_status = 1` |
| 待拣货 | `dispatch_status = 2` |
| 已拣货 | `dispatch_status = 3` |
| 打包 | `dispatch_status = 4` |
| 称重 | `dispatch_status = 5` |
| 出库 | `dispatch_status = 6` |
| 已签收 | `dispatch_status = 7` |

状态名称来自 `shipmentFun.ts` 的 `getShipmentState()`。

### 核心模型

| 模型 | 角色 |
| --- | --- |
| `DispatchlistEntity` | 出库明细行，也是发货业务的主工作单元 |
| `dispatch_no` | 逻辑上的发货单号，用来把多行 `DispatchlistEntity` 聚合成一张单据 |
| `DispatchpicklistEntity` | 锁定并记录从哪个库位、哪个批次拣了多少 |
| `FreightfeeEntity` | 承运与运费规则 |
| `StockEntity` | 最终被锁定、扣减的库存台账 |

### 一个重要建模特点

与入库不同，出库没有单独的 `DispatchmasterEntity`。当前实现是：
- 用相同的 `dispatch_no` 把多行 `DispatchlistEntity` 视作一张发货单
- 真正的拣货明细则落在 `DispatchpicklistEntity`

这说明当前出库模型更偏向“逻辑单头 + 物理明细”的组合，而不是显式的主从聚合对象。

### 核心步骤

1. **创建发货单**
   - `AddAsync` 为多行明细生成同一个 `dispatch_no`
   - 每行关联 `customer_id`、`sku_id`、`qty`

2. **校验并锁定库存**
   - `ConfirmOrderCheck()` 会先算每行的可用库存
   - 计算公式包含：
     - 当前库存
     - 冻结量
     - 其他发货单已锁定量
     - 加工锁定量
     - 移库锁定量
   - `ConfirmOrder()` 确认后：
     - 创建 `DispatchpicklistEntity`
     - 写入库位、货主、系列号、保质期、单价、上架日期
     - 把 `dispatch_status` 变为 `2`

3. **确认拣货**
   - `ConfirmPickByDispatchNo()` 把 `picked_qty = lock_qty`
   - 状态变为 `3`

4. **打包 / 称重**
   - `Package()` 维护 `package_qty`、`package_no`、`package_person`
   - `Weight()` 维护 `weighing_qty`、`weighing_weight`、`weighing_no`
   - 两个动作都带并发处理逻辑，说明这里是多人并行操作的高冲突区

5. **出库**
   - `Delivery()` 是真正扣减库存的动作
   - 系统按 `goods_location_id + sku_id + goods_owner_id + series_number + expiry_date + price + putaway_date` 找到库存层
   - 扣减 `picked_qty`
   - 同时把 `DispatchpicklistEntity.is_update_stock = true`

6. **签收**
   - `SignForArrival()` 会：
     - 写入破损数量 `damage_qty`
     - 计算签收数量 `sign_qty = actual_qty - damage_qty`
     - 状态变为 `7`

### 一个重要规则：可用库存不是“库存总数”

`ConfirmOrderCheck()` 清楚展示了 ModernWMS 的库存承诺逻辑：

`qty_available = stock - frozen - dispatch_locked - process_locked - move_locked`

因此，出库旅程的核心不是“直接扣库存”，而是：
1. 先看可承诺量
2. 再锁定
3. 再拣货
4. 最后在出库时真正扣减

---

## 6. 旅程五：系统管理与审计

虽然不是核心仓储作业，但系统仍然围绕以下管理能力运行：

- 用户管理
- 角色菜单管理
- 公司信息
- 打印方案
- 操作日志

这些模块的作用是：
- 让不同岗位只看到自己的菜单
- 为入库、出库、库内作业提供权限边界
- 为打印、审计、追踪提供基础能力

---

## 7. 从用户旅程看系统主闭环

ModernWMS 的核心业务闭环可以概括为：

1. **先建模**：仓、库区、库位、货主、客户、供应商、商品
2. **再入库**：到货通知 → 到货 → 卸货 → 分拣 → 上架
3. **形成库存**：库存按批次、货主、库位、价格、上架日期分层记录
4. **再出库**：发货单 → 锁库 → 拣货 → 打包 → 称重 → 出库 → 签收
5. **持续校正**：移库、冻结、加工、盘点、调整

这说明 ModernWMS 的本质不是“订单系统”，而是一个**以库存可用性和仓内执行为中心的执行型 WMS**。

## 8. 对后续领域文档的启发

如果要继续细化领域模型，最值得继续拆出的专题有：

- 统一语言：ASN、Dispatch、Goods Owner、Available Stock 的精确定义
- 状态机：ASN 与 Dispatch 的完整状态转移图
- 聚合边界：入库单头/单身、发货单/拣货明细、库存层
- 权限模型：哪些岗位可以执行哪些状态推进动作
