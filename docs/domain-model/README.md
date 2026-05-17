# 领域模型文档

本目录存放 ModernWMS 的长期业务领域知识。

## 当前文档

- `user-journeys.md`：从角色和业务流程角度说明系统如何被使用
- `bounded-contexts.md`：说明系统中的业务上下文划分、边界与依赖关系
- `strategic-ddd-design.md`：说明核心域、支撑域、通用域、统一语言与战略设计判断

## 分析依据

以下文档基于 `understand-explain` 的阅读方式整理，主要参考：

- `.understand-anything/knowledge-graph.json`
- `backend/ModernWMS.WMS/Services/Asn/AsnService.cs`
- `backend/ModernWMS.WMS/Services/Dispatchlist/DispatchlistService.cs`
- `backend/ModernWMS.WMS/Services/Stock/StockService.cs`
- `backend/ModernWMS.WMS/Services/Stockmove/StockmoveService.cs`
- `backend/ModernWMS.WMS/Services/Stocktaking/StocktakingService.cs`
- `backend/ModernWMS.WMS/Services/Warehouse/WarehouseService.cs`
- `backend/ModernWMS.WMS/Services/Warehousearea/WarehouseareaService.cs`
- `backend/ModernWMS.WMS/Services/Goodslocation/GoodslocationService.cs`
- `backend/ModernWMS.WMS/Services/GoodsOwner/GoodsownerService.cs`
- `backend/ModernWMS.WMS/Services/Sku/SpuService.cs`
- `frontend/src/view/base/warehouseSetting/warehouseSetting.vue`
- `frontend/src/view/base/commodityManagement/commodityManagement.vue`
- `frontend/src/view/wms/stockAsn/stockAsn.vue`
- `frontend/src/view/wms/stockManagement/stockManagement.vue`
- `frontend/src/view/deliveryManagement/deliveryManagement/deliveryManagement.vue`
- `frontend/src/view/warehouseWorking/warehouseMove/warehouseMove.vue`
- `frontend/src/view/warehouseWorking/warehouseTaking/warehouseTaking.vue`

## 后续扩展建议

如果领域知识继续细化，可以在本目录继续增加：

- `ubiquitous-language.md`
- `aggregates-and-invariants.md`
- `domain-events-and-state-transitions.md`
- `roles-and-authority-model.md`
