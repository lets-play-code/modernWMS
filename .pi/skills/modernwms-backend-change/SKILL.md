---
name: modernwms-backend-change
description: Use when changing existing ModernWMS backend behavior, query contracts, API fields, response structures, business rules, states, or permissions and the agent must assess tests, tenant, seed, contract, and frontend impact before editing code.
---

# ModernWMS Backend Change

## Overview

Treat backend changes in ModernWMS as regression and contract work. Understand the delta, update existing tests first, then make the smallest implementation change and explicitly assess frontend impact.

## Required Reading

Before acting, read:
- `../../../docs/development-standards/ai-collaboration-sop/backend-change-sop.md`
- `../../../docs/development-standards/backend-conventions.md`
- `../../../docs/development-standards/testing-conventions.md`
- relevant requirement / design docs
- relevant `../../../docs/domain-model/<context>/overview.md`

## Quick Reference

| Phase | Must do |
| --- | --- |
| 理解变更 | 说明变更前后差异，标明字段 / 规则 / 状态 / 查询 / 返回结构变化 |
| 影响分析 | 检查 `ResultModel<T>`、`PageData<T>`、tenant、导入导出、打印、权限、日志、seed、前端契约 |
| 红灯测试 | 优先迭代现有 API E2E / 单元测试，不轻易复制平行场景 |
| 最小实现 | 按 ViewModel → Service → Controller → seed / 权限 / 日志配套顺序改 |
| 绿灯验证 | 先当前测试，再受影响模块，再 `dotnet build` / `test-all.sh`，必要时补 UI 驱动 E2E |
| 前端评估 | 判断是否需要 `modernwms-frontend-change` |
| 文档同步 | 必要时更新长期规则或过程状态 |

## Hard Rules

- 先理解变更，再改代码。
- 先改测试，再改实现。
- 优先在已有测试中表达新预期，不轻易平行复制场景。
- 只做最小必要变更，不顺手重构无关模块。
- 如果会影响前端契约，必须明确标注并交接。

## Required Checks

Check these when relevant:
- `ResultModel<T>` / `PageData<T>` contract
- `tenant_id` handling
- query / paging / import-export / print impact
- field naming impact on frontend, especially `snake_case`
- permissions / menu / logs / copy:
  - `../../../scripts/seeds/database_mysql.sql`
  - `../../../frontend/src/utils/systemLog.ts`
  - `../../../frontend/src/utils/router/index.ts`
  - `../../../frontend/src/view/base/roleMenu/actionList.ts`
- test support / seed updates:
  - `../../../backend/ModernWMS.Tests.ApiE2E/Support/...`
  - `../../../backend/ModernWMS.Tests.Unit/Support/...`

## Verification

- target unit tests when checking service / core branches:
  - `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"`
- target API E2E when checking real HTTP + service + DB:
  - `cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"`
- build:
  - `cd backend && dotnet build ModernWMS.sln`
- broader backend verification:
  - `./scripts/test-all.sh --skip-ui`
- UI-driven E2E when the backend delta changes menus, permissions, page states, or UI / API consistency:
  - `./scripts/macos-dev.sh start`
  - `(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)`
  - `./scripts/macos-dev.sh stop`

## Stop Points

Stop and confirm after:
1. 变更理解
2. 影响分析
3. 新行为的红灯测试确认
4. 前端影响判断

## Handoff

- 需要前端适配 → `modernwms-frontend-change`
- 若变化其实是新增能力，不是既有能力调整 → 改用 `modernwms-backend-implementation`

## Common Mistakes

- 静默改变前端契约，不交接 UI 影响
- 跳过现有测试，直接复制一套新场景
- 忘记 tenant、seed SQL、菜单 / 权限 / 日志检查
- 把小变更顺手扩大成大重构
- 用与项目不一致的新抽象层解决局部问题

## Full Workflow

For the complete step list, output templates, and stop points, read:
- `../../../docs/development-standards/ai-collaboration-sop/backend-change-sop.md`

**REQUIRED SUB-SKILL:** Use `test-driven-development` for the actual code change and `verification-before-completion` before claiming the change is done.
