# 后端覆盖率 Baseline（2026-05-18）

## 执行命令

```bash
MODERNWMS_COVERAGE_THRESHOLD=0 ./scripts/test-all.sh --skip-ui
```

日志：`/tmp/modernwms-cov-baseline-run.log`

## 覆盖率文件

- `backend/ModernWMS.Tests.ApiE2E/TestResults/4a1bb975-52c4-42bd-8402-ab74ace8eebe/coverage.cobertura.xml`
- `backend/ModernWMS.Tests.Unit/TestResults/a1ce036f-df79-4448-ae7a-a7aa1a29fd89/coverage.cobertura.xml`

## 全局结果

| 指标 | 值 |
| --- | ---: |
| 合并行覆盖 | 35.76% |
| Covered / Valid lines | 664 / 1857 |
| 后端测试结果 | Unit 16 passed；API E2E 12 passed |
| UI E2E | 跳过 |

## 按领域上下文的初始覆盖率

> 口径：按 cobertura 中 `ModernWMS.Core + ModernWMS.WMS` 文件行合并计算。业务上下文按文件路径粗分；Core/shared closure 为跨上下文公共代码。

| Context | 当前覆盖率 | Covered / Valid | 初始判断 |
| --- | ---: | ---: | --- |
| 基础主数据 | 7.00% | 20 / 286 | 缺口最大，且是下游测试数据基础，建议优先收敛 |
| 系统管理 | 14.46% | 24 / 166 | Auth 有覆盖，但 User/Company/Print/Userrole/Approve 等几乎未覆盖 |
| 入库执行 | 37.70% | 23 / 61 | 已有 ASN 冒烟，生命周期分支仍需补齐 |
| 库存可视化 | 51.35% | 19 / 37 | Service/Controller 已覆盖，主要剩 ViewModel/Entity/查询入口补足 |
| 库内作业 | 15.04% | 20 / 133 | 仅冻结有覆盖，移库/加工/盘点/调整基本未覆盖 |
| 出库履约 | 23.36% | 25 / 107 | Dispatch 主流程部分覆盖，Freightfee 与后续履约状态缺口明显 |
| Core/shared closure | 49.76% | 529 / 1063 | Startup 高覆盖拉高整体；转换、缓存、过滤器、租户等缺口大 |
| 未分类/其他 | 100.00% | 4 / 4 | `RequestLogger` |

## 低覆盖文件热点

### 基础主数据

| 覆盖率 | Covered / Valid | 文件 |
| ---: | ---: | --- |
| 0.00% | 0 / 74 | `ModernWMS.WMS/Services/Sku/SpuService.cs` |
| 0.00% | 0 / 22 | `ModernWMS.WMS/Services/Sku/CategoryService.cs` |
| 0.00% | 0 / 9 | `ModernWMS.WMS/Entities/ViewModels/Sku/SkuDetailViewModel.cs` |
| 0.00% | 0 / 9 | `ModernWMS.WMS/Entities/ViewModels/Sku/SkuViewModel.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Services/Customer/CustomerService.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Services/Goodslocation/GoodslocationService.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Services/GoodsOwner/GoodsownerService.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Services/Supplier/SupplierService.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Services/Warehousearea/WarehouseareaService.cs` |

### 系统管理

| 覆盖率 | Covered / Valid | 文件 |
| ---: | ---: | --- |
| 0.00% | 0 / 21 | `ModernWMS.WMS/Services/Approve/FlowSetService.cs` |
| 0.00% | 0 / 19 | `ModernWMS.WMS/Services/User/UserService.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Services/Company/CompanyService.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Services/Print/PrintSolutionService.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Services/Userrole/UserroleService.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Controllers/ActionLog/ActionLogController.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Controllers/Company/CompanyController.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Controllers/Print/PrintSolutionController.cs` |

### 入库执行

| 覆盖率 | Covered / Valid | 文件 |
| ---: | ---: | --- |
| 0.00% | 0 / 5 | `ModernWMS.WMS/Entities/ViewModels/Asn/Asnmaster/AsnmasterDetailViewModel.cs` |
| 0.00% | 0 / 4 | `ModernWMS.WMS/Entities/ViewModels/Asn/Asnmaster/AsnmasterBothViewModel.cs` |
| 0.00% | 0 / 4 | `ModernWMS.WMS/Entities/Models/Asn/AsnEntity.cs` |
| 0.00% | 0 / 3 | `ModernWMS.WMS/Entities/Models/Asn/AsnmasterEntity.cs` |

### 库存可视化

| 覆盖率 | Covered / Valid | 文件 |
| ---: | ---: | --- |
| 0.00% | 0 / 4 | `ModernWMS.WMS/Entities/ViewModels/Stock/StockViewModel.cs` |
| 0.00% | 0 / 4 | `ModernWMS.WMS/Entities/ViewModels/Stock/DeliveryStatisticViewModel.cs` |
| 0.00% | 0 / 2 | `ModernWMS.WMS/Entities/ViewModels/Stock/DeliveryStatisticSearchViewModel.cs` |
| 0.00% | 0 / 2 | `ModernWMS.WMS/Entities/ViewModels/Stock/SafetyStockManagementViewModel.cs` |
| 0.00% | 0 / 2 | `ModernWMS.WMS/Entities/ViewModels/Stock/StockAgeSearchViewModel.cs` |

### 库内作业

| 覆盖率 | Covered / Valid | 文件 |
| ---: | ---: | --- |
| 0.00% | 0 / 10 | `ModernWMS.WMS/Services/Stockmove/StockmoveService.cs` |
| 0.00% | 0 / 10 | `ModernWMS.WMS/Services/Stockprocess/StockprocessService.cs` |
| 0.00% | 0 / 10 | `ModernWMS.WMS/Services/Stocktaking/StocktakingService.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Services/Stockadjust/StockadjustService.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Controllers/Stockadjust/StockadjustController.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Controllers/Stockmove/StockmoveController.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Controllers/Stockprocess/StockprocessController.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Controllers/Stocktaking/StocktakingController.cs` |

### 出库履约

| 覆盖率 | Covered / Valid | 文件 |
| ---: | ---: | --- |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Services/Freightfee/FreightfeeService.cs` |
| 0.00% | 0 / 8 | `ModernWMS.WMS/Controllers/Freightfee/FreightfeeController.cs` |
| 0.00% | 0 / 7 | `ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistDetailViewModel.cs` |
| 0.00% | 0 / 7 | `ModernWMS.WMS/Entities/Models/Dispatchlist/DispatchlistEntity.cs` |
| 0.00% | 0 / 6 | `ModernWMS.WMS/Entities/ViewModels/Freightfee/FreightfeeViewModel.cs` |

### Core/shared closure

| 覆盖率 | Covered / Valid | 文件 |
| ---: | ---: | --- |
| 0.00% | 0 / 76 | `ModernWMS.Core/Utility/ModelConvertHelper.cs` |
| 0.00% | 0 / 15 | `ModernWMS.Core/MultiTenancy/TenantProvider.cs` |
| 0.00% | 0 / 3 | `ModernWMS.Core/DBContext/CallContext.cs` |
| 0.87% | 1 / 115 | `ModernWMS.Core/Utility/UtilConvert.cs` |
| 10.53% | 4 / 38 | `ModernWMS.Core/Utility/FucntionHelper.cs` |
| 11.27% | 8 / 71 | `ModernWMS.Core/JWT/CacheManger.cs` |
| 12.00% | 6 / 50 | `ModernWMS.Core/Middleware/ViewModelActionFiter.cs` |

## 后续使用方式

每个 context Gate 必须基于本 baseline 和最新 coverage 动态循环：

1. 重新计算该 context 当前 gap。
2. 先选业务 API E2E 场景覆盖可触达路径。
3. 分支爆炸或 API 不稳定覆盖时，转为单元/组件测试。
4. 达到 context 有效覆盖率 80% 后，在本 context 内做 mutation-style 抽样。
5. mutation survivor 或覆盖率不足都回到 gap 分析，不进入下一个 context。
