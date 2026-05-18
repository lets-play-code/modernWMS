# 出库履约上下文

> 全局视角见 [`../user-journeys.md`](../user-journeys.md)、[`../bounded-contexts.md`](../bounded-contexts.md) 与 [`../strategic-ddd-design.md`](../strategic-ddd-design.md)。本文只记录出库履约上下文的本地知识。

## 1. 业务目标

把“客户需求”推进为“已签收的履约结果”。

它解决的关键问题是：

- 库存能否被承诺
- 从哪些库存层拣货
- 何时打包、称重、出库、签收
- 什么时候真正扣减库存

## 2. 范围 / 非范围

### 范围内

- 发货单创建与聚合
- 锁库、拣货、打包、称重、出库、签收
- 拣货明细与库存层关联
- 出库过程中的库存扣减

### 不在范围内

- ASN 到货与上架
- 仓储空间和商品主数据维护
- 用户权限与菜单授权
- 独立的库存视图解释

## 3. 主要角色

| 角色 | 主要目标 |
| --- | --- |
| 出库专员 | 把发货需求推进到签收完成 |
| 仓库现场人员 | 完成拣货、打包、称重、出库 |
| 客服或运营 | 跟踪履约状态与签收结果 |

## 4. 状态机

| 状态值 | 业务含义 |
| --- | --- |
| `0` | 预发货 |
| `1` | 新发货 |
| `2` | 待拣货 |
| `3` | 已拣货 |
| `4` | 打包 |
| `5` | 称重 |
| `6` | 出库 |
| `7` | 已签收 |

## 5. 关键旅程

1. **创建发货单**
   - 多行 `DispatchlistEntity` 共享同一个 `dispatch_no`
2. **校验并锁定库存**
   - `ConfirmOrderCheck()` 先计算可用库存
   - `ConfirmOrder()` 创建 `DispatchpicklistEntity`
   - 状态推进到 `2`
3. **确认拣货**
   - `ConfirmPickByDispatchNo()` 将 `picked_qty = lock_qty`
   - 状态推进到 `3`
4. **打包 / 称重**
   - `Package()` 维护包裹信息
   - `Weight()` 维护称重信息
5. **出库**
   - `Delivery()` 才是真正扣减库存的动作
   - 同时把 `DispatchpicklistEntity.is_update_stock = true`
6. **签收**
   - `SignForArrival()` 写入 `damage_qty`
   - 计算 `sign_qty = actual_qty - damage_qty`
   - 状态推进到 `7`

## 6. 核心模型

| 模型 | 业务含义 |
| --- | --- |
| `DispatchlistEntity` | 出库明细行，也是主要工作单元 |
| `dispatch_no` | 逻辑上的发货单号，用来聚合多行明细 |
| `DispatchpicklistEntity` | 拣货与锁库事实 |
| `FreightfeeEntity` | 运费与承运信息 |
| `StockEntity` | 被锁定和扣减的库存事实 |

## 7. 关键规则 / 不变量

- **当前实现没有显式 `DispatchmasterEntity`**
  - 同一 `dispatch_no` 承担逻辑聚合根的角色
- **可用库存不是库存总数**
  - `qty_available = stock - frozen - dispatch_locked - process_locked - move_locked`
- **锁库不等于扣库**
  - 真正扣减库存发生在 `Delivery()`，不是在 `ConfirmOrder()`
- **拣货明细要保留库存层维度**
  - 包括 `goods_location_id`、`goods_owner_id`、`series_number`、`expiry_date`、`price`、`putaway_date`

## 8. 上下游与协作

### 上游依赖方

- [`../master-data/overview.md`](../master-data/overview.md)
- [`../inventory-visibility/overview.md`](../inventory-visibility/overview.md)

### 主要协作方

- [`../internal-operations/overview.md`](../internal-operations/overview.md)
  - 共同占用库存时会影响可承诺量

### 协作说明

- 出库履约与库存可视化通过 `StockEntity` 和锁定量计算形成 Shared Kernel 关系
- 主数据语义错误会直接影响发货单录入、库存承诺与履约结果

## 9. 代码入口

### 后端服务

- `backend/ModernWMS.WMS/Services/Dispatchlist/DispatchlistService.cs`
- `backend/ModernWMS.WMS/Services/Freightfee/FreightfeeService.cs`

### 前端页面

- `frontend/src/view/deliveryManagement/deliveryManagement/deliveryManagement.vue`
- `frontend/src/view/deliveryManagement/deliveryManagement/shipmentFun.ts`

## 10. 相关阅读

- [`../user-journeys.md`](../user-journeys.md)
- [`../bounded-contexts.md`](../bounded-contexts.md)
- [`../strategic-ddd-design.md`](../strategic-ddd-design.md)
