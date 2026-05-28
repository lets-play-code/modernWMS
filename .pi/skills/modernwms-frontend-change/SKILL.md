---
name: modernwms-frontend-change
description: Use when adapting existing ModernWMS frontend pages to API field changes, layout changes, permissions, logs, i18n, routing, or interaction adjustments without rewriting the page.
---

# ModernWMS Frontend Change

## Overview

Handle existing frontend changes in ModernWMS as strict regression work: **understand delta → impact analysis → RED → Verify RED → GREEN → Verify GREEN → Final Verification**. No implementation before a failing test first.

## Required Reading

Before acting, read:
- `../../../docs/development-standards/ai-collaboration-sop/frontend-change-sop.md`
- `../../../docs/development-standards/frontend-conventions.md`
- `../../../docs/development-standards/testing-conventions.md`
- `../../../docs/software-design/api-design.md`
- `../../../docs/software-design/ui-ux-style-guide.md`
- relevant requirement / change analysis docs

## Quick Reference

| Phase | Must do |
| --- | --- |
| 理解变更 | 明确来自后端契约变化还是纯前端交互调整，列出前后差异 |
| 影响分析 | 先列 API / 类型 / 页面 / 组件 / 路由 / 权限 / 日志 / i18n 的受影响文件，并判断 UI 驱动 E2E 是否触发 |
| RED | 优先迭代已有 Playwright spec；必要时新增目标 spec |
| Verify RED | 亲自运行并确认“旧 UI 行为仍在 / 新契约未适配”，不是环境错误 |
| GREEN | API 与类型 → 页面脚本 → 模板 → i18n / 日志 / 权限 / 路由，且只做最小改动 |
| Verify GREEN | 当前 RED、受影响冒烟、构建通过 |
| Final Verification | 按范围跑目标或全量 UI 驱动 E2E，并补 `yarn build` |
| 文档同步 | 只有形成稳定规则时才更新长期设计 / 规范文档 |

## Hard Rules

- 先分析影响，再改代码。
- 先改测试，再改实现。
- `yarn build` 不是 RED / GREEN 的行为证明。
- 最小变更，不借机重写整页。
- 用户可见变化必须经过真实验证，而不是只靠人工目测。

## UI-driven E2E Trigger

UI-driven E2E must enter the verification chain when any of these apply:
- menu / route / page reachability changes
- button permission or visible / disabled semantics change
- frontend logic depends on backend fields for status, visibility, or UI / API consistency
- the real user flow must be proven across UI + API + DB

## Required Checks

Check these when relevant:
- API: `../../../frontend/src/api/...`
- types: `../../../frontend/src/types/...`
- views: `../../../frontend/src/view/...`
- shared components: `../../../frontend/src/components/...`
- route / dynamic menu: `../../../frontend/src/utils/router/index.ts`
- action permissions: `../../../frontend/src/view/base/roleMenu/actionList.ts`
- operation log copy: `../../../frontend/src/utils/systemLog.ts`
- i18n: `../../../frontend/src/languages/...`

## Verification

- target UI-driven E2E:
  - `./scripts/macos-dev.sh start`
  - `(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)`
  - `./scripts/macos-dev.sh stop`
- full UI-driven regression when needed:
  - `./scripts/macos-dev.sh start`
  - `(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e)`
  - `./scripts/macos-dev.sh stop`
- build:
  - `cd frontend && yarn build`
- integration start / status only when needed:
  - `./scripts/macos-dev.sh start`
  - `./scripts/macos-dev.sh status`

## Common Mistakes

- 先改页面，再补 Playwright 测试
- 把 `yarn build` 当成行为验证
- 因一次字段改动重做整页结构
- 跳过 i18n 直接硬编码
- 忘记同步日志文案、权限或动态菜单

## Full Workflow

For the complete flow, strict gates, and affected-file templates, read:
- `../../../docs/development-standards/ai-collaboration-sop/frontend-change-sop.md`

**REQUIRED SUB-SKILL:** Use `test-driven-development` for behavior changes and `verification-before-completion` before claiming the frontend change is complete.
