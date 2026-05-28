# ModernWMS AI 协同前端功能实现作业指导书

## 适用场景

适用于 **前端新页面、新弹窗、新列表、新交互能力** 的实现，通常以前置的后端 API 已完成或已明确为前提。

## 必读文档

- `docs/development-standards/frontend-conventions.md`
- `docs/development-standards/testing-conventions.md`
- `docs/software-design/api-design.md`
- `docs/software-design/ui-ux-style-guide.md`
- 对应上下文文档：`docs/domain-model/<context>/overview.md`

## 真实技术栈映射

> 本项目前端不是 `frontend-v2 + Element Plus + AG-Grid + Pinia + pnpm` 方案，必须按仓库现状执行。

| 主题 | ModernWMS 实际方案 |
| --- | --- |
| 前端框架 | Vue 3 |
| 语言 | TypeScript |
| 构建工具 | Vite |
| UI 组件 | Vuetify 3 |
| 表格 | VXETable |
| 状态管理 | Vuex 4 |
| 路由 | Vue Router 4 |
| 多语言 | Vue I18n |
| 请求 | Axios（统一封装在 `utils/http/request.ts`） |
| UI 驱动 E2E | Playwright（真实前端 + 后端 API + 数据库） |
| 构建验证 | `cd frontend && yarn build` |

## 本 SOP 对齐的开发基线

本 SOP 的开发阶段**严格对齐** `superpowers:test-driven-development`：

```text
RED（先写失败测试）
→ Verify RED（确认因目标 UI / 链路行为缺失而失败）
→ GREEN（最小实现）
→ Verify GREEN（目标测试通过）
→ REFACTOR（仅在绿灯下整理）
→ Final Verification（按影响范围做最小充分验证）
```

## 核心原则

1. **任何生产代码前必须先有失败测试**
2. **以后端 API 和既有页面骨架为准**
3. **类型、API、i18n、页面实现都属于生产代码，不能先写再补测**
4. **保留现有 `snake_case` 业务字段命名**
5. **新增页面不仅能显示，还要接入菜单、权限、日志、路由**

## TDD 强制门禁

### 1. RED 门禁

以下内容都算生产代码，**不得先写**：
- `src/api/**`
- `src/types/**`
- `src/languages/**`
- `src/view/**`
- 路由、权限、日志、菜单配套

### 2. Verify RED 门禁

必须确认：
- 目标测试真的失败，而不是直接通过
- 失败原因与页面行为尚未实现、旧交互仍存在一致
- 不是测试环境、选择器、数据准备、断言错误

### 3. GREEN 门禁

实现阶段只允许：
- 让当前 RED 通过所需的最小代码
- 与该行为直接相关的最小 API / 类型 / i18n / 路由 / 权限 / 日志配套

### 4. Verify GREEN 门禁

必须确认：
1. 当前 RED 测试通过
2. 受影响的相邻 UI 测试 / 冒烟测试通过
3. 构建通过

### 5. REFACTOR 门禁

只有在 Verify GREEN 完成后，才允许做局部整理；整理后必须重新回到绿灯。

## UI 驱动 E2E 何时必须进入 RED / GREEN

当满足以下任一条件时，**UI 驱动 E2E 必须进入本次前端实现的 RED / GREEN 链路**：

- 菜单、路由、页面可达性发生变化
- 按钮权限、visible / disabled 语义发生变化
- 前端依赖后端字段做状态展示、可见性判断、前后端一致性逻辑
- 需要确认真实用户链路在 **UI + API + DB** 上一起工作

对于“新页面 / 新路由 / 新菜单入口 / 新按钮交互”这类实现，通常天然满足以上条件，应默认优先准备目标 Playwright spec。

## 流程总览

```text
F0. 菜单归属与页面位置判断
F1. 分析 API / 数据契约并选择验证切片
F2. 编写失败测试（RED）
F3. 验证红灯（Verify RED）
F4. 最小实现（GREEN）
F5. 验证绿灯（Verify GREEN）
F6. 最小重构（REFACTOR）
F7. 最小充分验证（Final Verification）
```

---

## 步骤 F0：菜单归属与页面位置判断

### 需要确认的点

- 页面属于 `base`、`wms`、`warehouseWorking`、`deliveryManagement`、`statisticAnalysis` 还是其他现有视图分组？
- 是否应出现在动态菜单中？
- 是完整页面、tab 子页，还是 `add-or-update-xxx.vue` 对话框组件？

### 必查文件

- `frontend/src/utils/router/index.ts`
- `frontend/src/view/base/roleMenu/actionList.ts`
- 相关现有页面目录：`frontend/src/view/...`

🛑 **强制停止点**：菜单归属、页面类型、入口位置先和用户确认。

---

## 步骤 F1：分析 API / 数据契约并选择验证切片

### AI 行动

1. 只分析当前必须支持的后端 API
2. 确认请求参数、响应结构、分页结构
3. 明确页面是列表、详情、流程页还是表单页
4. 判断本次最小可验证切片是什么
5. 判断是否命中 UI 驱动 E2E 强制条件

### 必查位置

- `frontend/src/api/...`
- `frontend/src/types/...`
- `docs/software-design/api-design.md`
- 对应后端 Controller / ViewModel

### 页面常见类型

| 类型 | 典型骨架 |
| --- | --- |
| 普通台账页 | 查询区 + `BtnGroup` + `vxe-table` + `custom-pager` + 弹窗 |
| 流程页 | `v-tabs` + 子组件 + `nextTick()` 触发子页加载 |
| 详情页 | 只读信息块 + 明细表 |
| 新增 / 编辑弹窗 | `add-or-update-xxx.vue` |

---

## 步骤 F2：编写失败测试（RED）

### RED 的首选方式

### 命中 UI 驱动 E2E 条件时

优先：
- 迭代已有 Playwright spec
- 或新增一个只覆盖当前最小行为切片的目标 spec

例如只验证：
- 菜单入口可达
- 某个按钮在有权限时 enabled、无权限时 disabled
- 某个状态标签在真实后端返回下正确显示
- 某个用户操作能通过 UI 成功触发真实 API 链路

### 未命中 UI 驱动 E2E 条件时

如果只是纯类型、构建配置、文案补充等**非行为性**改动，可不新增 Playwright spec；但要注意：
- `yarn build` 只能算补充验证
- 它**不能**充当 RED / GREEN 的行为证明
- 如果你实际上在改用户可见行为，就不能把它假装成“纯静态改动”

### RED 编写要求

1. 页面、按钮、路由、交互这类用户可见行为，优先用 Playwright 表达
2. 一次只写一个最小行为切片，不把整页所有能力打包进一个 RED
3. 先改测试，再改 API / 类型 / i18n / 页面代码
4. 如果当前仓库没有合适的自动化表达方式，应先停下确认，不准先实现再补测

---

## 步骤 F3：验证红灯（Verify RED）

### 常用命令

**目标 UI 驱动 E2E：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

### Verify RED 必须确认

- 目标 spec 真正失败
- 失败原因与页面 / 交互 / 链路尚未实现一致
- 不是环境错误、登录失败、种子数据缺失、选择器写错

### 遇到以下情况必须停止

- **测试直接通过**：先修 RED，不准写实现
- **测试因环境错误失败**：先修环境 / 测试准备
- **必须先写大量页面代码才会失败**：说明 RED 切片太大，先缩小

---

## 步骤 F4：最小实现（GREEN）

### 实现顺序

1. API 与类型
2. i18n
3. 页面脚本逻辑
4. 模板展示
5. 路由 / 权限 / 日志 / 菜单配套

### 实现规则

1. 页面里不要直接写 axios
2. 请求统一复用 `frontend/src/utils/http/request.ts`
3. 保持现有读取方式：`const { data: res } = await api()`
4. 类型命名延续现有 `*VO`、`DataProps`、`TablePage` 等风格
5. 业务字段保留 `snake_case`，不要额外做 camelCase 映射层
6. 继续复用现有 `script setup`、`reactive`、`vxe-table`、`custom-pager`、`BtnGroup`、`SearchGroup` 骨架
7. 只实现让当前 RED 通过所需的最小代码，不夹带大范围重写

### 如果页面要出现在菜单中

至少检查：
- `frontend/src/utils/router/index.ts`
- `frontend/src/view/base/roleMenu/actionList.ts`
- `backend/ModernWMS.WMS/Services/User/UserService.cs`
- `scripts/seeds/database_mysql.sql`

### 如果页面存在写操作

至少检查：
- `frontend/src/utils/systemLog.ts`
- 行内按钮权限 / 禁用态
- 弹窗提交后的成功反馈与列表刷新

---

## 步骤 F5：验证绿灯（Verify GREEN）

### 推荐顺序

1. 当前 RED spec 通过
2. 受影响的现有 UI 冒烟 / 相邻 spec 通过
3. 前端构建通过
4. 若本次是跨层真实链路，则确认目标 UI 驱动 E2E 已覆盖到真实 API + DB

### 常用命令

**目标 UI 驱动 E2E：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

**需要回归现有冒烟 / 相邻 spec 时：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e)
./scripts/macos-dev.sh stop
```

**构建验证：**

```bash
cd frontend && yarn build
```

### Verify GREEN 必须确认

- 当前 RED 已变绿
- 没有破坏相邻 UI 行为
- 构建通过
- 没有用“页面看起来应该行了”替代真实命令输出

---

## 步骤 F6：最小重构（REFACTOR）

只允许做与当前功能直接相关的整理：
- 提取局部重复逻辑
- 改善命名
- 收敛脚本复杂度
- 让模板与脚本边界更清晰

### REFACTOR 规则

- 不改变行为
- 一次只整理一个问题
- 整理后必须至少重新跑当前 GREEN 验证链路

---

## 步骤 F7：最小充分验证（Final Verification）

> Final Verification **不是** Verify GREEN 的替代品，而是面向收口 / 提交 / 交接的最小充分验收。

### 推荐组合

### 目标行为主要在 UI 语义或跨层链路

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
cd frontend && yarn build
```

### 影响范围较广，需要 UI 回归

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e)
./scripts/macos-dev.sh stop
cd frontend && yarn build
```

### 联调状态检查

```bash
./scripts/macos-dev.sh status
```

说明：
- `status` 只能证明环境已启动，**不能替代行为测试**
- 长运行命令优先复用 `./scripts/macos-dev.sh`，或放入 `tmux`

## 常见禁止项

1. 在页面里直接写 axios
2. 先写页面，再补 Playwright 测试
3. 把 `yarn build` 当成 RED / GREEN 证明
4. 引入 Element Plus / AG-Grid / Pinia / `frontend-v2` 约定
5. 把接口字段整体改成 camelCase 再映射回去
6. 新增页面后漏接路由、权限、菜单种子、日志文案
7. 大量硬编码中文，跳过 i18n
8. 在普通管理页绕开现有 `vxe-table + custom-pager` 模式

## 收尾检查清单

- [ ] 页面归属已确认
- [ ] 已确认本次最小可验证切片
- [ ] 已先写失败测试，再写 API / 类型 / i18n / 页面代码
- [ ] 已亲自验证 RED，且失败原因正确
- [ ] 已用最小实现让当前 RED 通过
- [ ] 已亲自验证 GREEN，而不是凭感觉判断
- [ ] 命中 UI 驱动 E2E 条件时，已将其纳入 RED / GREEN 链路
- [ ] 复用了现有页面骨架和工具组件
- [ ] 如需菜单、权限、日志，已同步检查
- [ ] 已完成最小充分验证
