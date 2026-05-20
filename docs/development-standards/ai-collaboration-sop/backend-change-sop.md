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

## 核心原则

1. **先理解变更，再改代码**
2. **先改测试，再改实现**
3. **优先迭代已有测试，不轻易平行复制场景**
4. **只做最小必要变更，不顺手重构无关模块**
5. **如果变更会影响前端契约，要明确标注并交接**

## 流程总览

```text
1. 理解变更
2. 影响分析
3. 调整测试并制造红灯
4. 最小改动实现
5. 验证绿灯
6. 评估前端影响
7. 更新文档 / 计划状态
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

### 风险提醒

| 风险 | 说明 |
| --- | --- |
| 高 | 破坏已有前端契约、状态流转、关键库存规则 |
| 中 | 调整筛选、分页、可选字段 |
| 低 | 补文案、补日志、局部校验 |

🛑 **强制停止点**：影响分析完成后，等待用户确认范围。

---

## 步骤 3：调整测试并制造红灯

### 优先级

1. **先迭代已有 API E2E / 单元测试**
2. 只有当行为真正独立时才新增测试场景
3. 先让测试表达新预期，再改实现

### 常见做法

- 查询变更：更新对应 feature / 单元测试中的断言
- 写操作变更：新增状态变化或数据库结果断言
- 规则变更：补边界用例、异常用例

### 常用命令

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~StockServiceTests"
```

```bash
cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj
```

🛑 **强制停止点**：测试表达的新行为与用户确认一致后，再继续改实现。

---

## 步骤 4：最小改动实现

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

### 如果涉及数据库结构或测试初始化

本项目测试数据库来自 `scripts/seeds/database_mysql.sql`，如变更结构或初始化数据，需要同步评估：

- `scripts/seeds/database_mysql.sql`
- `backend/ModernWMS.Tests.ApiE2E/Support/...`
- `backend/ModernWMS.Tests.Unit/Support/...`

不要直接套用 Liquibase、Flyway、JPA 迁移说明。

---

## 步骤 5：验证绿灯

### 推荐顺序

1. 当前修改的测试
2. 受影响模块的测试类 / feature
3. 后端构建
4. 必要时完整后端验证

### 常用命令

```bash
cd backend && dotnet build ModernWMS.sln
```

```bash
./scripts/test-all.sh --skip-ui
```

---

## 步骤 6：评估前端影响

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

🛑 **强制停止点**：明确是否要继续做前端适配。

---

## 步骤 7：更新文档 / 计划状态

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
- [ ] 已先调整测试并验证红灯
- [ ] 已按最小范围修改实现
- [ ] 已验证构建 / 测试结果
- [ ] 已评估前端是否受影响
- [ ] 已同步长期文档或过程状态
