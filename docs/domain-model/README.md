# 领域模型文档

本目录存放 ModernWMS 的长期业务领域知识。

当前采用 **“全局总览 + 直接上下文子目录”** 的混合结构：

- 全局文档负责解释系统全景、上下文边界、战略判断和统一语言
- 每个上下文直接使用一个独立子目录沉淀本地知识
- 新人应先建立全局认知，再进入自己负责的上下文

## 推荐阅读顺序

### 1. 新人入门

1. [`user-journeys.md`](./user-journeys.md)：先理解系统如何被使用
2. [`bounded-contexts.md`](./bounded-contexts.md)：再理解系统如何划分边界
3. [`strategic-ddd-design.md`](./strategic-ddd-design.md)：再理解为什么这样划分
4. [`ubiquitous-language.md`](./ubiquitous-language.md)：统一术语和概念边界
5. 对应上下文目录下的 `overview.md` 等内容文档：深入查看本地旅程、状态、规则和代码入口

### 2. 做需求或影响分析

1. 先看 [`bounded-contexts.md`](./bounded-contexts.md)
2. 再看目标上下文文档
3. 如果涉及共享术语，补看 [`ubiquitous-language.md`](./ubiquitous-language.md)
4. 如果涉及跨上下文规则，再回看 [`strategic-ddd-design.md`](./strategic-ddd-design.md)

### 3. 做架构或领域讨论

建议一起阅读：

- [`bounded-contexts.md`](./bounded-contexts.md)
- [`strategic-ddd-design.md`](./strategic-ddd-design.md)
- [`ubiquitous-language.md`](./ubiquitous-language.md)
- 涉及上下文的本地文档

## 什么时候直接进入上下文目录

适合以下场景：

- 已经知道自己要改哪个业务模块
- 需要做局部影响分析
- 需要给新人介绍某一个具体上下文
- 需要在不通读全部全局文档的前提下快速进入目标模块

## 目录结构

```text
domain-model/
├── README.md
├── user-journeys.md
├── bounded-contexts.md
├── strategic-ddd-design.md
├── ubiquitous-language.md
├── master-data/
│   └── overview.md
├── inbound-execution/
│   └── overview.md
├── inventory-visibility/
│   └── overview.md
├── internal-operations/
│   └── overview.md
├── outbound-fulfillment/
│   └── overview.md
└── system-management/
    └── overview.md
```

## 全局文档

- [`user-journeys.md`](./user-journeys.md)
  - 说明系统端到端如何被使用
  - 适合新人快速建立业务闭环认知
- [`bounded-contexts.md`](./bounded-contexts.md)
  - 说明有哪些上下文、边界在哪里、彼此如何协作
  - 适合做需求归属和影响分析
- [`strategic-ddd-design.md`](./strategic-ddd-design.md)
  - 说明核心域、支撑域、通用域、共享内核和战略判断
  - 适合做架构讨论和长期维护决策
- [`ubiquitous-language.md`](./ubiquitous-language.md)
  - 说明统一语言、关键术语和易混概念边界
  - 适合做文档命名、需求沟通和设计澄清

## 上下文子目录

- [`master-data/overview.md`](./master-data/overview.md)
- [`inbound-execution/overview.md`](./inbound-execution/overview.md)
- [`inventory-visibility/overview.md`](./inventory-visibility/overview.md)
- [`internal-operations/overview.md`](./internal-operations/overview.md)
- [`outbound-fulfillment/overview.md`](./outbound-fulfillment/overview.md)
- [`system-management/overview.md`](./system-management/overview.md)

## 命名约定

- `README.md` 只用于记录目录级的元信息，例如：
  - 本目录放什么
  - 推荐阅读顺序
  - 文档分工和组织方式
- 实际业务 / 代码相关的内容文档不要命名为 `README.md`
- 内容文档应使用有语义的名字，例如：
  - `overview.md`
  - `user-journeys.md`
  - `bounded-contexts.md`
  - `state-machine.md`
  - `rules.md`

## 文档分工约定

- 全局文档只保留系统级视角，不重复展开上下文本地细节
- 上下文文档负责本地旅程、状态机、核心模型、关键规则、上下游关系和代码入口
- 当一个规则影响多个上下文时：
  - 在全局文档中说明它的共享语义
  - 在受影响上下文文档中分别说明本地影响
- 当一个上下文文档明显变大时，再从该目录内拆出 `journey.md`、`state-machine.md`、`rules.md` 等专题文件
- 优先更新已有文档，而不是为同一主题重复创建新文档

## 主要分析依据

这些文档主要基于以下材料整理：

- `.understand-anything/knowledge-graph.json`
- `backend/ModernWMS.WMS/Services/*`
- `frontend/src/view/base/*`
- `frontend/src/view/wms/*`
- `frontend/src/view/warehouseWorking/*`
- `frontend/src/view/deliveryManagement/*`

后续如果领域知识继续细化，可在本目录继续增加：

- `aggregates-and-invariants.md`
- `domain-events-and-state-transitions.md`
- `roles-and-authority-model.md`
