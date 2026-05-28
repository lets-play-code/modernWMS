# ModernWMS AI 协同代码重构作业指导书

## 适用场景

适用于：
- 功能实现后做最小整理
- 功能变更后做局部重构
- 独立的代码质量提升任务
- **测试已覆盖、希望在绿灯下改善结构** 的场景

## 必读文档

- `docs/development-standards/backend-conventions.md`
- `docs/development-standards/frontend-conventions.md`
- `docs/development-standards/testing-conventions.md`

## 与 TDD 的关系

重构不是跳过 TDD，而是严格对应 `superpowers:test-driven-development` 中的 **REFACTOR** 阶段：

```text
先确认已有验证链路是 GREEN
→ 只做一个局部结构整理
→ 立即重新验证回到 GREEN
→ 再做下一个整理
```

如果当前任务会**改变行为**，那就不再是纯重构，必须切换到对应的实现 / 变更 SOP，重新从 **RED** 开始。

## 核心原则

1. **测试绿灯优先于重构速度**
2. **没有绿灯基线，不准开始重构**
3. **一次只处理一个问题**
4. **局部重构，不借机改写整层架构**
5. **重构后必须重新验证，而不是凭感觉说更好了**

## TDD 强制门禁

### 1. 绿灯基线门禁

开始重构前，必须先有可重复运行的绿灯验证链路。至少要明确：
- 当前用什么测试证明行为不变
- 哪个命令是本次重构的最小回归基线

如果没有这个基线：
- 停止重构
- 先转到对应的实现 / 变更 SOP 补测试

### 2. 单问题门禁

一次只处理一个问题，例如：
- 一个重复逻辑
- 一个命名问题
- 一个方法拆分
- 一个局部性能点

不允许把多个不同性质的问题混在同一轮重构里。

### 3. 行为变化门禁

如果重构中发现：
- 需要改行为才能继续
- 现有绿灯无法证明行为不变
- 必须新增测试来保护行为

则立即停止当前重构，切换到对应 SOP：
- 后端行为变化 → `backend-implementation-sop.md` 或 `backend-change-sop.md`
- 前端行为变化 → `frontend-implementation-sop.md` 或 `frontend-change-sop.md`

## UI 驱动 E2E 何时必须进入重构回归链路

当满足以下任一条件时，**UI 驱动 E2E 必须进入本次重构的回归链路**：

- 菜单、路由、页面可达性可能受影响
- 按钮权限、visible / disabled 语义可能受影响
- 前端依赖后端字段做状态展示、可见性判断、前后端一致性逻辑
- 需要确认真实用户链路在 **UI + API + DB** 上仍然闭环工作

## 流程总览

```text
1. 建立绿灯基线
2. 生成单问题重构清单
3. 做一个最小重构
4. 立即验证回到绿灯
5. 重复直到清单完成
6. 做最小充分验证与文档沉淀
```

---

## 步骤 1：建立绿灯基线

### 需要先回答的问题

- 本次重构要保护的行为是什么？
- 哪个测试命令能证明这些行为当前是绿的？
- 是否命中 UI 驱动 E2E 条件？

### 常见绿灯基线来源

**后端 service / core：**

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"
```

**后端真实 HTTP 契约：**

```bash
cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"
```

**UI 驱动 E2E：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

🛑 **强制停止点**：如果没有已知绿灯基线，不准开始重构。

---

## 步骤 2：生成单问题重构清单

### 后端常见检查项

| 问题类型 | 检查重点 |
| --- | --- |
| Controller 过胖 | 是否把业务规则、复杂查询、状态流转写进 Controller |
| Service 过长 | 是否超过当前任务可理解范围、职责过多 |
| 查询重复 | 是否存在重复 LINQ、重复过滤、重复 tenant 条件 |
| 返回不统一 | 是否绕开 `ResultModel<T>` / `PageData<T>` |
| 租户遗漏 | 是否缺失 `tenant_id` 过滤或写入 |
| 本地化遗漏 | 是否硬编码错误消息 |
| 性能问题 | 是否缺 `AsNoTracking()`、是否有明显 N+1 / 重复查询 |

### 前端常见检查项

| 问题类型 | 检查重点 |
| --- | --- |
| 页面直写请求 | 是否绕过 `src/api/**` 和统一请求封装 |
| 状态组织混乱 | 是否同一页面混入多套状态模型 |
| 重复列表骨架 | 是否可以复用现有按钮区、分页、表格模式 |
| 硬编码文案 | 是否跳过 i18n |
| 权限遗漏 | 是否漏接 action code 或禁用态 |
| 日志遗漏 | 写操作是否漏补 `systemLog.ts` |
| 过度抽象 | 是否为了单页需求新增没有复用价值的组件 / composable |

### 清单要求

- 一项问题，一次处理
- 每项都能明确对应回归命令
- 先做风险最低、收益最高的问题

---

## 步骤 3：做一个最小重构

### 原则

- 每次只解决一个问题
- 问题间不要交叉改动
- 如果发现必须改行为，立即停止并切换到实现 / 变更 SOP
- 如果只是纯结构整理，也要在改后立刻验证

### 常见重构动作

| 问题 | 常见重构方式 |
| --- | --- |
| Controller 拼接复杂查询 | 下沉到 Service |
| Service 重复 tenant 过滤 | 提取局部辅助方法 |
| 页面内直写 axios | 抽回 `src/api/**` |
| 列表页重复分页逻辑 | 复用 `custom-pager` 和既有分页状态 |
| 写操作缺日志文案 | 补 `systemLog.ts` |
| 文案硬编码 | 补 i18n key |

---

## 步骤 4：立即验证回到绿灯

每做完一个最小重构，必须立刻运行**同一条绿灯基线**，证明行为未变。

### 后端

**局部单元测试（service / core 分支、边界条件）：**

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"
```

**目标 API E2E（真实 HTTP 契约与多层联动）：**

```bash
cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"
```

### 前端 / UI 驱动 E2E

**目标 UI 驱动 E2E（验证 UI + API + DB 一起工作）：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

**构建验证（静态结构、类型、样式的补充验证）：**

```bash
cd frontend && yarn build
```

### 必须确认

- 当前回归链路重新变绿
- 没有因为结构整理引入行为差异
- 若命中 UI 驱动 E2E 条件，真实 UI 链路仍然为绿

---

## 步骤 5：重复直到清单完成

每轮都遵守：

```text
选一个问题
→ 做一个最小重构
→ 回到同一条绿灯基线
→ 再选下一个问题
```

如果某一轮失败：
- 先恢复绿灯
- 再分析是否需要缩小重构切片
- 不要在红灯上继续叠加重构

---

## 步骤 6：最小充分验证与文档沉淀

### 推荐组合

**后端范围较大：**

```bash
./scripts/test-all.sh --skip-ui
```

**前端范围较大或命中 UI 驱动 E2E 条件：**

```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e)
./scripts/macos-dev.sh stop
cd frontend && yarn build
```

**联调类改动：**

```bash
./scripts/macos-dev.sh status
```

说明：
- `status` 只能证明环境状态，**不能替代行为验证**
- 长运行命令优先复用仓库脚本或 `tmux`

### 必要时更新长期规范文档

如果本次重构形成了稳定规则，应同步更新：
- 后端规则：`docs/development-standards/backend-conventions.md`
- 前端规则：`docs/development-standards/frontend-conventions.md`
- 测试规则：`docs/development-standards/testing-conventions.md`
- API / UI 长期规则：`docs/software-design/...`

如果只是本次局部整理，不要强行写进长期文档制造噪音。

## 何时不适合继续重构

以下情况应停止并先汇报：
- 重构开始触及未批准的模块
- 为了“更优雅”需要大规模改架构
- 当前没有绿灯基线，无法安全确认行为不变
- 需要同时动前后端多个边界且目标不清晰
- 实际上已经变成行为修改任务

## 收尾检查清单

- [ ] 开始前已有明确绿灯基线
- [ ] 已判断是否命中 UI 驱动 E2E 条件
- [ ] 已生成明确的单问题重构清单
- [ ] 每次只处理了一个问题
- [ ] 每次处理后都重新跑回同一条绿灯基线
- [ ] 没有把行为修改伪装成重构
- [ ] 已完成最小充分验证
- [ ] 如有稳定新规则，已更新长期规范文档
