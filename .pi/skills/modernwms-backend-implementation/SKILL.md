---
name: modernwms-backend-implementation
description: Use when adding a new ModernWMS backend capability, API, or service behavior after the requirement or design is confirmed, especially when the work must follow the repo's real .NET, EF Core, ResultModel, PageData, tenant, and test conventions.
---

# ModernWMS Backend Implementation

## Overview

Implement new backend work in ModernWMS with test-first flow and the repository's actual stack. Follow thin controller, thick service, explicit tenant handling, and existing DTO / paging / localization patterns.

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
| 阅读现有实现 | 先看 `Program.cs`、`Startup.cs`、相关 Controller / IServices / Services / ViewModels / Tests |
| 测试先行 | 先补 API E2E 或单元测试，再跑红灯 |
| 最小实现 | 在 `Controllers`、`IServices`、`Services`、`Entities/ViewModels`、必要时 `Entities/Models` 做最小改动 |
| 绿灯验证 | 先跑当前测试，再跑相关测试类 / feature |
| 最小重构 | 只整理本次实现直接相关的重复、命名、边界 |
| 充分验证 | 目标 unit / API E2E、`dotnet build`、`test-all.sh --skip-ui`，必要时 UI 驱动 E2E |

## Hard Rules

- 先测试，后实现。
- Controller 继承 `BaseController`，保持薄；业务逻辑放 Service。
- 返回统一使用 `ResultModel<T>`；分页统一使用 `PageSearch` / `PageData<T>`。
- Service 继续用 `SqlDBContext` + LINQ / EF Core；读操作优先 `AsNoTracking()`。
- 写操作显式处理 `tenant_id`、`create_time`、`last_update_time`、`IStringLocalizer<MultiLanguage>`。
- 不在局部引入新的 Repository / UnitOfWork / Java 风格分层。

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

- target unit tests when checking service / core branches:
  - `cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"`
- target API E2E when checking real HTTP + service + DB:
  - `cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"`
- build:
  - `cd backend && dotnet build ModernWMS.sln`
- broader backend verification:
  - `./scripts/test-all.sh --skip-ui`
- UI-driven E2E when backend work reaches menus, permissions, page states, or UI / API consistency:
  - `./scripts/macos-dev.sh start`
  - `(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)`
  - `./scripts/macos-dev.sh stop`
- integration status when needed:
  - `./scripts/macos-dev.sh status`

## Handoff

- 新接口需要页面入口 / 页面适配 → `modernwms-frontend-implementation`
- 完成后若需要系统性整理 → `modernwms-code-refactoring`

## Common Mistakes

- 按 Spring / JPA / Maven / repository 模式实现
- 跳过红灯，直接写实现
- 忘记 `tenant_id`、本地化消息、统一返回、分页契约
- 漏掉 seed SQL、权限、菜单、前端入口同步检查
- 在新功能实现中顺手扩张成大重构

## Full Workflow

For the complete workflow, stop points, file list, and command examples, read:
- `../../../docs/development-standards/ai-collaboration-sop/backend-implementation-sop.md`

**REQUIRED SUB-SKILL:** Use `test-driven-development` before implementation and `verification-before-completion` before claiming success.
