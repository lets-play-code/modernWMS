# Context Gate 摘要：基础主数据

## 状态

- 状态：completed
- Baseline 覆盖率：7.00%（20 / 286）
- 当前覆盖率：84.27%（241 / 286）
- Loop 次数：3
  1. 扩展主数据 API 查询场景，覆盖仓库、库区、库位、货主、供应商、客户、分类、SPU/SKU 查询。
  2. 增加 SPU 详情、SKU 条码查询、安全库存维护、SPU 新增与重复校验等业务 API 场景。
  3. 对 SPU 体积单位换算分支用单元测试补强。

## 修改文件

- `backend/ModernWMS.Tests.ApiE2E/Features/MasterData/warehouse-and-sku.feature`
- `backend/ModernWMS.Tests.ApiE2E/Steps/ResponseAssertionSteps.cs`
- `backend/ModernWMS.Tests.ApiE2E/Support/ApiClient.cs`
- `backend/ModernWMS.Tests.ApiE2E/Support/ScenarioDataContext.cs`
- `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Specs/MasterDataSpecs.cs`
- `backend/ModernWMS.Tests.Unit/Services/SpuServiceTests.cs`

## 新增 / 强化能力

- 新增通用响应对象模式断言：`response body should match:`。
- 新增请求 path/body 中 `${key}` 占位符解析，用于串联测试数据规格中跟踪的业务 ID。
- `仓库和SKU` 规格现在跟踪主数据 ID 与业务编码，支持 API 场景使用真实关联 ID。

## 业务场景覆盖

- 主数据维护界面可按 API 查询到仓库、库区、库位、货主、供应商、客户。
- SPU 列表、SPU 详情、SKU 条码查询可返回商品目录与 SKU 明细。
- SKU 安全库存可维护并在 SPU 详情中体现。
- 新增 SPU/SKU 可成功，重复 SPU code 被拒绝。
- SPU SKU 体积单位换算矩阵由单元测试覆盖，避免为了覆盖分支堆叠大量 API case。

## 仍未覆盖 / 例外说明

当前 context 已超过 80%。剩余未覆盖主要为：

- Excel import DTO：`CustomerImportViewModel`、`GoodsownerImportViewModel`、`SupplierExcelImportViewModel`、`WarehouseExcelImportViewModel`。
- 下拉选择 DTO：`SkuSelectViewModel`。
- `CategoryService` 的部分更新/删除级联分支。

这些不是本 Gate 阻塞项：当前 API E2E 已覆盖主数据核心查询与商品主数据维护；复杂/低频导入分支可在后续 Core/shared 或专门导入能力 Gate 中补充。

## 验证

- Targeted API E2E：`dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter FullyQualifiedName~MasterData` 通过。
- Targeted Unit：`dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~SpuServiceTests` 通过。
- Full backend coverage：`MODERNWMS_COVERAGE_THRESHOLD=0 ./scripts/test-all.sh --skip-ui` 通过。
- 当前全局覆盖率：47.87%（889 / 1857）。

## Mutation-style 抽样

| Mutant | 修改 | 验证命令 | 结果 |
| --- | --- | --- | --- |
| M1 | 将 `ChangeLengthUnit(length_unit=1, volume_unit=2)` 返回值从 `0.01M` 改为 `0.02M` | `dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~SpuServiceTests` | killed，单位换算测试失败 |
| M2 | 将 `GetSkuByBarCodeAsync` 的条码查询条件改为永远查不到目标条码 | `dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter FullyQualifiedName~MasterData` | killed，SKU 条码 API 场景失败 |

## 是否允许进入下一 context

允许。建议下一 Gate：系统管理。
