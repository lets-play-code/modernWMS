---
name: modernwms-code-refactoring
description: Use when improving existing ModernWMS code structure after behavior is already covered, especially for long services, repeated page logic, naming, boundaries, readability, or localized performance issues.
---

# ModernWMS Code Refactoring

## Overview

Refactor ModernWMS code only under green tests or clear verification coverage. Improve one local problem at a time, verify after each change, and avoid turning a bounded cleanup into an architecture rewrite.

## Required Reading

Before acting, read:
- `../../../docs/development-standards/ai-collaboration-sop/code-refactoring-sop.md`
- `../../../docs/development-standards/backend-conventions.md`
- `../../../docs/development-standards/frontend-conventions.md`
- `../../../docs/development-standards/testing-conventions.md`

## Quick Reference

| Phase | Must do |
| --- | --- |
| 生成清单 | 列出重复代码、命名、方法过长、边界混乱、性能问题、魔法值等具体问题 |
| 逐项重构 | 一次只处理一个问题，不交叉改动 |
| 每项后验证 | 后端 / 前端 / 联调按最小充分命令验证 |
| 文档沉淀 | 只有稳定新规则才更新长期规范 |

## Focus Areas

Backend checks:
- Controller 过胖
- Service 过长
- 重复 LINQ / tenant 过滤
- 绕开 `ResultModel<T>` / `PageData<T>`
- 缺失 `AsNoTracking()`、N+1、重复查询
- 本地化遗漏

Frontend checks:
- 页面直写请求，绕开 `src/api/**`
- 页面状态组织混乱
- 重复列表骨架
- 文案硬编码，跳过 i18n
- 权限 / 日志遗漏
- 为单页需求做无复用价值的过度抽象

## Hard Rules

- 测试绿灯优先于重构速度。
- 一次只处理一个问题。
- 局部重构，不借机改写整层架构。
- 优先改善重复、命名、边界、可读性和明显性能问题。
- 重构后必须重新验证，而不是凭感觉说更好了。

## Verification

Backend:
- `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"`
- `cd backend && dotnet build ModernWMS.sln`
- `./scripts/test-all.sh --skip-ui`

Frontend:
- `cd frontend && yarn build`
- `cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e`

Integration:
- `./scripts/macos-dev.sh status`
- use repo scripts or `tmux` for long-running start / stop flows

## Stop and Report When

- 重构开始触及未批准模块
- 为了“更优雅”需要大规模改架构
- 测试覆盖不足，无法安全确认行为不变
- 需要同时动前后端多个边界且目标不清晰

## Common Mistakes

- 在没有测试或验证基线时重构
- 一次混入多个问题：命名、抽象、行为修改一起做
- 因为“顺手”扩大需求范围
- 把局部整理升级成全局框架改造
- 验证失败后仍宣称重构完成

## Full Workflow

For the full checklist, examples, and stop points, read:
- `../../../docs/development-standards/ai-collaboration-sop/code-refactoring-sop.md`

**REQUIRED SUB-SKILL:** Use `verification-before-completion` before claiming the refactor is done.
