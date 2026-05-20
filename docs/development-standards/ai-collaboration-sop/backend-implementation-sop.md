# ModernWMS AI 协同后端功能实现作业指导书

## 适用场景

适用于 **后端新功能开发**、**新接口实现**、**新服务能力补齐**。

前置条件：
- 需求分析或设计已确认
- 已明确目标上下文与 MVP 范围
- 已确定应优先补 API E2E 还是单元测试

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
| 全量验证 | `./scripts/test-all.sh --skip-ui` |

## 核心原则

1. **先测试，后实现**
2. **薄 Controller，厚 Service**
3. **显式处理租户、校验、本地化、日志**
4. **优先兼容现有接口契约，不在局部突然改风格**
5. **最小改动，不顺手重构无关模块**

## 流程总览

```text
0. 阅读现有实现与测试
1. 编写 / 调整测试
2. 运行红灯
3. 最小实现
4. 运行绿灯
5. 做最小重构
6. 运行最小充分验证
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
- 更适合补 API E2E 还是补 service 单元测试

---

## 步骤 1：编写 / 调整测试

### API E2E 适用场景

适用于：
- 新增接口
- 关键业务流程
- 多表 / 多状态联动
- 需要验证真实 HTTP 契约

### 单元测试适用场景

适用于：
- 复杂 service 分支
- 库存计算、状态流转、边界条件
- API E2E 已覆盖主流程，但还需补局部规则

### API E2E 文件位置

- Feature：`backend/ModernWMS.Tests.ApiE2E/Features/<Context>/...feature`
- 支持代码：`backend/ModernWMS.Tests.ApiE2E/Support/...`

### 单元测试文件位置

- `backend/ModernWMS.Tests.Unit/Services/...Tests.cs`
- `backend/ModernWMS.Tests.Unit/Core/...Tests.cs`

### 测试编写要求

1. 先复用现有 Reqnroll step 和数据规格，不要新增大量一次性 step
2. 若只是规则分支，优先迭代已有测试，而不是平行复制一份
3. 写操作至少验证：
   - HTTP / service 返回结果
   - 关键状态变化
   - 持久化结果
4. 新查询至少验证：
   - 分页契约
   - tenant 隔离
   - 关键筛选条件

🛑 **强制停止点**：测试用例写完后，先与用户确认场景覆盖是否正确。

---

## 步骤 2：运行红灯

### 常用命令

```bash
cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj
```

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~AsnServiceTests"
```

### 目标

- 新增测试当前应失败
- 失败原因应与预期一致，而不是环境错误或无关断言失败

---

## 步骤 3：最小实现

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

## 步骤 4：运行绿灯

### 目标验证顺序

1. 先跑当前新增 / 调整的测试
2. 再跑相关测试类或相关 feature
3. 必要时再跑完整后端验证

### 常用命令

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~DispatchlistServiceTests"
```

```bash
cd backend && dotnet build ModernWMS.sln
```

```bash
./scripts/test-all.sh --skip-ui
```

---

## 步骤 5：最小重构

在测试为绿的前提下，只做与本次实现直接相关的整理：

- 提取重复查询或重复校验
- 改善方法命名、局部变量命名
- 把 Controller 中滑出的业务逻辑收回 Service
- 补租户过滤、本地化消息、日志文案

如果需要系统性整理，转交 `code-refactoring-sop.md`，不要在当前功能实现里无限扩张。

---

## 步骤 6：最小充分验证

### 按改动范围选择

**仅后端改动：**

```bash
cd backend && dotnet build ModernWMS.sln
```

**后端测试与覆盖率：**

```bash
./scripts/test-all.sh --skip-ui
```

**涉及前后端联调或需要手工验证 API：**

```bash
./scripts/macos-dev.sh status
```

如需启动完整环境，优先使用：

```bash
./scripts/macos-dev.sh start
```

> 长运行命令必须走仓库脚本或 `tmux`，不要直接阻塞当前终端。

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
- [ ] 测试先行，且红灯原因正确
- [ ] 实现遵守 `backend-conventions.md`
- [ ] 没有引入与仓库不一致的新分层模式
- [ ] tenant、本地化、统一返回、分页契约已处理
- [ ] 已做最小充分验证
- [ ] 如有前端影响，已明确交接下一步
