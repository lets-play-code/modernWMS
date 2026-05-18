# Context Gate 摘要：库内作业

## 状态

- 状态：completed
- Baseline 覆盖率：15.04%（20 / 133）
- 当前覆盖率：100.00%（133 / 133）
- 全局覆盖率：58.91%（1094 / 1857）→ 65.11%（1209 / 1857）
- Loop 次数：3
  1. 先基于 baseline/最新 coverage 把缺口拆成 API E2E 与单元分支：移库、冻结、加工、盘点几乎全空白，`Stockadjust` 只有 list API，但由加工/盘点生成调整记录即可连带闭环。
  2. 按 TDD 先补组件测试，暴露两处真实生产 bug：`StockmoveService.Confirm` 目标库存查询写成 `sku_id != entity.sku_id` 导致目标层不合并；`StocktakingService.ConfirmAsync` 缺少已调整保护，重复确认会再次改库存并重复写调整。
  3. 追加真实 API 场景跑通移库、冻结/解冻、加工、盘点差异；中途发现 `stockprocess` 新增请求若不显式传 `process_status=false` 会沿用 ViewModel 默认值 `true`，按真实前端请求修正 feature 后完成 full coverage 与 mutation 抽样。

## Gap 分类与收敛策略

### API E2E 可覆盖

- `POST/GET/PUT/DELETE /stockmove*`：新增移库、查询、确认、重复确认/已确认删除保护。
- `POST/GET /stockfreeze*`：冻结、解冻、列表/详情/全部查询，以及库存可用量变化。
- `POST/GET/PUT /stockprocess*`：加工单创建、详情、列表、确认加工、重复确认保护、确认调整。
- `POST/GET/PUT /stocktaking*`：盘点任务创建、计数确认、差异入账、重复调整保护。
- `POST /stockadjust/list`：验证加工/盘点生成的库存调整事实。
- `POST /stock/location-list`、`POST /stock/stock-list`：用真实库存读模型验证源/目标库存变化、冻结量、锁定量与可用量。

### 单元/组件测试补强

- `StockmoveServiceTests`：补目标库存层合并与重复确认保护。
- `StockfreezeServiceTests`：补冻结/解冻成功流，以及 `process/dispatch/move` 未确认阻塞。
- `StockprocessServiceTests`：补冻结源库存拒绝、确认调整后源减目标增与重复调整保护。
- `StocktakingServiceTests`：补计数差异计算、差异入账与重复确认保护。

### 真实 bug / 生产修复

- `backend/ModernWMS.WMS/Services/Stockmove/StockmoveService.cs`
  - `Confirm` 新增 `move_status` 保护，已确认移库再次确认直接返回 `status_changed`。
  - 修正目标库存查询条件，从 `t.sku_id != entity.sku_id` 改为 `t.sku_id == entity.sku_id`，保证同库存层移入时合并目标库存，而不是生成重复库存层。
- `backend/ModernWMS.WMS/Services/Stocktaking/StocktakingService.cs`
  - `ConfirmAsync` 新增 `Stockadjust(job_type=1, source_table_id=entity.id)` 存在性检查，重复确认直接返回 `status_changed`，避免库存重复增减与重复调整记录。

## 业务场景覆盖

### 1. 移库确认

文件：`backend/ModernWMS.Tests.ApiE2E/Features/InternalOperations/internal-stock-operations.feature`

覆盖业务：
- 新增移库任务并回查详情/列表/全部接口；
- 确认后源库位数量从 6 降到 2、目标库位从 0 升到 4；
- 已确认移库再次确认被拒绝；
- 已确认移库不能被删除。

### 2. 冻结/解冻

文件：`backend/ModernWMS.Tests.ApiE2E/Features/InternalOperations/internal-stock-operations.feature`

覆盖业务：
- 冻结任务创建后 `qty_frozen=5`、`qty_available=0`；
- 解冻任务创建后 `qty_frozen=0`、`qty_available=5`；
- 列表、详情、全部接口都能观察到冻结/解冻任务事实。

### 3. 加工源/目标库存

文件：`backend/ModernWMS.Tests.ApiE2E/Features/InternalOperations/internal-stock-operations.feature`

覆盖业务：
- 新增加工单后源库存先被锁定：`qty_locked=4`、`qty_available=2`；
- `process-confirm` 成功后再次确认被拒绝；
- `adjustment-confirm` 后源 SKU 数量从 6 降到 2，目标 SKU 新增 4；
- `stockadjust/list` 返回一正一负两条加工调整记录。

### 4. 盘点差异与库存调整

文件：`backend/ModernWMS.Tests.ApiE2E/Features/InternalOperations/internal-stock-operations.feature`

覆盖业务：
- 新建盘点任务并回查详情/列表；
- 计数 5 对账面 8 产生 `difference_qty=-3`；
- `adjustment-confirm` 后库存从 8 降到 5；
- 重复 `adjustment-confirm` 被拒绝；
- `stockadjust/list` 返回 `job_type=1`、`qty=-3` 的盘点调整记录。

## 单元 / 组件测试

### `backend/ModernWMS.Tests.Unit/Services/StockmoveServiceTests.cs`

- `ConfirmMovesQuantityIntoExistingDestinationLayer`
  - 覆盖目标库存层合并，防止相同维度库存生成重复目标层。
- `ConfirmRejectsAlreadyConfirmedMove`
  - 覆盖重复确认保护与二次确认后库存不再变化。

### `backend/ModernWMS.Tests.Unit/Services/StockfreezeServiceTests.cs`

- `AddAsyncFreezesThenUnfreezesMatchingStocks`
  - 覆盖冻结/解冻成功流与任务落库。
- `AddAsyncRejectsWhenBlockingTasksExist`
  - 覆盖 `process_not_comfirm`、`dispatch_not_comfirm`、`move_not_comfirm` 三类阻塞分支。

### `backend/ModernWMS.Tests.Unit/Services/StockprocessServiceTests.cs`

- `AddAsyncRejectsFrozenSourceStock`
  - 覆盖冻结源库存拒绝加工。
- `ConfirmAdjustmentMovesInventoryAndRejectsRepeatAdjustment`
  - 覆盖确认调整后的源减目标增、`detail.is_update_stock` 回写、重复调整保护。

### `backend/ModernWMS.Tests.Unit/Services/StocktakingServiceTests.cs`

- `PutAsyncStoresCountedQuantityAndDifference`
  - 覆盖盘点差异计算与处理人回写。
- `ConfirmAsyncAppliesDifferenceOnceAndRejectsDuplicateAdjustment`
  - 覆盖差异入账、调整记录生成与重复确认保护。

## 覆盖率明细

| 文件 | 覆盖率 | Covered / Valid |
| --- | ---: | ---: |
| `ModernWMS.WMS/Controllers/Stockadjust/StockadjustController.cs` | 100.00% | 8 / 8 |
| `ModernWMS.WMS/Controllers/Stockfreeze/StockfreezeController.cs` | 100.00% | 8 / 8 |
| `ModernWMS.WMS/Controllers/Stockmove/StockmoveController.cs` | 100.00% | 8 / 8 |
| `ModernWMS.WMS/Controllers/Stockprocess/StockprocessController.cs` | 100.00% | 8 / 8 |
| `ModernWMS.WMS/Controllers/Stocktaking/StocktakingController.cs` | 100.00% | 8 / 8 |
| `ModernWMS.WMS/Entities/Models/Stockadjust/StockadjustEntity.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/Models/Stockfreeze/StockfreezeEntity.cs` | 100.00% | 1 / 1 |
| `ModernWMS.WMS/Entities/Models/Stockmove/StockmoveEntity.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/Models/Stockprocess/StockprocessEntity.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/Models/Stockprocess/StockprocessdetailEntity.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/Models/Stocktaking/StocktakingEntity.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Stockadjust/StockadjustViewModel.cs` | 100.00% | 4 / 4 |
| `ModernWMS.WMS/Entities/ViewModels/Stockfreeze/StockfreezeViewModel.cs` | 100.00% | 3 / 3 |
| `ModernWMS.WMS/Entities/ViewModels/Stockmove/StockmoveViewModel.cs` | 100.00% | 4 / 4 |
| `ModernWMS.WMS/Entities/ViewModels/Stockprocess/StockprocessGetViewModel.cs` | 100.00% | 3 / 3 |
| `ModernWMS.WMS/Entities/ViewModels/Stockprocess/StockprocessViewModel.cs` | 100.00% | 4 / 4 |
| `ModernWMS.WMS/Entities/ViewModels/Stockprocess/StockprocessWithDetailViewModel.cs` | 100.00% | 5 / 5 |
| `ModernWMS.WMS/Entities/ViewModels/Stockprocess/StockprocessdetailViewModel.cs` | 100.00% | 4 / 4 |
| `ModernWMS.WMS/Entities/ViewModels/Stocktaking/StocktakingBasicViewModel.cs` | 100.00% | 3 / 3 |
| `ModernWMS.WMS/Entities/ViewModels/Stocktaking/StocktakingConfirmViewModel.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Stocktaking/StocktakingViewModel.cs` | 100.00% | 3 / 3 |
| `ModernWMS.WMS/Services/Stockadjust/StockadjustService.cs` | 100.00% | 8 / 8 |
| `ModernWMS.WMS/Services/Stockfreeze/StockfreezeService.cs` | 100.00% | 9 / 9 |
| `ModernWMS.WMS/Services/Stockmove/StockmoveService.cs` | 100.00% | 10 / 10 |
| `ModernWMS.WMS/Services/Stockprocess/StockprocessService.cs` | 100.00% | 10 / 10 |
| `ModernWMS.WMS/Services/Stocktaking/StocktakingService.cs` | 100.00% | 10 / 10 |

## 验证

- Targeted Unit：`cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~StockmoveServiceTests|FullyQualifiedName~StockfreezeServiceTests|FullyQualifiedName~StockprocessServiceTests|FullyQualifiedName~StocktakingServiceTests"`
  - 结果：10 passed
  - 日志：`/tmp/pi-modernwms-internal-operations-unit-final.log`
- Targeted API：`cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter FullyQualifiedName~InternalOperations`
  - 结果：4 passed
  - 日志：`/tmp/pi-modernwms-internal-operations-e2e-final.log`
- Full backend coverage：`MODERNWMS_COVERAGE_THRESHOLD=0 ./scripts/test-all.sh --skip-ui`
  - 结果：Unit 39 passed；API E2E 24 passed；全局后端 line coverage 65.11%
  - 日志：`/tmp/pi-modernwms-internal-operations-full-final.log`

## Mutation-style 抽样

| Mutant | 修改 | 验证命令 | 结果 |
| --- | --- | --- | --- |
| M1 | 把 `StockmoveService.Confirm` 中目标库存匹配从 `sku_id == entity.sku_id` 改回 `!=` | `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~StockmoveServiceTests` | killed；`ConfirmMovesQuantityIntoExistingDestinationLayer` 检出目标库存层被拆成两条，日志：`/tmp/pi-modernwms-internal-operations-mut1.log` |
| M2 | 把 `StocktakingService.ConfirmAsync` 的重复调整保护从 `job_type == 1` 改成永不命中的 `job_type == 9` | `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~StocktakingServiceTests` | killed；`ConfirmAsyncAppliesDifferenceOnceAndRejectsDuplicateAdjustment` 检出二次确认仍成功，日志：`/tmp/pi-modernwms-internal-operations-mut2.log` |

## 证据化例外

无。当前 context 25 个目标文件全部达到 100% line coverage，不存在残余未覆盖文件。

## 是否允许进入下一 context

允许。建议下一 Gate：出库履约（OutboundFulfillment）。
