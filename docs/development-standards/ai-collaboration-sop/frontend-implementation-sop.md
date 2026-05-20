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
| E2E | Playwright |
| 构建验证 | `cd frontend && yarn build` |

## 核心原则

1. **以后端 API 和既有页面骨架为准**
2. **优先复用现有组件与交互模式**
3. **类型、API、i18n 先行，再写页面**
4. **保留现有 `snake_case` 业务字段命名**
5. **新增页面不仅能显示，还要接入菜单、权限、日志、路由**

## 流程总览

```text
F0. 菜单归属与页面位置判断
F1. 分析当前 API 与数据契约
F2. 补 API / 类型 / i18n
F3. 实现页面或弹窗
F4. 接路由 / 权限 / 日志
F5. 验证构建与必要联调
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

## 步骤 F1：分析当前 API 与数据契约

### AI 行动

1. 只分析当前需要支持的后端 API
2. 确认请求参数、响应结构、分页结构
3. 明确页面是列表、详情、流程页还是表单页
4. 如果后端尚未稳定，先停止，不要猜测字段

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

## 步骤 F2：补 API / 类型 / i18n

### 文件位置

- API：`frontend/src/api/...`
- 类型：`frontend/src/types/...`（如已有更合适位置则复用）
- 文案：`frontend/src/languages/...`

### 规则

1. 页面里不要直接写 axios
2. 请求统一复用 `frontend/src/utils/http/request.ts`
3. 保持现有读取方式：`const { data: res } = await api()`
4. 类型命名延续现有 `*VO`、`DataProps`、`TablePage` 等风格
5. 业务字段保留 `snake_case`，不要额外做 camelCase 映射层
6. 有写操作时同步检查 `frontend/src/utils/systemLog.ts`

### 常见 API 目录

- `frontend/src/api/base/...`
- `frontend/src/api/sys/...`
- `frontend/src/api/wms/...`

---

## 步骤 F3：实现页面或弹窗

### 优先复用的页面模式

- `script setup lang="ts"`
- `reactive({ ...data })` + `reactive({ ...method })`
- `vxe-table`
- `custom-pager`
- `tooltip-btn`
- `BtnGroup`
- `SearchGroup`
- `hookComponent.$message()` / `hookComponent.$dialog()`

### 普通列表页最小清单

- [ ] 查询表单或搜索区
- [ ] 按钮区
- [ ] `vxe-table`
- [ ] `custom-pager`
- [ ] 新增 / 编辑对话框（如有）
- [ ] i18n 文案
- [ ] 导出逻辑（如页面有导出）

### 流程页最小清单

- [ ] `v-tabs` / `v-window`
- [ ] 子页面负责本 tab 数据加载
- [ ] 切换时由父组件在 `nextTick()` 中触发子组件刷新

### 高度与布局

优先复用：

- `computedCardHeight()`
- `computedTableHeight()`
- `SYSTEM_HEIGHT`

不要在单页再造一套固定高度常量。

---

## 步骤 F4：接路由 / 权限 / 日志

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

### 如果页面要接动态菜单

记住：本项目不是“静态路由写完就上线”的模式，仍需后端菜单权限数据配套。

---

## 步骤 F5：验证构建与必要联调

### 最小验证命令

**仅前端改动：**

```bash
cd frontend && yarn build
```

**需要完整联调时：**

```bash
./scripts/macos-dev.sh start
./scripts/macos-dev.sh status
```

**需要 UI E2E 时：**

```bash
./scripts/macos-dev.sh start
cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e
./scripts/macos-dev.sh stop
```

> 长运行命令优先复用 `./scripts/macos-dev.sh`，或放入 `tmux`，不要直接在当前终端裸跑长期服务。

🛑 **强制停止点**：构建或联调结果出来后，和用户确认交互是否正确。

---

## 常见禁止项

1. 在页面里直接写 axios
2. 引入 Element Plus / AG-Grid / Pinia / `frontend-v2` 约定
3. 把接口字段整体改成 camelCase 再映射回去
4. 新增页面后漏接路由、权限、菜单种子、日志文案
5. 大量硬编码中文，跳过 i18n
6. 在普通管理页绕开现有 `vxe-table + custom-pager` 模式

## 收尾检查清单

- [ ] 页面归属已确认
- [ ] API / 类型 / i18n 已补齐
- [ ] 复用了现有页面骨架和工具组件
- [ ] 如需菜单、权限、日志，已同步检查
- [ ] 已执行 `yarn build` 或更高等级验证
- [ ] 如有联调，已通过仓库脚本或 `tmux` 管理长运行进程
