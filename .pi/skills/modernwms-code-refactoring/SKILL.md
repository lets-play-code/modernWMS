---
name: modernwms-code-refactoring
description: Use when improving existing ModernWMS code structure after behavior is already covered, especially for long services, repeated page logic, naming, boundaries, readability, or localized performance issues.
---

# ModernWMS Code Refactoring

## Overview

Refactor ModernWMS code only under an existing green baseline. This skill aligns to the **REFACTOR** phase of TDD: establish GREEN first, make one structural change, then return to GREEN before continuing.

## Required Reading

Before acting, read:
- `../../../docs/development-standards/ai-collaboration-sop/code-refactoring-sop.md`
- `../../../docs/development-standards/backend-conventions.md`
- `../../../docs/development-standards/frontend-conventions.md`
- `../../../docs/development-standards/testing-conventions.md`

## Quick Reference

| Phase | Must do |
| --- | --- |
| 绿灯基线 | 先明确哪条测试链路证明当前行为为绿 |
| 单问题清单 | 一次只选一个重复 / 命名 / 边界 / 性能问题 |
| 最小重构 | 只做一个局部结构整理 |
| 回到绿灯 | 立即跑同一条基线；命中 UI 条件时目标 UI 驱动 E2E 也要回绿 |
| 重复 | 清单未完成前持续“一问题一验证” |
| Final Verification | 范围较大时跑更高等级验证，并按需沉淀长期规则 |

## Hard Rules

- No green baseline, no refactor.
- 一次只处理一个问题。
- 如果发现需要改行为，立即停止并切换到实现 / 变更 SOP。
- 重构后必须重新验证，而不是凭感觉说更好了。
- 不把局部整理升级成全局架构改造。

## UI-driven E2E Trigger

UI-driven E2E must enter the regression chain when any of these apply:
- menu / route / page reachability could be affected
- button permission or visible / disabled semantics could be affected
- frontend logic depends on backend fields for status, visibility, or UI / API consistency
- the real user flow must remain proven across UI + API + DB

## Verification

Backend:
- target unit tests:
  - `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"`
- target API E2E:
  - `cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"`
- build:
  - `cd backend && dotnet build ModernWMS.sln`
- broader backend verification:
  - `./scripts/test-all.sh --skip-ui`

Frontend / UI-driven E2E:
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

Integration:
- `./scripts/macos-dev.sh status`

## Stop and Report When

- 当前没有绿灯基线
- 实际上已经变成行为修改任务
- 重构开始触及未批准模块
- 为了“更优雅”需要大规模改架构
- 需要同时动前后端多个边界且目标不清晰

## Common Mistakes

- 在没有测试基线时重构
- 一次混入多个问题：命名、抽象、行为修改一起做
- 因为“顺手”扩大需求范围
- 把行为修改伪装成重构
- 验证失败后仍宣称重构完成

## Full Workflow

For the full checklist, green-baseline gate, and repetition pattern, read:
- `../../../docs/development-standards/ai-collaboration-sop/code-refactoring-sop.md`

**REQUIRED SUB-SKILL:** Use `verification-before-completion` before claiming the refactor is done.
