# ModernWMS AI 协同需求变更作业指导书

## 适用场景

适用于 **已有需求**、**已有设计**、**已有功能规划** 的变更，包括但不限于：

- 业务规则调整
- API 字段变更
- 用户旅程变更
- 领域模型增删改
- 页面交互或展示方式调整
- 迭代范围收缩 / 扩大

## 必读文档

- 原始需求文档：`docs/requirements/...`
- 对应上下文文档：`docs/domain-model/...`
- 相关设计文档：`docs/software-design/...`
- 相关开发规范：
  - `docs/development-standards/backend-conventions.md`
  - `docs/development-standards/frontend-conventions.md`
  - `docs/development-standards/testing-conventions.md`

## 核心原则

1. **先分析影响，再讨论实现**
2. **优先更新已有文档，不要为同一主题再造一份新文档**
3. **变更原因必须可追溯**
4. **只改必须改的长期知识，过程性状态放 `docs/progress/`**
5. **如果变更暴露上下文边界问题，要先修正文档边界再改实现**

## 流程总览

```text
1. 理解变更内容
2. 影响分析
3. 更新长期设计文档
4. 调整迭代规划 / 执行计划
5. 进入后端 / 前端变更 SOP
```

---

## 步骤 1：理解变更内容

### AI 行动

1. 明确变更前后的差异
2. 判断变更类型（规则 / 字段 / 流程 / 模型 / 交互）
3. 说明变更原因和业务动机
4. 用简明表格输出变更对比

### 输出模板

```markdown
## 一、变更理解

### 1. 变更描述
- ...

### 2. 变更类型
- [ ] 业务规则调整
- [ ] API 字段变更
- [ ] 用户旅程变更
- [ ] 领域模型变更
- [ ] 交互方式变更

### 3. 前后对比
| 项目 | 变更前 | 变更后 |
| --- | --- | --- |
| ... | ... | ... |

### 4. 变更原因
- ...
```

🛑 **强制停止点**：输出变更理解后，等待用户确认。

---

## 步骤 2：影响分析

### AI 行动

1. 判断是否影响上下文边界
2. 判断影响哪些长期文档
3. 判断影响哪些代码模块与测试用例
4. 评估风险与回归面

### 输出模板

```markdown
## 二、影响分析

### 1. 上下文边界评估
- 是否影响 `bounded-contexts.md`：是 / 否
- 是否影响 `strategic-ddd-design.md`：是 / 否
- 是否影响某个上下文 `overview.md`：是 / 否

### 2. 受影响的长期文档
| 文档 | 路径 | 需要调整的内容 |
| --- | --- | --- |
| 需求 | docs/requirements/... | ... |
| 领域 | docs/domain-model/... | ... |
| 设计 | docs/software-design/... | ... |

### 3. 受影响的代码与测试
| 类型 | 路径 | 影响说明 |
| --- | --- | --- |
| 后端 | backend/... | ... |
| 前端 | frontend/... | ... |
| 测试 | backend/ModernWMS.Tests.* / frontend/e2e/... | ... |

### 4. 风险评估
| 风险 | 等级 | 应对 |
| --- | --- | --- |
| ... | 高 / 中 / 低 | ... |
```

🛑 **强制停止点**：输出影响分析后，等待用户确认。

---

## 步骤 3：更新长期设计文档

### 更新顺序建议

1. `docs/requirements/...`
2. `docs/domain-model/bounded-contexts.md`（如涉及边界）
3. `docs/domain-model/strategic-ddd-design.md`（如涉及战略判断）
4. `docs/domain-model/<context>/overview.md`
5. 如果变更形成 **跨需求稳定 API 协作规则**，更新 `docs/software-design/api-design.md`
6. 如果变更形成 **跨页面稳定 UI / UX 规则**，更新 `docs/software-design/ui-ux-style-guide.md`
7. 如果只是单次需求的专题设计，优先在 `docs/software-design/` 下新增或更新专题文档，而不是把一次性细节写进总览文档

### 变更记录建议

在相关文档末尾追加：

```markdown
## 变更记录

| 日期 | 变更内容 | 变更原因 |
| --- | --- | --- |
| 2026-05-19 | ... | ... |
```

### 注意事项

- 不要新建“docs/用户旅程/”“docs/API设计/”“docs/UX设计/”这类与仓库结构冲突的旧目录
- 如果只是一次性执行记录，不要写进长期文档，应放 `docs/progress/`
- AI 设计 / 计划文档优先放 `docs/progress/planned/superpowers/specs/` 与 `docs/progress/planned/superpowers/plans/`
- 如果 API / UI 规则已稳定，优先更新现有规范文档；如果只是单需求设计，优先写 `docs/software-design/` 下的专题文档

🛑 **强制停止点**：每次完成关键文档更新后，等待用户确认。

---

## 步骤 4：调整迭代规划 / 执行计划

### 触发条件

以下情况应同步调整计划：

- 新增了接口或页面
- 删除了原计划中的能力
- 变更导致测试场景需要重排
- 原来的 P0 / P1 / P2 边界不再成立

### 输出模板

```markdown
## 三、计划调整

### 新增项
| 项目 | 类型 | 说明 |
| --- | --- | --- |
| ... | 后端 / 前端 / 测试 | ... |

### 删除项
| 项目 | 原因 |
| --- | --- |
| ... | ... |

### 调整项
| 项目 | 原内容 | 新内容 |
| --- | --- | --- |
| ... | ... | ... |
```

### 归档位置

- AI 设计说明 / spec：`docs/progress/planned/superpowers/specs/`
- AI 实施计划 / plan：`docs/progress/planned/superpowers/plans/`
- 执行中的阶段性说明：`docs/progress/active/`
- 完成后的 AI 工作流归档：`docs/progress/archive/superpowers/`

🛑 **强制停止点**：输出计划调整后，等待用户确认。

---

## 步骤 5：进入后续变更 SOP

| 变更类型 | 后续 SOP |
| --- | --- |
| 仅后端 | `backend-change-sop.md` |
| 仅前端 | `frontend-change-sop.md` |
| 前后端都变 | 先 `backend-change-sop.md`，再 `frontend-change-sop.md` |
| 实际上是新增能力而不是调整 | 改走实现 SOP |

## 变更类型速查

| 变更项 | 需求文档 | 领域文档 | 设计文档 | 后端 | 前端 | 测试 |
| --- | --- | --- | --- | --- | --- | --- |
| 数值规则调整 | ✅ | ⚠️ | ⚠️ | ✅ | ⚠️ | ✅ |
| 状态流转变更 | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| API 新增字段 | ⚠️ | ⚠️ | ✅ | ✅ | ✅ | ✅ |
| 页面交互调整 | - | - | ✅ | ⚠️ | ✅ | ⚠️ |
| 上下文边界调整 | ⚠️ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ |

## 收尾检查清单

- [ ] 变更原因已记录
- [ ] 影响范围已与用户确认
- [ ] 长期文档已同步
- [ ] 计划 / 执行状态已按类型同步到 `docs/progress/planned/superpowers/`、`docs/progress/active/` 或 `docs/progress/archive/superpowers/`
- [ ] 后续应走实现 SOP 还是变更 SOP 已明确
