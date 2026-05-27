# ModernWMS 前端权限 UI 测试设计

> 状态：已与用户确认设计方向。
>
> 已确认约束：
> - 权限验收语义采用**当前实现**：
>   - 无菜单权限时，相关页面**入口不可见**；
>   - 有菜单权限但无 action 权限时，相关按钮/控件**可见但 disabled**；
> - 角色、菜单和按钮权限通过**API / 测试夹具预置**，不通过 UI 手工配置；
> - **孤儿 code 不纳入覆盖**；
> - 覆盖边界以**当前前端可达页面中真实生效的权限判断代码**为准，而不是仅以 `actionList.ts` 目录声明为准。

## 1. 目标

为 ModernWMS 补充一组可持续维护的 Playwright UI 权限测试，重点保护以下行为：

1. 当用户**具有某菜单权限**时，能在侧边栏看到对应页面入口；
2. 当用户**不具有某菜单权限**时，看不到该入口；
3. 当用户**具有某页面 action 权限**时，页面中的相关按钮/控件处于可操作状态；
4. 当用户**没有该 action 权限**时，页面中的相关按钮/控件仍可见，但必须是 disabled；
5. 用例组织方式必须体现**业务角色、用户旅程和领域上下文**，而不是机械地一条 code 对应一条用例。

## 2. 现状与设计边界

### 2.1 当前前端权限现实

ModernWMS 当前前端权限主要分两层：

1. **菜单入口权限**
   - 登录后通过 `/rolemenu/authority` 获取 `menulist`；
   - 前端将 `menulist` 转成动态路由和侧边栏；
   - 没有菜单权限时，入口不会出现在侧边栏。

2. **页面内 action 权限**
   - 页面通过 `getMenuAuthorityList()` 获取当前路由对应的 `authorityList`；
   - 顶部按钮主要由 `BtnGroup` 驱动；
   - 行内按钮主要由 `tooltip-btn` 配合 `:disabled="!authorityList.includes(code)"` 驱动；
   - 当前前端主流语义是：**没有 action 权限时按钮 disabled，而不是隐藏**。

### 2.2 当前后端权限现实

当前代码库中，后端并未为大多数 action code 提供统一的细粒度授权拦截。现有模型更接近：

- 菜单与按钮的**前端可见性 / 可操作性控制**；
- 后端负责登录身份和租户隔离；
- 因此本次 UI 权限测试主要保护的是**前端权限表达是否符合预期**。

### 2.3 本次覆盖边界

本次测试只覆盖：

- 当前主流程中**用户实际可达的菜单入口**；
- 当前可达页面中**真实参与权限判断**的 action code；
- 不覆盖：
  - 孤儿 code；
  - 已注释的按钮权限位点；
  - 当前主页面未挂入的历史 / 备用 tab；
  - 目录中声明但当前 UI 没有真正接入权限判断的 action。

## 3. 覆盖统计口径

### 3.1 覆盖单位

本次覆盖不只按 unique code 统计，而按两层单位统计：

1. **菜单入口**：`menuPath`
2. **页面内权限点**：`menu + code`

原因是像 `save`、`delete`、`export` 这类 code 会在多个页面复用；真实测试保护单位必须是“某菜单下的某权限点”，而不是脱离上下文的全局字符串。

### 3.2 统计结果

当前纳入 UI 权限测试覆盖的范围为：

- **24 个菜单入口**
- **146 个实际可达的 `menu + code` 权限点**
- **80 个实际可达的 unique code**

分上下文统计如下：

| 上下文 | 菜单数 | `menu + code` 数 |
| --- | ---: | ---: |
| 系统管理 | 5 | 16 |
| 基础主数据 | 7 | 46 |
| 入库执行 | 1 | 23 |
| 库存与统计 | 5 | 11 |
| 库内作业 | 5 | 24 |
| 出库履约 | 1 | 26 |
| 合计 | 24 | 146 |

## 4. 完整权限目录（按菜单分组）

> 说明：以下清单是**本次实际纳入 UI 权限测试**的目录，而不是 `actionList.ts` 的名义全量目录。
>
> `roleMenu` 只有入口权限，不含 action 覆盖。

### 4.1 系统管理

- `companySetting`
  - `save`
  - `delete`
  - `export`

- `userRoleSetting`
  - `save`
  - `delete`
  - `export`

- `roleMenu`
  - 无 action code，仅覆盖入口可见性

- `userManagement`
  - `save`
  - `delete`
  - `import`
  - `export`
  - `resetPwd`
  - `exportAll`

- `print`
  - `save`
  - `delete`
  - `export`
  - `exportAll`

### 4.2 基础主数据

- `commodityCategorySetting`
  - `save`
  - `delete`
  - `export`

- `commodityManagement`
  - `save`
  - `delete`
  - `export`
  - `saftyStock`
  - `printQrCode`
  - `printBarCode`
  - `import`
  - `exportAll`

- `supplier`
  - `save`
  - `delete`
  - `import`
  - `export`
  - `exportAll`

- `warehouseSetting`
  - `warehouse-save`
  - `warehouse-delete`
  - `warehouse-import`
  - `warehouse-export`
  - `warehouse-exportAll`
  - `area-save`
  - `area-delete`
  - `area-export`
  - `area-exportAll`
  - `location-save`
  - `location-delete`
  - `location-export`
  - `location-exportAll`
  - `location-printBarCode`
  - `location-printQrCode`

- `ownerOfCargo`
  - `save`
  - `delete`
  - `import`
  - `export`
  - `exportAll`

- `freightSetting`
  - `save`
  - `delete`
  - `import`
  - `export`
  - `exportAll`

- `customer`
  - `save`
  - `delete`
  - `import`
  - `export`
  - `exportAll`

### 4.3 入库执行

- `stockAsn`
  - `notice-save`
  - `notice-delete`
  - `notice-export`
  - `notice-exportAll`
  - `delivered-confirm`
  - `delivered-export`
  - `delivered-exportAll`
  - `unloaded-confirm`
  - `unloaded-delete`
  - `unloaded-export`
  - `unloaded-exportAll`
  - `sorted-editCount`
  - `sorted-confirm`
  - `sorted-delete`
  - `sorted-export`
  - `sorted-exportAll`
  - `putOnTheShelf-editArrival`
  - `putOnTheShelf-delete`
  - `putOnTheShelf-export`
  - `putOnTheShelf-exportAll`
  - `putOnTheShelf-printQrCode`
  - `detail-export`
  - `detail-exportAll`

### 4.4 库存与统计

- `stockManagement`
  - `area-export`
  - `area-exportAll`
  - `stock-export`
  - `stock-exportAll`

- `saftyStock`
  - `export`
  - `exportAll`

- `asnStatistic`
  - `export`
  - `exportAll`

- `deliveryStatistic`
  - `exportAll`

- `stockageStatistic`
  - `export`
  - `exportAll`

### 4.5 库内作业

- `warehouseProcessing`
  - `split`
  - `group`
  - `confirmOpeartion`
  - `confirmAdjust`
  - `delete`
  - `export`
  - `exportAll`

- `warehouseMove`
  - `save`
  - `delete`
  - `export`
  - `confirm`
  - `exportAll`

- `warehouseFreeze`
  - `freeze`
  - `unfreeze`
  - `export`
  - `exportAll`

- `warehouseAdjust`
  - `export`
  - `exportAll`

- `warehouseTaking`
  - `save`
  - `delete`
  - `export`
  - `confirmOpeartion`
  - `confirmAdjust`
  - `exportAll`

### 4.6 出库履约

- `deliveryManagement`
  - `invoice-save`
  - `invoice-confirm`
  - `invoice-revoke`
  - `invoice-delete`
  - `invoice-export`
  - `invoice-exportAll`
  - `invoice-printQrCode`
  - `picked-confirm`
  - `picked-revoke`
  - `picked-export`
  - `picked-exportAll`
  - `packaged-package`
  - `packaged-export`
  - `packaged-exportAll`
  - `packaged-revoke`
  - `weighed-weigh`
  - `weighed-export`
  - `weighed-exportAll`
  - `weighed-revoke`
  - `delivered-delivery`
  - `delivered-setCarrier`
  - `delivered-signIn`
  - `delivered-export`
  - `delivered-exportAll`
  - `signedIn-export`
  - `signedIn-exportAll`

## 5. 角色模型

本次测试不按 code 机械拆用例，而按业务角色和用户旅程组织。建议使用以下 7 类测试角色：

| 角色 | 业务含义 | 主要菜单范围 | 权限风格 |
| --- | --- | --- | --- |
| 系统配置管理员 | 负责账号、角色、公司、打印等平台配置 | `companySetting` `userRoleSetting` `roleMenu` `userManagement` `print` | 系统管理全量 |
| 基础资料管理员 | 负责仓、货、伙伴主数据和仓网配置 | `commodityCategorySetting` `commodityManagement` `supplier` `warehouseSetting` `ownerOfCargo` `freightSetting` `customer` | 主数据全量 |
| 入库专员 | 负责 ASN 从通知到上架 | `stockAsn` | 入库全量 |
| 库存分析员 | 负责库存查询、预警、统计导出 | `stockManagement` `saftyStock` `asnStatistic` `deliveryStatistic` `stockageStatistic` | 分析导出型 |
| 库内作业员 | 负责移库、冻结、加工、盘点 / 调整 | `warehouseProcessing` `warehouseMove` `warehouseFreeze` `warehouseAdjust` `warehouseTaking` | 作业全量 |
| 出库履约专员 | 负责发货单从建单到签收 | `deliveryManagement` | 出库全量 |
| 审计员（只读） | 跨上下文查看状态但不推进流程 | 大多数业务菜单 | 菜单可见、action 为空 |

### 5.1 为什么使用审计员作为统一反向角色

审计员不是为了凑测试而造出的机械角色，而是一个符合业务意义的“跨上下文只读账号”：

- 能进入页面；
- 能查看列表与详情；
- 不能创建、确认、删除、导入、导出、打印、撤销、签收。

这个角色非常适合承担“**同一菜单下无 action 权限**”的反向断言。

## 6. 测试用例矩阵

### 6.1 正向 / 反向覆盖策略

每个权限点都至少应有：

- 1 个**正向**断言：具备权限时入口可见、按钮可用；
- 1 个**反向**断言：缺少权限时入口不可见，或按钮 visible 且 disabled。

### 6.2 用例组织

建议落成 12 条左右主用例，按上下文成对组织：

| 用例 ID | 用例名称 | 正向角色 | 反向角色 | 主要上下文 |
| --- | --- | --- | --- | --- |
| TC01 | 系统配置管理员可进入系统菜单并使用配置动作 | 系统配置管理员 | - | 系统管理 |
| TC02 | 审计员能看系统页面但编辑动作全部禁用 | - | 审计员 | 系统管理 |
| TC03 | 基础资料管理员可维护仓、货与交易伙伴主数据 | 基础资料管理员 | - | 基础主数据 |
| TC04 | 审计员可查看主数据但维护动作禁用 | - | 审计员 | 基础主数据 |
| TC05 | 入库专员可推进 ASN 全旅程 | 入库专员 | - | 入库执行 |
| TC06 | 审计员可查看 ASN 各阶段但推进动作禁用 | - | 审计员 | 入库执行 |
| TC07 | 库存分析员可查看库存与统计并导出 | 库存分析员 | - | 库存与统计 |
| TC08 | 审计员可浏览库存与统计但导出动作禁用 | - | 审计员 | 库存与统计 |
| TC09 | 库内作业员可执行移库、冻结、加工、盘点 / 调整相关动作 | 库内作业员 | - | 库内作业 |
| TC10 | 审计员可查看库内作业但执行动作禁用 | - | 审计员 | 库内作业 |
| TC11 | 出库履约专员可推进发货全旅程 | 出库履约专员 | - | 出库履约 |
| TC12 | 审计员可跟踪出库进度但履约动作禁用 | - | 审计员 | 出库履约 |

### 6.3 入口反向覆盖角色

除了“同菜单下 action 为空”的审计员反向断言外，还需要用**没有该菜单权限**的角色验证入口不可见：

| 上下文 / 菜单组 | 正向角色 | 同菜单反向角色 | 入口反向角色 |
| --- | --- | --- | --- |
| 系统管理 | 系统配置管理员 | 审计员 | 基础资料管理员 |
| 基础主数据 | 基础资料管理员 | 审计员 | 系统配置管理员 |
| 入库执行 | 入库专员 | 审计员 | 库存分析员 |
| 库存与统计 | 库存分析员 | 审计员 | 入库专员 |
| 库内作业 | 库内作业员 | 审计员 | 入库专员 |
| 出库履约 | 出库履约专员 | 审计员 | 入库专员 |

## 7. 测试数据策略

## 7.1 身份 / 角色 / 菜单 / action 权限

这层通过**真实后台 API**预置：

1. `POST /login` 获取管理员 token；
2. `GET /rolemenu/menus` 获取菜单目录；
3. `GET /userrole/all` / `POST /userrole` 创建或查找测试角色；
4. `POST /rolemenu` / `PUT /rolemenu` 对齐角色的菜单与 `menu_actions_authority`；
5. `POST /user` 创建测试用户。

设计目标：

- 保持幂等；
- 不要求人工预先建角色和用户；
- 测试真正走到系统当前的权限装配链路。

## 7.2 业务状态数据

页面所需业务状态不建议全部通过 UI 旅程生成，而建议使用稳定的夹具 bundle，直接把页面放到“如果有权限，则按钮本应可操作”的状态。

建议准备以下 5 类 bundle：

### Bundle A：`system-and-masterdata-baseline`

用途：系统管理、基础主数据、仓网配置页面的通用基线。

包含：
- 基础仓库、库区、库位；
- 货主、供应商、客户；
- 商品分类、SPU、SKU；
- 打印方案基础数据。

### Bundle B：`asn-workbench-bundle`

用途：`stockAsn`。

包含：
- 1 条待到货记录；
- 1 条待卸货记录；
- 1 条待分拣记录；
- 1 条待上架记录；
- 1 条可在收货明细中查询到的相关数据。

目标：保证 `stockAsn` 各 tab 中的权限按钮处于可断言状态，而不是因业务状态不匹配导致误判。

### Bundle C：`stock-and-statistics-bundle`

用途：`stockManagement`、`saftyStock`、统计类页面。

包含：
- 一组正常库存；
- 一组低于或接近安全库存的 SKU；
- 能在统计页被聚合到的数据。

### Bundle D：`internal-operations-bundle`

用途：库内作业。

包含：
- 待确认移库任务；
- 冻结 / 解冻相关数据；
- 待确认加工任务；
- 待确认盘点任务；
- 可查询的调整记录。

### Bundle E：`dispatch-workbench-bundle`

用途：`deliveryManagement`。

包含：
- 待确认发货单；
- 已锁库待拣货；
- 已拣货；
- 已打包；
- 已称重；
- 待出库；
- 已签收。

目标：保证出库旅程中的每类按钮都在**正确业务状态**下接受权限断言。

## 7.3 数据生命周期

### 身份数据

统一使用固定前缀：

- 角色：`E2E-PERM-*`
- 用户：`e2e_perm_*`

策略：
- 已存在则更新；
- 不存在则创建；
- 每次运行做“对齐”，而不是无脑重复插入。

### 业务数据

统一使用业务前缀：

- `ASN-E2E-PERM-*`
- `DP-E2E-PERM-*`
- `MOVE-E2E-PERM-*`
- `FREEZE-E2E-PERM-*`

策略：
- 先清理同前缀旧数据；
- 再重建 bundle；
- 保证测试可重复运行。

## 8. 断言与误判防护

## 8.1 菜单入口断言

### 正向
- 登录后能在侧边栏看到目标菜单入口。

### 反向
- 缺少菜单权限时，看不到该入口。

断言重点是“**侧边栏入口存在性**”，而不是直接通过 hash 路由硬跳转后的页面结果。

## 8.2 顶部按钮断言

对 `BtnGroup` 中的按钮：

### 正向
- 按钮可见；
- 且处于 enabled 状态。

### 反向
- 按钮可见；
- 但必须 disabled。

## 8.3 行内按钮断言

对表格行内按钮：

### 正向
- 在正确业务状态的行上，按钮可见且 enabled。

### 反向
- 在同样业务状态的行上，按钮可见但 disabled。

### 关键原则

正反场景必须使用**同类业务状态数据**，否则容易把“业务状态不允许”误判成“权限不允许”。

例如：
- `invoice-confirm` 的正反断言都应使用待确认发货单；
- `confirm` 的正反断言都应使用待确认移库任务；
- `delivered-signIn` 的正反断言都应使用待签收状态数据。

## 9. 选择器与测试钩子设计

当前前端没有系统性的 `data-testid`。为了让 Playwright 权限测试可维护，建议补充**最小测试钩子**，不改变业务行为，只增强可定位性。

### 9.1 菜单入口

建议给侧边栏菜单项增加：

- `data-menu-path="deliveryManagement"`
- `data-menu-path="stockAsn"`
- `data-menu-path="warehouseSetting"`

这样入口权限断言可以稳定绑定到真实菜单路径，而不是依赖文字或图标顺序。

### 9.2 顶部按钮 / 行内按钮

建议增强 `tooltip-btn`：

1. 支持输出 `data-auth-code`；
2. 支持输出 `aria-label`，可直接复用 `tooltipText`；
3. 允许调用方显式传入 `authCode`，用于手写行内按钮。

目标示例：

- `data-auth-code="invoice-save"`
- `data-auth-code="confirmOpeartion"`
- `aria-label="Export"`

这样可以避免测试依赖：
- 第几个 icon button；
- 某个 `mdi-*` 图标 class；
- 某段容易变化的文案。

## 10. 覆盖清单（manifest）

为了证明“完整覆盖”，建议维护一份权限覆盖 manifest，而不是只靠人工说明“应该都测到了”。

建议每条记录至少包含：

| 字段 | 含义 |
| --- | --- |
| `context` | 所属上下文 |
| `menuPath` | 菜单路径 |
| `pageOrTab` | 页面或 tab |
| `authCode` | 权限 code；入口项可为空 |
| `selectorType` | `menu` / `top-button` / `row-button` |
| `positiveRole` | 正向角色 |
| `negativeRole` | 反向角色 |
| `fixtureBundle` | 依赖的数据包 |
| `specFile` | 对应 spec 文件 |
| `assertionType` | `visible` / `enabled` / `disabled` / `absent` |

manifest 的用途：

1. 在设计期确认没有漏掉任何真实权限点；
2. 在实现期核对每个权限点都被映射到至少一个正向和一个反向场景；
3. 当页面权限点新增 / 删除时，可以快速看出需要补哪些 spec。

## 11. 建议文件结构

在现有 `frontend/e2e/` 目录上扩展：

```text
frontend/e2e/
├── playwright.config.ts
├── specs/
│   ├── login.spec.ts
│   └── permissions/
│       ├── sidebar-visibility.spec.ts
│       ├── system-management-permissions.spec.ts
│       ├── master-data-permissions.spec.ts
│       ├── inbound-permissions.spec.ts
│       ├── inventory-and-statistics-permissions.spec.ts
│       ├── internal-operations-permissions.spec.ts
│       └── outbound-fulfillment-permissions.spec.ts
├── support/
│   ├── auth.ts
│   ├── test-system.ts
│   ├── api-client.ts
│   ├── permission-bootstrap.ts
│   ├── business-bundles.ts
│   ├── permission-manifest.ts
│   ├── selectors.ts
│   └── permission-assertions.ts
```

### 11.1 各 spec 的职责

- `sidebar-visibility.spec.ts`
  - 专门覆盖 24 个菜单入口的可见 / 不可见。

- `system-management-permissions.spec.ts`
  - 系统配置管理员正向；
  - 审计员系统管理反向；
  - `roleMenu` 仅覆盖入口，不做 action 测试。

- `master-data-permissions.spec.ts`
  - 主数据全量正向；
  - 审计员反向；
  - 特别覆盖 `warehouse-*`、`area-*`、`location-*` 三层仓网权限。

- `inbound-permissions.spec.ts`
  - 基于 `asn-workbench-bundle` 覆盖 `stockAsn` 23 个权限点。

- `inventory-and-statistics-permissions.spec.ts`
  - 只覆盖当前实际接入权限判断的库存与统计页面按钮。

- `internal-operations-permissions.spec.ts`
  - 基于 `internal-operations-bundle` 覆盖库内作业正反场景。

- `outbound-fulfillment-permissions.spec.ts`
  - 基于 `dispatch-workbench-bundle` 覆盖当前可达的出库履约正反场景。

## 12. 执行方式与顺序

## 12.1 执行方式

沿用现有仓库脚本：

### 只跑 UI E2E

```bash
./scripts/macos-dev.sh start
cd frontend
COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e
cd ..
./scripts/macos-dev.sh stop
```

### 全量验收

```bash
./scripts/test-all.sh
```

## 12.2 执行顺序

建议串行执行，不启用权限套件并行：

1. `login.spec.ts`
2. `permissions/sidebar-visibility.spec.ts`
3. `permissions/system-management-permissions.spec.ts`
4. `permissions/master-data-permissions.spec.ts`
5. `permissions/inbound-permissions.spec.ts`
6. `permissions/inventory-and-statistics-permissions.spec.ts`
7. `permissions/internal-operations-permissions.spec.ts`
8. `permissions/outbound-fulfillment-permissions.spec.ts`

原因：
- 这些用例共享真实数据库；
- 会共享测试角色、测试用户和业务前缀；
- 并行清理 / 重建 bundle 容易互相污染。

## 12.3 Playwright 配置建议

建议对权限测试显式配置：

- `workers: 1`
- 失败保留 `trace`
- 失败保留 `screenshot`
- 继续使用现有 HTML report

## 13. 验收标准

### 13.1 覆盖完整性

- 24 个菜单入口全部纳入 manifest；
- 146 个实际可达 `menu + code` 权限点全部纳入 manifest；
- 每个权限点至少有 1 个正向断言和 1 个反向断言。

### 13.2 行为正确性

- 无菜单权限时，对应侧边栏入口不可见；
- 有菜单但无 action 权限时，相关按钮可见但 disabled；
- 不出现“业务状态不允许”被误判成“权限不允许”的情况。

### 13.3 业务表达正确

- 用例名称、角色和场景具有业务含义；
- 用例能映射到系统管理、主数据、入库、库存分析、库内作业、出库履约等真实用户旅程；
- 不退化成 146 条机械 code 枚举测试。

### 13.4 工程可维护性

- 不依赖人工预建测试角色 / 用户 / 业务数据；
- 测试可重复执行；
- 失败时能快速定位是入口权限、action 权限，还是 bundle 数据问题；
- 选择器不依赖脆弱的图标顺序。

## 14. 风险与缓解

| 风险 | 说明 | 缓解 |
| --- | --- | --- |
| 前端缺少稳定选择器 | 纯 icon button 难以稳定定位 | 补最小测试钩子：`data-menu-path`、`data-auth-code`、`aria-label` |
| 业务状态误判为权限禁用 | 同一个按钮会同时受权限和状态控制 | 为每个上下文准备稳定 bundle，并要求正反场景使用同类状态数据 |
| 目录与页面权限位点不一致 | `actionList.ts` 不是 UI 真相的唯一来源 | 以“当前可达页面中的真实权限判断代码”为准，借助 manifest 维护 |
| 真实数据库导致重复运行污染 | 角色、用户、业务数据容易积累脏数据 | 所有测试数据采用固定前缀并在每轮运行前对齐 / 清理 |
| 套件运行时间偏长 | 需要真实前后端和数据库 | 权限套件串行、基于 bundle 复用数据，不在 UI 中重复走重前置链路 |

## 15. 明确不纳入本次覆盖的内容

以下内容不属于本次 UI 权限测试范围：

1. 孤儿 code；
2. 已注释掉的权限位点；
3. 当前主页面未挂入的历史 / 备用 tab；
4. 只有目录声明、但当前 UI 没有真正接入权限判断的 action；
5. 后端细粒度服务端授权本身。

## 16. 结论

本设计采用“**业务角色驱动 + manifest 完整覆盖兜底**”的方式，为 ModernWMS 建立前端权限 UI 测试保护：

- 从用户旅程组织用例，保持业务语义；
- 以当前真实前端权限行为为准，避免目录与页面脱节；
- 用 API 预置角色和权限，用 bundle 预置业务状态；
- 用最小测试钩子提高 Playwright 稳定性；
- 以 24 个菜单入口和 146 个真实权限点作为明确验收边界。
