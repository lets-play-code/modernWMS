# E2E API Coverage 80% Exceptions

> 本文件集中记录当前仍保留的 evidence-based exceptions。已完成业务 context 的历史例外继续以各自 summary 为准；本次主要补充 Core/shared closure 的剩余未覆盖代码。

## Core/shared closure

| 文件 / 行 | 现状 | 证据 |
| --- | --- | --- |
| `ModernWMS.Core/DBContext/SqlDBContext.cs:131-171` | `SqlQueryDynamic<T>` raw ADO helper 未直接命中 | 当前已覆盖 `EnsureCreated`、`GetDbSet`、`DataTableToIList` 与模型自动映射。剩余段落依赖 `DbProviderFactories.GetFactory(connection)`、`DbDataAdapter.Fill(DataTable)` 和 provider-specific `DbCommand/DbConnection` 行为；现有后端主路径统一走 EF Core LINQ/ExecuteUpdate/ExecuteDelete，不经过此 helper。若未来业务实际调用该 helper，应优先补组件测试或删除未使用 helper。 |
| `ModernWMS.Core/Extentions/StartupExtensions.cs:124-126,168-169,255-256` | host/config guard 未直接命中 | 剩余行分别是 Development-only middleware 分支与 public extension 的 `null` guard。命中需要真实 ASP.NET host 切到 Development、启动 Hangfire pipeline，或故意向 extension 传 `null` 的 `IServiceCollection`；当前文件已覆盖 `250 / 257`。 |
| `ModernWMS.Core/JWT/TokenManager.cs:74-75,98-99,107-108,112-113,139-140,148-149` | defensive fallback / dead branch 未直接命中 | 已覆盖正常 token round-trip、Authorization header 读取、non-bearer header、empty string token。剩余分支要么需要 `ValidateToken` 成功但返回非 `JwtSecurityToken` 或 claim 反序列化为 `null`（在当前 validator 前置约束下不稳定），要么依赖被 `ObjToString().Trim()` 消掉的“空 Bearer”死分支。 |
| `ModernWMS.Core/Utility/FucntionHelper.cs:60-61,69-70,74-75` | 与 `TokenManager` 同构的 defensive fallback 未直接命中 | 当前已覆盖有效 token 取租户、默认序号生成、年/月重置规则。剩余分支只会在无效 JWT 仍通过验证，或命中同样的“空 Bearer”死分支时出现。 |
| `ModernWMS.Core/DynamicSearch/QueryCollection.cs:57-59` | dead code | 代码在 50-54 行已对 `item.Text.Trim().Length == 0` 直接 `continue`，因此后续 `if (item.Text.Length == 0) item.Text = item.Value.ToString();` 不可达。 |
| `ModernWMS.Core/JWT/CacheManger.cs:13,127` | static field / dead guard 未直接命中 | `Default` 为静态默认实例字段，无额外行为分支；`Is_Token_Exist` 内的 `key = $"ModernWMS_{type}_{userID}"` 不会生成空白字符串，因此 `ArgumentNullException` guard 为不可达防御。 |
| `ModernWMS.Core/Controller/AccountController.cs:150-152` | `hello_world()` 匿名本地化 echo 包装层未直接命中 | `AccountService.HelloWorld()` 已有单元测试覆盖；控制器方法只做一层 `ResultModel.Success` 包装，不影响登录、refresh token、鉴权失败等主认证路径。 |
