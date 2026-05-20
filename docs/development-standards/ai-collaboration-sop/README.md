# ModernWMS AI 协作 SOP

本目录现在作为 **ModernWMS project skills 的人类可读参考索引**。Agent 侧的正式入口已经改成仓库内 project skills：`.pi/skills/`。

> 这些 SOP 仍然保留为详细参考文档；对应 project skill 会先被发现，再按需读取本目录下的完整说明。

## 适用技术栈

### 后端
- .NET 7
- ASP.NET Core
- EF Core + `SqlDBContext`
- MySQL / SQLite / SQL Server / PostgreSQL
- NLog
- Hangfire

### 前端
- Vue 3
- TypeScript
- Vite
- Vuetify 3
- VXETable
- Vue Router 4
- Vuex 4
- Vue I18n
- Axios

### 测试与验证
- xUnit
- FluentAssertions
- Reqnroll（API E2E / BDD）
- Testcontainers.MySql
- Playwright
- `./scripts/test-all.sh`

## 与 ModernWMS 文档结构的映射

原始 SOP 中有一些旧的顶层目录约定（如“docs/用户旅程/”“docs/API设计/”“docs/UX设计/”“docs/迭代规划/”），**在 ModernWMS 中不要直接照搬**，统一按仓库现有文档结构归档：

| 内容类型 | ModernWMS 归档位置 |
| --- | --- |
| 需求背景、会议纪要、验收标准 | `docs/requirements/` |
| 用户旅程、上下文、统一语言、领域规则 | `docs/domain-model/` |
| API、UI/UX、架构、集成设计 | `docs/software-design/` |
| 跨需求通用研发规则 | `docs/development-standards/` |
| 计划、执行记录、阶段性产物 | `docs/progress/`（AI 设计 / 计划文档优先放 `docs/progress/planned/superpowers/specs/` 与 `docs/progress/planned/superpowers/plans/`） |

## Project Skill 映射

| 场景 | Project skill | 详细参考文档 |
| --- | --- | --- |
| 新功能需求分析与迭代规划 | `modernwms-requirements-analysis` | `requirements-analysis-sop.md` |
| 已有需求的变更分析与文档同步 | `modernwms-requirements-change` | `requirements-change-sop.md` |
| 后端新功能实现 | `modernwms-backend-implementation` | `backend-implementation-sop.md` |
| 后端既有功能变更 | `modernwms-backend-change` | `backend-change-sop.md` |
| 前端新功能实现 | `modernwms-frontend-implementation` | `frontend-implementation-sop.md` |
| 前端既有功能变更 | `modernwms-frontend-change` | `frontend-change-sop.md` |
| 代码重构 | `modernwms-code-refactoring` | `code-refactoring-sop.md` |

Project skills 位于：
- `.pi/skills/modernwms-requirements-analysis/`
- `.pi/skills/modernwms-requirements-change/`
- `.pi/skills/modernwms-backend-implementation/`
- `.pi/skills/modernwms-backend-change/`
- `.pi/skills/modernwms-frontend-implementation/`
- `.pi/skills/modernwms-frontend-change/`
- `.pi/skills/modernwms-code-refactoring/`

## 推荐使用顺序

1. Agent 先按任务类型使用对应 project skill
2. Skill 再按需读取本目录中的详细 SOP
3. 同时配套阅读：
   - `../backend-conventions.md`
   - `../frontend-conventions.md`
   - `../testing-conventions.md`
   - `../../software-design/api-design.md`
   - `../../software-design/ui-ux-style-guide.md`
   - `../../domain-model/README.md`

## 使用原则

1. **先读现有文档，再写新文档**
2. **优先更新已有长期文档，不要无节制新建平行文档**
3. **过程性产物放 `docs/progress/`；其中 AI 设计 / 计划文档优先放 `docs/progress/planned/superpowers/specs/` 与 `docs/progress/planned/superpowers/plans/`，长期知识放长期目录**
4. **验证命令要与 ModernWMS 实际工具链一致**，不要再写 Maven、JPA、Element Plus、AG-Grid、Pinia、`frontend-v2` 等与本仓库不符的约定
5. **长运行命令优先复用 `./scripts/macos-dev.sh`，或放在 `tmux` 中运行**
