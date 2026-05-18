# ModernWMS 测试设计规范

> 本文记录 ModernWMS 长期适用的测试设计约定，重点约束 API E2E / BDD 测试 DSL、测试数据准备、断言表达和覆盖率目标。
>
> 参考对象：`~/code/course-practice/legacy-code-csharp/e2e-tests/` 中 Test-charm/JFactory/DAL 风格的测试表达。ModernWMS 不直接采用该 Java 运行架构，但应吸收其“少量通用 step + 数据规格 + 结构化断言”的 DSL 思路。

相关文档：
- 后端规范：`./backend-conventions.md`
- 前端规范：`./frontend-conventions.md`
- API 设计：`../software-design/api-design.md`
- 领域模型入口：`../domain-model/README.md`

---

## 1. 测试分层原则

ModernWMS 的测试保护按以下顺序建设：

1. **API E2E / BDD 测试优先**
   - 覆盖 API 中暴露的关键领域模型和关键业务流程。
   - 必须集成真实后端服务和真实数据库。
2. **后端核心模块单元/组件测试补强**
   - 覆盖服务层复杂分支、边界条件、状态流转和库存计算。
   - 用于补齐 API E2E 难以稳定覆盖的分支和覆盖率。
3. **少量 UI E2E 测试冒烟**
   - 覆盖登录、菜单加载、库存/ASN/出库关键页面可达。
   - UI 测试不替代 API E2E 和后端测试。

后端整体覆盖率目标：`ModernWMS.Core + ModernWMS.WMS` 总体覆盖率应高于 80%。

---

## 2. BDD DSL 总体目标

BDD DSL 的目标不是把自然语言写得更像人工描述，而是让测试正文同时满足：

- **可读**：业务人员和开发者能看出场景意图。
- **可查**：前置数据、动作、结果之间的关键字段关系直接出现在测试正文中。
- **可复用**：新增领域模型和场景时，不因为措辞变化不断增加 step。
- **可造脏数据**：异常状态、边界值、坏数据能通过同一套数据规格表达。
- **不过度细节化**：与当前验证点无关的支持数据由规格默认值补齐，不污染场景。

### 2.1 禁止的 DSL 形态

禁止按场景临时堆叠大量相似 step，例如：

```gherkin
假如存在 12 件可用库存 "SKU-001"
假如存在 8 件冻结库存 "SKU-001"
假如存在一个已分拣的 ASN
假如存在一个待拣货的发货单
```

这类写法的问题是：

- step 数量随场景增长，不可发现、不可维护；
- 文案稍有差异就需要新增 step；
- 数据细节被藏在 step 实现里，测试正文无法审查字段关系；
- 类似机制的异常数据无法复用，只能继续新增专用 step。

也禁止只用定性断言隐藏模型细节，例如：

```gherkin
那么其中 8 件应被出库锁定
```

应改为对领域模型或查询视图做结构化断言，显式展示参与规则的字段。

---

## 3. 标准 step 机制

API E2E / BDD 测试应优先收敛到少量标准 step。step 数量应主要随“操作类型”变化，而不是随“领域模型”或“场景关注点”变化。

### 3.1 数据准备 step

统一使用数据规格名作为参数：

```gherkin
假如存在"<规格名>":
  """
  <对象或对象列表>
  """
```

或表格形式：

```gherkin
假如存在"<规格名>":
  | fieldA | fieldB | relation.fieldC |
  | value  | value  | value           |
```

规则：

- `<规格名>` 由测试数据规格注册表解析，例如 `可用库存`、`已分拣的 到货通知`、`发货单`。
- 规格负责提供默认值、关联数据创建、字段转换和持久化方式。
- 场景正文只覆盖当前测试关心的字段。
- 新增领域实体时，优先新增规格和仓储映射，不新增 step。

### 3.2 API 调用 step

统一使用 HTTP 动作 step：

```gherkin
当POST "/dispatchlist/confirm-order":
  """
  {
    "dispatch_no": "DP-E2E-001"
  }
  """
```

同类 step 包括：

- `当GET "<path>"`
- `当POST "<path>":`
- `当PUT "<path>":`
- `当DELETE "<path>"`

API step 只负责发起请求和记录响应，不承担业务断言。

### 3.3 响应断言 step

统一使用结构化响应断言：

```gherkin
那么response should be:
  """
  : {
    code= 200
    body.json= {
      isSuccess: true
      data: {
        dispatch_status: 2
      }
    }
  }
  """
```

断言表达应支持：

- 对象字段匹配；
- 数组匹配；
- 通配符 `*`；
- 正则；
- 字段路径；
- 数组投影；
- `size` 等集合断言；
- JSON 字符串解析后的断言。

### 3.4 数据断言 step

统一使用模型查询断言：

```gherkin
那么所有"<模型名>"应为:
  """
  = [{
    fieldA: value
    fieldB: value
  }]
  """
```

规则：

- `<模型名>` 可以是数据库实体，也可以是领域查询视图，例如 `库存层`、`库存视图`、`拣货明细`。
- 查询范围默认限定在当前场景创建或跟踪的数据内，避免把基础 seed 噪音带入断言。
- 每个模型仓储必须定义默认排序，保证断言稳定。
- 断言应展示能证明业务规则的关键字段，而不是一句自然语言结论。

### 3.5 组合数据断言 step

当需要跨多个模型统一断言时，可以使用一个组合数据断言：

```gherkin
并且数据应为:
  """
  : {
    库存层: [{ sku_code: 'SKU-001' qty: 12 }]
    拣货明细: [{ sku_code: 'SKU-001' pick_qty: 8 }]
  }
  """
```

该 step 仍然基于模型仓储注册表，不允许在 step 中手写特定场景逻辑。

---

## 4. 数据规格机制

### 4.1 规格不是 step

可以为领域模型定义多个规格，但规格扩展不等于 step 扩展。

示例：

```text
规格名：库存层
规格名：可用库存
规格名：冻结库存
规格名：已分拣的 到货通知
规格名：待拣货 发货单
```

这些规格都通过同一个 `假如存在"<规格名>"` step 使用。

### 4.2 规格职责

每个规格负责：

- 建立默认字段；
- 创建必要但与测试意图无关的关联数据；
- 把业务别名转换为实体字段；
- 注册当前场景创建的数据身份，供后续 `所有"<模型>"应为` 查询；
- 必要时选择通过 API 或直接数据库写入完成前置数据。

### 4.3 字段覆盖规则

场景中写出的字段应满足以下规则：

| 字段类型 | 是否应出现在测试正文 | 说明 |
| --- | --- | --- |
| 参与本场景行为判断的字段 | 必须出现 | 例如 `qty`、`lock_qty`、`dispatch_status` |
| 用于连接前置、动作、结果的身份字段 | 必须出现 | 例如 `sku_code`、`dispatch_no`、`asn_no` |
| 只是为了满足外键/必填约束的支持字段 | 不应默认出现 | 由规格默认值补齐 |
| 异常值/脏数据字段 | 必须出现 | 例如非法状态、负数数量、跨租户 id |

### 4.4 关联表达

关联数据优先使用点路径表达，避免新增专用 step：

```gherkin
假如存在"发货单":
  | dispatch_no | sku.code       | customer.name | qty | dispatch_status |
  | DP-E2E-001  | SKU-E2E-DP-001 | 练习客户      | 8   | 1               |
```

如果关联结构较复杂，可以使用文档字符串：

```gherkin
假如存在"已分拣的 到货通知":
  """
  asn_no: ASN-E2E-001
  sku:
    code: SKU-E2E-ASN-001
  goods_owner:
    name: 练习货主
  sorts:
    | location.code | sorted_qty | price |
    | PUT-A-01      | 8          | 12.50 |
  """
```

---

## 5. 好的 DSL 示例

### 5.1 出库锁库场景

```gherkin
# language: zh-CN
功能: 出库履约锁库

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
    那么response should be:
      """
      body.json.isSuccess= true
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

这个场景没有写“其中 8 件应被出库锁定”，而是把 `qty`、`lock_qty`、`qty_locked`、`qty_available` 的关系直接展示出来。

### 5.2 异常状态数据场景

```gherkin
场景: 已上架 ASN 不能再次确认到货
  假如存在"到货通知":
    | asn_no      | sku.code        | asn_qty | asn_status |
    | ASN-E2E-001 | SKU-E2E-ASN-001 | 8       | 4          |
  当PUT "/asn/confirm":
    """
    { "id": "${到货通知:ASN-E2E-001.id}" }
    """
  那么response should be:
    """
    body.json.isSuccess= false
    body.json.errorMessage= *
    """
  那么所有"到货通知"应为:
    """
    = [{
      asn_no: 'ASN-E2E-001'
      asn_status: 4
      actual_qty: 0
    }]
    """
```

异常状态通过同一个 `假如存在"到货通知"` step 设置字段，不新增“存在一个已上架 ASN”专用 step。

---

## 6. DSL 实现约束

### 6.1 建议组件

BDD 测试项目应包含类似以下组件：

```text
Support/
├── ScenarioDataContext.cs        # 当前场景创建数据、别名、变量、响应
├── DomainSpecRegistry.cs         # 规格名 -> 规格类型
├── DomainRepositoryRegistry.cs   # 模型名 -> 查询/写入仓储
├── ObjectPatternParser.cs        # 结构化断言表达解析
├── ObjectPatternAssertions.cs    # 通配符、路径、数组、正则等断言
├── TestDataFactory.cs            # 根据规格创建实体/关联
└── ApiClient.cs                  # HTTP 调用与响应记录
```

### 6.2 规格与仓储

每个领域模型最多应新增：

- 一个默认规格；
- 少量有稳定业务含义的派生规格；
- 一个模型仓储；
- 必要的字段别名映射。

不要为每个业务场景新增独立 step。

### 6.3 场景作用域

每个场景必须有独立的数据作用域：

- 自动生成唯一前缀或场景 id；
- 规格创建的数据默认带此前缀或被 `ScenarioDataContext` 追踪；
- 查询断言默认只返回当前场景数据；
- 场景结束后清理当前场景创建的数据。

### 6.4 何时允许新增 step

只有出现新的“操作类型”时才允许新增 step，例如：

- 调用 HTTP；
- 准备数据；
- 断言响应；
- 断言模型数据；
- 切换登录身份；
- 控制时间；
- 控制外部依赖。

不允许因为以下原因新增 step：

- 换了一个领域实体；
- 换了一个状态值；
- 换了一个数量字段；
- 某个字段需要异常值；
- 文案想更贴近自然语言。

---

## 7. API E2E 数据准备方式

前置数据可以通过两种方式创建：

| 方式 | 使用场景 | 约束 |
| --- | --- | --- |
| 直接数据库写入 | 构造前置状态、异常状态、脏数据、跨租户数据 | 必须通过领域规格，不在 feature 中写 SQL |
| 调用真实 API | 当前测试要覆盖上游行为，或必须通过业务流程形成状态 | 不能为了隐藏复杂度把被测行为放进 Given |

原则：

- 如果场景验证的是“出库确认锁库”，则库存前置可以直接用 `可用库存` 规格创建。
- 如果场景验证的是“ASN 上架形成库存”，则库存结果不能在 Given 中直接创建，必须通过 API 动作形成。

---

## 8. DSL 评审清单

新增或修改 BDD 场景时，必须检查：

- [ ] 是否复用了标准数据准备 / API 调用 / 响应断言 / 数据断言 step？
- [ ] 是否没有因为实体、状态、数量变化新增专用 step？
- [ ] Given 中是否展示了影响行为判断的关键字段？
- [ ] Then 中是否展示了证明结果的实体字段或查询视图字段？
- [ ] 支持性外键和默认字段是否由规格隐藏，而不是污染场景？
- [ ] 异常值是否能通过同一规格字段覆盖表达？
- [ ] 查询断言是否限定在当前场景数据范围内？
- [ ] 场景是否没有把被测行为偷偷放进 Given？

---

## 9. 与 legacy Test-charm 示例的对应关系

| legacy Test-charm 思路 | ModernWMS 落地方式 |
| --- | --- |
| `假如存在"规格名"` | Reqnroll 通用数据准备 step + `DomainSpecRegistry` |
| JFactory Spec 默认值 | C# `DomainSpec` / `TestDataFactory` 默认值 |
| `CompositeDataRepository` | `DomainRepositoryRegistry` 按模型分派 DB/API/查询视图仓储 |
| `那么所有"模型"应为` | 模型查询 + Object Pattern 结构化断言 |
| DAL 表达式 | ModernWMS 自研轻量 Object Pattern 断言，支持字段路径、通配符、数组和正则 |
| Feature 中只覆盖关键字段 | 规格默认值补齐支持数据，测试正文保留关键字段 |

---

## 10. 测试运行命令

### 10.1 后端构建

```bash
cd backend
dotnet build ModernWMS.sln
```

### 10.2 后端测试与覆盖率

```bash
cd backend
dotnet test ModernWMS.sln --collect:"XPlat Code Coverage" --settings coverlet.runsettings
```

覆盖率检查：

```bash
python3 ../scripts/check-dotnet-coverage.py \
  $(find . -path '*/TestResults/*/coverage.cobertura.xml' -type f -print | sort) \
  --threshold 0.80
```

说明：

- 长期目标仍为 `ModernWMS.Core + ModernWMS.WMS` 后端覆盖率高于 80%。
- 当前第一批测试保护已经建立 API E2E、后端测试、UI E2E 和覆盖率统计链路，但覆盖率尚未达到 80%。
- 在覆盖率补充任务完成前，允许通过环境变量临时降低本地全量脚本门槛，例如：

```bash
MODERNWMS_COVERAGE_THRESHOLD=0.30 ./scripts/test-all.sh
```

该临时门槛只用于阶段性验证测试基础设施可运行，不能替代长期 80% 覆盖率验收。

### 10.3 UI E2E

UI E2E 需要真实前端、后端和数据库。优先通过仓库脚本启动完整系统：

```bash
./scripts/macos-dev.sh start
cd frontend
COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e
cd ..
./scripts/macos-dev.sh stop
```

### 10.4 全量脚本

```bash
./scripts/test-all.sh
```

常用环境变量：

- `MODERNWMS_COVERAGE_THRESHOLD`：覆盖率阈值，默认 `0.80`。
- `DOTNET_ROLL_FORWARD`：默认由脚本设为 `Major`，用于本机只有 .NET 8 runtime 时运行 `net7.0` 测试项目。

