# 拣货增强：AI 提交与人工实际修改对比评估

## 背景

本次评估基于：

- `ModernWMS` 中 AI 通过 `/run-plan` 完成的提交：`6b3044b` `feat: add outbound picking sheet workflow`
- `ModernWMS-picking-restore/` 中对应文件里的人工实际修改结果

本次对比的目标是：

- 判断 AI 是否做出了与人工**等效**或**更完善**的修改
- 分析 AI 是否遗漏了人工修改中隐含的考虑因素
- 评估本次改动在**代码风格、设计约定、可理解性、可维护性**方面的表现
- 总结如果本次结果不够理想，项目应补充哪些**规则 / 信息 / 反馈机制**，以提升 AI 下次表现

> 说明：本次评估允许参考 `ModernWMS-picking-restore/`，但该目录仅作为**对照实现**，不作为本次 AI 实现时的输入来源。

---

## 对比范围

### AI 提交直接修改的核心文件

- 后端
  - `backend/ModernWMS.WMS/Controllers/Dispatchlist/DispatchlistController.cs`
  - `backend/ModernWMS.WMS/IServices/Dispatchlist/IDispatchlistService.cs`
  - `backend/ModernWMS.WMS/Services/Dispatchlist/DispatchlistService.cs`
  - 新增 `DispatchlistPickingSheet*ViewModel`、`DispatchlistPickItemsOperationViewModel`
  - `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchpicklistViewModel.cs`
- 前端
  - `frontend/src/api/wms/deliveryManagement.ts`
  - `frontend/src/types/DeliveryManagement/DeliveryManagement.ts`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabGoodsToBePicked.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/picking-sheet-dialog.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/search-delivered-detail.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabPicked.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabShipment.vue`
  - `frontend/src/utils/systemLog.ts`
  - 三套 i18n
- 测试 / 文档
  - `backend/ModernWMS.Tests.Unit/Services/DispatchlistServiceTests.cs`
  - `backend/ModernWMS.Tests.ApiE2E/Features/OutboundFulfillment/dispatch-lifecycle.feature`
  - `frontend/e2e/specs/dispatch-picking-sheet.spec.ts`
  - `docs/domain-model/outbound-fulfillment/overview.md`
  - `docs/software-design/api-design.md`

### 人工实际修改中涉及、但 AI 并未完全覆盖的代表性文件

- 后端
  - `ModernWMS-picking-restore/backend/ModernWMS.WMS/Entities/Models/Dispatchlist/DispatchlistEntity.cs`
  - `ModernWMS-picking-restore/backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistViewModel.cs`
  - `ModernWMS-picking-restore/backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/PickinglistViewModel.cs`
  - `ModernWMS-picking-restore/backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/PickingItemViewModel.cs`
  - `ModernWMS-picking-restore/backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/PickingItemDispatchViewModel.cs`
- 前端
  - `ModernWMS-picking-restore/frontend/src/view/deliveryManagement/deliveryManagement/pick-order.vue`
  - `ModernWMS-picking-restore/frontend/src/view/deliveryManagement/deliveryManagement/tabPackaged.vue`
  - `ModernWMS-picking-restore/frontend/src/view/deliveryManagement/deliveryManagement/tabWeighed.vue`
  - `ModernWMS-picking-restore/frontend/src/view/deliveryManagement/deliveryManagement/tabDelivered.vue`

---

## 结论摘要

### 总体结论

AI 本次修改**没有逐文件复制人工实现**，但在**核心功能目标**上已经达到了“同类能力”甚至在部分关键点上**优于人工修改**：

- 它补出了“生成运行时拣货单 / 行级确认 / 行级撤销 / 整单复核 / 留痕 / 自动化测试 / 文档沉淀”的完整闭环；
- 在**库存语义一致性、租户/状态约束、回归测试保护、长期文档补充**方面，AI 明显比人工版本更完整；
- 但 AI 也**没有完全覆盖人工修改中的一些细节考虑**，尤其是：
  - 下游页面的复核员展示范围
  - `pick_checker_id` 的类型一致性修复
  - 打印/拣货单按仓库分组的现场可读性优化
  - 某些操作在后端缺少“重复确认/重复撤销”的状态校验

因此，更准确的判断是：

> **AI 完成了“需求导向下更系统的一版实现”，而不是“对人工补丁的一比一复刻”。**

如果评价标准是“是否理解了需求并做出可信实现”，这次 AI 表现是**较好**；
如果评价标准是“是否完全复现人工版本的所有具体取舍”，则仍有**若干遗漏与风格偏差**。

---

## 详细对比

## 1. 功能修改是否等效

### 1.1 AI 与人工等效的部分

以下能力两边都覆盖到了：

1. **待拣货入口生成拣货单 / 拣货视图**
   - 人工：`GetPickingList()` + `pick-order.vue`
   - AI：`GetPickingSheet()` + `picking-sheet-dialog.vue`

2. **拣货员留痕**
   - 两边都把 `picker` / `picker_id` 暴露到 `DispatchpicklistViewModel`
   - 都把详情弹窗中可见拣货员信息补出来

3. **复核员留痕**
   - 两边都在整单确认拣货时写入 `pick_checker` / `pick_checker_id`
   - 都在“已拣货”页面增加了复核员展示

4. **相关发货单展示**
   - 人工：`PickingItemViewModel.datalist`
   - AI：`related_dispatches`

5. **整单复核继续沿用现有入口**
   - 两边都保留了 `confirm-pick-dispatchlistno`
   - 都把它从“简单确认拣货”进一步解释成“复核 / 放行”语义

### 1.2 AI 比人工更完善的地方

#### A. AI 更准确地保持了库存与锁库语义

人工实现中，`ConfirmPickDetail()` 会：

- `picked_qty = pick_qty`
- 然后把 `pick_qty = 0`
- 并同步把 `dispatch.picked_qty += totalPicked`

这会把 `pick_qty` 从“锁定数量”改造成“剩余待拣数量”，而当前系统中很多库存/锁定相关查询仍把 `dispatchpicklist.pick_qty` 当作锁定量来源。

这意味着人工代码会引入一个隐含风险：

> **已确认的行如果把 `pick_qty` 归零，库存锁定视图可能被提前释放或被错误解释。**

AI 的实现没有这样做：

- `pick_qty` 保持不变
- 行级确认只写 `picked_qty`
- `Dispatchlist.picked_qty` 仍在整单复核时推进

这更符合当前项目既有语义，也更符合本次需求里的关键边界：

> 锁库不等于扣库；拣货执行事实与业务状态推进要分层处理。

这是本次 AI 最重要的优势之一。

#### B. AI 在查询层补了租户与状态边界

人工 `GetPickingList(List<int> dispatch_ids)`：

- 没有显式限制 `tenant_id`
- 没有限制 `dispatch_status == 2`

AI `GetPickingSheet(DispatchlistPickingSheetQueryViewModel, CurrentUser)`：

- 显式校验 `dl.tenant_id == currentUser.tenant_id`
- 显式限制 `dl.dispatch_status == 2`

这比人工实现更符合项目的后端约定，也减少了“跨租户 / 非待拣货状态被拿来生成拣货单”的风险。

#### C. AI 的聚合键更接近库存层真实身份

人工版本聚合维度主要是：

- `sku_id`
- `goods_owner_id`
- `goods_location_id`
- `warehouse_id`
- `series_number`

AI 版本聚合维度包含：

- `sku_id`
- `goods_owner_id`
- `goods_location_id`
- `series_number`
- `expiry_date`
- `price`
- `putaway_date`

这更接近项目里已有的库存层身份维度，也更贴合需求文档中“不能把不同库存层错误合并”的要求。

#### D. AI 把测试和长期文档也补上了

人工对照实现几乎只体现在生产代码与页面行为中；AI 则额外补了：

- 后端单元测试
- API E2E
- 前端 Playwright smoke
- 领域文档与 API 文档

这使得 AI 版本在**可验证性与知识沉淀**上明显强于人工版本。

### 1.3 AI 未覆盖或弱于人工的部分

#### A. 人工把复核员展示延伸到了更多下游页面，AI 没有完全覆盖

人工版本除了 `tabPicked.vue`，还在这些页面显示了 `pick_checker`：

- `tabPackaged.vue`
- `tabWeighed.vue`
- `tabDelivered.vue`

AI 只在：

- `tabPicked.vue`
- 新增 `picking-sheet-dialog.vue` 内的复核区域

展示了复核员。

这意味着人工版本在“**后续链路持续可见复核责任人**”这一点上考虑得更完整；AI 虽然满足了核心流程，但在“留痕要在更多合适位置可见”上仍偏保守。

#### B. 人工修了 `pick_checker_id` 类型一致性，AI 没有跟进

人工版本中：

- `DispatchlistEntity.pick_checker_id` 为 `int`
- `DispatchlistViewModel.pick_checker_id` 为 `int`

AI 当前仍保留：

- `DispatchlistEntity.pick_checker_id` 为 `long`
- `DispatchlistViewModel.pick_checker_id` 为 `byte`

这说明人工曾经显式处理过这个历史类型不一致问题，而 AI 没有把这一步纳入修改范围。

当前测试之所以没暴露，是因为测试用户 id 很小；但它仍是一个**潜在截断风险**和**类型漂移问题**。

#### C. 人工更偏重“纸面拣货单可读性”，AI 更偏重“交互闭环”

人工 `pick-order.vue` 的一个隐含考虑是：

- 按仓库分组
- 打印时合并仓库单元格
- 更像传统的现场纸面拣货单

AI 的 `picking-sheet-dialog.vue` 更强调：

- 在线交互
- 行级确认 / 撤销
- 相关发货单弹窗
- 复核区域

从功能闭环看，AI 更强；
但从“**纸质拣货单给现场看起来是否一目了然**”这个角度，人工版本在排版取向上更贴近一线操作习惯。

#### D. AI 的运行时拣货单响应没有直接带出 picker 展示字段

人工 `PickingItemViewModel` 里已经有 `picker` 字段；
AI 的 `DispatchlistPickingSheetLineViewModel` 当前没有对应的 `picker` / `picker_display`。

这带来两个结果：

1. AI 的拣货单主表格里无法直接显示“这条当前是谁拣的”；
2. 前端为了显示复核员，又额外调用 `viewDeliveryMainDetail` 做了 N+1 次补查。

这说明 AI 虽然整体设计更完整，但在“把 UI 真正需要的字段一次性返回”这件事上还有提升空间。

---

## 2. AI 是否遗漏了人工修改时的考虑因素

### 2.1 明显遗漏的人工考虑

#### 1）下游责任展示范围
人工把 `pick_checker` 扩展到了已打包、已称重、已出库页面；AI 没有。

#### 2）类型一致性修正
人工同时修了 `pick_checker_id` 的类型一致性；AI 没有。

#### 3）纸质拣货单的仓库分组打印体验
人工版本显然考虑了打印阅读场景；AI 更多站在交互流程角度组织界面。

### 2.2 人工有“意识”，但 AI 没完全吸收的点

人工 `ConfirmPickDetail()` / `CancelConfirmPickDetail()` 虽然实现本身存在问题，但它至少说明人工**意识到**这些操作应该有自己的状态约束，不是任何时候都能重复执行。

AI 当前 `UpdatePickItems()`：

- 只校验 pick id 是否存在
- 只校验父发货单是否仍为 `dispatch_status = 2`
- **没有校验当前 pick 明细本身是否已经确认 / 是否已经撤销**

因此当前 AI 版本的后端实际上允许：

- 对已确认行再次执行确认
- 对未确认行直接执行撤销

虽然前端按钮做了禁用态，但**后端没有强约束**。

这说明 AI 在“命令接口的负向约束”上仍不够严谨。

> 结论：AI 没有遗漏主流程理解，但遗漏了部分人工在“展示面”和“状态约束”上的细节考虑。

---

## 3. AI 是否比人工考虑得更完善

### 3.1 更完善的方面

#### 1）领域边界更清晰
AI 版本明确区分：

- 运行时拣货单视图
- 行级执行事实
- 整单复核放行

而不是把所有动作都堆到原有 detail 弹窗里。

#### 2）对现有模型语义保护更好
AI 没有像人工那样把 `pick_qty` 当作“剩余待拣数量”去改写，避免破坏锁定语义。

#### 3）兼容旧流程的处理更完整
AI 在 `ConfirmPickByDispatchNo()` 中：

- 会自动补齐未确认明细的 `picked_qty`
- 如果 `picker` 为空，会补写当前操作人
- 会记录 `pick_checker`

这比人工版本更完整。

#### 4）测试与文档远强于人工版本
AI 增加了：

- 单元测试：验证聚合、不同库位拆分、行级确认/撤销、整单复核
- API E2E：验证运行时拣货单、行级操作、复核语义
- Playwright：验证页面主路径
- API / 领域文档：沉淀长期规则

这使 AI 版本在可持续维护上明显占优。

### 3.2 不能简单认为“更完善”的地方

AI 前端通过一个新的 `picking-sheet-dialog.vue` 承载了：

- 聚合列表
- 相关发货单弹窗
- 行级确认
- 行级撤销
- 复核列表
- 打印区域

它功能完整，但也把很多职责集中到了一个 400+ 行的新组件里。

所以这部分不能简单说“更完善”，更准确地说是：

> **功能更全，但前端组件复杂度也明显上升。**

---

## 4. 风格、设计约定与可维护性评估

## 4.1 是否符合项目原有后端风格

### 符合的方面

- 仍是“薄 Controller + 厚 Service”
- 没有引入新的仓储层/抽象框架
- 通过新增 ViewModel 保持了接口契约清晰
- 辅助方法如 `BuildPickingSheetLines()`、`UpdatePickItems()` 提升了局部可读性

### 偏离或不足的方面

- 修改仍堆在已很庞大的 `DispatchlistService.cs` 中，继续加重了这个大文件的职责集中问题
- 新的 item 命令接口用 `PUT`，而项目里大量命令式子路由更常见的是 `POST /resource/action`
- `pick_checker_id` 的类型漂移没有顺手消除

总体评价：**后端风格基本兼容，局部结构比人工更清晰，但仍受现有超大 service 文件拖累。**

## 4.2 是否符合项目原有前端风格

### 做得好的地方

- 仍落在现有 `deliveryManagement` 模块下
- 保留原有待拣货页作为入口，没有新建顶级菜单
- 继续使用 `vxe-table`、`hookComponent.$dialog`、`hookComponent.$message`
- 增加了 Playwright 可定位的 `data-testid`，提升了 UI 可测性

### 偏离原有习惯的地方

#### 1）选择模式偏离现有 VXETable 习惯

人工版本使用：

- `vxe-column type="checkbox"`
- `BtnGroup` 内按钮触发生成拣货单

AI 版本改成：

- 自定义选择列 + `CustomCheckbox`
- 单独放一个 `v-btn` 在 `BtnGroup` 旁边
- 自己维护 `selectedDispatchIds`

这会让该页的交互风格和项目中大量列表页不完全一致，也增加了额外状态同步逻辑。

#### 2）新组件过大、职责过多

`picking-sheet-dialog.vue` 既负责：

- 数据拉取
- 数据转换
- 复核项构造
- 相关发货单弹窗
- 行级命令
- 打印 DOM

这对当前项目来说有点“把一个子流程页面的所有事情都塞进一个组件”。

#### 3）i18n key 风格不够统一

人工版本更多使用：

- `pick_checker`
- `related_orders`
- `pickListDetail`

AI 版本新增的是：

- `pickChecker`
- `relatedDispatches`
- `generatePickingSheet`
- `reviewPickingFallback`

项目本身确实存在混合命名，但 AI 这次又引入了一组新的 camelCase 语义 key，风格上不如人工版本贴近已有字段/页面命名。

#### 4）前端出现 N+1 补查

`picking-sheet-dialog.vue` 中 `buildReviewItems()` 会对每个 `dispatch_no` 调用一次 `viewDeliveryMainDetail()` 获取 `pick_checker`。

这说明：

- 后端 contract 没一次性提供前端需要的复核信息
- 前端用额外请求拼出来了结果

从长期维护和性能看，这不如把字段直接放进主响应中更稳妥。

总体评价：

> **前端功能完整度高于人工版本，但在“是否更像当前项目原生写法”这件事上，人工版本更贴近既有风格。**

---

## 5. 对代码库整体可理解性与可维护性的影响

## 5.1 保持 / 改善的部分

### 明显改善

1. **需求语义更清楚**
   - AI 把“拣货执行”和“整单复核”拆开了
   - 这比把动作塞进原有详情弹窗更容易讲清楚

2. **测试保护大幅提升**
   - 这是对代码库可维护性最直接的正向改善

3. **长期文档有沉淀**
   - 后续维护者更容易理解本次增强的边界与契约

## 5.2 恶化或潜在恶化的部分

### 轻度恶化

1. **前端新增大组件**
   - `picking-sheet-dialog.vue` 复杂度偏高
   - 后续如果继续加功能，容易继续膨胀

2. **前端出现额外请求拼装数据**
   - 说明 contract 还不够收敛

3. **风格不完全统一**
   - 选择模式、按钮布局、i18n key 风格与原项目有一定漂移

### 潜在风险

1. **`pick_checker_id` 类型不一致仍在**
2. **重复确认 / 重复撤销后端未做硬约束**
3. **留痕展示面不如人工版本完整**

综合判断：

> **本次修改总体上提升了代码库的可验证性和需求表达清晰度，但前端局部复杂度上升，且仍留下一些风格一致性与隐性约束问题。**

---

## 评估结论

### 1. AI 是否做出了等效修改

**部分等效，但不是逐文件等效。**

AI 与人工在核心业务目标上是同方向的，并完成了更系统的一版实现；
但在具体文件划分、接口命名、展示范围与若干细节取舍上，并没有完全复刻人工补丁。

### 2. AI 是否遗漏了人工修改时的考虑因素

**有遗漏。**

主要遗漏点：

- 下游页面复核员展示范围
- `pick_checker_id` 类型一致性修复
- 纸面拣货单按仓库分组的阅读优化
- 命令接口本身的重复操作状态校验

### 3. AI 是否比人工更完善

**在以下方面更完善：**

- 锁库/拣货语义更稳
- 租户与状态边界更清晰
- 自动化测试和文档沉淀明显更强
- 旧流程兼容处理更完整

### 4. 本次修改是否改善了代码库整体可理解性与可维护性

**总体是小幅改善，但伴随局部复杂度上升。**

改善主要来自：

- 测试
- 文档
- 更清楚的流程边界

代价主要来自：

- 前端新组件过大
- 部分 UI/命名风格偏离既有惯例
- 仍有几个隐性一致性问题没有彻底收口

---

## 为提升 AI 下次表现，项目应补充哪些规则 / 信息 / 反馈机制

## A. 规则层

### 1. 明确出库拣货的核心不变量

建议把以下规则写进长期文档或变更 SOP：

- `dispatchpicklist.pick_qty` 表示锁定数量，**不得在行级拣货确认时改写为 0**
- `dispatchpicklist.picked_qty` 才表示执行进度
- `dispatchlist.picked_qty` 何时可更新，要有明确规则
- `Delivery()` 之前不得出现真实扣库存

这样 AI 下次更容易做出与项目一致的实现，而不是靠读代码推断。

### 2. 明确留痕字段的展示矩阵

建议直接列出：

| 字段 | 至少应出现在什么位置 |
| --- | --- |
| `picker` | 拣货明细详情 / 拣货执行界面 |
| `pick_checker` | 已拣货、已打包、已称重、已出库等关键后续列表 |

这样 AI 就不会只在一个页面补展示。

### 3. 明确前端列表页交互约定

例如：

- 多选优先使用 `vxe-column type="checkbox"`
- 页面顶部动作优先走 `BtnGroup`
- 非必要不要在同页再造一套选择状态管理

这能显著减少 AI 在 UI 结构上的自由发挥。

### 4. 明确 API 命令接口的校验要求

建议把“写操作不仅要校验父单状态，也要校验当前明细自身状态”写进后端 SOP。

例如：

- 已确认行不能再次确认
- 未确认行不能直接撤销
- 复核后明细不能再做行级撤销

## B. 信息层

### 1. 提供“字段语义 / 类型一致性清单”

本次 `pick_checker_id` 的遗漏说明：

- AI 只在能编译和能通过当前测试的范围内修补
- 对“历史类型不一致但暂时不爆炸”的问题，默认不会主动修

建议对关键 identity 字段维护一份清单：

- Entity 类型
- ViewModel 类型
- 前端类型
- 是否允许 nullable

### 2. 提供“隐式验收项”文档

当前需求文档主要描述了主能力，但没有明确写出：

- 打印是否要按仓库分组
- 复核员是否要在后续多个页面持续展示
- 拣货单主表是否必须显示 picker
- 是否允许前端为补字段发 N+1 请求

这些正是 AI 和人工实现发生分歧的地方。

如果项目希望 AI 更接近人工结果，就要把这些“人工默认知道”的东西显式写出来。

## C. 反馈机制层

### 1. 增加负向测试模板

本次 AI 补了很多正向测试，但没有覆盖：

- 重复确认
- 重复撤销
- 未确认即撤销
- 复核后再做行级操作

建议为命令型接口建立统一负向测试模板，迫使 AI 在实现时自然补上这些约束。

### 2. 增加 UI 约定检查项

建议在 code review / AI review checklist 中加入：

- 是否沿用现有表格多选方式
- 是否复用 `BtnGroup`
- 是否新增过大的 workflow 组件
- 是否新增了前端 N+1 请求
- i18n key 是否延续既有命名模式

### 3. 建立“实现后对照人工版本”的复盘模板

如果项目本来就有“AI 对照人工补丁”的评估需求，可以固定一个模板：

- 核心语义是否等效
- 哪些地方 AI 更强
- 哪些地方 AI 少想了一步
- 哪些地方只是风格偏移，不是功能错误
- 下次需要在 prompt / docs / checklist 里补什么

这样每次复盘都能转化为下次 AI 的先验知识，而不是停留在一次性结论。

---

## 最终评价

如果用一句话总结本次结果：

> **AI 这次已经不是“会改功能”，而是“能围绕需求给出一版更系统、带测试和文档的实现”；但它仍然会漏掉人类在长期维护中自然会补上的一些局部约定、展示细节和一致性修正。**

这意味着：

- 在**需求理解、整体方案设计、测试补强**上，AI 已经表现出较强能力；
- 在**风格收敛、隐式约束吸收、局部人情味/现场经验细节**上，项目仍需要给 AI 更明确的规则与反馈。

---

## 补充章节：权限与授权配置评估

### 1. 是否存在权限问题

**存在，而且是两类问题同时出现：一类是“该有的权限没有同步配置”，另一类是“不同操作没有按权限正确拆分”。**

#### 1.1 新入口依赖 `picked-pick`，但默认角色权限未同步

AI 新增的待拣货页入口 `frontend/src/view/deliveryManagement/deliveryManagement/tabGoodsToBePicked.vue` 明确使用了：

- `authorityList.includes('picked-pick')`

也就是说，“生成 / 打开拣货单”已经被实现为一个受 `picked-pick` 控制的新入口。

但仓库内默认 MySQL seed `scripts/seeds/database_mysql.sql` 中，`deliveryManagement` 的管理员默认 `menu_actions_authority` 并**不包含** `picked-pick`。这会导致：

- 在 fresh seed / 默认管理员环境下，AI 新增入口会直接不可用；
- 功能代码已经存在，但角色配置没有同步落地；
- 只有后续补种 SQL（如课堂练习补种脚本）才把这个权限补上。

这说明本次实现存在明显的“**功能交付完成，但权限数据未一并交付**”问题。

#### 1.2 拣货单对话框内部操作没有按 action code 正确拆分

本次设计文档已经明确约定：

- `picked-pick`：生成 / 查看拣货单、行级确认；
- `picked-revoke`：行级撤销；
- `picked-confirm`：整单复核。

但 AI 新增的 `frontend/src/view/deliveryManagement/deliveryManagement/picking-sheet-dialog.vue` 内部：

- 行级确认按钮没有显式按 `picked-pick` 做权限控制；
- 行级撤销按钮没有显式按 `picked-revoke` 做权限控制；
- 整单复核按钮没有显式按 `picked-confirm` 做权限控制。

当前这些按钮主要只按业务状态禁用，例如：

- `row.picked_qty >= row.pick_qty`
- `row.picked_qty <= 0`
- `row.pick_qty <= 0`

而不是按 `authorityList.includes(...)` 禁用。

这会带来两个风险：

1. **拿到 `picked-pick` 入口权限的用户，一旦进入 dialog，可能连撤销或复核也能操作；**
2. **只有 `picked-confirm` 的用户，虽然理论上应能做整单复核，但在新 dialog 流程下不一定能获得对应入口。**

也就是说，当前实现把“能进入拣货单界面”和“能执行界面中的所有操作”混成了一层权限判断，没有真正做到“**入口权限**”与“**命令权限**”分离。

#### 1.3 后端没有 action-level 授权作为最终兜底

本次新增接口：

- `POST /dispatchlist/picking-sheet`
- `PUT /dispatchlist/confirm-pick-items`
- `PUT /dispatchlist/revoke-pick-items`
- `PUT /dispatchlist/confirm-pick-dispatchlistno`

在服务端侧主要只受统一登录鉴权控制（`BaseController` 上的 `[Authorize]`），没有看到与 `picked-pick` / `picked-revoke` / `picked-confirm` 对应的更细粒度 action-level 授权约束。

这意味着当前系统对这类动作的控制，本质上仍主要依赖前端按钮显示 / 禁用，而不是服务端的最终权限判定。

因此这不是一个单纯的“前端漏写 disabled”问题，而是一个更一般的机制问题：

> **权限语义存在于前端与配置中，但没有在后端形成真正的强约束。**

### 2. 分析报告中是否有遗漏

**有，而且遗漏的是高优先级维度。**

原报告已经分析了：

- 功能等效性
- 锁库语义
- 展示范围
- 类型一致性
- 状态约束
- 前端风格与复杂度

但几乎没有覆盖以下内容：

- `picked-pick` / `picked-revoke` / `picked-confirm` 的权限映射是否正确；
- `rolemenu.menu_actions_authority` 是否同步更新；
- 默认 seed 是否能让新功能在真实环境中可用；
- 新增 UI 中不同按钮是否按不同 action code 做了权限拆分；
- 后端是否有与这些操作对应的最终授权兜底。

更具体地说，报告的对比范围没有把下面这些文件 / 维度纳入核心检查对象：

- `frontend/src/view/base/roleMenu/actionList.ts`
- `scripts/seeds/database_mysql.sql`
- `rolemenu` / `menu_actions_authority` 相关配置
- 角色最小权限矩阵下的新流程可达性

因此，这不是“提得少了一点”，而是：

> **原报告基本没有把“权限是否正确交付”当成一个独立评估维度。**

而这类遗漏比一般的风格偏差更严重，因为它直接影响：

- 功能是否真正可用；
- 操作是否按岗位正确隔离；
- fresh setup 后系统是否能复现设计中的主路径。

### 3. 出现这个问题的原因

这次问题不是单点疏忽，更像是多个机制缺口叠加后的结果。

#### 3.1 权限信息分散在多个位置，缺少单一事实源

同一个权限语义同时分散在：

- 设计文档；
- 前端 `authorityList.includes(...)`；
- `actionList.ts`；
- `rolemenu.menu_actions_authority`；
- seed SQL / 补种 SQL；
- 人工 code review 经验。

一旦没有统一来源，就很容易出现：

- UI 用了新 action code；
- 角色默认授权没同步；
- 某个按钮补了权限，另一个按钮漏了；
- 文档写了规则，但实现与数据没有同时跟上。

#### 3.2 “复用已有 action code”容易被误解为“权限配置不用改”

本次方案里强调的是：

- 不新建权限模型；
- 复用 `picked-pick`、`picked-revoke`、`picked-confirm`。

这本来是正确方向，但在执行时很容易被简化理解成：

- action code 已经存在；
- 那权限这件事应该天然就是通的。

实际上，“已有 code”只表示**命名资源存在**，并不代表：

- 默认角色已经授予；
- 新 UI 已按操作维度接线；
- 后端已经做了对应授权校验。

#### 3.3 新 dialog 聚合了多个命令，权限边界更容易被吞掉

`picking-sheet-dialog.vue` 同时承载了：

- 查看拣货单；
- 行级确认；
- 行级撤销；
- 整单复核。

当多个动作聚在一个 workflow 组件里时，如果没有非常明确的“每个按钮对应哪个 action code”的实现约束，最容易漏掉的就是内部按钮的细粒度授权。

也就是说：

> **组件越像一个小工作台，就越不能只在入口处做一次权限判断。**

#### 3.4 验证主要覆盖 happy path，没有覆盖 least-privilege 场景

现有测试与验证更偏向：

- 管理员账号；
- 正向流程可用；
- 接口返回成功。

但没有系统验证：

- fresh seed 后管理员是否真的拥有新入口；
- 只有 `picked-pick` 的角色是否不能撤销；
- 只有 `picked-confirm` 的角色是否能获得正确的复核入口；
- 未授权调用是否会被服务端拒绝。

因此，这类问题在“看起来流程通了”的情况下很容易长期隐藏。

#### 3.5 项目当前缺少服务端 action-level auth 的统一模式

本次问题被放大的一个更深原因，是项目整体上对“菜单 action code = 服务端写操作授权”还没有形成统一的强制实现模式。

只靠前端控制：

- UI 改版时容易漏；
- 新增复合组件时容易串权；
- 直接调用 API 时没有最终防线。

### 4. 未来如何一般化防范

如果希望未来不再反复出现类似问题，关键不是记住这一次的 `picked-pick`，而是建立一套可复用机制。

#### 4.1 建立权限单一事实源（single source of truth）

建议把“菜单 action code、对应 UI 操作、对应 API、默认角色授予关系”维护为一份机器可读清单，而不是分别散落在：

- 设计文档
- Vue 组件
- `actionList.ts`
- seed SQL
- 角色配置页面

例如可以维护一份权限矩阵配置，再由脚本生成或校验：

- 前端 action 常量；
- 默认 seed；
- 文档矩阵；
- 角色测试数据。

这样可以显著减少“改了 UI 没改 seed”的同步失败。

#### 4.2 把关键写操作的授权下沉到后端

对命令型接口，建议建立统一的服务端授权约束，例如按菜单 + action code 做显式判定，而不是只依赖 `[Authorize]`。

目标不是替代前端控制，而是形成“双层防线”：

- 前端负责可用性与交互提示；
- 后端负责真实性与最终拒绝。

这样即使前端遗漏了按钮禁用，未授权操作仍会在服务端被拒绝。

#### 4.3 前端统一使用带权限声明的操作组件

对所有会触发写操作的按钮，建议要求使用统一封装，例如：

- `AuthorizedButton`
- `AuthorizedTooltipBtn`

并强制显式声明：

- 所属菜单；
- `actionCode`；
- 未授权时的显示 / 禁用策略。

这样新增 workflow 组件时，不容易出现“按钮都写出来了，但没人接权限”的情况。

#### 4.4 把“fresh seed + 最小权限角色矩阵”纳入验证流程

建议把以下验证做成固定模板：

1. **fresh seed smoke**
   - 用仓库默认 seed 启动后，验证管理员是否能看到新入口；
   - 验证主路径是否真实可用，而不是只在补种环境可用。

2. **least-privilege role matrix**
   - 仅有 `picked-pick` 的角色；
   - 仅有 `picked-revoke` 的角色；
   - 仅有 `picked-confirm` 的角色；
   - 管理员角色。

分别验证：

- 按钮是否可见 / 可点击；
- 不该有的按钮是否不可见或禁用；
- 对应 API 未授权时是否返回拒绝。

#### 4.5 把权限交付加入 AI 评估与 code review checklist

建议以后凡是涉及新增入口、新增命令、新增 workflow 组件的任务，评审模板中固定增加一节：

- 是否新增或复用了 action code；
- UI 中每个操作是否绑定到正确权限；
- 默认角色 / seed / migration 是否同步更新；
- 是否覆盖了最小权限角色验证；
- 后端是否有最终授权兜底。

这样可以避免以后再次出现“功能做完了，但角色配置和权限拆分没人检查”的情况。

### 5. 补充结论

如果把权限维度纳入本次复盘，那么对 AI 提交的评价需要多补一句：

> **AI 这次在功能闭环、测试补强、文档沉淀上表现较强，但在“权限是否随功能一起完整交付、以及不同操作是否按岗位正确拆分”这一维上存在明显缺口；原分析报告也遗漏了这一高优先级问题。**

这类问题的性质，不只是“风格不够贴近人工实现”，而是更接近：

- **交付完整性不足**；
- **授权边界没有随新工作流一起被严格实现**；
- **项目缺少把权限规则从文档落实到实现与验证的统一机制。**
