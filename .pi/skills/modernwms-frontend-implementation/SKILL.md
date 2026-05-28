---
name: modernwms-frontend-implementation
description: Use when adding a new ModernWMS page, dialog, list, or frontend workflow that must fit the repo's Vue 3, Vuetify, VXETable, Vuex, dynamic menu, i18n, and snake_case conventions.
---

# ModernWMS Frontend Implementation

## Overview

Implement new frontend work in ModernWMS by fitting the existing page skeleton, API layer, dynamic menu model, and field naming rules. Do not import a different frontend architecture into this repo.

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
| F1 API / 数据契约 | 只分析当前必须支持的后端 API、请求参数、响应结构、分页结构 |
| F2 API / 类型 / i18n | 先补 `src/api`、`src/types`、`src/languages` |
| F3 页面 / 弹窗实现 | 复用现有 `script setup`、`reactive`、`vxe-table`、`custom-pager`、`BtnGroup`、`SearchGroup` 骨架 |
| F4 路由 / 权限 / 日志 | 接 `router`、`actionList.ts`、`systemLog.ts`、后端菜单 / seed 配套 |
| F5 验证 | `yarn build`，必要时联调；需要同时验证 UI / API 时跑 UI 驱动 E2E |

## Hard Rules

- 以后端 API 和现有页面骨架为准。
- 先补 API / 类型 / i18n，再写页面。
- 业务字段保持 `snake_case`，不要新造 camelCase 映射层。
- 页面里不要直接写 axios。
- 继续复用 `vxe-table`、`custom-pager`、`tooltip-btn`、`BtnGroup`、`SearchGroup`、`hookComponent.$message()` / `$dialog()`。
- 新页面不仅要能显示，还要检查菜单、权限、日志、路由是否接通。

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

- build when the verification point is static structure / types / styles only:
  - `cd frontend && yarn build`
- integration status:
  - `./scripts/macos-dev.sh status`
- full start when needed:
  - `./scripts/macos-dev.sh start`
- target UI-driven E2E when validating UI + API + DB together:
  - `./scripts/macos-dev.sh start`
  - `(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)`
  - `./scripts/macos-dev.sh stop`
- full UI-driven E2E regression:
  - `./scripts/macos-dev.sh start`
  - `(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e)`
  - `./scripts/macos-dev.sh stop`

UI-driven E2E is not frontend-only. Use it when menu / button semantics, page reachability, real API interaction, or UI / API consistency must be verified.

> Long-running commands must use repo scripts or `tmux`, not a blocking terminal session.

## Stop Points

Stop and confirm after:
1. 菜单归属、页面类型、入口位置
2. API 契约是否稳定
3. 构建 / 联调结果

## Common Mistakes

- 在页面里直接写 axios
- 引入 Element Plus / Pinia / frontend-v2 / pnpm 约定
- 把接口字段整体改成 camelCase
- 新页面漏接路由、权限、菜单 seed、日志文案
- 大量硬编码中文，跳过 i18n
- 在普通管理页绕开现有 `vxe-table + custom-pager` 模式

## Full Workflow

For the complete workflow, required files, and stop points, read:
- `../../../docs/development-standards/ai-collaboration-sop/frontend-implementation-sop.md`

**REQUIRED SUB-SKILL:** Use `test-driven-development` when implementation affects behavior and `verification-before-completion` before claiming success.
