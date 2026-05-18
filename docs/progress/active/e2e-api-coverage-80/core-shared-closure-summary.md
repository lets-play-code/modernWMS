# Context Gate 摘要：Core/shared closure

## 状态

- 状态：completed
- Gate0 基线：49.76%
- 本轮启动基线：54.75%（582 / 1063，`ModernWMS.Core`）
- 当前 Core/shared 覆盖率：93.67%（1007 / 1075，`ModernWMS.Core`）
- 全局覆盖率：69.95%（1299 / 1857）→ 92.24%（1724 / 1869）
- Loop 次数：2

## Gap 分类与收敛策略

### 单元测试优先补齐

- 转换与序列化：`UtilConvert`、`ModelConvertHelper`、`JsonHelper`、`JsonStringTrimConverter`
- 查询与响应：`QueryCollection`、`ResultModel` 现有覆盖基础上补边界
- 认证与缓存：`CacheManager`、`TokenManager`
- 中间件与上下文：`ViewModelActionFiter`、`CorsMiddleware`、`TenantProvider`、`CallContext`
- DB/辅助能力：`SqlDBContext` helper、`FunctionHelper`、`AccountService`

### 最小生产修复（由 failing test 证明）

1. `ModernWMS.Core/Utility/UtilConvert.cs`
   - 为 `ObjToDouble/ObjToDecimal` 两组重载补齐 `null` 防御，消除 `NullReferenceException`。
2. `ModernWMS.Core/Utility/ModelConvertHelper.cs`
   - `double` 空值默认分支改为写入 `0D`，避免把 `decimal` 写到 `double` 属性时整行被吞掉。
3. `ModernWMS.Core/Middleware/CorsMiddleware.cs`
   - `Origin` 为空时不再回写空的 `Access-Control-Allow-Origin`。

## 新增 / 强化测试

### 新增测试文件

- `backend/ModernWMS.Tests.Unit/Core/UtilityConversionTests.cs`
  - 覆盖 DataTable → model 映射、空值默认、坏行跳过、数值/日期/字符串转换、JSON helper、trim converter。
- `backend/ModernWMS.Tests.Unit/Core/CacheManagerTests.cs`
  - 覆盖 cache set/get/remove、sliding/absolute expire、refresh token 匹配与 missing-token 回退。
- `backend/ModernWMS.Tests.Unit/Core/MiddlewareTests.cs`
  - 覆盖 GET/POST 模型校验输出、OPTIONS CORS short-circuit、普通请求 header 回写。
- `backend/ModernWMS.Tests.Unit/Core/CoreInfrastructureTests.cs`
  - 覆盖 `TenantProvider`、`CallContext`、`SqlDBContext` helper、`FunctionHelper`、`AccountService`。

### 强化既有测试文件

- `backend/ModernWMS.Tests.Unit/Core/DynamicSearchTests.cs`
  - 增补 OR 条件、日期上界、nullable equal、invalid query/null expression。
- `backend/ModernWMS.Tests.Unit/Core/TokenManagerTests.cs`
  - 增补 Authorization header 读取、无 HttpContext / non-bearer / empty string token fallback、refresh token base64 断言。

## 验证

- Targeted Core unit：
  - `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter FullyQualifiedName~Core`
  - 最终日志：`/tmp/pi-modernwms-core-shared-loop2c-green.log`
  - 结果：37 tests passed
- Full backend coverage：
  - `MODERNWMS_COVERAGE_THRESHOLD=0 ./scripts/test-all.sh --skip-ui`
  - 最终日志：`/tmp/pi-modernwms-core-shared-full-final3.log`
  - 结果：75 Unit + 27 API E2E passed；Backend line coverage = 92.24%

## Mutation-style 抽样

| Mutant | 修改 | 验证命令 | 结果 |
| --- | --- | --- | --- |
| M1 | 将 `ModelConvertHelper` 的 `double` 空值默认从 `0D` 改回 `0M` | `dotnet test ... --filter FullyQualifiedName~UtilityConversionTests` | killed，`ModelConvertHelperUsesDefaultsForEmptyValues` 失败；日志：`/tmp/pi-modernwms-core-shared-mut1.log` |
| M2 | 将 `QueryCollection` 日期上界从 `23:59:59` 改为 `00:00:00` | `dotnet test ... --filter FullyQualifiedName~DynamicSearchTests` | killed，`DateTimePickerLessThanOrEqualIncludesEndOfSelectedDay` 失败；日志：`/tmp/pi-modernwms-core-shared-mut2.log` |
| M3 | 反转 `CacheManager.Is_Token_Exist` 的 refresh token 匹配条件 | `dotnet test ... --filter FullyQualifiedName~CacheManagerTests` | killed，`CacheSetVariantsAndTokenHelperRoundTripValues` 失败；日志：`/tmp/pi-modernwms-core-shared-mut3.log` |

## 证据化例外

详见 `docs/progress/active/e2e-api-coverage-80/exceptions.md`。本轮保留的例外主要是：

- `SqlDBContext.SqlQueryDynamic<T>` 的 provider-specific raw ADO path
- `StartupExtensions` 的 Development / null-guard / host pipeline 分支
- `TokenManager` / `FunctionHelper` 中依赖 JWT validator 前置约束的 defensive fallback
- `QueryCollection` 中已被前置 `continue` 截断的 dead code
- `CacheManager.Default` 静态字段与不可达 key guard
- `AccountController.hello_world()` 的匿名本地化 echo 包装层

## 是否允许进入下一 context

允许。建议下一 Gate：完成。
