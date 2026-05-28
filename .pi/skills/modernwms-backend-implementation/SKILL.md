---
name: modernwms-backend-implementation
description: Use when adding a new ModernWMS backend capability, API, or service behavior after the requirement or design is confirmed, especially when the work must follow the repo's real .NET, EF Core, ResultModel, PageData, tenant, and test conventions.
---

# ModernWMS Backend Implementation

## Overview

Implement new backend work in ModernWMS under a strict TDD gate: **RED → Verify RED → GREEN → Verify GREEN → REFACTOR → Final Verification**. No production code before a failing test first.

## Required Reading

Before acting, read:
- `../../../docs/development-standards/ai-collaboration-sop/backend-implementation-sop.md`
- `../../../docs/development-standards/backend-conventions.md`
- `../../../docs/development-standards/testing-conventions.md`
- `../../../docs/software-design/api-design.md`
- relevant `../../../docs/domain-model/<context>/overview.md`
- relevant `../../../docs/requirements/...`

## Actual Stack Map

- Backend: C# / .NET 7 / ASP.NET Core
- Data access: EF Core + `SqlDBContext`
- DI: `IDependency` + `RegisterAssembly()`
- API envelope: `ResultModel<T>` / `PageData<T>`
- Paging/search: `PageSearch` + `SearchObject` + `QueryCollection`
- API E2E: Reqnroll + xUnit + Testcontainers.MySql
- Unit tests: xUnit + FluentAssertions
- UI-driven E2E: Playwright + real frontend / backend / MySQL when user-visible cross-layer behavior needs protection

## Quick Reference

| Phase | Must do |
| --- | --- |
| 阅读现状 | 先看 `Program.cs`、`Startup.cs`、相关 Controller / IServices / Services / ViewModels / Tests |
| RED | 先选最小验证切片，再写失败测试 |
| Verify RED | 亲自运行并确认“因目标行为缺失而失败”，不是环境错误 |
| GREEN | 只做让当前 RED 通过的最小实现 |
| Verify GREEN | 当前测试、受影响近邻测试通过；命中 UI 条件时目标 UI 驱动 E2E 也通过 |
| REFACTOR | 仅在绿灯下做局部整理，整理后重新回绿 |
| Final Verification | 按范围跑 target unit / API E2E、`dotnet build`、`test-all.sh --skip-ui`，必要时 UI 驱动 E2E |

## Hard Rules

- No production code before a failing test first.
- Verify RED is mandatory. Test passing immediately means the test is wrong or already covered.
- Verify GREEN is mandatory before refactor or completion claims.
- Controller stays thin; business logic stays in Service.
- Keep `ResultModel<T>` / `PageData<T>` / tenant / localization conventions intact.
- Do not bundle unrelated refactors into feature implementation.

## UI-driven E2E Trigger

UI-driven E2E must enter the verification chain when any of these apply:
- menu / route / page reachability changes
- button permission or visible / disabled semantics change
- frontend logic depends on backend fields for status, visibility, or UI / API consistency
- the real user flow must be proven across UI + API + DB

## Required Checks

Check these when relevant:
- menu / permission / visibility:
  - `../../../scripts/seeds/database_mysql.sql`
  - `../../../backend/ModernWMS.WMS/Services/User/UserService.cs`
  - `../../../frontend/src/utils/router/index.ts`
  - `../../../frontend/src/view/base/roleMenu/actionList.ts`
- test DB / fixtures:
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
- integration status only when needed:
  - `./scripts/macos-dev.sh status`

## Common Mistakes

- 跳过 RED，直接写实现
- 没验证 RED 的失败原因，就开始改代码
- 用 `dotnet build` 代替行为验证
- 命中 UI 条件却没跑目标 UI 驱动 E2E
- 顺手扩张成大重构

## Full Workflow

For the complete workflow, stop points, and strict gates, read:
- `../../../docs/development-standards/ai-collaboration-sop/backend-implementation-sop.md`

**REQUIRED SUB-SKILL:** Use `test-driven-development` before implementation and `verification-before-completion` before claiming success.
