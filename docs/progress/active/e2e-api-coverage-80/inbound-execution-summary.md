# Context Gate 摘要：入库执行

## 状态

- 状态：completed
- Baseline 覆盖率：37.70%（23 / 61）
- 当前覆盖率：90.16%（55 / 61）
- 全局覆盖率：54.28%（1008 / 1857）→ 58.05%（1078 / 1857）
- Loop 次数：3
  1. 扩展入库 API E2E，覆盖 ASN 单头创建、到货确认、卸货、分拣、完成分拣、待上架查询、上架、打印序列号与库存形成。
  2. 增加草稿 ASN 批量改货主场景，补齐 `BulkModifyGoodsowner` 行为与查询视图回显。
  3. 用 `AsnService` 组件式单元测试补强数量规则与库存层合并/残次数量规则。

## Gap 分类与收敛策略

### API E2E 可覆盖

- `POST /asn/asnmaster`：创建单头 + 明细。
- `GET /asn/asnmaster`、`POST /asn/asnmaster/list`：草稿详情/列表视图。
- `PUT /asn/confirm`、`PUT /asn/unload`、`PUT /asn/sorting`、`PUT /asn/sorted`、`PUT /asn/putaway`：完整状态流转。
- `GET /asn/sorting`、`GET /asn/pending-putaway`、`POST /asn/list`、`POST /asn/print-sn`：分拣/待上架/收货明细/打印视图。
- `PUT /asn/bulk-modify-goods-owner`：草稿批量改货主。
- 非法状态动作：已卸货 ASN 直接上架被拒绝，且不会写入库存。

### 单元/组件测试补强

- `SortedAsync`：`sorted_qty` 小于/大于 `asn_qty` 时分别计算 shortage / more。
- `PutAwayAsync`：同库存层合并更新库存；残次区上架累计 `damage_qty`。

### 证据化例外

剩余未覆盖仅为以下 3 个 DTO，共 6 行：

- `ModernWMS.WMS/Entities/ViewModels/AnsSummary/AnsSummaryInputViewModel.cs`
- `ModernWMS.WMS/Entities/ViewModels/AnsSummary/AnsSummaryViewModel.cs`
- `ModernWMS.WMS/Entities/ViewModels/Asn/Flow/AsnFlowInputViewModel.cs`

证据：`rg -n "AnsSummaryInputViewModel|AnsSummaryViewModel|AsnFlowInputViewModel" backend/ModernWMS.WMS -S` 仅命中 DTO 定义文件本身，当前没有 Controller/Service 消费路径，属于未接线 DTO，而非可通过真实 API 触达的行为缺口。

## 新增 / 强化能力

- `MasterDataBuilder` 支持 `*.key` 命名跟踪，可在同一场景里稳定引用多库位/多货主：如 `${location.damage.id}`、`${goods_owner.secondary.id}`。
- `ResponseAssertionSteps` 支持数组路径解析：如 `body.json.data.detailList[0].id`、`body.json.data[0].series_number`。
- 新增通用领域规格：`已卸货的 到货通知`，用于非法状态动作校验。
- 新增领域仓储断言：`库存层`；并扩展 `到货通知` / `分拣记录` 查询字段。
- `库存视图` 仓储支持回退读取 `sku.code` 跟踪值，便于从 ASN 场景直接验证库存可用量。

## 业务场景覆盖

### 1. ASN 完整生命周期形成正常库存与残次库存

文件：`backend/ModernWMS.Tests.ApiE2E/Features/InboundExecution/asn-lifecycle.feature`

覆盖业务：
- 创建 ASN 单头与单行明细。
- 查询 ASN 单头详情/列表。
- 到货确认、卸货、分拣、完成分拣。
- 待上架视图返回序列号与可上架数量。
- 一次上架拆分到正常区与残次区，形成两层库存事实。
- 打印序列号查询可回读分拣生成的 SN。
- 收货明细列表反映 `actual_qty / sorted_qty / damage_qty`。
- 库存视图反映总量 8、可用量 6（残次区 2 不计入正常可用）。

### 2. 草稿 ASN 批量改货主

文件：`backend/ModernWMS.Tests.ApiE2E/Features/InboundExecution/asn-lifecycle.feature`

覆盖业务：
- 草稿 ASN 创建后可批量改货主。
- `GET /asn` 详情与数据库事实同步回显新的货主。

### 3. 非法状态动作拒绝

文件：`backend/ModernWMS.Tests.ApiE2E/Features/InboundExecution/asn-lifecycle.feature`

覆盖业务：
- 已卸货 ASN 不能直接执行上架。
- 拒绝后 `actual_qty`、库存层均保持不变。

## 单元 / 组件测试

文件：`backend/ModernWMS.Tests.Unit/Services/AsnServiceTests.cs`

- `SortedAsyncSetsMoreAndShortageQuantitiesFromSortedQty`
  - 覆盖 `sorted_qty < asn_qty` 与 `sorted_qty > asn_qty` 两类数量偏差。
- `PutAwayAsyncMergesExistingStockLayerAndTracksDamageQty`
  - 覆盖同库存层合并、残次区累计、`Asnsort.putaway_qty` 回写。

## 验证

- Targeted API：`cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter FullyQualifiedName~InboundExecution`
  - 结果：3 passed
  - 日志：`/tmp/pi-modernwms-inbound-execution-target-final.log`
- Targeted Unit：`cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~AsnServiceTests`
  - 结果：3 passed
  - 日志：`/tmp/pi-modernwms-inbound-execution-unit-final.log`
- Full backend coverage：`MODERNWMS_COVERAGE_THRESHOLD=0 ./scripts/test-all.sh --skip-ui`
  - 结果：API E2E 17 passed；Unit 31 passed；全局后端 line coverage 58.05%
  - 日志：`/tmp/pi-modernwms-inbound-execution-full-final.log`

## Mutation-style 抽样

| Mutant | 修改 | 验证命令 | 结果 |
| --- | --- | --- | --- |
| M1 | 将 `PutAwayAsync` 完成上架时的状态写回从 `4` 改成 `3` | `cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter FullyQualifiedName~InboundExecution` | killed；`asn_status:4` 列表场景查不到记录，日志：`/tmp/pi-modernwms-inbound-execution-mut1.log` |
| M2 | 将残次区判断从 `warehouse_area_property == 5` 改成 `== 4` | `cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter FullyQualifiedName~InboundExecution` | killed；`damage_qty=2` / 库存可用量断言失败，日志：`/tmp/pi-modernwms-inbound-execution-mut2.log` |

## 是否允许进入下一 context

允许。建议下一 Gate：库存可视化。
