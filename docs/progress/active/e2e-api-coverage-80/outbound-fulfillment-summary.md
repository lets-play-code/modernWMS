# Context Gate 摘要：出库履约

## 状态

- 状态：completed
- Baseline 覆盖率：23.36%（25 / 107）
- 当前覆盖率：100.00%（107 / 107）
- 全局覆盖率：65.11%（1209 / 1857）→ 69.95%（1299 / 1857）
- Loop 次数：3
  1. 先基于最新 coverage 把缺口拆成 API E2E 与单元测试：Dispatch 完整履约主线、库存不足/取消失败场景走 API，DTO/Entity/服务辅助方法与签收规则走单元测试。
  2. 首轮红灯暴露一处真实生产 bug：`DispatchlistService.SignForArrival` 用 `t.id == t.id` 选取签收输入，多个明细同批签收时会错误复用首条 damage 数量；同时梳理出 API 上 `DispatchlistFreightfeeViewModel.carrier` 的必填约束，补齐真实请求字段。
  3. 修复签收 bug、补齐 Freightfee API 维护链路后重新跑 targeted/full coverage，context 达到 100%；随后做 3 个 mutation 抽样，全部被现有测试杀死。

## Gap 分类与收敛策略

### API E2E 可覆盖

- `POST /dispatchlist` + `POST /dispatchlist/advanced-list` + `POST /dispatchlist/list`：创建发货单、草稿/待处理查询。
- `GET /dispatchlist/confirm-check` + `POST /dispatchlist/confirm-order`：订单承诺、锁库但不扣库。
- `GET /dispatchlist/pick-list` + `PUT /dispatchlist/confirm-pick-dispatchlistno`：拣货明细与拣货确认。
- `POST /dispatchlist/package` / `weight` / `freightfee` / `delivery` / `sign`：打包、称重、设置承运、出库扣库、签收闭环。
- `POST /dispatchlist/cancel-order`：锁库后取消释放库存占用。
- `POST /freightfee` / `GET /freightfee` / `POST /freightfee/list` / `GET /freightfee/all` / `PUT /freightfee` / `POST /freightfee/excel` / `DELETE /freightfee`：运费模板维护与查询。

### 单元测试补强

- `DispatchlistServiceTests` 覆盖：
  - 草稿单创建、查询、更新、删除；
  - 承诺检查与锁库后库存不扣减；
  - 拣货、打包、称重、设置运费、出库扣库；
  - 按明细 ID 签收数量规则；
  - 整单取消、明细回退；
  - Freightfee CRUD / Excel 导入；
  - `GetPackageOrWeightCode` 辅助方法。

### 真实 bug / 生产修复

- `backend/ModernWMS.WMS/Services/Dispatchlist/DispatchlistService.cs`
  - `SignForArrival` 将匹配签收输入的条件从 `t.id == t.id` 修正为 `t.id == entity.id`，避免多明细同批签收时错误复用首条 damage 数量，确保 `sign_qty` 与 `damage_qty` 按明细正确计算。

## 业务场景覆盖

### 1. 发货单完整履约链路

文件：`backend/ModernWMS.Tests.ApiE2E/Features/OutboundFulfillment/dispatch-lifecycle.feature`

覆盖业务：
- 真实 API 创建发货单并回查 `advanced-list` / `list`；
- `confirm-check` 给出可承诺库存与推荐拣货明细；
- `confirm-order` 后仅锁库，不扣减库存，`dispatchpicklist.is_update_stock=false`；
- `confirm-pick-dispatchlistno`、`package`、`weight`、`freightfee`、`delivery`、`sign` 串成完整出库闭环；
- 出库后库存从 8 降到 3，签收后 `sign_qty=4`、`damage_qty=1`。

### 2. 库存不足确认失败

文件：`backend/ModernWMS.Tests.ApiE2E/Features/OutboundFulfillment/dispatch-lifecycle.feature`

覆盖业务：
- 库存仅 4 件、订单需求 6 件时，`confirm-check` 返回 `confirm=false`；
- 草稿单仍保持 `dispatch_status=0`、`lock_qty=0`；
- 库存视图保持 `qty_locked=0`、`qty_available=4`。

### 3. 锁库后取消释放库存

文件：`backend/ModernWMS.Tests.ApiE2E/Features/OutboundFulfillment/dispatch-lifecycle.feature`

覆盖业务：
- 已锁库发货单通过 `cancel-order` 回退到待处理；
- 拣货明细被清空；
- 库存从 `qty_locked=8` 恢复为 `qty_locked=0`、`qty_available=12`。

### 4. Freightfee 维护与查询

文件：`backend/ModernWMS.Tests.ApiE2E/Features/OutboundFulfillment/freightfee-management.feature`

覆盖业务：
- 新增运费模板后可通过详情、列表、全部查询读取；
- 更新到新城市/最低收费后响应可见；
- Excel 导入新增第二条模板；
- 删除后再次查询返回失败。

## 单元 / 组件测试

文件：`backend/ModernWMS.Tests.Unit/Services/DispatchlistServiceTests.cs`

新增/扩展 8 个测试：
- `AddUpdateDeleteAndQueryDraftDispatchAsync`
- `ConfirmOrderLocksInventoryWithoutDeductingStockAsync`
- `PackageWeightDeliveryAndFreightFlowUpdatesDispatchAndStockAsync`
- `SignForArrivalUsesMatchingViewModelPerDispatchIdAsync`
- `CancelOrderOperationCanRevertPickedDispatchBackToDraftAsync`
- `CancelDispatchlistDetailOperationRollsBackPackageAndWeightStagesAsync`
- `FreightfeeCrudAndExcelImportSupportQueriesAsync`
- `GetPackageOrWeightCodeUsesTodayPrefixAndDigits`

## 覆盖率明细

| 文件 | 覆盖率 | Covered / Valid |
| --- | ---: | ---: |
| `ModernWMS.WMS/Controllers/Dispatchlist/DispatchlistController.cs` | 100.00% | 8 / 8 |
| `ModernWMS.WMS/Controllers/Freightfee/FreightfeeController.cs` | 100.00% | 8 / 8 |
| `ModernWMS.WMS/Entities/Models/Dispatchlist/DispatchlistEntity.cs` | 100.00% | 7 / 7 |
| `ModernWMS.WMS/Entities/Models/Dispatchlist/DispatchpicklistEntity.cs` | 100.00% | 1 / 1 |
| `ModernWMS.WMS/Entities/Models/Freightfee/FreightfeeEntity.cs` | 100.00% | 4 / 4 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/CancelOrderOprationViewModel.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistAddViewModel.cs` | 100.00% | 4 / 4 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistConfirmDetailViewModel.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistConfirmPickDetailViewModel.cs` | 100.00% | 3 / 3 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistDeliveryViewModel.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistDetailViewModel.cs` | 100.00% | 7 / 7 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistFreightfeeViewModel.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistPackageViewModel.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistSignViewModel.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistViewModel.cs` | 100.00% | 7 / 7 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistWeightViewModel.cs` | 100.00% | 3 / 3 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchpicklistViewModel.cs` | 100.00% | 3 / 3 |
| `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/PreDispatchlistViewModel.cs` | 100.00% | 5 / 5 |
| `ModernWMS.WMS/Entities/ViewModels/Freightfee/FreightfeeExcelmportViewModel.cs` | 100.00% | 5 / 5 |
| `ModernWMS.WMS/Entities/ViewModels/Freightfee/FreightfeeViewModel.cs` | 100.00% | 6 / 6 |
| `ModernWMS.WMS/Services/Dispatchlist/DispatchlistService.cs` | 100.00% | 16 / 16 |
| `ModernWMS.WMS/Services/Freightfee/FreightfeeService.cs` | 100.00% | 8 / 8 |

## 验证

- Targeted Unit：`cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~DispatchlistServiceTests`
  - 结果：8 passed
  - 日志：`/tmp/pi-modernwms-outbound-fulfillment-unit-final.log`
- Targeted API：`cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter FullyQualifiedName~OutboundFulfillment`
  - 结果：4 passed
  - 日志：`/tmp/pi-modernwms-outbound-fulfillment-e2e-final.log`
- Full backend coverage：`MODERNWMS_COVERAGE_THRESHOLD=0 ./scripts/test-all.sh --skip-ui`
  - 结果：Unit 46 passed；API E2E 27 passed；全局后端 line coverage 69.95%
  - 日志：`/tmp/pi-modernwms-outbound-fulfillment-full-final.log`

## Mutation-style 抽样

| Mutant | 修改 | 验证命令 | 结果 |
| --- | --- | --- | --- |
| M1 | 把 `ConfirmOrder` 新建拣货明细的 `is_update_stock=false` 改成 `true` | `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~ConfirmOrderLocksInventoryWithoutDeductingStockAsync` | killed；`ConfirmOrderLocksInventoryWithoutDeductingStockAsync` 检出锁库阶段错误地把拣货明细标记为已扣库，日志：`/tmp/pi-modernwms-outbound-fulfillment-mut1.log` |
| M2 | 把 `Delivery` 中的库存扣减 `s.qty -= pick.picked_qty` 改成 `s.qty += pick.picked_qty` | `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~PackageWeightDeliveryAndFreightFlowUpdatesDispatchAndStockAsync` | killed；`PackageWeightDeliveryAndFreightFlowUpdatesDispatchAndStockAsync` 检出出库后库存从 8 错误变成 13，日志：`/tmp/pi-modernwms-outbound-fulfillment-mut2.log` |
| M3 | 把 `SignForArrival` 的 `sign_qty = actual_qty - damage_qty` 改成 `sign_qty = actual_qty` | `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~SignForArrivalUsesMatchingViewModelPerDispatchIdAsync` | killed；`SignForArrivalUsesMatchingViewModelPerDispatchIdAsync` 检出签收数量未扣减 damage，日志：`/tmp/pi-modernwms-outbound-fulfillment-mut3.log` |

## 证据化例外

无。当前 context 22 个目标文件全部达到 100% line coverage，不存在残余未覆盖文件。

## 是否允许进入下一 context

允许。建议下一 Gate：Core/shared closure。
