# 系统管理上下文

> 全局视角见 [`../bounded-contexts.md`](../bounded-contexts.md) 与 [`../strategic-ddd-design.md`](../strategic-ddd-design.md)。本文只记录系统管理上下文的本地知识。

## 1. 业务目标

为各业务上下文提供统一的身份、权限、菜单、日志、打印和公司级基础能力，使仓储流程能够被控制、被追踪、被审计。

这个上下文不决定仓储业务规则，但决定谁可以进入业务流程、执行哪些动作，以及操作能否被记录。

## 2. 范围 / 非范围

### 范围内

- 登录认证 / Token
- 用户、角色、菜单
- 操作日志
- 公司信息
- 打印方案

### 不在范围内

- 入库、出库、库存和库内作业规则本身
- 商品、仓库、货主等业务主数据定义

## 3. 主要角色

| 角色 | 主要目标 |
| --- | --- |
| 系统管理员 | 配置账号、角色、菜单和公司信息 |
| 业务负责人 | 控制权限边界、审计操作行为 |
| 一线业务用户 | 在权限允许的前提下使用具体业务上下文 |

## 4. 主要能力

| 能力 | 关键模型 / 组件 | 作用 |
| --- | --- | --- |
| 登录认证 | `ModernWMS.Core.JWT/*` | 提供身份认证能力 |
| 用户 / 角色 / 菜单 | `User`、`Rolemenu`、`Userrole` | 控制可见入口与操作权限 |
| 操作日志 | `ActionLog` | 记录关键业务操作 |
| 公司信息 | `Company` | 维护公司级基础配置 |
| 打印方案 | `PrintSolution` | 支撑标签和单据输出 |

## 5. 关键规则 / 不变量

- **系统管理是 Generic Subdomain，而不是仓储核心域**
  - 它支撑业务，但不负责定义仓储执行规则
- **菜单与权限控制的是入口和动作，不是库存语义**
- **新增关键业务动作时，应同步考虑日志与权限边界**
- **打印属于支撑能力，不能反向主导领域模型设计**

## 6. 上下游与协作

### 被支撑方

- [`../master-data/overview.md`](../master-data/overview.md)
- [`../inbound-execution/overview.md`](../inbound-execution/overview.md)
- [`../inventory-visibility/overview.md`](../inventory-visibility/overview.md)
- [`../internal-operations/overview.md`](../internal-operations/overview.md)
- [`../outbound-fulfillment/overview.md`](../outbound-fulfillment/overview.md)

### 协作说明

系统管理横切所有上下文：

- 决定谁能看到哪个菜单
- 决定谁能执行哪个动作
- 为关键操作提供审计与追踪能力

## 7. 代码入口

### 后端服务

- `backend/ModernWMS.WMS/Services/User/UserService.cs`
- `backend/ModernWMS.WMS/Services/Rolemenu/RolemenuService.cs`
- `backend/ModernWMS.WMS/Services/Userrole/UserroleService.cs`
- `backend/ModernWMS.WMS/Services/ActionLog/ActionLogService.cs`
- `backend/ModernWMS.WMS/Services/Company/CompanyService.cs`
- `backend/ModernWMS.WMS/Services/PrintSolution/PrintSolutionService.cs`

### 前端页面

- `frontend/src/view/base/userManagement/*`
- `frontend/src/view/base/roleMenu/*`
- `frontend/src/view/base/userRoleSetting/*`
- `frontend/src/view/base/printTemplate/*`

## 8. 相关阅读

- [`../bounded-contexts.md`](../bounded-contexts.md)
- [`../strategic-ddd-design.md`](../strategic-ddd-design.md)
