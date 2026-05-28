# ModernWMS AI 协同后端功能实现作业指导书

## 适用场景

适用于 **后端新功能开发**、**新接口实现**、**新服务能力补齐**。

前置条件：
- 需求分析或设计已确认
- 已明确目标上下文与 MVP 范围
- 已确认本次能力更适合由 **单元测试**、**API E2E**，还是 **UI 驱动 E2E** 来承接主要验证

## 必读文档

- `docs/development-standards/backend-conventions.md`
- `docs/development-standards/testing-conventions.md`
- `docs/software-design/api-design.md`
- 目标上下文的 `docs/domain-model/<context>/overview.md`
- 对应需求文档：`docs/requirements/...`

## 真实技术栈映射

> 本项目后端不是 Java / Spring / JPA / Maven 体系，必须按实际栈执行。

| 主题 | ModernWMS 实际方案 |
| --- | --- |
| 语言 / 平台 | C# / .NET 7 |
| Web 框架 | ASP.NET Core |
| 数据访问 | EF Core + `SqlDBContext` |
| 依赖注入 | `IDependency` + `RegisterAssembly()` 自动扫描 |
| API 返回 | `ResultModel<T>`、`PageData<T>` |
| 分页查询 | `PageSearch` + `SearchObject` + `QueryCollection` |
| API E2E | Reqnroll + xUnit + Testcontainers.MySql |
| 单元测试 | xUnit + FluentAssertions |
| UI 驱动 E2E | Playwright（真实前端 + 后端 API + 数据库，需要时补充） |
| 全量验证 | `./scripts/test-all.sh --skip-ui` |

## 本 SOP 对齐的开发基线

本 SOP 的开发阶段**严格对齐** `superpowers:test-driven-development`：

```text
RED（先写失败测试）
→ Verify RED（确认因目标行为缺失而失败）
→ GREEN（最小实现）
→ Verify GREEN（当前目标测试通过）
→ REFACTOR（仅在绿灯下整理）
→ Final Verification（按影响范围做最小充分验证）
```

## 核心原则

1. **任何生产代码前必须先有失败测试**
2. **未完成 Verify RED，不得进入实现**
3. **未完成 Verify GREEN，不得进入重构或宣称完成**
4. **薄 Controller，厚 Service**
5. **显式处理租户、校验、本地化、日志**
6. **最小改动，不顺手重构无关模块**

## TDD 强制门禁

### 1. RED 门禁

以下内容都算生产代码，**不得先写**：
- `Controllers`
- `IServices`
- `Services`
- `Entities/ViewModels`
- `Entities/Models`
- seed、权限、路由配套所需的真实业务改动

### 2. Verify RED 门禁

必须亲自运行目标测试并确认：
- 测试确实失败，而不是直接通过
- 失败原因与“功能尚未实现 / 旧行为仍存在”一致
- 不是环境错误、端口错误、数据库没起、选择器错、断言写错

如果测试：
- **直接通过** → 说明你没有覆盖到新行为，先修测试
- **报环境错误** → 先修环境 / 测试夹具，不准跳去写实现

### 3. GREEN 门禁

实现阶段只允许：
- 让当前失败测试通过所需的**最小代码**
- 与当前行为直接相关的最小配套修改

不允许：
- 顺手重构
- 顺手修无关问题
- 一次打包多个行为变更

### 4. Verify GREEN 门禁

至少确认：
1. 当前 RED 测试现在通过
2. 受影响的相邻测试类 / feature 通过
3. 如果命中 UI 驱动 E2E 触发条件，则目标 UI 驱动 E2E 也通过

### 5. REFACTOR 门禁

只有在 Verify GREEN 完成后，才允许做局部整理；整理后必须重新回到绿灯。

## UI 驱动 E2E 何时必须进入验证链路

当满足以下任一条件时，**UI 驱动 E2E 必须进入本次开发的验证链路**；如果它是主要验收点，就应在 RED 阶段先写 / 先改它：

- 菜单、路由、页面可达性发生变化
- 按钮权限、visible / disabled 语义发生变化
- 前端依赖后端字段做状态展示、可见性判断、前后端一致性逻辑
- 需要确认真实用户链路在 **UI + API + DB** 上一起工作

如果以上条件都不满足，UI 驱动 E2E 可不作为本次主 RED 测试，但仍要在最终验证时重新评估是否需要补跑。

## 流程总览

```text
0. 阅读现有实现与测试
1. 选择验证切片并编写失败测试（RED）
2. 验证红灯（Verify RED）
3. 最小实现（GREEN）
4. 验证绿灯（Verify GREEN）
5. 最小重构（REFACTOR）
6. 最小充分验证（Final Verification）
7. 如需，交接前端实现
```

---

## 步骤 0：阅读现有实现与测试

### 重点阅读路径

- 启动与装配：
  - `backend/ModernWMS/Program.cs`
  - `backend/ModernWMS/Startup.cs`
  - `backend/ModernWMS.Core/Extentions/StartupExtensions.cs`
- 业务实现：
  - `backend/ModernWMS.WMS/Controllers/...`
  - `backend/ModernWMS.WMS/IServices/...`
  - `backend/ModernWMS.WMS/Services/...`
  - `backend/ModernWMS.WMS/Entities/ViewModels/...`
- 测试：
  - `backend/ModernWMS.Tests.ApiE2E/Features/...`
  - `backend/ModernWMS.Tests.ApiE2E/Support/...`
  - `backend/ModernWMS.Tests.Unit/...`

### 需要确认的点

- 新能力属于哪个资源前缀（如 `/asn`、`/dispatchlist`、`/stock`）
- 现有 service 是否已经有相近方法
- 是否需要菜单、权限、种子数据或操作日志配套
- 本次最小可验证切片更适合由哪种测试承接：单元测试、API E2E、UI 驱动 E2E

---

## 步骤 1：选择验证切片并编写失败测试（RED）

### 1.1 选择主验证类型

### 单元测试优先的场景

适用于：
- 复杂 service 分支
- 库存计算、状态流转、边界条件
- API E2E 已覆盖主流程，但仍需补局部规则

### API E2E 优先的场景

适用于：
- 新增接口
- 关键业务流程
- 多表 / 多状态联动
- 需要验证真实 HTTP 契约

### UI 驱动 E2E 必须进入 RED 的场景

满足以下任一项时，目标 UI 驱动 E2E 应直接作为本次 RED 测试，或至少与主 RED 测试并列：
- 菜单、路由、页面可达性变化
- 按钮权限、visible / disabled 语义变化
- 前端依赖后端字段做状态 / 标签 / 可见性 / 一致性判断
- 真实用户链路必须在 UI + API + DB 上闭环验证

### 1.2 测试文件位置

- API E2E Feature：`backend/ModernWMS.Tests.ApiE2E/Features/<Context>/...feature`
- API E2E 支持代码：`backend/ModernWMS.Tests.ApiE2E/Support/...`
- 单元测试：
  - `backend/ModernWMS.Tests.Unit/Services/...Tests.cs`
  - `backend/ModernWMS.Tests.Unit/Core/...Tests.cs`
- UI 驱动 E2E：`frontend/e2e/specs/...`

### 1.3 RED 编写要求

1. 先复用现有 Reqnroll step、数据规格、Playwright helper，不要新增大量一次性胶水代码
2. 先在已有测试中表达新预期；只有当行为真正独立时才新增测试文件或新场景
3. 当前 RED 只覆盖**一个最小行为切片**
4. 写操作至少验证：
   - HTTP / service 返回结果
   - 关键状态变化
   - 持久化结果
5. 新查询至少验证：
   - 分页契约
   - tenant 隔离
   - 关键筛选条件
6. UI 驱动 E2E 若进入 RED，断言必须落在真实 UI 语义或真实链路上，而不是仅看页面是否打开

🛑 **强制停止点**：RED 测试写完后，先确认它表达的是本次要交付的最小行为，而不是更大范围。

---

## 步骤 2：验证红灯（Verify RED）

### 常用命令

**目标单元测试：**

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"
```

**目标 API E2E：**

```bash
cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"
```

**目标 UI 驱动 E2E：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

### Verify RED 必须确认

- 测试失败，而不是通过
- 失败原因与目标行为缺失一致
- 不是环境错误、依赖缺失、端口错误、测试选择器错误、夹具错误

### 遇到以下情况必须停止

- **测试直接通过**：说明测试没覆盖到新行为，先修测试
- **测试因环境错误失败**：先修测试环境，不准写实现
- **需要多个改动一起上才能失败**：说明测试切片太大，先缩小 RED

---

## 步骤 3：最小实现（GREEN）

### 文件落点

通常只在以下位置增改：
- `backend/ModernWMS.WMS/Controllers/...`
- `backend/ModernWMS.WMS/IServices/...`
- `backend/ModernWMS.WMS/Services/...`
- `backend/ModernWMS.WMS/Entities/ViewModels/...`
- 必要时：`backend/ModernWMS.WMS/Entities/Models/...`

### 实现规则

1. Controller 继承 `BaseController`
2. 返回统一使用 `ResultModel<T>`
3. 分页统一使用 `PageSearch` / `PageData<T>`
4. Service 使用 `SqlDBContext` + LINQ / EF Core
5. 读操作优先 `AsNoTracking()`
6. 写操作显式处理：
   - `tenant_id`
   - `create_time`
   - `last_update_time`
7. 错误信息优先走 `IStringLocalizer<MultiLanguage>`
8. 不在局部引入新的 Repository / UnitOfWork 风格
9. 只实现让当前 RED 通过所需的最小代码，不夹带无关重构

### 如果涉及菜单 / 权限 / 可见性

还要同步检查：
- `scripts/seeds/database_mysql.sql`
- `backend/ModernWMS.WMS/Services/User/UserService.cs`
- `frontend/src/utils/router/index.ts`
- `frontend/src/view/base/roleMenu/actionList.ts`

### 如果涉及测试数据或数据库结构

本仓库测试数据库由 `scripts/seeds/database_mysql.sql` 初始化，必要时还要同步：
- `backend/ModernWMS.Tests.ApiE2E/Support/...`
- `backend/ModernWMS.Tests.Unit/Support/...`

如果需要改表结构，先确认是否属于本次范围，再决定是否更新 seed SQL 与测试初始化逻辑；不要直接照搬 Liquibase / JPA 迁移思路。

---

## 步骤 4：验证绿灯（Verify GREEN）

### 推荐顺序

1. 当前 RED 测试现在通过
2. 受影响的相邻测试类 / feature 通过
3. 如果命中 UI 驱动 E2E 触发条件，目标 UI 驱动 E2E 必须通过
4. 后端构建通过
5. 范围较大时，再跑完整后端验证

### 常用命令

**目标单元测试：**

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"
```

**目标 API E2E：**

```bash
cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"
```

**目标 UI 驱动 E2E：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

**后端构建：**

```bash
cd backend && dotnet build ModernWMS.sln
```

**完整后端验证：**

```bash
./scripts/test-all.sh --skip-ui
```

### Verify GREEN 必须确认

- 当前目标测试通过
- 没有因为修代码而破坏近邻行为
- 若本次能力会落到真实 UI 语义或前后端一致性，UI 驱动 E2E 已被验证
- 当前输出是干净的，没有用“应该没问题”替代真实结果

---

## 步骤 5：最小重构（REFACTOR）

只有在 Verify GREEN 完成后，才允许做与本次实现直接相关的整理：
- 提取重复查询或重复校验
- 改善方法命名、局部变量命名
- 把 Controller 中滑出的业务逻辑收回 Service
- 补租户过滤、本地化消息、日志文案

### REFACTOR 规则

- 一次只做一类整理
- 不改变行为
- 每次整理后，至少回跑本次的 GREEN 验证链路

如果需要系统性整理，转交 `code-refactoring-sop.md`，不要在当前功能实现里无限扩张。

---

## 步骤 6：最小充分验证（Final Verification）

> Final Verification **不是** Verify GREEN 的替代品，而是面向“准备收口 / 交付 / 提交”时的最小充分验收。

### 按改动范围选择

### 仅 service / core 规则分支

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"
cd backend && dotnet build ModernWMS.sln
```

### 涉及真实 HTTP 契约或关键业务流程

```bash
cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"
cd backend && dotnet build ModernWMS.sln
```

### 命中 UI 驱动 E2E 触发条件（本次必须补跑）

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

### 后端范围较大或需要覆盖率验收

```bash
./scripts/test-all.sh --skip-ui
```

### 联调状态 / 启动链路检查

```bash
./scripts/macos-dev.sh status
```

说明：
- `status` / `logs` 只能证明环境状态，**不能替代行为测试**
- 长运行命令必须走仓库脚本或 `tmux`

---

## 步骤 7：交接前端实现（可选）

以下情况通常需要继续走前端实现 SOP：
- 新接口需要页面入口
- 新字段需要列表 / 表单展示
- 新状态需要按钮、标签、权限或日志文案
- 菜单、路由、按钮权限发生变化

对应后续文档：`frontend-implementation-sop.md`

## 收尾检查清单

- [ ] 已阅读目标上下文与现有实现
- [ ] 已先写失败测试，再写生产代码
- [ ] 已亲自验证 RED，且失败原因正确
- [ ] 已用最小实现让当前 RED 通过
- [ ] 已亲自验证 GREEN，而不是凭感觉判断
- [ ] 若命中 UI 驱动 E2E 条件，已在 GREEN 或 Final Verification 中运行目标 UI 驱动 E2E
- [ ] 实现遵守 `backend-conventions.md`
- [ ] 没有引入与仓库不一致的新分层模式
- [ ] tenant、本地化、统一返回、分页契约已处理
- [ ] 已完成最小充分验证
- [ ] 如有前端影响，已明确交接下一步
