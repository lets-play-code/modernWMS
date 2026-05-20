# ModernWMS AI 协同代码重构作业指导书

## 适用场景

适用于：

- 功能实现后做最小整理
- 功能变更后做局部重构
- 独立的代码质量提升任务
- 测试已覆盖、希望在绿灯下改善结构的场景

## 必读文档

- `docs/development-standards/backend-conventions.md`
- `docs/development-standards/frontend-conventions.md`
- `docs/development-standards/testing-conventions.md`

## 核心原则

1. **测试绿灯优先于重构速度**
2. **一次只处理一个问题**
3. **局部重构，不借机改写整层架构**
4. **优先改善重复、命名、边界、可读性和明显性能问题**
5. **重构后必须重新验证，而不是凭感觉说更好了**

## 流程总览

```text
1. 生成重构清单
2. 逐项重构
3. 每项后跑最小充分验证
4. 必要时更新长期规范文档
```

---

## 步骤 1：生成重构清单

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

### 通用检查项

- 重复代码
- 命名不清晰
- 方法 / 函数过长
- 条件分支难读
- 未使用代码
- 魔法数字 / 魔法字符串
- 与项目现有风格冲突的新写法

---

## 步骤 2：逐项重构

### 原则

- 每次只解决一个问题
- 问题间不要交叉改动
- 如果重构会改变行为，先补测试再改代码
- 如果只是纯结构整理，也要在改后立刻验证

### 建议顺序

1. 重复代码
2. 命名与可读性
3. 方法拆分
4. 边界收敛（例如 Controller -> Service）
5. 性能问题
6. 小范围规范沉淀

### 重构动作示例

| 问题 | 常见重构方式 |
| --- | --- |
| Controller 拼接复杂查询 | 下沉到 Service |
| Service 重复 tenant 过滤 | 提取局部辅助方法 |
| 页面内直写 axios | 抽回 `src/api/**` |
| 列表页重复分页逻辑 | 复用 `custom-pager` 和既有分页状态 |
| 写操作缺日志文案 | 补 `systemLog.ts` |
| 文案硬编码 | 补 i18n key |

---

## 步骤 3：每项后跑最小充分验证

### 后端

**局部单元测试：**

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~StockServiceTests"
```

**后端构建：**

```bash
cd backend && dotnet build ModernWMS.sln
```

**完整后端验证：**

```bash
./scripts/test-all.sh --skip-ui
```

### 前端

**构建验证：**

```bash
cd frontend && yarn build
```

**必要时 UI E2E：**

```bash
./scripts/macos-dev.sh start
cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e
./scripts/macos-dev.sh stop
```

### 联调类改动

```bash
./scripts/macos-dev.sh status
```

---

## 步骤 4：必要时更新长期规范文档

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
- 测试覆盖不足，无法安全确认行为不变
- 需要同时动前后端多个边界且目标不清晰

## 收尾检查清单

- [ ] 已生成明确的重构问题清单
- [ ] 每次只处理了一个问题
- [ ] 每次处理后都做了验证
- [ ] 没有借重构扩张需求范围
- [ ] 如有稳定新规则，已更新长期规范文档
