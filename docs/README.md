# ModernWMS 文档目录规范

本文定义 `docs/` 下的长期文档、进度文档和教学练习资料的组织方式，作为项目文档入口。

## 目标

- 让长期有效的知识有固定归档位置，而不是散落在 `docs/` 根目录
- 让 Agent 和人工都能快速判断“这类信息应该写到哪里”
- 区分**长期知识**、**过程进度**与**课堂练习资料**
- 支持“一个主题一篇文档”“一个主题一个目录 + 多篇文档”以及“全局总览 + 上下文子目录”三种组织方式

## 目录总览

```text
docs/
├── README.md                                  # 文档目录规范与入口
├── macOS-setup.md                             # 根目录公共入口 / 操作文档
├── domain-model/                              # 领域模型
├── software-design/                           # 软件设计
├── requirements/                              # 需求
│   └── classroom-practice/                    # 课堂练习 / 教学场景材料
├── development-standards/                     # 开发规范
└── progress/                                  # 当前 / 计划 / 已完成事项
    ├── planned/                               # 计划进行 / 待执行
    ├── active/                                # 当前进行中
    └── archive/                               # 已完成归档
```

## 长期文档的一级分类

### 1. `docs/domain-model/`
记录业务领域本身，而不是具体技术实现。

应放内容：
- 用户旅程（User Journey）
- 业务流程
- 上下文划分（Bounded Context）
- DDD 战略设计
- 统一语言（Ubiquitous Language）
- 核心实体、聚合、领域规则说明

说明：
- 可以只有一篇总文档，也可以拆成 `README.md + 多篇专题文档`
- 当主题同时需要全局视角和局部落地时，推荐采用“全局总览 + 上下文子目录”的混合模式
- 当业务概念和技术实现都要说明时，业务含义优先放这里，技术落地细节放到 `software-design/`

### 2. `docs/software-design/`
记录系统如何被设计和实现。

应放内容：
- 架构设计
- 部署架构
- API 设计
- 数据流设计
- 集成设计
- UX / 交互设计
- 非功能设计（性能、可靠性、安全等）

说明：
- 强调“软件如何工作”
- 与 `domain-model/` 的区别：这里关注技术方案、接口、边界、部署和实现结构

### 3. `docs/requirements/`
记录需求来源、目标和约束。

应放内容：
- 原始需求来源
- 客户参考信息
- 会议纪要 / 背景材料
- 需求拆解
- 验收标准
- 需求变更记录

说明：
- 需求文档优先保留来源和上下文
- 时间敏感内容可以按日期拆分
- 与课堂练习或教学场景有关、但不属于正常业务主线的材料，放在 `docs/requirements/classroom-practice/`

### 4. `docs/development-standards/`
记录跨需求可复用的研发约束和检查规则。

应放内容：
- 代码风格
- 数据库设计风格
- 跨需求公共检查项
- 测试设计规范
- 接口兼容性约束
- 提交、评审、发布前检查规则

说明：
- 应尽量写成可执行、可检查、可复用的规则
- 不写一次性任务说明，不写只对单次需求有效的临时结论

## 进度目录

### `docs/progress/`
记录项目中**计划进行、当前进行中、已经完成归档**的事项。

推荐子目录：
- `docs/progress/planned/`：待开始、待批准执行、已形成计划但尚未进入实施的事项
- `docs/progress/active/`：当前正在执行的事项、进展记录、阶段性说明
- `docs/progress/archive/`：已完成事项的归档

### superpowers 文档放置规则

AI 工作流产物（例如 spec、implementation plan、执行中的中间说明）统一放在 `docs/progress/` 下，而不是单独放在 `docs/` 根目录。

推荐位置：
- 计划阶段 spec：`docs/progress/planned/superpowers/specs/`
- 计划阶段 plan：`docs/progress/planned/superpowers/plans/`
- 已完成历史归档：`docs/progress/archive/superpowers/`

规则：
- `superpowers` 文档属于**过程文档**，不是长期知识主目录
- 如果其中内容已经稳定且长期有效，应迁移到：
  - `domain-model/`
  - `software-design/`
  - `requirements/`
  - `development-standards/`
 之一

## 课堂练习资料目录

### `docs/requirements/classroom-practice/`
本目录用于存放：
- 与课堂练习、教学演示、实验场景相关的说明
- 为课程或练习准备的数据脚本、指导文档、场景材料

规则：
- 它属于需求背景资料的一种特殊子类
- 不应被误认为正常业务主线的产品文档
- 若某份文档转化为正式产品需求，应迁回 `docs/requirements/` 的常规位置

## 根目录使用规则

`docs/` 根目录原则上只保留：
- `docs/README.md`
- 少量公共入口文档
- 跨目录导航用途的说明文档

新增**长期文档**时：
- 不要直接放在 `docs/` 根目录
- 应优先放入四个长期分类目录之一

新增**过程文档**时：
- 不要新建 `docs/superpowers/` 这类顶层目录
- 应放入 `docs/progress/` 的对应子目录

## 组织与命名建议

### 组织建议

优先使用以下三种方式之一：

1. **单文档模式**
   - 适用于主题小、边界清晰的内容
   - 示例：`docs/domain-model/user-journeys.md`

2. **目录索引模式**
   - 适用于主题较大、后续会持续扩展的内容
   - 示例：
     - `docs/domain-model/README.md`
     - `docs/domain-model/bounded-contexts.md`
     - `docs/domain-model/strategic-ddd-design.md`

3. **全局总览 + 上下文子目录模式**
   - 适用于既需要系统全景，又需要按边界持续细化的主题
   - 示例：
     - `docs/domain-model/user-journeys.md`
     - `docs/domain-model/bounded-contexts.md`
     - `docs/domain-model/strategic-ddd-design.md`
     - `docs/domain-model/ubiquitous-language.md`
     - `docs/domain-model/<context>/overview.md`

### 命名建议

- 稳定主题文档：使用 `kebab-case.md`
- 带时间属性的需求/调研文档：使用 `YYYY-MM-DD-topic.md`
- `README.md` 只用于目录级元信息，例如阅读顺序、组织方式、归档规则
- 实际业务 / 技术内容文档应使用有语义的名字，例如 `overview.md`、`state-machine.md`、`rules.md`

## 写文档时的归档决策

写文档前，按下面顺序判断：

1. 这是不是长期知识？
   - 是：进入四个长期分类之一
   - 不是：继续下一步
2. 这是不是当前任务/计划/执行过程中的进度文档？
   - 是：放 `docs/progress/`
3. 这是不是课堂练习或教学材料？
   - 是：放 `docs/requirements/classroom-practice/`
4. 它主要描述的是业务还是技术？
   - 业务：`domain-model/`
   - 技术：`software-design/`
5. 它主要描述的是“为什么做 / 需求从哪来”吗？
   - 是：`requirements/`
6. 它主要描述的是“以后都要遵守的做法”吗？
   - 是：`development-standards/`

## 维护规则

- 优先更新已有文档，而不是重复创建同主题新文档
- 新文档应链接到相关的需求、设计、领域模型或规范文档
- 当 `docs/progress/` 中的结论变成长期规则时，应及时迁移
- 存量文档暂不强制重写；但在下次修改时，应尽量迁移到规范位置

## 当前已建立的入口

- `docs/domain-model/README.md`
- `docs/domain-model/ubiquitous-language.md`
- `docs/software-design/README.md`
- `docs/requirements/README.md`
- `docs/development-standards/README.md`
- `docs/progress/README.md`
