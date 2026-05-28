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

## 本 SOP 对齐的开发基线

本 SOP 的开发阶段**严格对齐** `superpowers:test-driven-development`：

```text
理解变更
→ 影响分析
→ RED（先写失败测试）
→ Verify RED（确认因旧 UI / 旧契约行为仍存在而失败）
→ GREEN（最小改动实现）
→ Verify GREEN（目标测试通过）
→ Final Verification（按影响范围做最小充分验证）
→ 文档同步
```

## 核心原则

1. **以后端真实契约和现有页面模式为准**
2. **先分析影响文件，再动代码**
3. **先改测试，再改实现**
4. **最小变更，不借机重写整页**
5. **用户可见变化必须经过真实验证，而不是只看构建成功**

## TDD 强制门禁

### 1. RED 门禁

以下内容都算生产代码，必须在 RED 之后再改：
- `src/api/**`
- `src/types/**`
- `src/view/**`
- `src/components/**`
- `src/languages/**`
- 路由、权限、日志、菜单配套

### 2. Verify RED 门禁

必须确认：
- 目标测试失败，而不是直接通过
- 失败原因与旧 UI 语义 / 旧前后端契约仍在一致
- 不是环境错误、选择器错误、测试数据准备错误

### 3. GREEN 门禁

实现阶段只允许做让当前 RED 通过所需的最小改动，不允许借机重写整页。

### 4. Verify GREEN 门禁

必须确认：
1. 当前 RED 测试通过
2. 受影响的相邻 UI 测试 / 冒烟测试通过
3. 构建通过

## UI 驱动 E2E 何时必须进入验证链路

当满足以下任一条件时，**UI 驱动 E2E 必须进入本次变更的 RED / GREEN 或 Final Verification 链路**：

- 菜单、路由、页面可达性发生变化
- 按钮权限、visible / disabled 语义发生变化
- 前端依赖后端字段做状态展示、可见性判断、前后端一致性逻辑
- 需要确认真实用户链路在 **UI + API + DB** 上一起工作

## 流程总览

```text
1. 理解变更需求
2. 分析受影响文件
3. 编写失败测试（RED）
4. 验证红灯（Verify RED）
5. 最小改动实现（GREEN）
6. 验证绿灯（Verify GREEN）
7. 最小充分验证（Final Verification）
8. 补回归检查或文档同步（如需要）
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

### 本步骤必须额外判断

- 本次变更是否命中 UI 驱动 E2E 强制条件
- 更适合迭代哪个现有 Playwright spec，还是需要新增一个最小目标 spec

🛑 **强制停止点**：影响文件范围确认后，再继续修改。

---

## 步骤 3：编写失败测试（RED）

### 优先级

1. **先迭代已有 UI 驱动 E2E / 冒烟 spec**
2. 只有当行为真正独立时才新增目标 spec
3. 先让测试表达新预期，再改 API / 类型 / 组件 / 文案

### RED 适用方式

### 命中 UI 驱动 E2E 条件时

优先写 / 改目标 Playwright spec，例如验证：
- 菜单入口出现 / 消失
- 按钮 enabled / disabled / hidden 语义
- 某个状态标签、表格列、详情展示跟随真实后端返回变化
- 某个真实用户动作能正确走通 UI + API + DB 链路

### 未命中 UI 驱动 E2E 条件时

如果确属纯类型、纯文案、纯样式、纯构建层改动，可不新增 Playwright spec；但要注意：
- `yarn build` 只能算补充验证
- 它**不能**充当 RED / GREEN 的行为证明
- 如果你改的是用户可见行为，就不能把它伪装成“纯静态改动”

---

## 步骤 4：验证红灯（Verify RED）

### 常用命令

**目标 UI 驱动 E2E：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

### Verify RED 必须确认

- 目标测试确实失败
- 失败原因与旧 UI 行为仍存在 / 新契约尚未适配一致
- 不是环境错误、登录失败、选择器错、测试数据问题

### 遇到以下情况必须停止

- **测试直接通过**：说明 RED 无效，先修测试
- **测试因环境错误失败**：先修环境 / 测试准备
- **要写很多实现后才会失败**：说明 RED 切片太大，先缩小

---

## 步骤 5：最小改动实现（GREEN）

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
- 只改让当前 RED 通过所需的最小代码，不借机重写整页

### 常见变更类型与同步点

| 变更类型 | 必查项 |
| --- | --- |
| 新增字段 | API 类型、表格列、表单项、详情展示、i18n |
| 删除字段 | API 类型、表格列、模板引用、导出逻辑 |
| 字段重命名 | API 类型、页面引用、搜索表单、导出字段 |
| 状态值变化 | 标签显示、按钮禁用态、排序 / 筛选逻辑 |
| 路由 / 菜单变化 | 路由映射、权限 action code、后端菜单数据 |

---

## 步骤 6：验证绿灯（Verify GREEN）

### 推荐顺序

1. 当前 RED 测试通过
2. 受影响的相邻 UI 测试 / 冒烟通过
3. 构建通过
4. 若命中 UI 驱动 E2E 条件，确认真实 UI 链路已变绿

### 常用命令

**目标 UI 驱动 E2E：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

**需要全量 UI 驱动回归时：**

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
- 没有破坏相邻页面行为
- 构建通过
- 没有用“看起来像是好了”代替真实命令输出

---

## 步骤 7：最小充分验证（Final Verification）

> Final Verification **不是** Verify GREEN 的替代品，而是面向收口 / 提交 / 交接的最小充分验收。

### 推荐组合

### 命中 UI 驱动 E2E 条件（本次必须补跑）

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
- `status` 只能说明环境是否可访问，**不能替代行为验证**
- 长运行命令优先复用 `./scripts/macos-dev.sh`，或放在 `tmux` 中运行

---

## 步骤 8：补回归检查或文档同步（如需要）

以下情况应补同步动作：
- 变更形成长期交互规则：更新 `docs/software-design/ui-ux-style-guide.md`
- 变更形成长期接口协作规则：更新 `docs/software-design/api-design.md`
- 变更影响通用前端开发方式：更新 `docs/development-standards/frontend-conventions.md`

## 常见禁止项

1. 因一次字段改动重做整页结构
2. 先改页面，再补 Playwright 测试
3. 把 `yarn build` 当成 RED / GREEN 的证明
4. 引入与仓库不一致的新 UI 框架或组件体系
5. 跳过 i18n 直接硬编码
6. 忘记同步日志文案、权限或动态菜单
7. 没有跑真实验证就宣称前端改完

## 收尾检查清单

- [ ] 变更来源与范围已确认
- [ ] 已完成影响分析，并判断是否命中 UI 驱动 E2E 条件
- [ ] 已先写失败测试，再写实现
- [ ] 已亲自验证 RED，且失败原因正确
- [ ] 已按最小范围修改实现
- [ ] 已亲自验证 GREEN，而不是凭感觉判断
- [ ] 命中 UI 驱动 E2E 条件时，已将其纳入 RED / GREEN 或 Final Verification
- [ ] 已执行 `yarn build` 或更高等级验证
- [ ] 如有用户可见规则沉淀，已同步长期文档
