# ModernWMS API 设计与前后端协作约定

> 本文基于 **当前代码库实现** 整理，而不是理想化重构方案。
>
> 主要分析依据：
> - `backend/ModernWMS/Program.cs`
> - `backend/ModernWMS.Core/Controller/*`
> - `backend/ModernWMS.Core/JWT/*`
> - `backend/ModernWMS.Core/Middleware/*`
> - `backend/ModernWMS.WMS/Controllers/*`
> - `backend/ModernWMS.WMS/Services/*`
> - `frontend/src/api/*`
> - `frontend/src/router/index.ts`
> - `frontend/src/utils/http/request.ts`
> - `frontend/src/utils/router/index.ts`
> - `frontend/src/utils/systemLog.ts`
> - `frontend/src/view/**/*`
> - `frontend/src/constant/style.ts`
> - `scripts/seeds/database_mysql.sql`

相关文档：
- 业务上下文：`../domain-model/bounded-contexts.md`
- 前端开发规范：`../development-standards/frontend-conventions.md`
- 后端开发规范：`../development-standards/backend-conventions.md`
- 页面风格规范：`./ui-ux-style-guide.md`

---

## 1. 当前 API 总览

### 1.1 API 分组

当前后端并没有把 API 挂在 `/api/*` 前缀下，而是直接以资源名作为一级路径。
Swagger 也不是按版本号分组，而是按业务分组：

- `Base`：登录、用户、角色、菜单、主数据、打印方案等
- `WMS`：入库、库存、库内作业、出库、日志等

### 1.2 主要资源前缀

| 领域 | 主要接口前缀 | 主要前端页面 | 说明 |
| --- | --- | --- | --- |
| 认证与会话 | `/login`、`/refresh-token` | `frontend/src/view/login/*` | 根路径命令式接口 |
| 系统管理 / 基础主数据 | `/company`、`/user`、`/userrole`、`/rolemenu`、`/category`、`/spu`、`/supplier`、`/goodsowner`、`/freightfee`、`/customer`、`/warehouse`、`/warehousearea`、`/goodslocation`、`/PrintSolution` | `frontend/src/view/base/*` | 以 CRUD 为主 |
| 入库执行 | `/asn`、`/asn/asnmaster` | `frontend/src/view/wms/stockAsn/*` | 到货通知 + 状态流转 |
| 库存与统计 | `/stock/*` | `frontend/src/view/wms/stockManagement/*`、`frontend/src/view/statisticAnalysis/*` | 以只读查询为主 |
| 库内作业 | `/stockprocess`、`/stockmove`、`/stockfreeze`、`/stocktaking`、`/stockadjust` | `frontend/src/view/warehouseWorking/*` | 当前 `stockadjust` 已暴露接口较少 |
| 出库履约 | `/dispatchlist/*` | `frontend/src/view/deliveryManagement/deliveryManagement/*` | 列表 + 多阶段命令 |
| 日志与审计 | `/actionlog/list` | `frontend/src/components/system/view-log-dialog.vue` | 页面操作日志 |

### 1.3 当前资源组织特征

1. **资源名直接作为路由前缀**，例如 `/user`、`/warehouse`、`/dispatchlist`。
2. **详情与删除普遍使用 query 参数传 id**，例如 `GET /company?id=1`、`DELETE /user?id=1`，而不是 `/company/1`。
3. **分页查询普遍使用 `POST /resource/list`**，而不是 `GET + query string`。
4. **复杂流程接口使用“资源 + 命令子路由”**，例如：
   - `/asn/confirm`
   - `/asn/unload`
   - `/dispatchlist/package`
   - `/stockprocess/process-confirm`

---

## 2. 认证、租户与权限设计

### 2.1 认证模型

当前认证是 **JWT + refresh token + Vuex/localStorage 持久化**。

认证流程如下：

```text
[登录页]
   ↓ POST /login
[返回 access_token / refresh_token / expire / userrole_id]
   ↓ GET /rolemenu/authority?userrole_id=...
[返回菜单 + 按钮 action codes]
   ↓
[前端生成动态路由 / 侧边栏 / 当前页面 authorityList]
   ↓
[axios 为后续请求注入 Authorization]
```

当前匿名接口只有：

- `POST /login`
- `POST /refresh-token`
- `POST /hello-world`
- `POST /user/register`

其余控制器都通过 `BaseController` 继承了 `[Authorize]`。

### 2.2 Token 与会话续期

`/login` 返回：

- `access_token`
- `refresh_token`
- `expire`
- `user_id`
- `user_name`
- `user_num`
- `user_role`
- `userrole_id`
- `tenant_id`

前端在 `frontend/src/utils/http/request.ts` 中：

- 将 token、refreshToken、过期时间、用户信息写入 `Vuex + localStorage`
- 在 token 将要过期时自动调用 `/refresh-token`
- 刷新成功后重放挂起请求
- 刷新失败时回到 `/login`

### 2.3 租户隔离模型

当前系统是 **单库多租户**，租户标识主要来自 token 内的 `CurrentUser.tenant_id`。

现状特点：

1. `CurrentUser` 中包含 `tenant_id`
2. 大多数业务表显式包含 `tenant_id`
3. 服务层读写时**手工加 tenant 过滤**
4. `SqlDBContext` 当前**没有启用全局租户过滤器**

这意味着：

- **租户隔离是服务层约定，不是 EF Core 的全局机制**
- 新增服务查询时，必须显式检查是否带上 `currentUser.tenant_id`

### 2.4 菜单与按钮权限模型

当前权限是两层：

| 层级 | 数据来源 | 前端用途 | 后端用途 |
| --- | --- | --- | --- |
| 菜单级 | `rolemenu` 记录存在即可视为有菜单 | 动态路由、侧边栏显示 | 后端基本不校验 |
| 按钮级 | `rolemenu.menu_actions_authority` | 控制 `BtnGroup` / 行操作按钮禁用 | 后端基本不校验 |

权限实体关系：

- `user`：用户，记录 `user_role`
- `userrole`：角色
- `menu`：菜单定义，含 `module`、`vue_path`、`vue_directory`
- `rolemenu`：角色与菜单关系，附加 `menu_actions_authority`

前端权限链路：

1. 登录后拿到 `userrole_id`
2. 调用 `GET /rolemenu/authority`
3. 把返回值写入 `store.user.menulist`
4. 用 `menusToRouter()` 动态生成路由
5. 用 `menusToSideBar()` 动态生成侧边栏
6. 页面内通过 `getMenuAuthorityList()` 取得当前菜单 action codes
7. `BtnGroup` 或 `tooltip-btn` 根据 code 禁用按钮

### 2.5 action code 命名规则

当前项目已经形成两类 action code 命名方式：

1. **单页 CRUD 页面**：直接用通用动作名
   - `save`
   - `delete`
   - `import`
   - `export`
   - `exportAll`

2. **一个路由下包含多个 tab / 子流程时**：用 `子流程-动作` 命名
   - `notice-save`
   - `warehouse-save`
   - `area-delete`
   - `picked-confirm`
   - `delivered-signIn`

新增按钮权限时，应继续沿用这套规则，避免不同 tab 之间的 code 冲突。

### 2.6 当前权限设计的现实边界

这是本文最重要的现状结论之一：

> **当前代码库中，菜单权限和按钮权限主要由前端控制可见性 / 可点击性，后端默认只强制校验“是否已登录”和“是否属于当前租户”，并未按 action code 做服务端授权拦截。**

因此：

- 现有权限模型更接近 **UI 权限 + 数据隔离**
- 不是完整的 **后端能力级授权**
- 如果未来新增高风险接口，不能只加前端按钮禁用，还应补服务端授权判断

### 2.7 当前存量注意事项

1. `menu.menu_actions` 字段在数据库和后端模型中存在，但当前种子数据与 `UserService.Register()` 初始化时基本为空。
2. 真正作为按钮权限来源的，是 `rolemenu.menu_actions_authority`。
3. `frontend/src/view/base/roleMenu/actionList.ts` 实际上承担了“按钮动作目录”的角色。
4. `rolemenu.authority` 字段当前几乎只起到“这条角色-菜单关系存在”的作用，业务上很少单独判断其值。
5. 自注册租户初始化菜单时，默认会创建菜单记录与 admin 角色，但按钮 action 列表不会自动补齐到与种子库相同的水平。

---

## 3. API 公共契约

### 3.1 统一响应包装

后端统一返回 `ResultModel<T>`，JSON 形态如下：

```json
{
  "isSuccess": true,
  "code": 200,
  "errorMessage": "",
  "data": {
    "rows": [],
    "totals": 0
  }
}
```

约定：

- `isSuccess`：业务成功 / 失败
- `code`：业务状态码，成功通常为 `200`
- `errorMessage`：失败消息
- `data`：业务载荷

### 3.2 字段命名约定

当前接口字段命名存在两层风格：

1. **响应包装层**：`isSuccess`、`errorMessage`、`rows`、`totals`
2. **业务字段层**：大量沿用数据库风格的 `snake_case`
   - `user_name`
   - `goods_owner_id`
   - `dispatch_no`
   - `estimated_arrival_time`

也就是说：

- **外层包装字段看起来像 camelCase**
- **业务载荷字段仍以 snake_case 为主**

新增接口不要随意改成另一套字段风格，否则会破坏现有前端类型与表单绑定。

### 3.3 分页查询约定

当前标准分页请求体是 `PageSearch`：

```json
{
  "pageIndex": 1,
  "pageSize": 20,
  "sqlTitle": "dispatch_status=3",
  "searchObjects": [
    {
      "name": "user_name",
      "operator": 6,
      "text": "admin",
      "value": "admin"
    }
  ]
}
```

标准分页响应体是 `PageData<T>`：

```json
{
  "rows": [],
  "totals": 0
}
```

约定：

- `pageIndex` 从 `1` 开始
- `pageSize` 默认前端常用 `20`
- 当 `pageIndex <= 0` 或 `pageSize <= 0` 时，后端通常按“取全部数据”处理，前端用它实现 `exportAll`

### 3.4 动态搜索约定

通用列表页查询条件使用 `searchObjects`，操作符来自后端 `Operators` 枚举：

| 值 | 含义 | 前端常量 |
| --- | --- | --- |
| `1` | Equal | `SearchOperator.EQUAL` |
| `6` | Contains | `SearchOperator.INCLUDE` |

当前前端常见做法：

- 搜索框输入通过 `setSearchObject()` 转成 `searchObjects`
- 普通文本默认 `Contains`
- 精确字段可显式传 `Equal`

### 3.5 `sqlTitle` 的当前角色

`sqlTitle` 不是严格意义上的 SQL，而是一个 **服务端约定的状态筛选提示字段**。

现状用法示例：

- `asn_status:0`
- `dispatch_status=3`
- `package`
- `weight`
- `delivery`
- `select`

建议：

- 新增接口时，优先把 `sqlTitle` 只用于“列表状态分区 / 查询模式切换”
- 不要继续把它演化成任意业务命令的万能入口
- 如果是新场景且筛选复杂，优先定义专门 DTO

### 3.6 HTTP 动作表达规则

基于当前代码库，建议继续遵守以下动作语义：

| 场景 | 当前约定 | 示例 |
| --- | --- | --- |
| 登录 / 刷新令牌 | `POST` 根路径命令接口 | `/login`、`/refresh-token` |
| 分页列表 | `POST /resource/list` | `/user/list`、`/asn/list` |
| 全量列表 | `GET /resource/all` | `/supplier/all` |
| 详情查询 | `GET /resource?id=...` | `/warehouse?id=1` |
| 新增 | `POST /resource` | `/company` |
| 修改 | `PUT /resource` | `/customer` |
| 删除 | `DELETE /resource?id=...` | `/goodsowner?id=1` |
| 选择器 / 级联下拉 | `GET /resource/select-item` 或关系型子路由 | `/warehouse/select-item`、`/warehousearea/areas-by-warehouse_id` |
| 状态流转 | 已有记录状态推进优先 `PUT /resource/<command>` | `/asn/confirm`、`/stockprocess/process-confirm` |
| 命令型处理 | 创建后续记录或批处理动作常见 `POST /resource/<command>` | `/dispatchlist/package`、`/dispatchlist/sign` |
| 批量导入 | `POST /resource/excel` 或 `/import` | `/supplier/excel`、`/dispatchlist/import` |
| 文件上传 | `POST /resource/uploadImg` | `/spu/uploadImg` |

### 3.7 关于导入 / 导出的特殊说明

当前代码里：

- `/excel` **不是导出接口**，而是历史命名下的**批量导入接口**
- 导出主要由前端用 `vxe-table + xlsx` 本地完成
- `exportAll` 的实现方式，是先用 `pageIndex=0,pageSize=0` 拉全量，再在浏览器导出

所以后续新增接口时：

- 如果只是和现有管理页一致的导出，不必新建后端 `/export`
- 如果一定要做服务端导出，应单独说明为什么不能沿用当前前端导出模式

### 3.8 复合表单与批量命令约定

当前有两类高频复合提交模式：

1. **单头 + 明细整体提交**
   - `SpuBothViewModel.detailList`
   - `AsnmasterBothViewModel.detailList`

2. **批量命令数组提交**
   - `confirmArrival(List<...>)`
   - `confirmOrder(List<...>)`
   - `package(List<...>)`
   - `weight(List<...>)`
   - `delivery(List<...>)`

设计倾向是：

- 如果页面本身就是“单据 + 明细”，优先一次提交完整复合 DTO
- 如果页面是在“勾选多行后执行命令”，优先提交数组 DTO

### 3.9 本地化与审计头

当前前端会自动做两件事：

1. **所有请求自动追加 `culture` query 参数**
   - `zh-cn`
   - `en-us`

2. **所有变更请求尽量附带操作日志头**
   - `X-Vue-Path`
   - `X-Action-Content`

后端通过 `RequestResponseMiddleware` + `RequestLogger` + `ActionLogService` 把它落到 `action_log` 表。

因此，新增变更型接口时：

- 前端 API 封装与页面调用应保证 `request.ts` 能拿到可解析的 `url / method / data`
- 如果希望操作日志更可读，应同步补 `frontend/src/utils/systemLog.ts`

### 3.10 出库拣货增强接口约定

当前 `deliveryManagement` 中的拣货增强遵循“**运行时拣货单视图 + 行级执行命令 + 整单复核命令**”三层分工：

1. **运行时拣货单视图**
   - `POST /dispatchlist/picking-sheet`
   - 请求体：`{ dispatchlist_ids: number[] }`
   - 只聚合父 `dispatchlist.dispatch_status = 2` 的 `dispatchpicklist`
   - 返回 `dispatch_nos + lines`
   - `lines[*].group_key` 只是前端渲染用的响应字段，不是持久化业务编号
   - 聚合键固定为：`sku_id`、`goods_location_id`、`goods_owner_id`、`series_number`、`expiry_date`、`price`、`putaway_date`

2. **行级拣货执行命令**
   - `PUT /dispatchlist/confirm-pick-items`
   - `PUT /dispatchlist/revoke-pick-items`
   - 请求体统一为：`{ pick_detail_ids: number[] }`
   - 只允许操作父发货明细仍处于 `dispatch_status = 2` 的记录
   - 这两个命令只修改 `DispatchpicklistEntity`，不推进 `DispatchlistEntity.dispatch_status`
   - `GET /dispatchlist/pick-list?dispatch_id=...` 会返回 `picker / picker_id`，供详情弹窗查看现场执行人

3. **整单复核 / 旧流程兼容命令**
   - `PUT /dispatchlist/confirm-pick-dispatchlistno?dispatch_no=...`
   - 语义不是“逐条拣货确认”，而是“整单复核并放行到已拣货”
   - 它会自动补齐未确认的 `DispatchpicklistEntity`，并写入：
     - 行级 `picker / picker_id`（仅在原明细还没有执行人时补齐）
     - 整单 `pick_checker / pick_checker_id`
   - 然后把对应 `DispatchlistEntity.dispatch_status` 从 `2` 推进到 `3`
   - 该接口保留了旧的“直接整单推进”路径，但库存扣减时机仍然保持在 `Delivery()`

前端协作上的稳定约定是：

- 待拣货页继续沿用原 tab，不新增菜单或新路由；
- 新增能力优先通过局部对话框承载，而不是引入新的持久化单据页面；
- `picked-pick`、`picked-revoke`、`picked-confirm` 继续复用为生成/执行/撤销/复核入口。

---

## 4. 页面与 API 的协作规范

### 4.1 标准管理页布局

当前绝大多数后台管理页遵循下述骨架：

```text
[SideBar] [Header/Breadcrumb]
          [Tabs?]
          [Card]
            [BtnGroup | Search Area]
            [vxe-table / Chart / Nav+Detail]
            [custom-pager]
            [Dialog Components]
```

典型实现位于：

- `frontend/src/view/base/*`
- `frontend/src/view/wms/*`
- `frontend/src/view/warehouseWorking/*`
- `frontend/src/view/deliveryManagement/*`

### 4.2 页面视觉与交互基线

当前 UI 风格基线来自 `frontend/src/constant/style.ts`、`homeHeader.vue`、`homeSideBar.vue`：

- 主色：`#9C27B0`
- 侧边栏激活态：紫色渐变 `#af85fc -> #9155fd`
- 破坏性动作色：`#BA2828`
- 顶部 header 高度：`60px`
- 侧边栏展开宽度：`300px`
- 折叠宽度：`100px`

页面控件风格约定：

| 场景 | 当前惯例 |
| --- | --- |
| 搜索框 | `v-text-field` + `variant="solo"` + `density="comfortable"` |
| 表单弹窗 | `v-dialog` + `v-form` + `variant="outlined"` |
| 操作按钮 | `BtnGroup` / `tooltip-btn` |
| 数据表格 | `vxe-table` |
| 分页器 | `custom-pager` |
| 成功 / 失败提示 | `hookComponent.$message` |
| 确认弹窗 | `hookComponent.$dialog` |
| 日期列 | `VxeDateColumn` |

### 4.3 页面高度计算规则

管理页不要手写大量固定高度，当前约定是使用：

- `computedCardHeight()`
- `computedTableHeight()`
- `computedSelectTableSearchHeight()`

并根据页面是否有：

- tab
- pager
- 操作条
- toolbar

传入不同参数。

### 4.4 搜索与分页交互规则

当前列表页的统一交互是：

1. `searchForm` 保存原始表单
2. `watch(searchForm, { deep: true })` + `DEBOUNCE_TIME = 350`
3. `setSearchObject(searchForm)` 转换查询条件
4. 调用 `POST /resource/list`
5. `custom-pager` 改变页码和页大小

因此新页面应尽量复用这套节奏，而不是单独再造一套搜索协议。

### 4.5 tab 页规范

对于一个路由下有多个业务阶段的页面，当前惯例是：

- 父页面负责 `v-tabs + v-window`
- 子 tab 是独立组件
- 子组件通过 `defineExpose()` 暴露 `getList()` 或 `refresh()`
- 父组件在 `changeTabs()` 内 `nextTick()` 后调用子组件刷新方法

典型页面：

- `frontend/src/view/wms/stockAsn/stockAsn.vue`
- `frontend/src/view/deliveryManagement/deliveryManagement/deliveryManagement.vue`
- `frontend/src/view/base/warehouseSetting/warehouseSetting.vue`

### 4.6 例外页面

以下页面是当前标准管理页规范的例外，不应强行套用 CRUD 列表骨架：

- `frontend/src/view/largeScreen/largeScreen/*`：DataV 大屏展示
- `frontend/src/view/vwms/*`：3D / Unity 交互页

---

## 5. 前后端代码风格惯例摘要

### 5.1 后端

当前后端已经形成的稳定惯例：

1. 控制器薄、服务厚
2. 目录按 `Controllers / Services / IServices / Entities / ViewModels` 划分
3. 公共控制器能力放在 `ModernWMS.Core`
4. 每个控制器通过构造函数注入 service 与 localizer
5. 控制器统一返回 `ResultModel<T>`
6. 读取当前用户统一通过 `BaseController.CurrentUser`
7. 服务层显式接收 `CurrentUser` 并自己处理 `tenant_id`
8. 简单映射使用 Mapster，复杂聚合使用 LINQ 手写投影
9. ViewModel / Entity 大量使用 `snake_case` 属性名，以保持与数据库和前端字段一致
10. 公开方法大多保留 XML 注释与 `#region` 结构

### 5.2 前端

当前前端已经形成的稳定惯例：

1. API 封装统一放 `src/api/**`，页面不要直接写 axios
2. 类型统一放 `src/types/**`
3. 页面组件普遍使用 `script setup + TypeScript`
4. 业务状态常用 `reactive({ data... }) + reactive({ method... })`
5. 页面按钮通过 `btnList + BtnGroup` 组装
6. 权限码通过 `getMenuAuthorityList()` 获取
7. 所有展示文案优先走 i18n
8. 对话框组件使用 `showDialog` 入参和 `close / saveSuccess` 事件
9. 列表页导出统一走 `exportData()`
10. 搜索自动触发优先使用 debounce watch

更细的开发规范见：
- `../development-standards/frontend-conventions.md`
- `../development-standards/backend-conventions.md`
- `./ui-ux-style-guide.md`

---

## 6. 当前存量差异与新增接口注意事项

### 6.1 需要接受的存量差异

以下内容是当前代码库里已经存在的“非完美但真实”的地方，文档需要如实承认：

1. 没有 `/api` 前缀
2. `PrintSolution` 路由仍保留 PascalCase
3. `/excel` 历史上表示导入，不表示导出
4. `sqlTitle` 被用作状态筛选提示，而不是严格语义字段
5. 菜单 / 按钮权限没有服务端细粒度拦截
6. `stockadjust` 前端仍保留一组历史封装，但后端控制器当前只暴露 `/stockadjust/list`
7. `frontend/src/api/wms/stockAsn.ts` 中保留了部分历史的单记录命令包装；新增设计应以控制器真实签名为准

### 6.2 新增 API 的最小检查清单

新增接口时，至少检查以下事项：

- 是否应挂在现有资源前缀下，而不是新造一级路由
- 是否应复用 `ResultModel<T>`
- 是否应复用 `PageSearch / PageData<T>`
- 是否需要显式带上 `CurrentUser` 并做 tenant 过滤
- 是否需要为前端页面补 `src/api/*` 封装与 `src/types/*` 类型
- 是否需要补 `frontend/src/utils/systemLog.ts` 的操作文案
- 如果新增菜单 / 页面，是否同步更新：
  - `scripts/seeds/database_mysql.sql`
  - `backend/ModernWMS.WMS/Services/User/UserService.cs` 的注册初始化
  - `frontend/src/utils/router/index.ts`
  - `frontend/src/view/base/roleMenu/actionList.ts`

### 6.3 未来若要加强权限

如果后续要把权限从“前端可见性控制”升级为“后端能力授权”，建议按这个顺序推进：

1. 先把 action code 的后端来源统一化
2. 再给关键命令接口补服务端权限判断
3. 最后再考虑把 `menu.menu_actions` 变成真正的权限目录来源

在此之前，新增高风险接口时，不要默认认为“按钮隐藏了就安全”。
