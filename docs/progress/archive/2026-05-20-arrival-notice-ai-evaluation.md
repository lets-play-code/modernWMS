# 到货通知检索修复：AI 与人工修改对比评估

## 背景

本次评估基于 `ModernWMS` 当前工作区未提交变更，与 `ModernWMS-picking-restore/` 中对应的人工实际修复代码进行对比。

评估目标：
- 判断 AI 是否做出了与人工等效的修改
- 分析 AI 是否遗漏了人工修复时隐含考虑的因素，或是否做了额外完善
- 评估本次修改在代码风格、设计约定、可理解性与可维护性方面的表现
- 总结如果本次结果不够理想，项目应补充哪些规则、信息与反馈机制，以提升 AI 下次表现

## 对比范围

### 当前工作区未提交变更
- `backend/ModernWMS.WMS/Services/Asn/AsnService.cs`
- `backend/ModernWMS.Tests.Unit/Services/AsnServiceTests.cs`

### 人工实际修复对照
- `ModernWMS-picking-restore/backend/ModernWMS.WMS/Services/Asn/AsnService.cs`

### 相关上下文
- `frontend/src/view/wms/stockAsn/tabNotice.vue`
- `backend/ModernWMS.Core/DynamicSearch/QueryCollection.cs`
- `backend/ModernWMS.Tests.Unit/Core/DynamicSearchTests.cs`

## 问题根因

到货通知页面调用 `/asn/asnmaster/list` 时，会把 `supplier_name` 和 `sku_name` 作为搜索字段提交。

但 `PageAsnmasterAsync()` 原本把所有 `searchObjects` 都直接交给：

```csharp
queries.AsExpression<AsnmasterBothViewModel>()
```

而 `AsnmasterBothViewModel` 顶层并没有 `supplier_name`、`sku_name` 这两个属性。它们实际位于 `detailList` 明细中。

因此当动态搜索表达式尝试解析这些字段时，会出现“没有可用谓词”的情况；原实现继续执行 `.Where(null)`，最终在检索时抛出异常。

## 结论摘要

### 总体结论

AI 本次修改在**核心业务修复逻辑上与人工修复基本等效**，并且在**自动化回归测试补充**方面比人工修复更完整。

但 AI 额外加入的 `expression != null` 防御逻辑，也带来了一个与项目原有语义不完全一致的变化：
- 原项目很多 service 的写法更接近“非法查询条件尽早暴露问题”
- AI 当前写法更偏向“忽略无法生成表达式的条件，继续执行”

这属于**局部防御性增强**，但不完全等同于**全局一致性更优**。

## 详细对比

### 1. 功能修复是否等效

#### 人工修复做了什么
人工修复在 `PageAsnmasterAsync()` 中：
- 把 `supplier_name` / `sku_name` 从通用 `QueryCollection` 中拆出来
- 不再把这两个字段交给 `AsExpression<AsnmasterBothViewModel>()`
- 改为用 `detailList.Any(...)` 在明细层进行过滤
- 其余能映射到顶层字段的筛选条件仍然保留原有通用搜索逻辑

#### AI 修改做了什么
AI 当前代码同样：
- 将 `supplier_name` / `sku_name` 从 `searchObjects` 中单独抽取
- 仅把其他字段加入 `QueryCollection`
- 通过 `detailList.Any(detail => ...)` 处理供应商名与规格名筛选
- 保留原有顶层通用查询行为

#### 判断
在业务修复路径上，AI 与人工修复**等效**。

### 2. AI 是否遗漏了人工更改时的考虑因素

#### 没有遗漏的关键考虑
AI 正确理解了人工修复最关键的隐含前提：
- 页面检索字段并不总是对应列表 ViewModel 顶层属性
- `supplier_name` / `sku_name` 是到货通知明细层字段
- 该问题不能仅靠前端修补，需要在 service 查询逻辑中处理嵌套明细字段搜索

这说明 AI 不是只在表层“防异常”，而是抓住了数据结构与查询模型不匹配这个根因。

#### 仍未上升为更通用设计的地方
AI 与人工都停留在“局部特判”层面，没有把问题进一步抽象为统一规则，例如：
- 为列表接口建立“搜索字段 -> 顶层字段 / 明细字段”的声明式映射
- 给动态搜索系统提供嵌套字段过滤扩展点
- 统一定义 invalid search field 的处理策略

因此，AI 这次虽然没有遗漏人工关键考虑，但也没有超越人工，去消化掉更底层的设计债务。

### 3. AI 是否比人工更完善

#### AI 更完善的点：补了回归测试
AI 新增了：
- `backend/ModernWMS.Tests.Unit/Services/AsnServiceTests.cs`
- `PageAsnmasterAsyncFiltersByDetailFields`

覆盖场景：
- 按 `supplier_name` 检索
- 按 `sku_name` 检索

这比人工修复更完整。人工对照代码只修 service，没有配套测试保护。

从长期维护角度看，这一点很重要：
- 它把“修复了 bug”变成了“留下了可验证的行为契约”
- 后续重构时更容易发现回归问题

#### AI 更完善但存在取舍的点：防御性空判断
AI 新增：

```csharp
var expression = queries.AsExpression<AsnmasterBothViewModel>();
if (expression != null)
{
    query = query.Where(expression);
}
```

优点：
- 避免出现 `.Where(null)` 导致的运行时异常

代价：
- 对于以后误传的未知字段，本方法可能更倾向于“静默忽略该条件”
- 而项目中原有很多 service 写法没有这样处理，更接近“异常暴露查询契约问题”的风格

因此，这不是简单的“更好”，而是“更防御，但语义与全局未必一致”。

## 风格与项目约定评估

## 1. 是否符合项目原有代码风格

### 基本符合的方面
- 修复落点仍在后端 service 层，符合当前项目分层结构
- 没有大范围重构，只做局部最小修补，符合项目“Minimal changes”要求
- 查询逻辑仍沿用现有 LINQ 组织方式，没有引入明显异风格结构
- 新增测试也采用了项目现有 `AsnServiceTests` 的测试设施与 Testcontainers 方式

### 轻微不一致的方面
- AI 使用了 `string.Empty`、更显式的大括号与中间变量 `expression`
- 这些写法本身没有问题，但与人工对照代码相比更显式、更防御性
- `expression != null` 的处理方式与项目里其他大量 `query.Where(queries.AsExpression<T>())` 的用法不完全一致

总体评价：**风格基本兼容，但并非完全延续局部既有写法。**

## 2. 是否符合项目原有设计约定

### 符合之处
- 仍把动态搜索作为默认路径
- 仅对不适合动态搜索的字段做特判
- 没有引入新的通用抽象或基础设施，避免扩大改动面

### 不完全符合之处
- 当前项目隐含约定并没有明确规定“无效搜索表达式”该被忽略还是报错
- AI 在本处做了“忽略 null expression”的选择，实际上为这个方法单独引入了一种更宽松的语义

因此这次修改**功能上合理，但在系统级约定上没有完全统一**。

## 对代码库可理解性与可维护性的影响

## 1. 可理解性

### 改善
- `supplier_name` / `sku_name` 被明确拆出处理，阅读者更容易理解 bug 原因
- 回归测试直接说明了该方法需要支持“明细字段检索”，降低后续理解成本

### 仍然不足
- `PageAsnmasterAsync()` 本身仍是一个较长、较复杂的方法
- 搜索字段映射规则仍然写死在方法内部，不是声明式约定

结论：**可理解性有小幅改善，主要来自测试补充；方法结构本身没有获得明显简化。**

## 2. 可维护性

### 改善
- 通过新增测试提升了后续修改的安全性
- 改动局部且边界明确，降低了回归风险

### 保留的设计债务
- 嵌套字段搜索仍靠 service 层手工特判
- 如果以后又新增更多 `detailList` 层字段搜索，很可能继续复制这种模式
- `expression != null` 的局部处理可能导致不同 service 对“非法查询条件”的行为不一致

结论：**可维护性总体略有提升，但底层搜索契约问题仍未解决。**

## 评估结论

### 1. AI 是否做出了等效修改
是。AI 在核心业务逻辑上完成了与人工修复**等效**的修改。

### 2. AI 是否遗漏了人工修复的考虑因素
没有遗漏人工修复最关键的考虑因素：它识别出了页面搜索字段与 ViewModel 顶层字段不匹配的问题，并在明细层补上了正确过滤。

### 3. AI 是否比人工更完善
在“**补充自动化回归测试**”这一点上，AI 比人工更完善。

### 4. AI 是否存在不够理想之处
有。AI 加入的 `expression != null` 判空虽然提升了防御性，但改变了当前方法面对非法搜索条件时的行为倾向，未必完全符合项目整体隐含约定。

## 为提升 AI 下次表现，项目可补充的规则 / 信息 / 反馈机制

## A. 规则层

### 1. 明确列表接口搜索字段映射规则
建议为关键列表接口建立文档或配置，明确：
- 前端提交字段名
- 后端对应字段
- 是顶层字段还是嵌套明细字段
- 是否需要自定义过滤逻辑

这样 AI 就不用靠局部推断去识别哪些字段不能直接走动态搜索。

### 2. 明确 `AsExpression()` 返回 null 时的统一策略
项目应明确：
- 这是错误，应 fail-fast
- 还是允许忽略，并记录日志
- 或者应该返回可理解的业务错误

如果没有统一规则，AI 很容易在单点修复时作出与其他模块不一致的选择。

### 3. 规定 bugfix 至少补一层测试
建议明确：
- service 层 bugfix：至少补 unit test
- API 契约问题：至少补 API E2E
- 页面可见缺陷：最好补 API 或 UI 一层回归用例

这能让 AI 默认产出更完整，而不是只修代码不补保护。

## B. 信息层

### 1. 提供“页面搜索字段 -> 接口字段 -> 后端模型”链路文档
例如为到货通知页面补充：
- 页面文件路径
- 请求接口
- 搜索字段列表
- 每个字段对应的后端落点

这类信息对 AI 定位检索问题非常高效。

### 2. 在 bug 模板中固定记录请求 payload 与报错堆栈
建议 bug 模板至少包含：
- 页面路径
- 操作步骤
- 实际请求体
- 返回错误或异常堆栈
- 相关测试数据

这样 AI 能更快完成根因定位，而不是依赖项目内检索推断。

## C. 反馈机制层

### 1. 增加搜索字段合法性校验或测试
例如：
- 前端页面允许发出的搜索字段必须出现在接口允许列表中
- 或必须存在于顶层 ViewModel / 自定义搜索映射配置中

这能把类似问题提前暴露在开发和测试阶段，而不是等到页面检索时报异常。

### 2. 给这类场景建立固定回归用例
建议至少覆盖：
- `/asn/asnmaster/list` 按 `supplier_name` 检索
- `/asn/asnmaster/list` 按 `sku_name` 检索
- 混合条件检索
- 未知字段输入时的预期行为

### 3. 如果目的是做 AI 能力评估，应尽量隔离答案线索
本次项目中存在一些能帮助 AI 还原答案的线索，例如：
- git 历史里保留了对应修复提交
- 练习 SQL 中直接提到 ASN 查询 bug 与供应商 / SKU 搜索场景

如果要做更严格的 benchmark，建议：
- 使用不含未来修复历史的评测快照
- 或限制 AI 读取真实修复提交
- 或把明显指向答案的训练性文案移出工作区

否则测到的不只是“理解与改代码能力”，还会混入“检索历史答案能力”。

## 本次评估最终结论

可以把本次结果概括为：

> AI 基本完成了与人工修复等效的业务修改，并且在回归测试补充上优于人工；
> 但 AI 额外引入的防御性判空处理改变了该方法面对非法搜索条件时的行为倾向，体现出它在局部稳健性上更积极、在全局一致性上仍需要项目规则进一步约束。

## 验证记录

本次代码修改已通过如下验证命令：

```bash
cd backend
dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~AsnServiceTests"
```

结果：
- 通过：5
- 失败：0
- 说明：到货通知检索修复相关测试以及 `AsnServiceTests` 现有测试均通过
