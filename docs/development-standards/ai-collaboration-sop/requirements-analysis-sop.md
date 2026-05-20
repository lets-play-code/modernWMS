# ModernWMS AI 协同需求分析与迭代规划作业指导书

## 适用场景

适用于 **新功能需求**、**较大增强需求**、**跨上下文能力设计**。

如果只是非常局部的文案、字段展示或规则微调，优先改走变更 SOP，而不是把小问题包装成一次完整需求分析。

## 必读文档

开始前至少阅读：

- `docs/domain-model/README.md`
- `docs/domain-model/user-journeys.md`
- `docs/domain-model/bounded-contexts.md`
- `docs/domain-model/strategic-ddd-design.md`
- `docs/domain-model/ubiquitous-language.md`
- `docs/software-design/api-design.md`
- `docs/software-design/ui-ux-style-guide.md`
- `docs/development-standards/backend-conventions.md`
- `docs/development-standards/frontend-conventions.md`
- `docs/development-standards/testing-conventions.md`

如果需求只落在某一个上下文，还要补读对应上下文目录，例如：

- `docs/domain-model/master-data/overview.md`
- `docs/domain-model/inbound-execution/overview.md`
- `docs/domain-model/inventory-visibility/overview.md`
- `docs/domain-model/internal-operations/overview.md`
- `docs/domain-model/outbound-fulfillment/overview.md`
- `docs/domain-model/system-management/overview.md`

## 核心原则

1. **先确认业务价值，再谈实现细节**
2. **先判断上下文归属，再做接口和页面拆分**
3. **MVP 优先，避免一次性把 P0/P1/P2 混做**
4. **用户旅程、领域规则、API、UI 设计分别归档到正确目录**
5. **优先更新已有长期文档，不要另起一套并行知识体系**

## 流程总览

```text
1. 需求理解与 JTBD
2. 用户旅程梳理
3. 上下文归属判断
4. 领域模型 / 状态 / 规则整理
5. MVP 迭代规划
6. P0 的 API / UI 设计
7. 后续实现 SOP 交接
```

---

## 步骤 1：需求理解与 JTBD

**目标**：明确谁要解决什么问题、为什么重要。

### AI 行动

1. 识别核心角色（3-5 个以内）
2. 提炼每个角色的目标、痛点、当前障碍
3. 区分“真正业务目标”和“用户口头提出的功能”
4. 给出初步优先级判断

### 输出模板

```markdown
## 一、需求理解

### 1. 核心角色与目标
| 角色 | 要完成的任务 | 真正目标 | 当前障碍 |
| --- | --- | --- | --- |
| 仓库管理员 | ... | ... | ... |
| 收货员 | ... | ... | ... |

### 2. 初步优先级
| 能力 | 服务对象 | 业务价值 | 优先级 |
| --- | --- | --- | --- |
| ... | ... | ... | P0 / P1 / P2 |
```

🛑 **强制停止点**：输出需求理解后，等待用户确认。

### 归档位置

- 需求背景、来源、会议纪要：`docs/requirements/YYYY-MM-DD-<topic>.md`

---

## 步骤 2：用户旅程梳理

**目标**：用业务语言描述主流程与异常流程，不提前写技术实现。

### AI 行动

1. 识别主流程（Happy Path）
2. 识别异常流程和失败处理
3. 标记关键角色切换点
4. 记录前置条件与后置条件

### 输出模板

```markdown
## 二、用户旅程

### 1. 主流程
1. [角色] 执行 ...
2. [角色] 确认 ...
3. 系统记录 ...
4. [角色] 完成 ...

### 2. 异常流程
- 场景 A：...
- 场景 B：...

### 3. 前置 / 后置条件
- 前置：...
- 后置：...
```

🛑 **强制停止点**：输出用户旅程后，等待用户确认。

### 归档位置

- 如果影响全局旅程：更新 `docs/domain-model/user-journeys.md`
- 如果是某一上下文特有旅程：补充到对应 `docs/domain-model/<context>/overview.md` 或同目录专题文档

---

## 步骤 3：上下文归属判断

**目标**：把需求放进已有边界，而不是先定义代码结构。

### AI 行动

1. 对照 `bounded-contexts.md` 判断归属
2. 判断是扩展已有上下文，还是需要新增上下文文档
3. 如果跨上下文，明确主上下文与协作上下文
4. 明确共享术语、共享字段和边界规则

### 归属判断问题

- 需求主要改变的是主数据、入库、库存可视化、库内操作、出库履约还是系统管理？
- 是否会修改多个上下文都依赖的统一语言？
- 是否需要更新 `bounded-contexts.md` 或 `strategic-ddd-design.md`？

### 输出模板

```markdown
## 三、上下文归属

### 1. 主上下文
- 归属：`outbound-fulfillment`
- 理由：...

### 2. 协作上下文
| 上下文 | 参与方式 | 影响点 |
| --- | --- | --- |
| master-data | 读取客户 / SKU / 仓库数据 | ... |
| inventory-visibility | 使用库存可用量 | ... |

### 3. 是否需要调整上下文文档
- [ ] 仅扩展现有文档
- [ ] 需要更新全局边界文档
```

🛑 **强制停止点**：输出上下文归属后，等待用户确认。

### 归档位置

- 全局边界与战略判断：`docs/domain-model/bounded-contexts.md`、`docs/domain-model/strategic-ddd-design.md`
- 上下文本地知识：`docs/domain-model/<context>/overview.md`

---

## 步骤 4：领域模型、状态与规则整理

**目标**：从旅程中提炼状态变化、关键对象和业务规则。

### AI 行动

1. 识别核心领域对象
2. 描述状态流转和关键命令
3. 提炼领域规则、前置校验、异常约束
4. 与统一语言对齐命名

### 输出模板

```markdown
## 四、领域模型与规则

### 1. 核心对象
| 对象 | 核心职责 | 关键状态 |
| --- | --- | --- |
| ASN | ... | 草稿 / 已确认 / 已分拣 / 已上架 |
| Dispatchlist | ... | ... |

### 2. 状态流转
- 对象 A：状态1 -> 状态2 -> 状态3
- 对象 B：...

### 3. 关键业务规则
- 规则 1：...
- 规则 2：...
- 规则 3：...
```

🛑 **强制停止点**：输出领域模型与规则后，等待用户确认。

### 归档位置

- 统一语言：`docs/domain-model/ubiquitous-language.md`
- 上下文规则：`docs/domain-model/<context>/overview.md` 或专题文档

---

## 步骤 5：MVP 迭代规划

**目标**：把需求拆成 P0 / P1 / P2，优先形成最小可用闭环。

### AI 行动

1. 从业务价值角度拆分场景
2. 明确本次只做哪些 API、页面、状态变化
3. 给出 P0 验收标准
4. 标记后续增强项

### 输出模板

```markdown
## 五、迭代规划

### P0（MVP）
| 场景 | 说明 | 涉及上下文 | 验收标准 |
| --- | --- | --- | --- |
| SCENE-01 | ... | ... | ... |

### P1
| 场景 | 说明 |
| --- | --- |
| ... | ... |

### P2
| 场景 | 说明 |
| --- | --- |
| ... | ... |
```

🛑 **强制停止点**：输出 MVP 规划后，等待用户确认。

### 归档位置

- 需求背景与业务上下文：`docs/requirements/`
- AI 设计说明 / spec：`docs/progress/planned/superpowers/specs/`
- AI 实施计划 / plan：`docs/progress/planned/superpowers/plans/`
- 执行中的阶段性说明：`docs/progress/active/`
- 如果某项结论长期有效且跨需求复用，再沉淀到 `docs/software-design/` 或 `docs/domain-model/`

---

## 步骤 6：P0 的 API / UI 设计

**目标**：只设计本次 MVP 必须交付的接口与交互。

### API 设计关注点

- 是否复用 `ResultModel<T>`、`PageData<T>`、`PageSearch`
- 是否需要租户隔离
- 是否需要菜单、权限、操作日志
- 是否需要导入导出、打印、批量操作

### UI 设计关注点

- 是否复用现有列表页 / 对话框骨架
- 是否接入 `custom-pager`、`BtnGroup`、`tooltip-btn`、`SearchGroup`
- 是否补齐 i18n、动态菜单、按钮权限
- 是否影响 `ui-ux-style-guide.md`

### 归档位置

- 如果形成的是 **跨需求稳定 API 协作规则**，更新 `docs/software-design/api-design.md`
- 如果形成的是 **跨页面稳定 UI / UX 规则**，更新 `docs/software-design/ui-ux-style-guide.md`
- 如果只是本次需求的专题设计，优先在 `docs/software-design/` 下新增或更新专题文档（如 `YYYY-MM-DD-<topic>.md`、`<topic>/overview.md`），不要把单次需求细节硬塞进全局总览文档

---

## 步骤 7：交接到实现 SOP

根据确认结果进入后续流程：

| 场景 | 后续 SOP |
| --- | --- |
| 新增后端能力 | `backend-implementation-sop.md` |
| 新增前端能力 | `frontend-implementation-sop.md` |
| 同时有前后端 | 先后端，再前端 |

## 产出检查清单

- [ ] 需求背景已落到 `docs/requirements/`
- [ ] 上下文归属已明确
- [ ] 领域模型 / 状态 / 规则已沉淀到 `docs/domain-model/`
- [ ] P0 范围已确认
- [ ] API / UI 设计已按“全局规则更新总览、单需求设计写专题文档”的方式落到 `docs/software-design/`
- [ ] 没有新建与仓库结构冲突的顶层文档目录
