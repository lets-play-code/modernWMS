# Context Gate 摘要：库存可视化

## 状态

- 状态：completed
- Baseline 覆盖率：51.35%（19 / 37）
- 当前覆盖率：100.00%（37 / 37）
- 全局覆盖率：58.05%（1078 / 1857）→ 58.91%（1094 / 1857）
- Loop 次数：2
  1. 先把库存查询、库位库存、库存选择、安全库存、库龄、出库统计的 failing API/单测写出来，定位到两类根因：`可用库存` DSL 只会插库存层，无法表达锁定/安全库存/统计；`SafetyStockPageAsync` 错把残次区数量计入仓库可用量。
  2. 扩展库存 DSL 以真实 MySQL 落库 dispatch/process/move/safety/delivery/date/price 数据；随后把安全库存查询改成仓库级正常区聚合 + 相关锁定子查询，消除 left join 空值异常并完成最终验证与 mutation 抽样。

## Gap 分类与收敛策略

### API E2E 可覆盖

- `POST /stock/stock-list`：库存总量、冻结量、出库锁定量、加工锁定量、移库锁定量共同影响可用量。
- `POST /stock/location-list`：库位视角返回可用量 / 冻结量 / 锁定量。
- `POST /stock/select`：默认 / `all` / `frozen` 三类库存选择过滤。
- `POST /stock/safety-list`：仓库级安全库存阈值与可用量。
- `POST /stock/stock-age-list`：库龄与有效期范围过滤。
- `POST /stock/delivery-list`：已出库统计的数量 / 金额 / 时间过滤。

### 单元/组件测试补强

- `StockPageAsync`：用真实 MySQL 组合冻结、残次区、出库锁定、加工锁定、移库锁定，直接校验可用量公式。
- `SelectPageAsync`：校验默认 / `all` / `frozen` 三个过滤分支，保证查询入口不会把不可承诺库存暴露给下游。
- `SafetyStockPageAsync`：校验仓库级聚合时残次区不计入可用量，并验证安全库存阈值回显。

### 真实 bug / 生产修复

- `backend/ModernWMS.WMS/Services/Stock/StockService.cs`
  - `SafetyStockPageAsync` 原实现把仓库级 `qty_available` 建立在总库存 `sg.qty` 上，并通过错误的库位 join 间接读取 `warehouse_area_property`，导致残次区库存被计入可用量。
  - 首轮修复后还暴露出 left join 物化空值异常；最终改成“正常区聚合 + 相关锁定子查询”的仓库级计算，消除了异常并让 API / 单测一致通过。

## 新增 / 强化能力

- `AvailableStockSpec` 现在支持在一张表里声明真实库存层之外的业务占用：
  - `dispatch_lock_qty` / `dispatch_qty` / `dispatch_picked_qty` / `dispatch_status` / `delivery_date`
  - `process_locked_qty`
  - `move_locked_qty`
  - `safety_stock_qty`
  - `sku.price` / `expiry_date` / `putaway_date` / `series_number`
- `StockViewRepository` 同步对齐库存汇总公式，补上 dispatch lock、加工锁定、移库锁定与残次区排除逻辑，后续库存 DSL 可继续复用。
- `StockServiceTests` 从占位 smoke test 升级为真实 MySQL 组件测试，覆盖库存公式、选择过滤、安全库存仓库聚合。

## 业务场景覆盖

### 1. 库存汇总可用量

文件：`backend/ModernWMS.Tests.ApiE2E/Features/InventoryVisibility/stock-availability.feature`

覆盖业务：
- 冻结库存不计入可承诺库存；
- 残次区库存进入总量，但不进入正常可用量；
- 出库锁定、加工锁定、移库锁定会一起扣减可用量；
- `stock-list` API 直接返回可用量 12、锁定量 8、冻结量 3、总量 27。

### 2. 库位库存与库存选择

文件：`backend/ModernWMS.Tests.ApiE2E/Features/InventoryVisibility/stock-availability.feature`

覆盖业务：
- `location-list` 返回每个库存层的可用量 / 锁定量 / 冻结量；
- `select` 默认只返回可承诺库存；
- `sqlTitle=all` 返回全部库存层；
- `sqlTitle=frozen` 只返回冻结库存。

### 3. 安全库存视图

文件：`backend/ModernWMS.Tests.ApiE2E/Features/InventoryVisibility/stock-availability.feature`

覆盖业务：
- 仓库级总量 = 正常区 + 冻结 + 残次；
- 仓库级可用量仅来自正常区扣减冻结/锁定；
- `safety-list` 能同时返回仓库名称、库存总量、可用量和安全库存阈值。

### 4. 库龄与统计查询

文件：`backend/ModernWMS.Tests.ApiE2E/Features/InventoryVisibility/stock-availability.feature`

覆盖业务：
- `stock-age-list` 按 `stock_age_from/stock_age_to` 与 `expiry_date_from/expiry_date_to` 过滤；
- `delivery-list` 按时间窗、客户、货主过滤已出库统计，并返回 `delivery_qty` 与 `delivery_amount`。

## 单元 / 组件测试

文件：`backend/ModernWMS.Tests.Unit/Services/StockServiceTests.cs`

- `StockPageAsyncAggregatesFrozenDamageAndTaskLocksIntoAvailableQty`
  - 覆盖冻结、残次区、dispatch/process/move 组合公式。
- `SelectPageAsyncFiltersDefaultAllAndFrozenBuckets`
  - 覆盖默认 / `all` / `frozen` 三个过滤入口。
- `SafetyStockPageAsyncAggregatesWarehouseAvailabilityAndThreshold`
  - 覆盖仓库级正常区可用量、安全库存阈值与残次区排除。

## 覆盖率明细

| 文件 | 覆盖率 | Covered / Valid |
| --- | ---: | ---: |
| `ModernWMS.WMS/Controllers/Stock/StockController.cs` | 100.00% | 8 / 8 |
| `ModernWMS.WMS/Services/Stock/StockService.cs` | 100.00% | 9 / 9 |
| `ModernWMS.WMS/Entities/Models/Stock/StockEntity.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Stock/StockManagementViewModel.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Stock/LocationStockManagementViewModel.cs` | 100.00% | 1 / 1 |
| `ModernWMS.WMS/Entities/ViewModels/Stock/StockViewModel.cs` | 100.00% | 4 / 4 |
| `ModernWMS.WMS/Entities/ViewModels/Stock/SafetyStockManagementViewModel.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Stock/DeliveryStatisticSearchViewModel.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Stock/DeliveryStatisticViewModel.cs` | 100.00% | 4 / 4 |
| `ModernWMS.WMS/Entities/ViewModels/Stock/StockAgeSearchViewModel.cs` | 100.00% | 2 / 2 |
| `ModernWMS.WMS/Entities/ViewModels/Stock/StockAgeViewModel.cs` | 100.00% | 1 / 1 |

## 验证

- Targeted Unit：`cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~StockServiceTests`
  - 结果：3 passed
  - 日志：`/tmp/pi-modernwms-inventory-visibility-unit-postmut.log`
- Targeted API：`cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter FullyQualifiedName~InventoryVisibility`
  - 结果：5 passed
  - 日志：`/tmp/pi-modernwms-inventory-visibility-e2e-postmut.log`
- Full backend coverage：`MODERNWMS_COVERAGE_THRESHOLD=0 ./scripts/test-all.sh --skip-ui`
  - 结果：Unit 33 passed；API E2E 21 passed；全局后端 line coverage 58.91%
  - 日志：`/tmp/pi-modernwms-inventory-visibility-full-postmut.log`

## Mutation-style 抽样

| Mutant | 修改 | 验证命令 | 结果 |
| --- | --- | --- | --- |
| M1 | 把 `StockPageAsync` 的可用量公式里“移库锁定扣减”删除 | `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~StockServiceTests` | killed；`StockPageAsyncAggregatesFrozenDamageAndTaskLocksIntoAvailableQty` 断言从 12 变 13，日志：`/tmp/pi-modernwms-inventory-visibility-mut1.log` |
| M2 | 把 `SelectPageAsync` 默认过滤从 `qty_available > 0` 改成 `qty_available >= 0` | `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~StockServiceTests.SelectPageAsyncFiltersDefaultAllAndFrozenBuckets` | killed；默认查询 totals 从 1 变 3，日志：`/tmp/pi-modernwms-inventory-visibility-mut2.log` |

## 证据化例外

无。当前 context 11 个目标文件均达到 100% line coverage，不存在残余未覆盖文件。

## 是否允许进入下一 context

允许。建议下一 Gate：库内作业。
