# Context Gate 摘要：系统管理

## 状态

- 状态：completed
- Baseline 覆盖率：14.46%（24 / 166）
- 当前覆盖率：83.33%（145 / 174）
- 全局覆盖率：47.87%（889 / 1857）→ 54.28%（1008 / 1857）
- Loop 次数：1

## Gap 分类与收敛策略

### API E2E 可覆盖

- `Company`：新增、查询、更新、删除。
- `ActionLog`：人工写入日志与列表查询。
- `PrintSolution`：新增、按 id 查询、按路径查询、分页查询、更新、删除。
- `Userrole / Rolemenu / User`：角色创建与改名、菜单授权、用户新增、密码重置、改密、Excel 导入、删除。
- `Register`：新租户注册后登录并读取默认菜单权限。

### 证据化例外

- `ModernWMS.WMS/Services/Approve/FlowSetService.cs`
- `ModernWMS.WMS/Entities/Models/Approve/FlowSetMainEntity.cs`
- `ModernWMS.WMS/Entities/ViewModels/Approve/FlowSetMapGetViewModel.cs`
- `ModernWMS.WMS/Entities/ViewModels/Approve/FlowSetUserViewModel.cs`

证据：
1. 仓内搜索未发现 `FlowSetController`、`IFlowSetService` 或 `AddScoped<...FlowSet...>` 注册；当前代码没有可触达 API 入口。
2. `FlowSetService.BuildFlow` 递归调用写成 `BuildFlow(fsm_lsit, fsm.prev_node_guid)`，若命中分支会沿相同 `prev_node_guid` 自递归，疑似无限递归 bug。
3. 因无公开入口且涉及真实行为歧义，本 Gate 将其记为 evidence-based exception，而不是在系统管理 API Gate 内强行修改生产代码。

另一个剩余缺口：
- `ModernWMS.Core/Services/AccountService.cs` 剩余未覆盖行为仅为 `HelloWorld()` 本地化 helper，不属于系统管理 API 行为路径。

## 新增 / 强化能力

- 在 `ResponseAssertionSteps` 新增通用 step：`记录响应字段 "..." 为 "..."`，用于把最新响应中的 id / token / 标识写入 `ScenarioDataContext`。
- 在 `ScenarioDataContext` 新增占位符变换：`${md5:key}`，用于串联“重置密码返回明文 → 改密接口提交 MD5”这类真实业务链路。

## 业务场景覆盖

### 1. 公司资料、打印方案与操作日志

文件：`backend/ModernWMS.Tests.ApiE2E/Features/SystemManagement/company-print-and-log.feature`

覆盖业务：
- 公司资料新增、查询、更新、删除。
- 操作日志手工写入与按 `vue_path` 查询。
- 打印方案新增、按 id 查询、按 path 查询、分页列表、更新、删除。

### 2. 用户、角色与菜单权限

文件：`backend/ModernWMS.Tests.ApiE2E/Features/SystemManagement/user-role-and-menu.feature`

覆盖业务：
- 角色新增与改名。
- 菜单清单读取、角色菜单授权、角色菜单详情读取、角色菜单列表读取、授权菜单读取。
- 用户新增、按 id 查询、分页查询、密码重置、改密后重新登录、Excel 导入、删除。
- 角色菜单删除、角色删除。

### 3. 租户注册

文件：`backend/ModernWMS.Tests.ApiE2E/Features/SystemManagement/tenant-registration.feature`

覆盖业务：
- 新租户注册。
- 注册账号登录。
- 读取该租户默认菜单权限。
- 读取新租户下的角色选择项。

## 验证

- Targeted API：`cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~Authentication|FullyQualifiedName~SystemManagement"` 通过。
- Full backend coverage：`MODERNWMS_COVERAGE_THRESHOLD=0 ./scripts/test-all.sh --skip-ui` 通过。
- 最终系统管理 context：83.33%（145 / 174）。
- 最终全局后端覆盖率：54.28%（1008 / 1857）。

## Mutation-style 抽样

| Mutant | 修改 | 验证命令 | 结果 |
| --- | --- | --- | --- |
| M1 | 将 `PrintSolutionService.GetByPathAsync` 的 `tab_page` 过滤条件改成固定错误值 | `dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~SystemManagement"` | killed，打印方案按路径查询场景失败 |
| M2 | 反转 `UserService.ChangePwd` 的旧密码校验条件 | `dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~SystemManagement"` | killed，用户改密场景失败 |

## 是否允许进入下一 context

允许。建议下一 Gate：入库执行。
