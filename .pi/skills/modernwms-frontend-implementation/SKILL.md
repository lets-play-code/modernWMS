---
name: modernwms-frontend-implementation
description: Use when adding a new ModernWMS page, dialog, list, or frontend workflow that must fit the repo's Vue 3, Vuetify, VXETable, Vuex, dynamic menu, i18n, and snake_case conventions.
---

# ModernWMS Frontend Implementation

## Overview

Implement new frontend work in ModernWMS under a strict TDD gate: **RED → Verify RED → GREEN → Verify GREEN → REFACTOR → Final Verification**. API / types / i18n / view code are all production code and cannot be written before a failing test first.

## Required Reading

Before acting, read:
- `../../../docs/development-standards/ai-collaboration-sop/frontend-implementation-sop.md`
- `../../../docs/development-standards/frontend-conventions.md`
- `../../../docs/development-standards/testing-conventions.md`
- `../../../docs/software-design/api-design.md`
- `../../../docs/software-design/ui-ux-style-guide.md`
- relevant `../../../docs/domain-model/<context>/overview.md`

## Actual Stack Map

- Vue 3 + TypeScript + Vite
- Vuetify 3
- VXETable
- Vuex 4
- Vue Router 4
- Vue I18n
- Axios via `frontend/src/utils/http/request.ts`
- UI-driven E2E: Playwright against real frontend / backend / MySQL

## Quick Reference

| Phase | Must do |
| --- | --- |
| F0 菜单归属 | 先确认页面属于哪个视图分组、是否进动态菜单、是完整页面还是弹窗 |
| F1 验证切片 | 分析 API / 数据契约，并判断是否命中 UI 驱动 E2E 条件 |
| RED | 优先写 / 改目标 Playwright spec，表达最小用户可见行为切片 |
| Verify RED | 亲自运行并确认“因 UI / 链路行为未实现而失败”，不是环境错误 |
| GREEN | 先补 API / 类型 / i18n，再补页面 / 路由 / 权限 / 日志，且只做最小实现 |
| Verify GREEN | 当前 RED、受影响冒烟、构建通过 |
| REFACTOR | 仅在绿灯下做局部整理 |
| Final Verification | 按范围跑目标或全量 UI 驱动 E2E，并补 `yarn build` |

## Hard Rules

- No production code before a failing test first.
- `yarn build` is supplemental verification only, never a RED / GREEN proof.
- Keep `snake_case`; do not invent a new camelCase mapping layer.
- Reuse existing page skeletons and helpers.
- New pages must also connect route / menu / permission / log paths when relevant.

## UI-driven E2E Trigger

UI-driven E2E must enter RED / GREEN when any of these apply:
- menu / route / page reachability changes
- button permission or visible / disabled semantics change
- frontend logic depends on backend fields for status, visibility, or UI / API consistency
- the real user flow must be proven across UI + API + DB

For new pages, routes, menus, and button interactions, this is usually triggered by default.

## Required Checks

Check these when relevant:
- menu / route / page type:
  - `../../../frontend/src/utils/router/index.ts`
  - `../../../frontend/src/view/base/roleMenu/actionList.ts`
  - related `../../../frontend/src/view/...`
- API / types / i18n:
  - `../../../frontend/src/api/...`
  - `../../../frontend/src/types/...`
  - `../../../frontend/src/languages/...`
- dynamic menu / permission / backend配套:
  - `../../../backend/ModernWMS.WMS/Services/User/UserService.cs`
  - `../../../scripts/seeds/database_mysql.sql`
- operation log copy:
  - `../../../frontend/src/utils/systemLog.ts`

## Verification

- target UI-driven E2E:
  - `./scripts/macos-dev.sh start`
  - `(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)`
  - `./scripts/macos-dev.sh stop`
- full UI-driven E2E regression:
  - `./scripts/macos-dev.sh start`
  - `(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e)`
  - `./scripts/macos-dev.sh stop`
- build:
  - `cd frontend && yarn build`
- integration status only when needed:
  - `./scripts/macos-dev.sh status`

## Common Mistakes

- 先写页面，再补 Playwright 测试
- 把 `yarn build` 当成 RED / GREEN 证明
- 引入 Element Plus / Pinia / frontend-v2 / pnpm 约定
- 把接口字段整体改成 camelCase
- 漏接 route / menu / permission / log 配套

## Full Workflow

For the complete workflow, strict gates, and stop points, read:
- `../../../docs/development-standards/ai-collaboration-sop/frontend-implementation-sop.md`

**REQUIRED SUB-SKILL:** Use `test-driven-development` when implementation affects behavior and `verification-before-completion` before claiming success.
