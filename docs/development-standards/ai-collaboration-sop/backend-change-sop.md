# ModernWMS AI 协同后端功能变更作业指导书

## 适用场景

适用于 **已有后端能力的变更**，包括但不限于：
- 字段增删改
- 业务规则调整
- 状态流转变更
- 查询条件或分页契约调整
- 接口参数、返回结构调整
- 菜单 / 权限 / 种子数据配套变更

## 必读文档

- `docs/development-standards/backend-conventions.md`
- `docs/development-standards/testing-conventions.md`
- 对应需求 / 设计文档
- 相关上下文文档：`docs/domain-model/<context>/overview.md`

## 本 SOP 对齐的开发基线

本 SOP 的开发阶段**严格对齐** `superpowers:test-driven-development`：

```text
理解变更
→ 影响分析
→ RED（先写失败测试）
→ Verify RED（确认因旧行为 / 缺失实现而失败）
→ GREEN（最小变更实现）
→ Verify GREEN（目标测试通过）
→ Final Verification（按范围做最小充分验证）
→ 前端影响评估 / 文档同步
```

## 核心原则

1. **先理解变更，再改代码**
2. **先改测试，再改实现**
3. **未完成 Verify RED，不得进入实现**
4. **未完成 Verify GREEN，不得宣称变更完成**
5. **只做最小必要变更，不顺手重构无关模块**
6. **如果变更会影响前端契约，要明确标注并交接**

## TDD 强制门禁

### 1. RED 门禁

以下内容都算生产代码，必须在 RED 之后再改：
- Controller / Service / ViewModel / Entity
- 种子数据、权限、日志文案配套
- 与变更直接相关的真实业务代码

### 2. Verify RED 门禁

必须确认：
- 测试失败，而不是直接通过
- 失败原因与“旧行为仍存在 / 新规则尚未生效”一致
- 不是环境错误、断言写错、测试夹具错误

### 3. GREEN 门禁

实现阶段只允许：
- 让当前 RED 测试通过所需的最小改动
- 与该变更直接相关的最小配套同步

### 4. Verify GREEN 门禁

必须确认：
1. 当前目标测试通过
2. 受影响的相邻测试类 / feature 通过
3. 若命中 UI 驱动 E2E 触发条件，则目标 UI 驱动 E2E 通过

## UI 驱动 E2E 何时必须进入验证链路

当满足以下任一条件时，**UI 驱动 E2E 必须进入本次变更的验证链路**；如果它是主要验收点，就应在 RED 阶段先写 / 先改它：

- 菜单、路由、页面可达性发生变化
- 按钮权限、visible / disabled 语义发生变化
- 前端依赖后端字段做状态展示、可见性判断、前后端一致性逻辑
- 需要确认真实用户链路在 **UI + API + DB** 上一起工作

## 流程总览

```text
1. 理解变更
2. 影响分析
3. 编写失败测试（RED）
4. 验证红灯（Verify RED）
5. 最小改动实现（GREEN）
6. 验证绿灯（Verify GREEN）
7. 最小充分验证（Final Verification）
8. 评估前端影响并同步文档 / 状态
```

---

## 步骤 1：理解变更

### AI 行动

1. 说明变更前后差异
2. 指出影响的是字段、规则、流程还是接口契约
3. 列出相关 Controller / Service / ViewModel / 测试文件
4. 明确是否涉及用户可见行为变化

### 输出模板

```markdown
## 一、后端变更理解

### 1. 变更描述
- ...

### 2. 变更类型
- [ ] 字段调整
- [ ] 规则调整
- [ ] 状态流转调整
- [ ] 查询契约调整
- [ ] 接口返回调整

### 3. 影响文件
| 类型 | 路径 | 影响 |
| --- | --- | --- |
| Controller | ... | ... |
| Service | ... | ... |
| ViewModel | ... | ... |
| Tests | ... | ... |
```

🛑 **强制停止点**：输出理解结果后，等待用户确认。

---

## 步骤 2：影响分析

### 重点检查

- 是否影响 `ResultModel<T>` 或 `PageData<T>` 契约
- 是否影响 tenant 隔离
- 是否影响已有列表查询、导入导出、打印
- 是否影响前端字段命名（尤其 `snake_case`）
- 是否影响权限、菜单、日志文案
- 是否需要同步 `scripts/seeds/database_mysql.sql`
- 是否命中 UI 驱动 E2E 触发条件

### 风险提醒

| 风险 | 说明 |
| --- | --- |
| 高 | 破坏已有前端契约、状态流转、关键库存规则 |
| 中 | 调整筛选、分页、可选字段 |
| 低 | 补文案、补日志、局部校验 |

🛑 **强制停止点**：影响分析完成后，等待用户确认范围。

---

## 步骤 3：编写失败测试（RED）

### 优先级

1. **先迭代已有 API E2E / 单元测试**
2. 只有当行为真正独立时才新增测试场景
3. 若命中 UI 驱动 E2E 条件，目标 UI 驱动 E2E 也应进入本次 RED 链路
4. 先让测试表达新预期，再改实现

### 常见做法

- 查询变更：更新对应 feature / 单元测试中的断言
- 写操作变更：新增状态变化或数据库结果断言
- 规则变更：补边界用例、异常用例
- UI / API 一致性变更：补目标 Playwright spec，验证真实页面语义

### RED 编写要求

- 一次只表达一个最小行为切片
- 优先改已有测试，不平行复制整套场景
- 断言必须能证明“旧行为不再正确 / 新行为尚未生效”
- `dotnet build`、`status`、手工点点页面都**不算 RED 测试**

---

## 步骤 4：验证红灯（Verify RED）

### 常用命令

**目标单元测试：**

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"
```

**目标 API E2E：**

```bash
cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"
```

**目标 UI 驱动 E2E（当变更会影响真实页面语义或前后端一致性时）：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

### Verify RED 必须确认

- 测试确实失败
- 失败原因与旧行为仍存在 / 新规则尚未实现一致
- 不是环境错误、测试数据错误、断言写错

### 遇到以下情况必须停止

- **测试直接通过**：先修 RED，不准改实现
- **测试因环境错误失败**：先修环境 / 夹具
- **必须写很多实现后才会失败**：说明 RED 切片太大，先缩小

🛑 **强制停止点**：RED 已被亲自验证后，才允许进入实现。

---

## 步骤 5：最小改动实现（GREEN）

### 修改顺序建议

1. ViewModel / 输入输出契约
2. Service 业务逻辑
3. Controller 入参与返回
4. 种子数据 / 权限 / 日志配套
5. 测试辅助代码（如数据规格、测试 seed）

### 实现要求

- 保持 `BaseController + ResultModel<T> + Service` 主体风格
- 分页依旧复用 `PageSearch / PageData<T>`
- 查询仍优先使用 `SqlDBContext + LINQ`
- 读操作继续优先 `AsNoTracking()`
- 变更写操作时检查 `tenant_id`、时间字段、本地化错误消息
- 不得在局部引入与项目不一致的新抽象层
- 只修让当前 RED 通过所需的最小代码，不夹带无关重构

### 如果涉及数据库结构或测试初始化

本项目测试数据库来自 `scripts/seeds/database_mysql.sql`，如变更结构或初始化数据，需要同步评估：
- `scripts/seeds/database_mysql.sql`
- `backend/ModernWMS.Tests.ApiE2E/Support/...`
- `backend/ModernWMS.Tests.Unit/Support/...`

不要直接套用 Liquibase、Flyway、JPA 迁移说明。

---

## 步骤 6：验证绿灯（Verify GREEN）

### 推荐顺序

1. 当前 RED 测试通过
2. 受影响模块的测试类 / feature 通过
3. 后端构建通过
4. 若命中 UI 驱动 E2E 触发条件，目标 UI 驱动 E2E 通过
5. 必要时完整后端验证

### 常用命令

**目标单元测试：**

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"
```

**目标 API E2E：**

```bash
cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"
```

**后端构建：**

```bash
cd backend && dotnet build ModernWMS.sln
```

**目标 UI 驱动 E2E：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

**完整后端验证：**

```bash
./scripts/test-all.sh --skip-ui
```

### Verify GREEN 必须确认

- 当前 RED 测试已经变绿
- 没有破坏受影响的近邻行为
- 命中 UI 条件时，真实 UI 链路也已变绿
- 输出干净，没有用“应该没问题”代替真实结果

---

## 步骤 7：最小充分验证（Final Verification）

> Final Verification **不是** Verify GREEN 的替代品，而是面向收口 / 提交 / 交接的最小充分验收。

### 推荐组合

### service / core 局部规则

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"
cd backend && dotnet build ModernWMS.sln
```

### HTTP 契约 / 关键流程 / 多表联动

```bash
cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"
cd backend && dotnet build ModernWMS.sln
```

### 命中 UI 驱动 E2E 条件（必须补跑）

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

### 后端范围较大或需要覆盖率验收

```bash
./scripts/test-all.sh --skip-ui
```

说明：
- `./scripts/macos-dev.sh status` 只能证明环境状态，**不能替代行为验证**
- 长运行命令必须走仓库脚本或 `tmux`

---

## 步骤 8：评估前端影响并同步文档 / 状态

### 以下情况通常需要前端配合

- 字段新增 / 删除 / 重命名
- 返回结构层级变化
- 按钮权限或菜单可见性变化
- 状态值、标签、颜色、排序方式变化
- 新增写操作日志语义

### 需要同步检查的前端位置

- `frontend/src/api/...`
- `frontend/src/view/...`
- `frontend/src/types/...`
- `frontend/src/utils/systemLog.ts`
- `frontend/src/utils/router/index.ts`
- `frontend/src/view/base/roleMenu/actionList.ts`

后续文档：`frontend-change-sop.md`

### 长期文档

如果变更已经形成稳定规则或契约，应同步更新：
- 跨需求稳定 API 协作规则：`docs/software-design/api-design.md`
- 上下文本地长期规则：`docs/domain-model/<context>/overview.md`
- 后端通用实现规则：`docs/development-standards/backend-conventions.md`
- 测试通用规则：`docs/development-standards/testing-conventions.md`
- 如果只是本次需求的专题设计，不要硬写进总览文档，优先更新 `docs/software-design/` 下的专题文档

### 过程性状态

- AI 设计 / 计划文档：`docs/progress/planned/superpowers/specs/`、`docs/progress/planned/superpowers/plans/`
- 执行中的阶段性说明：`docs/progress/active/`
- 完成后的 AI 工作流归档：`docs/progress/archive/superpowers/`

## 收尾检查清单

- [ ] 已明确变更前后差异
- [ ] 已完成影响分析，并确认是否命中 UI 驱动 E2E 条件
- [ ] 已先写失败测试，再写实现
- [ ] 已亲自验证 RED，且失败原因正确
- [ ] 已按最小范围修改实现
- [ ] 已亲自验证 GREEN，而不是凭感觉判断
- [ ] 若命中 UI 驱动 E2E 条件，已在 GREEN 或 Final Verification 中运行目标 UI 驱动 E2E
- [ ] 已完成最小充分验证
- [ ] 已评估前端是否受影响
- [ ] 已同步长期文档或过程状态
