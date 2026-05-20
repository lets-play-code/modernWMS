---
name: modernwms-requirements-change
description: Use when an existing ModernWMS requirement, design, or rollout plan changes and the agent must assess document, context, scope, code, and downstream workflow impact before implementation.
---

# ModernWMS Requirements Change

## Overview

Treat requirement changes as document and boundary work before code work. Update the existing long-lived knowledge first, then adjust plan and implementation flow.

## Required Reading

Before acting, read:
- `../../../docs/development-standards/ai-collaboration-sop/requirements-change-sop.md`
- original requirement docs under `../../../docs/requirements/`
- relevant `../../../docs/domain-model/...`
- relevant `../../../docs/software-design/...`
- `../../../docs/development-standards/backend-conventions.md`
- `../../../docs/development-standards/frontend-conventions.md`
- `../../../docs/development-standards/testing-conventions.md`

## Quick Reference

| Phase | Must check |
| --- | --- |
| 变更理解 | 变更前后差异、类型、业务原因 |
| 影响分析 | 上下文边界、长期文档、代码模块、测试回归面 |
| 长期文档更新 | `docs/requirements/`、`docs/domain-model/`、`docs/software-design/` |
| 计划调整 | P0/P1/P2、spec、plan、执行状态 |
| 后续交接 | 进入 backend / frontend change，或重新判定为 implementation |

## Document Destinations

- 长期需求知识 → `docs/requirements/`
- 领域边界、状态、术语 → `docs/domain-model/`
- 稳定 API / UI / 架构规则 → `docs/software-design/`
- 过程性 spec / plan / 执行状态 → `docs/progress/planned/superpowers/`、`docs/progress/active/`、`docs/progress/archive/superpowers/`

## Hard Rules

- 先分析影响，再讨论实现。
- 优先更新已有文档，不为同一主题再造一份平行文档。
- 变更原因必须可追溯。
- 长期知识放长期目录，过程状态放 `docs/progress/`。
- 如果变更暴露上下文边界问题，先修正文档边界，再改实现。

## Stop Points

Stop and confirm after:
1. 变更理解
2. 影响分析
3. 关键长期文档更新
4. 计划调整

## Handoff

Choose the next skill by change type:
- 仅后端变更 → `modernwms-backend-change`
- 仅前端变更 → `modernwms-frontend-change`
- 前后端都变 → 先 `modernwms-backend-change`，再 `modernwms-frontend-change`
- 实际上是新增能力而不是调整 → 改用 `modernwms-backend-implementation` / `modernwms-frontend-implementation`

## Common Mistakes

- 只更新新的计划文档，不更新原始需求 / 设计 / 领域文档
- 把过程说明写进长期规范，制造噪音
- 忽略边界变化，直接改接口和页面
- 只看代码影响，不看测试和文档影响
- 创建与仓库结构冲突的新顶层目录

## Full Workflow

For the complete step list, output templates, and change record guidance, read:
- `../../../docs/development-standards/ai-collaboration-sop/requirements-change-sop.md`

**REQUIRED SUB-SKILL:** Use `verification-before-completion` before claiming the change analysis is complete.
