---
name: modernwms-backend-change
description: Use when changing existing ModernWMS backend behavior, query contracts, API fields, response structures, business rules, states, or permissions and the agent must assess tests, tenant, seed, contract, and frontend impact before editing code.
---

# ModernWMS Backend Change

## Overview

Treat backend changes in ModernWMS as strict regression work: **understand delta → impact analysis → RED → Verify RED → GREEN → Verify GREEN → Final Verification**. No implementation before a failing test first.

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
| 影响分析 | 检查契约、tenant、导入导出、打印、权限、日志、seed、前端契约，并判断 UI 驱动 E2E 是否触发 |
| RED | 优先迭代现有 API E2E / 单元测试；命中 UI 条件时目标 UI 驱动 E2E 也进入链路 |
| Verify RED | 亲自运行并确认“旧行为仍在 / 新规则未生效”，不是环境错误 |
| GREEN | 按 ViewModel → Service → Controller → 配套顺序做最小改动 |
| Verify GREEN | 当前测试、近邻测试通过；命中 UI 条件时目标 UI 驱动 E2E 也通过 |
| Final Verification | 按范围跑 target unit / API E2E、`dotnet build`、必要时 `test-all.sh --skip-ui` 与目标 UI 驱动 E2E |
| 前端评估 | 判断是否需要 `modernwms-frontend-change` |

## Hard Rules

- 先理解变更，再改代码。
- 先改测试，再改实现。
- Verify RED / Verify GREEN are mandatory.
- 优先在已有测试中表达新预期，不轻易平行复制场景。
- 只做最小必要变更，不顺手重构无关模块。
- 如果会影响前端契约，必须明确标注并交接。

## UI-driven E2E Trigger

UI-driven E2E must enter the verification chain when any of these apply:
- menu / route / page reachability changes
- button permission or visible / disabled semantics change
- frontend logic depends on backend fields for status, visibility, or UI / API consistency
- the real user flow must be proven across UI + API + DB

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

- target unit tests:
  - `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"`
- target API E2E:
  - `cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"`
- build:
  - `cd backend && dotnet build ModernWMS.sln`
- broader backend verification:
  - `./scripts/test-all.sh --skip-ui`
- target UI-driven E2E when triggered:
  - `./scripts/macos-dev.sh start`
  - `(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)`
  - `./scripts/macos-dev.sh stop`

## Stop Points

Stop and confirm after:
1. 变更理解
2. 影响分析
3. RED 已写完但尚未实现前
4. 前端影响判断

## Common Mistakes

- 静默改变前端契约，不交接 UI 影响
- 跳过 RED，直接修改实现
- 没验证 RED 的失败原因，就开始写代码
- 用 build 代替行为测试
- 命中 UI 条件却没跑目标 UI 驱动 E2E

## Full Workflow

For the complete step list, strict gates, and output templates, read:
- `../../../docs/development-standards/ai-collaboration-sop/backend-change-sop.md`

**REQUIRED SUB-SKILL:** Use `test-driven-development` for the actual code change and `verification-before-completion` before claiming the change is done.
