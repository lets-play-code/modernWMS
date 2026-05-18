# ModernWMS 测试保护设计

> 状态：已与用户确认总体测试架构、覆盖边界与 BDD DSL 标准。
>
> 本文是实施前的设计规格。长期测试 DSL 约定已同步沉淀到 `docs/development-standards/testing-conventions.md`。

## 1. 目标

为 ModernWMS 增添可持续的测试保护，优先覆盖 API 中暴露的领域模型，其次覆盖后端核心模块的单元/组件测试，并辅以少量 UI 端到端测试。

完成后应满足：

- 关键领域对象 API 和关键用户旅程有自动化测试覆盖；
- API 与 UI 测试都是真端到端测试，必须集成真实系统服务和真实数据库；
- 集成类测试优先采用 BDD 风格；
- 后端整体覆盖率目标高于 80%；
- 测试 DSL 遵循少量标准 step + 领域数据规格 + 结构化断言，避免场景专用 step 膨胀。

## 2. 技术选型

采用 .NET 原生测试体系，不引入 legacy 项目的外挂 Java/Test-charm 运行架构。

| 测试类型 | 技术方案 |
| --- | --- |
| API E2E / BDD | Reqnroll/SpecFlow 风格 `.feature` + xUnit |
| 数据库 | Testcontainers MySQL，使用真实 schema 与测试数据 |
| 后端服务 | 真实 ASP.NET Core Host/Kestrel，测试配置连接 MySQL Testcontainer |
| 后端覆盖率 | coverlet.collector / cobertura |
| 后端单元/组件测试 | xUnit + FluentAssertions，可使用真实 EF Core 测试数据库或轻量测试上下文 |
| UI E2E | Playwright，启动真实后端、真实数据库和真实前端 |

## 3. 测试分层

```text
后端核心单元/组件测试
        ↑ 补齐复杂分支、边界和覆盖率
API E2E / BDD 测试
        ↑ 主要保护领域模型和业务流程
UI Playwright E2E
        ↑ 少量验证关键用户旅程可从页面走通
```

### 3.1 API E2E / BDD

API E2E 是本次测试保护的主体。

运行链路：

```text
Reqnroll Feature
      ↓
Step Definitions
      ↓
HTTP Client
      ↓
真实 ASP.NET Core Host / Kestrel
      ↓
真实 EF Core + MySQL Testcontainer
      ↓
API 响应断言 + 数据库/查询视图断言
```

每个 API 场景必须：

- 通过真实 HTTP 调用系统；
- 使用真实 MySQL 数据库；
- 使用业务 DSL 创建前置数据；
- 同时验证 API 响应和关键领域事实；
- 能重复运行，不依赖人工清理。

### 3.2 后端单元/组件测试

后端单元/组件测试不重复完整 API 流程，重点补强：

- 库存可用量公式；
- ASN 状态流转和上架库存层合并；
- 出库锁库、拣货、扣库、签收；
- 移库、冻结、加工、盘点、调整确认；
- 租户过滤、动态搜索、分页、Token/响应包装等 Core 行为。

### 3.3 UI E2E

UI 测试保持少量，目标是验证关键旅程可从浏览器走通，而不是覆盖所有按钮组合。

首批 UI 旅程：

1. 登录页可打开，`admin/1` 登录成功，进入 home；
2. 登录后动态菜单加载；
3. 库存页面可达并能加载列表；
4. ASN 页面可达并能加载关键列表/状态 tab；
5. 出库管理页面可达并能加载发货单状态列表。

## 4. 建议测试项目结构

```text
backend/
├── ModernWMS.sln
├── ModernWMS.Tests.Unit/
│   ├── Services/
│   ├── DomainRules/
│   └── TestDoubles/
├── ModernWMS.Tests.ApiE2E/
│   ├── Features/
│   │   ├── Authentication/
│   │   ├── MasterData/
│   │   ├── InboundExecution/
│   │   ├── InventoryVisibility/
│   │   ├── InternalOperations/
│   │   └── OutboundFulfillment/
│   ├── Steps/
│   ├── Support/
│   │   ├── ModernWmsApiHost.cs
│   │   ├── ModernWmsDatabase.cs
│   │   ├── ApiClient.cs
│   │   ├── ScenarioDataContext.cs
│   │   ├── DomainSpecRegistry.cs
│   │   ├── DomainRepositoryRegistry.cs
│   │   ├── TestDataFactory.cs
│   │   └── ObjectPatternAssertions.cs
│   └── Seeds/
└── coverlet.runsettings

frontend/
└── e2e/
    ├── specs/
    ├── support/
    └── playwright.config.ts
```

## 5. API E2E 覆盖矩阵

| 领域上下文 | Feature 文件 | 核心场景 |
| --- | --- | --- |
| 系统管理 | `Authentication/login-and-authority.feature` | 登录成功返回 token；登录后可加载菜单权限；未登录访问业务 API 被拒绝 |
| 基础主数据 | `MasterData/warehouse-and-sku.feature` | 建立仓库/库区/库位；建立货主/供应商/客户；建立分类/SPU/SKU；主数据可被下游流程引用 |
| 入库执行 | `InboundExecution/asn-lifecycle.feature` | 创建 ASN；确认到货；卸货；分拣；上架形成库存；非法状态动作被拒绝 |
| 库存可视化 | `InventoryVisibility/stock-availability.feature` | 库存总量、冻结量、出库锁定量、加工锁定量、移库锁定量共同影响可用量 |
| 库内作业 | `InternalOperations/internal-stock-operations.feature` | 移库确认影响源/目标库位；冻结影响可用量；盘点差异生成调整；加工确认影响库存结构 |
| 出库履约 | `OutboundFulfillment/dispatch-lifecycle.feature` | 创建发货单；确认订单锁库；拣货；打包；称重；出库扣减库存；签收完成；库存不足时不可确认 |

## 6. 后端测试覆盖矩阵

| 模块 | 测试文件 | 重点补强 |
| --- | --- | --- |
| `StockService` | `Services/StockServiceTests.cs` | 可用量公式、残次区库存不进入正常可用量、跨流程锁定聚合 |
| `AsnService` | `Services/AsnServiceTests.cs` | 上架数量不能超过分拣数量、库存层合并维度、状态逆向取消 |
| `DispatchlistService` | `Services/DispatchlistServiceTests.cs` | 锁库不扣库、Delivery 才扣库、签收破损数量影响签收数 |
| `StockmoveService` | `Services/StockmoveServiceTests.cs` | 移库任务确认后源库位减少、目标库位增加、重复确认保护 |
| `StockfreezeService` | `Services/StockfreezeServiceTests.cs` | 冻结/解冻状态、冻结量影响可用量 |
| `StockprocessService` | `Services/StockprocessServiceTests.cs` | 加工源库存锁定、确认后更新库存 |
| `StocktakingService` | `Services/StocktakingServiceTests.cs` | 盘点差异确认、调整入账 |
| `Core` | `Core/*Tests.cs` | Token、动态搜索、分页、响应模型、租户隔离辅助逻辑 |

## 7. BDD DSL 设计

BDD DSL 必须遵循 `docs/development-standards/testing-conventions.md`。

核心原则：

- 一组标准数据准备和断言 step，不随数据类型和关注点变化而临时增加数量；
- 数据准备和断言直接体现领域模型；
- 不用大量“存在 x 个某某数据”这类相似 step；
- 不用“其中 8 件应被锁定”这类隐藏数据细节的定性 step；
- 不把测试写成低层数据库脚本；
- 当前测试关注的关键字段必须出现在 feature 正文中；
- 必要但与测试目的无关的关联数据由规格默认值补齐。

标准 step 类型：

| 类型 | 形式 |
| --- | --- |
| 数据准备 | `假如存在"<规格名>":` |
| API 调用 | `当GET/POST/PUT/DELETE "<path>":` |
| 响应断言 | `那么response should be:` |
| 模型断言 | `那么所有"<模型名>"应为:` |
| 组合断言 | `并且数据应为:` |

示例：

```gherkin
场景: 确认发货单只锁定库存，不直接扣减库存
  假如存在"可用库存":
    | sku.code       | location.code | goods_owner.name | qty | is_freeze |
    | SKU-E2E-DP-001 | STOCK-A-01    | 练习货主         | 12  | false     |
  并且存在"新发货单":
    | dispatch_no | sku.code       | customer.name | qty |
    | DP-E2E-001  | SKU-E2E-DP-001 | 练习客户      | 8   |
  当POST "/dispatchlist/confirm-order":
    """
    { "dispatch_no": "DP-E2E-001" }
    """
  那么所有"发货单"应为:
    """
    = [{
      dispatch_no: 'DP-E2E-001'
      sku_code: 'SKU-E2E-DP-001'
      qty: 8
      dispatch_status: 2
      lock_qty: 8
    }]
    """
  并且所有"库存视图"应为:
    """
    = [{
      sku_code: 'SKU-E2E-DP-001'
      qty: 12
      qty_locked: 8
      qty_available: 4
    }]
    """
```

## 8. 测试数据策略

```text
基础 schema seed
  来自 scripts/seeds/database_mysql.sql
        ↓
测试场景基础数据
  由 DomainSpec/TestDataFactory 创建
        ↓
Given 步骤中的业务前置条件
  只展示当前场景关键字段
        ↓
When 步骤调用真实 API
        ↓
Then 步骤验证 API + 领域模型事实
```

数据隔离策略：

- 每个场景使用唯一前缀或 scenario id；
- 规格创建的数据默认被 `ScenarioDataContext` 追踪；
- 模型断言默认只查询当前场景数据；
- 场景结束后清理当前场景创建的数据；
- 不修改生产 seed；测试 seed/helper 放在测试项目内。

前置数据创建方式：

| 方式 | 使用场景 | 约束 |
| --- | --- | --- |
| 直接数据库写入 | 构造前置状态、异常状态、脏数据、跨租户数据 | 必须通过领域规格，不在 feature 中写 SQL |
| 调用真实 API | 当前测试要覆盖上游行为，或必须通过业务流程形成状态 | 不能为了隐藏复杂度把被测行为放进 Given |

## 9. 覆盖率与执行命令

推荐后端命令：

```bash
cd backend
dotnet test ModernWMS.sln \
  --collect:"XPlat Code Coverage" \
  --settings coverlet.runsettings
```

API E2E：

```bash
cd backend
dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj
```

UI E2E：

```bash
cd frontend
yarn e2e
```

全量测试建议后续新增：

```bash
./scripts/test-all.sh
```

## 10. 验收标准

| 类型 | 完成标准 |
| --- | --- |
| API E2E | 6 个领域上下文均有至少 1 个业务关键 Feature；入库/库存/出库/库内作业有状态或库存事实断言 |
| DSL | 标准 step 数量稳定；新增领域模型主要新增规格/仓储，不新增场景专用 step |
| 后端测试 | 核心服务和 Core 工具有单元/组件测试；后端整体覆盖率 >80% |
| UI E2E | 登录、菜单加载、库存/ASN/出库页面可达 |
| 稳定性 | 测试可重复运行，数据库隔离，无需手工清理 |
| 文档 | 测试运行方式和测试数据约定写入长期开发规范 |

## 11. 风险与缓解

| 风险 | 缓解 |
| --- | --- |
| Reqnroll/SpecFlow 与 .NET 7 项目集成存在包版本摩擦 | 先做最小 API E2E spike，验证 feature 编译、host 启动、MySQL Testcontainer 和覆盖率采集 |
| Object Pattern 断言一次性做得过大 | 先支持对象/数组/字段路径/通配符/基础比较，再按真实场景扩展 |
| API E2E 运行时间过长 | 测试容器按 collection 复用，场景通过数据作用域隔离 |
| 80% 覆盖率难以仅靠 API E2E 达成 | 用服务组件测试补齐复杂分支和 Core 工具类 |
| UI E2E 不稳定 | UI 测试只做少量冒烟，主要断言页面可达、请求成功、关键元素可见 |
