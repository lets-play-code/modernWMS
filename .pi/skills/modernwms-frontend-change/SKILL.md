---
name: modernwms-frontend-change
description: Use when adapting existing ModernWMS frontend pages to API field changes, layout changes, permissions, logs, i18n, routing, or interaction adjustments without rewriting the page.
---

# ModernWMS Frontend Change

## Overview

Handle existing frontend changes in ModernWMS as targeted adaptation work. Understand the change source, map impacted files first, then make the smallest update across API, types, views, i18n, logs, and permissions.

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
| 影响分析 | 先列 API / 类型 / 页面 / 组件 / 路由 / 权限 / 日志 / i18n 的受影响文件 |
| 实施顺序 | API 与类型 → 页面脚本逻辑 → 模板展示 → i18n / 日志 / 权限 / 路由 |
| 验证 | 至少 `yarn build`，需要时联调或 UI 回归 |
| 文档同步 | 只有形成稳定规则时才更新长期设计 / 规范文档 |

## Hard Rules

- 以后端真实契约和现有页面模式为准。
- 先分析影响文件，再动代码。
- 最小变更，不借机重写整页。
- 保持现有 Vuetify + VXETable + Vuex 体系一致性。
- 用户可见变化必须经过构建或联调验证。

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

- build: `cd frontend && yarn build`
- integration start / status:
  - `./scripts/macos-dev.sh start`
  - `./scripts/macos-dev.sh status`
- UI regression when needed:
  - `cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e`

## Stop Points

Stop and confirm after:
1. 变更理解
2. 影响文件范围确认
3. 构建 / 联调结果

## Common Mistakes

- 因一次字段改动重做整页结构
- 引入与仓库不一致的新 UI 框架或新状态管理
- 跳过 i18n 直接硬编码
- 忘记同步日志文案、权限或动态菜单
- 没跑 `yarn build` 就宣称前端改完

## Full Workflow

For the complete flow, affected-file templates, and stop points, read:
- `../../../docs/development-standards/ai-collaboration-sop/frontend-change-sop.md`

**REQUIRED SUB-SKILL:** Use `verification-before-completion` before claiming the frontend change is complete.
