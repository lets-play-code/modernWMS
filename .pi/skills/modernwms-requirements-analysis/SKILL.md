---
name: modernwms-requirements-analysis
description: Use when a ModernWMS task is a new feature, a larger enhancement, or a cross-context capability and the agent must decide bounded contexts, user journeys, domain rules, MVP scope, and document destinations before implementation.
---

# ModernWMS Requirements Analysis

## Overview

Treat new ModernWMS work as domain analysis first, implementation second. Start from business value, context boundaries, user journeys, and MVP, then place outputs into the repo's real documentation structure.

## Required Reading

Before acting, read:
- `../../../docs/development-standards/ai-collaboration-sop/requirements-analysis-sop.md`
- `../../../docs/domain-model/README.md`
- `../../../docs/domain-model/user-journeys.md`
- `../../../docs/domain-model/bounded-contexts.md`
- `../../../docs/domain-model/strategic-ddd-design.md`
- `../../../docs/domain-model/ubiquitous-language.md`
- relevant `../../../docs/domain-model/<context>/overview.md`
- `../../../docs/software-design/api-design.md`
- `../../../docs/software-design/ui-ux-style-guide.md`
- `../../../docs/development-standards/backend-conventions.md`
- `../../../docs/development-standards/frontend-conventions.md`
- `../../../docs/development-standards/testing-conventions.md`

## Quick Reference

| Phase | Must produce |
| --- | --- |
| 需求理解 / JTBD | 核心角色、目标、痛点、业务价值、初步优先级 |
| 用户旅程 | happy path、异常流程、前置/后置条件 |
| 上下文归属 | 主上下文、协作上下文、边界理由 |
| 领域模型与规则 | 核心对象、状态流转、关键规则、不变量 |
| MVP 规划 | P0 / P1 / P2、范围边界、验收标准 |
| P0 设计 | 仅本次 MVP 必需的 API / UI 设计 |

## Document Destinations

- 需求背景、来源、验收标准 → `docs/requirements/`
- 用户旅程、上下文、统一语言、领域规则 → `docs/domain-model/`
- 长期 API / UI / 架构设计 → `docs/software-design/`
- AI spec / plan → `docs/progress/planned/superpowers/specs/`、`docs/progress/planned/superpowers/plans/`
- 执行中阶段状态 → `docs/progress/active/`
- 完成后的 AI 工作流归档 → `docs/progress/archive/superpowers/`

## Hard Rules

- 先确认业务价值，再谈接口、表结构、页面细节。
- 先判断 bounded context，再拆 API 和页面。
- P0 / P1 / P2 必须分开，不把增强项混进 MVP。
- 优先更新已有长期文档，不新建与仓库结构冲突的平行目录。
- 单需求设计优先写专题文档，不把一次性细节硬塞进总览文档。

## Stop Points

Stop and confirm after each major section:
1. 需求理解 / JTBD
2. 用户旅程
3. 上下文归属
4. 领域模型与规则
5. MVP 规划

## Handoff

Choose the next skill by delivery type:
- 新增后端能力 → `modernwms-backend-implementation`
- 新增前端能力 → `modernwms-frontend-implementation`
- 前后端都新增 → 先 `modernwms-backend-implementation`，再 `modernwms-frontend-implementation`

## Common Mistakes

- 把局部小改动包装成一次完整需求分析
- 还没判断上下文就先设计 controller / table / page
- 把长期知识写进 `docs/progress/`
- 新建 `docs/用户旅程/`、`docs/API设计/` 之类仓库外目录
- 没拆 P0 / P1 / P2 就直接进入实现

## Full Workflow

For the complete checklist, templates, and stop points, read:
- `../../../docs/development-standards/ai-collaboration-sop/requirements-analysis-sop.md`

**REQUIRED SUB-SKILL:** Use `verification-before-completion` before claiming analysis or planning is done.
