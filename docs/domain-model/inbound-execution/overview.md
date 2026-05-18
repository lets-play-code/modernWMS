# 入库执行上下文

> 全局视角见 [`../user-journeys.md`](../user-journeys.md)、[`../bounded-contexts.md`](../bounded-contexts.md) 与 [`../strategic-ddd-design.md`](../strategic-ddd-design.md)。本文只记录入库执行上下文的本地知识。

## 1. 业务目标

把“计划到货”推进为“已经形成库存事实的实际收货结果”。

这个上下文的真正输出不是一句“入库完成”，而是带有货主、库位、批次、价格和上架日期等维度的 `StockEntity` 记录。

## 2. 范围 / 非范围

### 范围内

- ASN 单头、明细、分拣记录
- 到货、卸货、分拣、上架状态推进
- 实际收货数量、溢短损数量计算
- 按库存层维度创建或累加库存

### 不在范围内

- 客户发货需求
- 出库锁库、拣货、签收
- 用户权限与菜单授权
- 独立的库存查询解释逻辑

## 3. 主要角色

| 角色 | 主要目标 |
| --- | --- |
| 入库专员 | 把 ASN 从通知推进到上架完成 |
| 仓库现场人员 | 记录卸货、分拣、上架结果 |
| 库存控制员 | 关注实际上架结果是否正确形成库存 |

## 4. 状态机

| 状态值 | 业务含义 | 主要动作 |
| --- | --- | --- |
| `0` | 到货通知 / 待到货 | 创建 ASN、等待确认到货 |
| `1` | 已到货 / 待卸货 | `ConfirmAsync` |
| `2` | 已卸货 / 待分拣 | `UnloadAsync` |
| `3` | 已分拣 / 待上架 | `SortingAsync`、`SortedAsync` |
| `4` | 已上架 | `PutAwayAsync` |

## 5. 关键旅程

1. **创建 ASN 单据**
   - `AsnmasterEntity` 组织业务单头
   - `detailList` 持有多个 `AsnEntity`
2. **确认到货**
   - `ConfirmAsync` 将状态从 `0 -> 1`
   - 写入 `arrival_time`
3. **卸货**
   - `UnloadAsync` 将状态从 `1 -> 2`
   - 写入 `unload_time`、`unload_person`
4. **分拣**
   - `SortingAsync` 生成 `AsnsortEntity`
   - `SortedAsync` 将状态从 `2 -> 3`
   - 计算 `more_qty`、`shortage_qty`
5. **上架**
   - `PutAwayAsync` 校验库位和状态
   - 回写 `AsnsortEntity.putaway_qty`
   - 更新 `AsnEntity.actual_qty`
   - 创建或累加 `StockEntity`

## 6. 核心模型

| 模型 | 业务含义 |
| --- | --- |
| `AsnmasterEntity` | 到货通知单头 |
| `AsnEntity` | 到货通知明细行 |
| `AsnsortEntity` | 分拣记录 / 批次记录 |
| `StockEntity` | 入库完成后形成的库存事实 |

## 7. 关键规则 / 不变量

- **未完成分拣前不能上架**
- **上架数量不能超过已分拣数量**
- **库存不是只按 `sku_id + location` 合并**
  - 还会考虑：
    - `goods_owner_id`
    - `series_number`
    - `expiry_date`
    - `price`
    - `putaway_date`
- **残次区会改变库存语义**
  - 当目标库位所属区域 `warehouse_area_property == 5` 时，会累计 `damage_qty`
- **入库上下文对主数据是 Conformist**
  - 必须接受货主、供应商、SKU、库位等主数据定义

## 8. 上下游与协作

### 上游依赖方

- [`../master-data/overview.md`](../master-data/overview.md)

### 主要输出方

- [`../inventory-visibility/overview.md`](../inventory-visibility/overview.md)：解释新形成的库存
- [`../internal-operations/overview.md`](../internal-operations/overview.md)：在已有库存上执行仓内任务
- [`../outbound-fulfillment/overview.md`](../outbound-fulfillment/overview.md)：承诺并消耗库存

### 协作说明

入库执行与库存可视化/出库履约/库内作业通过 `StockEntity` 和库存层维度形成共享内核关系。

## 9. 代码入口

### 后端服务

- `backend/ModernWMS.WMS/Services/Asn/AsnService.cs`

### 前端页面

- `frontend/src/view/wms/stockAsn/stockAsn.vue`

## 10. 相关阅读

- [`../user-journeys.md`](../user-journeys.md)
- [`../bounded-contexts.md`](../bounded-contexts.md)
- [`../strategic-ddd-design.md`](../strategic-ddd-design.md)
