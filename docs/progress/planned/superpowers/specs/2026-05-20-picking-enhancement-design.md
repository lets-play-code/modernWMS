# ModernWMS 拣货增强设计

> 状态：已与用户确认总体设计。
>
> 范围：`ModernWMS` 现有出库履约流程中的拣货阶段增强。
>
> 约束：本设计仅基于当前仓库代码与 `docs/requirements/classroom-practice/modernwms-picking-enhancement-student-guide.md`，**不参考 `ModernWMS-picking-restore/`**。

## 1. 目标

在不重做现有出库主流程、不新增独立拣货单持久化表的前提下，为 ModernWMS 补齐面向现场执行的拣货能力，使系统从“能推进状态”提升为“能支持现场拣货执行、复核、纠错与留痕”。

本次完成后，应满足：

- 可在待拣货列表中选择任务并生成运行时拣货单视图；
- 拣货单按现场执行逻辑聚合，不跨库位错误合并；
- 每条拣货项可查看相关发货单；
- 支持行级确认拣货与复核前撤销；
- 支持按发货单整单复核；
- 能区分并展示“谁拣了货”和“谁做了复核”；
- 后续打包、称重、出库、签收流程继续兼容；
- 保持“锁库不等于扣库，真正扣库存发生在 `Delivery()`”这一长期规则。

## 2. 非目标

以下内容不属于本次设计范围：

- 新增独立持久化的拣货单主表/明细表；
- 引入独立拣货单编号和独立生命周期；
- 设计 PDA / 手持终端方案；
- 引入波次、路径优化等算法；
- 重做权限模型；
- 把拣货增强演化成新的独立业务系统。

## 3. 需求理解

### 3.1 核心角色

| 角色 | 要完成的任务 | 真正目标 | 当前障碍 |
| --- | --- | --- | --- |
| 拣货员 | 根据待拣任务去库位取货并逐条确认 | 少走回头路、少切换单据、减少误拣 | 现有系统更偏状态推进，缺少现场友好的聚合执行清单 |
| 复核员 | 对已执行的拣货结果做最终确认 | 判断发货任务是否可进入后续流程 | 当前确认拣货更像一键改状态，责任区分不清晰 |
| 出库专员 / 管理员 | 让发货流程稳定推进到后续环节 | 增强拣货能力但不破坏现有主流程 | 如果拣货增强改变现有状态语义，后续流程可能被卡住 |

### 3.2 本次真正解决的问题

这次不是重做独立拣货系统，而是在现有出库履约内补齐四类能力：

1. **执行清单能力**：从待拣货任务中生成适合现场执行的拣货单视图；
2. **执行回写能力**：拣货员能逐条确认“这条已经拣完”；
3. **纠错能力**：在整单复核前允许撤销已确认明细；
4. **责任留痕能力**：区分并展示拣货员与复核员。

## 4. 用户旅程

### 4.1 主流程

1. 出库专员进入“待拣货”列表；
2. 选择一批待处理任务，生成运行时拣货单视图；
3. 拣货员查看/打印拣货单并开始现场作业；
4. 拣货员按拣货项逐条确认完成；
5. 若发现错误，可在复核前撤销某条已确认拣货项；
6. 复核员按发货任务做整单复核；
7. 复核完成后继续进入打包、称重、出库、签收。

### 4.2 异常流程

- **多张发货单共享同一商品且来自同一库位**：可聚合为一条执行项，但必须展示相关发货单；
- **同一商品分布在多个库位**：必须拆分为多条执行项；
- **已确认明细在复核前发现错误**：允许撤销并恢复到未确认状态；
- **需要兼容现有旧流程**：即使不逐条确认，也应保留整单推进能力。

### 4.3 前置 / 后置条件

**前置条件**：

- 发货任务已完成出库确认；
- 当前状态进入待拣货；
- 系统已存在对应底层拣货明细；
- 库存已锁定但尚未真正扣减。

**后置条件**：

- 拣货明细上可看见拣货员；
- 发货任务上可看见复核员；
- 已复核的发货任务可以继续进入后续流程；
- 不破坏现有出库主链路。

## 5. 上下文归属与边界

### 5.1 主上下文

归属为 `outbound-fulfillment`（出库履约）。

理由：

- 需求核心发生在现有 `待拣货 -> 拣货执行 -> 拣货复核 -> 打包 -> 称重 -> 出库 -> 签收` 链路中；
- 核心模型仍是 `DispatchlistEntity` 与 `DispatchpicklistEntity`；
- 目标是增强现有流程，不是引入新业务系统。

### 5.2 协作上下文

| 上下文 | 参与方式 | 影响点 |
| --- | --- | --- |
| `inventory-visibility` | 提供库存层语义与锁定/可用量解释 | 拣货单聚合必须尊重库存层维度，不能破坏锁库与扣库边界 |
| `master-data` | 提供 SKU、仓库、库区、库位、货主、客户语义 | 拣货单展示依赖这些基础信息 |
| `internal-operations` | 间接协作 | 共享库存层与锁定量规则 |
| `system-management` | 提供用户、权限、日志、打印支撑 | 记录拣货员、复核员并复用现有权限与打印能力 |

### 5.3 边界结论

本次不新增独立“拣货上下文”。

- **发货单**仍是业务需求表达；
- **拣货明细**仍是底层锁库与执行事实；
- **拣货单**只是运行时聚合出来的执行视图，不是新的持久化业务单据。

本次不需要修改全局 `bounded-contexts.md` 或 `strategic-ddd-design.md`，后续如形成稳定规则，可补充 `docs/domain-model/outbound-fulfillment/overview.md`。

## 6. 领域模型与规则

### 6.1 核心对象

| 对象 | 角色 | 本次增强中的职责 |
| --- | --- | --- |
| `DispatchlistEntity` | 发货需求明细行 | 仍是业务主工作单元；按 `dispatch_no` 形成逻辑发货单；记录整单复核结果 |
| `dispatch_no` | 逻辑聚合标识 | 当前无独立 `DispatchmasterEntity`，继续承担同一张发货单的聚合作用 |
| `DispatchpicklistEntity` | 底层拣货/锁库事实 | 表示从哪层库存拣多少；承担行级执行事实与拣货员留痕 |
| `Picking Sheet Line` | 运行时拣货单聚合行 | 非数据库实体，仅为执行视图读模型 |
| `Related Dispatch Ref` | 相关发货单映射 | 告诉现场人员该聚合拣货项对应哪些发货任务与数量 |

### 6.2 模型分层

- **业务层**：`DispatchlistEntity` 表达“要发什么”；
- **执行层**：`DispatchpicklistEntity` 表达“从哪层库存取多少”；
- **展示层**：运行时拣货单表达“现场该怎么干活”。

### 6.3 状态流转

主状态机保持不变：

- `0` 预发货
- `1` 新发货
- `2` 待拣货
- `3` 已拣货
- `4` 打包
- `5` 称重
- `6` 出库
- `7` 已签收

本次只在 `dispatch_status = 2` 内补“执行子状态”，不新增新的主状态值。

#### `DispatchpicklistEntity` 的执行子状态

- **未确认**：`picked_qty = 0`，`picker / picker_id` 为空；
- **已确认**：`picked_qty = pick_qty`，`picker / picker_id` 为当前拣货员。

#### 整单复核

- 复核前：`DispatchlistEntity.dispatch_status = 2`；
- 复核后：`DispatchlistEntity.dispatch_status = 3`；
- 同时记录 `pick_checker / pick_checker_id`。

### 6.4 关键业务规则

1. **拣货单是运行时视图，不是持久化单据**；
2. **聚合以“同一现场取货动作”为准**，分组键建议使用：
   - `sku_id`
   - `goods_location_id`
   - `goods_owner_id`
   - `series_number`
   - `expiry_date`
   - `price`
   - `putaway_date`
3. **拣货单只处理待拣货数据**；
4. **MVP 只做整行确认，不支持部分数量确认**；
5. **行级确认只回写 `DispatchpicklistEntity`，不直接推进发货主状态**；
6. **整单复核才推进到“已拣货”**；
7. **复核前允许撤销，复核后不支持行级撤销**；
8. **保留并增强旧流程**：允许不逐条确认、直接整单复核；
9. **库存扣减时机不变**：`ConfirmOrder()` 锁库，`Delivery()` 才真正扣减库存；
10. **留痕分两层**：拣货员看 `DispatchpicklistEntity.picker`，复核员看 `DispatchlistEntity.pick_checker`。

## 7. MVP 范围

### 7.1 P0

- 在待拣货列表中多选 `dispatchlist` 明细；
- 生成运行时拣货单视图；
- 拣货单按现场执行规则聚合；
- 每条拣货项展示相关发货单；
- 支持行级确认拣货；
- 支持行级撤销拣货；
- 支持整单复核；
- 记录拣货员与复核员；
- 支持查看/打印拣货单；
- 保持后续流程兼容。

### 7.2 P1（本次不做）

- 历史拣货单保存；
- 独立拣货单编号；
- 复杂批次策略；
- 路径优化 / 波次策略；
- PDA 逐扫逐确认。

## 8. API 设计

### 8.1 保留并增强现有接口

#### `GET /dispatchlist/pick-list?dispatch_id=...`

继续保留单个发货明细的拣货明细查询，建议补充：

- `picker`
- `picker_id`
- 可选 `is_picked`（也可由前端用 `picked_qty === pick_qty` 推导）

用途：待拣货 / 已拣货详情弹窗查看。

#### `PUT /dispatchlist/confirm-pick-dispatchlistno?dispatch_no=...`

增强后语义明确为**整单复核**：

1. 找到该 `dispatch_no` 下所有 `dispatch_status = 2` 的 `dispatchlist`；
2. 找到其下所有 `Dispatchpicklist`；
3. 对尚未确认的明细自动补齐：
   - `picked_qty = pick_qty`
   - 若 `picker` 为空，则写当前操作人；
4. 对整单写入：
   - `dispatchlist.picked_qty = lock_qty`
   - `dispatch_status = 3`
   - `pick_checker / pick_checker_id = 当前操作人`

该接口继续兼容旧流程。

### 8.2 新增接口

#### `POST /dispatchlist/picking-sheet`

用途：生成运行时拣货单视图。

**请求示例**：

```json
{
  "dispatchlist_ids": [101, 102, 103]
}
```

**返回示例**：

```json
{
  "dispatch_nos": ["DP-001", "DP-002"],
  "lines": [
    {
      "group_key": "runtime-group-key",
      "pick_detail_ids": [1001, 1002],
      "sku_id": 10,
      "sku_code": "SKU-001",
      "spu_code": "SPU-001",
      "spu_name": "示例商品",
      "goods_owner_name": "货主A",
      "warehouse_name": "一号仓",
      "warehouse_area_name": "拣货区",
      "location_name": "A-01-01",
      "series_number": "SN001",
      "expiry_date": "2026-12-31T00:00:00",
      "price": 11.5,
      "putaway_date": "2026-05-01T00:00:00",
      "pick_qty": 8,
      "picked_qty": 3,
      "picker_display": "picker01",
      "related_dispatches": [
        {
          "dispatch_no": "DP-001",
          "dispatchlist_id": 101,
          "pick_qty": 5,
          "picked_qty": 0
        },
        {
          "dispatch_no": "DP-002",
          "dispatchlist_id": 102,
          "pick_qty": 3,
          "picked_qty": 3
        }
      ]
    }
  ]
}
```

说明：

- `group_key` 仅作前端渲染标识；
- `pick_detail_ids` 是确认/撤销时的真实操作目标；
- `picker_display` 用于聚合展示单人或多人状态。

#### `PUT /dispatchlist/confirm-pick-items`

用途：确认拣货单行。

**请求示例**：

```json
{
  "pick_detail_ids": [1001, 1002]
}
```

行为：

- 仅允许操作其父发货明细仍为 `dispatch_status = 2` 的记录；
- 对目标 `DispatchpicklistEntity`：
  - `picked_qty = pick_qty`
  - `picker / picker_id = 当前操作人`
  - `last_update_time = now`
- 不修改 `DispatchlistEntity.dispatch_status`。

#### `PUT /dispatchlist/revoke-pick-items`

用途：撤销拣货单行。

**请求示例**：

```json
{
  "pick_detail_ids": [1001, 1002]
}
```

行为：

- 仅允许其父发货明细仍为 `dispatch_status = 2`；
- 对目标 `DispatchpicklistEntity`：
  - `picked_qty = 0`
  - `picker / picker_id` 清空
  - `last_update_time = now`

### 8.3 ViewModel 设计

建议新增：

- `DispatchlistPickingSheetQueryViewModel`
- `DispatchlistPickingSheetViewModel`
- `DispatchlistPickingSheetLineViewModel`
- `DispatchlistPickingSheetDispatchRefViewModel`
- `DispatchlistPickItemsOperationViewModel`

建议扩展：

- `DispatchpicklistViewModel`：增加 `picker`、`picker_id`；
- `DispatchlistViewModel`：保证 `pick_checker`、`pick_checker_id` 在列表查询中正确投影。

### 8.4 权限策略

不新增 action code，复用现有权限：

- `picked-pick`：生成/查看拣货单、行级确认；
- `picked-revoke`：行级撤销、现有整单回退；
- `picked-confirm`：整单复核。

## 9. 前端设计

### 9.1 入口

继续使用 `frontend/src/view/deliveryManagement/deliveryManagement/tabGoodsToBePicked.vue` 作为主入口。

在待拣货页新增：

1. 多选框；
2. 顶部按钮“生成拣货单”；
3. 保留现有“查看明细”。

### 9.2 新增拣货单执行弹窗

建议新增文件：

- `frontend/src/view/deliveryManagement/deliveryManagement/picking-sheet-dialog.vue`

职责：

- 调用 `/dispatchlist/picking-sheet`；
- 展示聚合后的拣货单行；
- 支持查看相关发货单、行级确认、行级撤销、打印；
- 支持按发货单整单复核。

### 9.3 拣货单弹窗信息结构

**顶部摘要区**：

- 已选发货单数量；
- 涉及发货单号；
- 总拣货行数。

**主表格区字段建议**：

- `sku_code`
- `spu_name`
- `goods_owner_name`
- `warehouse_name`
- `warehouse_area_name`
- `location_name`
- `series_number`
- `expiry_date`
- `pick_qty`
- `picked_qty`
- `picker_display`
- `related_dispatch_count`
- 操作列

**操作列**：

- 查看相关发货单；
- 确认拣货；
- 撤销拣货。

### 9.4 相关发货单展示

推荐使用二级轻量详情弹窗，展示：

- `dispatch_no`
- `dispatchlist_id`
- `pick_qty`
- `picked_qty`

### 9.5 行级确认/撤销交互

#### 确认拣货

1. 弹确认框；
2. 调用 `/dispatchlist/confirm-pick-items`；
3. 成功后刷新拣货单数据；
4. 必要时同步刷新待拣货列表。

按钮禁用：

- 已全部确认则禁用“确认拣货”；
- 未确认则禁用“撤销拣货”。

#### 撤销拣货

1. 弹确认框；
2. 调用 `/dispatchlist/revoke-pick-items`；
3. 成功后刷新拣货单数据。

### 9.6 整单复核交互

复核对象必须是**发货单**，不是聚合行。

建议在拣货单弹窗内增加“待复核发货单列表”，展示：

- `dispatch_no`
- 已确认拣货进度
- `pick_checker`
- 操作：整单复核

复核时调用：

- `PUT /dispatchlist/confirm-pick-dispatchlistno?dispatch_no=...`

成功后刷新拣货单视图与待拣货列表。

### 9.7 打印设计

采用项目现有打印方式：

- `v-print`
- 打印专用 DOM 区域

打印内容至少包含：

- 标题：拣货单
- 打印时间
- 发货单号列表/摘要
- SKU 编码
- 商品名称
- 货主
- 仓库 / 库区 / 库位
- 批次/效期
- 待拣数量
- 相关发货单

### 9.8 已拣货与明细页增强

建议增强：

- `tabPicked.vue`：增加 `pick_checker` 展示；
- `search-delivered-detail.vue`：增加 `pick_qty`、`picked_qty`、`picker` 展示。

### 9.9 前端涉及文件

- `frontend/src/api/wms/deliveryManagement.ts`
- `frontend/src/types/DeliveryManagement/DeliveryManagement.ts`
- `frontend/src/view/deliveryManagement/deliveryManagement/tabGoodsToBePicked.vue`
- `frontend/src/view/deliveryManagement/deliveryManagement/tabPicked.vue`
- `frontend/src/view/deliveryManagement/deliveryManagement/search-delivered-detail.vue`
- `frontend/src/view/deliveryManagement/deliveryManagement/picking-sheet-dialog.vue`（新增）
- `frontend/src/utils/systemLog.ts`
- `frontend/src/languages/langsJson/cn.json`
- `frontend/src/languages/langsJson/en.json`
- `frontend/src/languages/langsJson/tw.json`

## 10. 错误处理

### 10.1 后端

- 传入数据不属于当前租户、状态不匹配、记录不存在时，返回现有风格业务错误；
- 行级确认/撤销只允许在父发货明细仍为待拣货时执行；
- 整单复核时如状态已变化，返回状态变更错误；
- 自动补齐未确认明细时应保持事务一致性，避免部分成功。

### 10.2 前端

继续复用：

- `hookComponent.$message`
- `hookComponent.$dialog`
- `httpCodeJudge`

对空选择、重复操作、状态过期、数据变化等，都给出明确提示并按现有模式刷新。

## 11. 测试策略

遵循现有测试约定：先测试表达新行为，再做最小实现。

### 11.1 后端单元测试

在 `backend/ModernWMS.Tests.Unit/Services/DispatchlistServiceTests.cs` 补强：

1. 同 SKU、同库位、同库存层身份聚合为一行；
2. 同 SKU、不同库位拆分为多行；
3. 聚合行能正确返回相关发货单；
4. 行级确认写入 `picked_qty` 与 `picker / picker_id`，不推进主状态；
5. 行级撤销恢复未确认状态；
6. 整单复核记录 `pick_checker / pick_checker_id` 并推进到 `dispatch_status = 3`；
7. 不先逐条确认、直接整单复核也可正常推进。

### 11.2 API E2E / BDD

优先扩展 `backend/ModernWMS.Tests.ApiE2E/Features/OutboundFulfillment/dispatch-lifecycle.feature`，增加：

1. 多发货明细生成拣货单视图；
2. 同 SKU 同库位聚合、不同库位不聚合；
3. 行级确认与撤销；
4. 整单复核记录复核员；
5. 后续打包/称重/出库链路继续可走通。

### 11.3 前端验证

最小验证：

1. `frontend` 构建通过；
2. 待拣货页可多选并打开拣货单弹窗；
3. 拣货单弹窗可查看相关发货单；
4. 行级确认/撤销与整单复核可触发正确请求；
5. 已拣货页可看到复核员；
6. 明细弹窗可看到拣货员；
7. 打印 DOM 可正常触发。

## 12. 风险与控制点

| 风险 | 说明 | 控制方式 |
| --- | --- | --- |
| 聚合维度错误 | 把不该合并的拣货项错误合并 | 严格按库存层身份字段聚合 |
| 执行与复核语义混淆 | 容易把“执行完成”直接当作“业务放行” | 明确行级写 `Dispatchpicklist`，整单写 `Dispatchlist` |
| 破坏现有旧流程 | 只支持新流程会卡住课堂演示 | 保留并增强 `confirm-pick-dispatchlistno` |
| 影响后续打包/称重/出库 | 已拣货状态语义被改乱 | 不改主状态机骨架，不改库存扣减时机 |
| 前端改动面过大 | 影响现有发货管理使用方式 | 仅增强待拣货页并新增一个执行弹窗 |

## 13. 验收标准

完成后至少满足：

1. 可在待拣货列表多选记录并生成拣货单视图；
2. 拣货单按现场执行逻辑聚合，且不跨库位错误合并；
3. 每条拣货项都可查看相关发货单；
4. 支持行级确认拣货；
5. 支持复核前撤销；
6. 支持按发货单整单复核；
7. 系统能区分并展示拣货员与复核员；
8. 原有后续流程仍可继续；
9. 旧的整单推进方式仍可工作；
10. 实现仅基于当前仓库与需求文档，不参考 `ModernWMS-picking-restore/`。

## 14. 最终结论

本次设计的核心结论是：

> 在现有出库履约模型上增加一个“面向现场执行的拣货单视图层”，用 `Dispatchpicklist` 记录执行事实，用 `Dispatchlist` 记录复核放行，既增强拣货能力，又不破坏现有出库主链路。
