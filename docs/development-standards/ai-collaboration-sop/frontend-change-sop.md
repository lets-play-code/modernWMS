# ModernWMS AI 协同前端功能变更作业指导书

## 适用场景

适用于 **已有前端能力的调整**，包括但不限于：

- 后端 API 字段 / 结构变更后的适配
- 页面布局调整
- 列表列项与搜索项调整
- 按钮权限、日志文案、菜单位置调整
- 交互细节或展示方式修正

## 必读文档

- `docs/development-standards/frontend-conventions.md`
- `docs/development-standards/testing-conventions.md`
- `docs/software-design/api-design.md`
- `docs/software-design/ui-ux-style-guide.md`
- 对应需求 / 变更分析文档

## 核心原则

1. **以后端真实契约和现有页面模式为准**
2. **先分析影响文件，再动代码**
3. **最小变更，不借机重写整页**
4. **保持现有 Vuetify + VXETable + Vuex 体系一致性**
5. **用户可见变化必须经过构建或联调验证**

## 流程总览

```text
1. 理解变更需求
2. 分析受影响文件
3. 修改 API / 类型 / 组件 / 文案
4. 验证构建与必要联调
5. 如有需要，补 UI 驱动 E2E 或回归检查
```

---

## 步骤 1：理解变更需求

### AI 行动

1. 明确变更来自后端契约变化还是纯前端交互调整
2. 列出前后差异
3. 判断是否影响菜单、权限、日志、i18n、导出
4. 标出会影响哪些页面

### 输出模板

```markdown
## 一、前端变更理解

### 1. 变更来源
- [ ] 后端 API 变更
- [ ] UI 调整
- [ ] 业务逻辑变更
- [ ] Bug 修复

### 2. 前后差异
| 项目 | 变更前 | 变更后 |
| --- | --- | --- |
| ... | ... | ... |

### 3. 影响页面
- ...
```

🛑 **强制停止点**：输出理解结果后，等待用户确认。

---

## 步骤 2：分析受影响文件

### 常见受影响位置

- API：`frontend/src/api/...`
- 类型：`frontend/src/types/...`
- 页面：`frontend/src/view/...`
- 公共组件：`frontend/src/components/...`
- 路由：`frontend/src/utils/router/index.ts`
- 按钮权限：`frontend/src/view/base/roleMenu/actionList.ts`
- 日志文案：`frontend/src/utils/systemLog.ts`
- i18n：`frontend/src/languages/...`

### 输出模板

```markdown
## 二、影响分析

| 文件 | 变更内容 |
| --- | --- |
| frontend/src/api/... | ... |
| frontend/src/view/... | ... |
| frontend/src/utils/systemLog.ts | ... |
```

🛑 **强制停止点**：影响文件范围确认后，再继续修改。

---

## 步骤 3：修改 API / 类型 / 组件 / 文案

### 建议顺序

1. API 与类型
2. 页面脚本逻辑
3. 模板展示
4. i18n / 日志 / 权限 / 路由

### 修改要求

- 页面不要直接改成新的请求封装风格
- 保持 `snake_case` 字段命名
- 继续复用 `vxe-table`、`custom-pager`、`tooltip-btn`、`BtnGroup`、`SearchGroup`
- 继续使用 `hookComponent.$message()` / `$dialog()`
- 如果新增写操作或改写动作含义，同步维护 `systemLog.ts`

### 常见变更类型与同步点

| 变更类型 | 必查项 |
| --- | --- |
| 新增字段 | API 类型、表格列、表单项、详情展示、i18n |
| 删除字段 | API 类型、表格列、模板引用、导出逻辑 |
| 字段重命名 | API 类型、页面引用、搜索表单、导出字段 |
| 状态值变化 | 标签显示、按钮禁用态、排序 / 筛选逻辑 |
| 路由 / 菜单变化 | 路由映射、权限 action code、后端菜单数据 |

---

## 步骤 4：验证构建、联调与必要的 UI 驱动 E2E

### 最小验证

**仅前端静态改动，且验证点不依赖真实后端：**

```bash
cd frontend && yarn build
```

### 如果需要联调

```bash
./scripts/macos-dev.sh start
./scripts/macos-dev.sh status
```

### 如果需要目标 UI 驱动 E2E

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

### 如果需要全量 UI 驱动回归

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e)
./scripts/macos-dev.sh stop
```

### UI 驱动 E2E 适用场景

UI 驱动 E2E **不是只测前端**，而是在真实前端、后端 API 和数据库之上验证整条用户链路。

适用于：
- 菜单、按钮、路由、页面可达、列表 / 表单展示等验证点落在 UI
- 需要确认真实 UI 操作与后端 API 返回一起工作正常
- 需要保护前端显示与后端字段、状态、权限语义的一致性逻辑
- API E2E 已覆盖后端主流程，但仍缺少 UI / API 一致性保护

🛑 **强制停止点**：验证结果出来后，等待用户确认 UI / 交互是否符合预期。

---

## 步骤 5：补回归检查或文档同步（如需要）

以下情况应补同步动作：

- 变更形成长期交互规则：更新 `docs/software-design/ui-ux-style-guide.md`
- 变更形成长期接口协作规则：更新 `docs/software-design/api-design.md`
- 变更影响通用前端开发方式：更新 `docs/development-standards/frontend-conventions.md`

## 常见禁止项

1. 因一次字段改动重做整页结构
2. 引入与仓库不一致的新 UI 框架或组件体系
3. 跳过 i18n 直接硬编码
4. 忘记同步日志文案、权限或动态菜单
5. 没有跑构建就宣称前端改完

## 收尾检查清单

- [ ] 变更来源与范围已确认
- [ ] 受影响文件已分析
- [ ] API / 类型 / 模板 / 文案已同步
- [ ] 已执行 `yarn build` 或更高等级验证
- [ ] 如有用户可见规则沉淀，已同步长期文档
