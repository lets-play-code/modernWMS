# ModernWMS 前后端开发惯例

> 本文只总结 **当前仓库已经稳定形成** 的工程习惯，供新增页面、接口和模块时参考。
>
> 这不是理想化编码规范，而是“为了尽量少踩现有项目的坑，新增代码应优先贴合的风格”。

相关设计文档：`../software-design/api-design.md`

---

## 1. 总体原则

1. **优先贴现有结构，不先重构再开发**
2. **新增功能先补目录、类型、API 封装，再写页面 / 服务逻辑**
3. **保持前后端字段名一致，当前项目优先使用业务 `snake_case`**
4. **先兼容存量路由与权限模型，再谈理想化 REST 或策略权限**
5. **所有长期规则优先写进文档，而不是只留在页面或 service 的隐式习惯里**

---

## 2. 后端惯例

### 2.1 目录与职责划分

后端当前稳定结构：

```text
backend/
├── ModernWMS/                 # 宿主、启动、配置、日志、Swagger
├── ModernWMS.Core/            # 共享基础设施
└── ModernWMS.WMS/             # 业务域实现
```

业务模块内部通常按下列目录组织：

```text
Controllers/
IServices/
Services/
Entities/Models/
Entities/ViewModels/
```

约定：

- `Controller` 只负责接收参数、调用 service、包装 `ResultModel<T>`
- 业务规则、校验、状态流转、租户过滤放在 `Service`
- 传输对象与表实体分开维护

### 2.2 控制器风格

新增控制器时，优先贴近现有写法：

- 继承 `BaseController`
- 使用构造函数注入 `IStringLocalizer` 和对应 service
- 使用 `[Route("resource")]`
- 使用 `[ApiController]`
- 使用 `[ApiExplorerSettings(GroupName = "Base" | "WMS")]`
- 返回 `Task<ResultModel<T>>`

建议保留：

- XML 注释
- `#region Args / constructor / Api`
- `Async` 后缀（命令接口中已有少量历史例外，但新代码应尽量统一）

### 2.3 服务层风格

当前 service 层的真实惯例是：

1. 构造函数注入 `SqlDBContext`
2. 读操作优先 `AsNoTracking()`
3. 分页返回 `(List<T> data, int totals)`
4. 写操作返回 `(bool flag, string msg)` 或 `(int id, string msg)`
5. 复杂列表优先 LINQ 手写投影
6. 简单实体 / ViewModel 转换可直接用 `Mapster.Adapt()`

新增服务时，优先延续这种模式，不要在局部突然切到另一套 repository / unit of work 风格。

### 2.4 当前用户与租户处理

后端当前约定不是自动租户过滤，而是：

- `BaseController.CurrentUser` 解析 token
- controller 把 `CurrentUser` 传给 service
- service 手工使用 `currentUser.tenant_id`

因此新增查询 / 新增写操作时，要显式检查：

- 是否只读当前租户数据
- 新建数据是否写入 `tenant_id`
- 关联查询是否遗漏租户条件

### 2.5 实体与 ViewModel 命名

当前项目的一个关键现状：

- **C# 类型名 / 文件名**：PascalCase
- **属性名**：大量沿用数据库风格 `snake_case`

例如：

- `CompanyController`
- `CompanyViewModel`
- `company_name`
- `goods_owner_id`

新增实体 / DTO 时，除非会大面积改动现有接口契约，否则不要单独引入一套 camelCase 业务字段。

### 2.6 校验与返回约定

新增 DTO 时：

- 优先补 `Display` / `Required` / `MaxLength` / `DataType`
- 依赖 `ViewModelActionFiter` 统一收敛模型错误
- 返回值统一包在 `ResultModel<T>` 中

不要：

- 直接返回裸对象
- 直接在 controller 里写大段业务校验
- 绕开统一错误包装

### 2.7 新增接口时必须同步关注的文件

如果是一个真正的新后端能力，通常至少会涉及：

- `backend/ModernWMS.WMS/Controllers/...`
- `backend/ModernWMS.WMS/IServices/...`
- `backend/ModernWMS.WMS/Services/...`
- `backend/ModernWMS.WMS/Entities/ViewModels/...`
- 必要时 `backend/ModernWMS.WMS/Entities/Models/...`
- 如果涉及菜单展示，还要更新：
  - `scripts/seeds/database_mysql.sql`
  - `backend/ModernWMS.WMS/Services/User/UserService.cs`

### 2.8 日志与可观测性惯例

当前后端有两类日志：

1. **API 访问日志**：`ApiLogFilter`
2. **业务操作日志**：`RequestResponseMiddleware` + `ActionLogService`

因此新增变更型接口时：

- 前端若需要可读操作日志，应补 `frontend/src/utils/systemLog.ts`
- 后端不必单独再造一套页面操作日志落库逻辑

### 2.9 后端格式与命名细节

后端当前没有像前端那样明显的格式化配置文件，新增代码应以现有 C# 文件风格为准：

- 类型、文件名、方法名使用 PascalCase
- 业务属性名优先保持现有 `snake_case`
- 私有依赖优先 `private readonly`
- 公共成员优先保留 XML 注释
- 结构上默认保留 `#region`
- 控制器与 service 的方法名尽量使用 `Async` 后缀

---

## 3. 前端惯例

### 3.1 目录组织

当前前端约定是按“能力类型”拆目录，而不是按纯业务域拆 monolith module：

```text
src/
├── api/
├── components/
├── constant/
├── languages/
├── router/
├── store/
├── types/
├── utils/
└── view/
```

新增页面通常至少要配套：

- `src/view/...`
- `src/api/...`
- `src/types/...`
- 可能还要补 `src/languages/...` 文案

### 3.2 API 调用风格

前端不要在页面里直接写 axios。

统一做法：

- 在 `src/api/**` 新增封装函数
- 页面里 `import { xxx } from '@/api/...'`
- 页面调用后使用：

```ts
const { data: res } = await someApi(params)
```

这是因为当前 `request.ts` 返回的仍然是接近 `AxiosResponse` 的结构，而不是彻底扁平化后的 `res.data`。

### 3.3 类型组织风格

当前前端类型命名比较稳定：

- 单条业务对象：`*VO`
- 页面局部状态：`DataProps`
- 表格分页：`TablePage`
- 按钮项：`btnGroupItem`

例如：

- `UserVO`
- `StockAsnVO`
- `RoleMenuVO`
- `DataProps`

新增页面时，优先先补 `types/**`，再写组件逻辑。

### 3.4 页面脚本风格

当前管理页大多采用：

- `script setup`
- `TypeScript`
- `reactive({ ...data })`
- `reactive({ ...method })`
- 少量 `ref` 存放 table、dialog、child component 引用

也就是说，项目更偏向：

- 用 `data` 聚合状态
- 用 `method` 聚合行为
- 而不是把每个值都拆成非常细的 composable

新页面应优先延续该写法，除非出现明确复用需求。

### 3.5 列表页通用骨架

标准管理页通常包含：

1. `BtnGroup`
2. 搜索区域
3. `vxe-table`
4. `custom-pager`
5. `add-or-update-*.vue` 对话框

新增列表页时，优先复用已有组件：

- `BtnGroup`
- `tooltip-btn`
- `custom-pager`
- `SearchGroup`
- `NavList`
- `VxeDateColumn`
- `HoverImagePreview`

### 3.6 表单弹窗风格

新增“新增 / 编辑”弹窗时，优先沿用：

- 文件名：`add-or-update-xxx.vue`
- props：`showDialog`、`form`
- emits：`close`、`saveSuccess`
- 标题区：`v-toolbar color="white"`
- 表单校验：本地 rules + `formRef.validate()`
- 提交前：`removeObjectNull()`

### 3.7 搜索与自动刷新风格

当前项目的常用搜索模式：

- 页面维护 `searchForm`
- `watch(searchForm, { deep: true })`
- 防抖时间使用 `DEBOUNCE_TIME`
- 列表页通过 `setSearchObject()` 生成查询条件

如果某个新页面只是普通列表搜索，不要自己再写一套完全不同的搜索协议。

### 3.8 权限风格

当前按钮权限接入方式非常固定：

1. 页面 `authorityList: getMenuAuthorityList()`
2. toolbar 按钮通过 `BtnGroup`
3. 行内按钮通过 `tooltip-btn` 的 `disabled`
4. action code 在 `frontend/src/view/base/roleMenu/actionList.ts` 维护

新增按钮动作时，至少要同步：

- 页面 `btnList`
- `actionList.ts`
- 默认权限种子（通常是 `scripts/seeds/database_mysql.sql`）

### 3.9 菜单与路由风格

本项目的菜单不是纯前端静态路由，而是“数据库菜单 + 前端动态生成路由”。

新增页面如果希望登录后能看到，通常要同步更新：

- `menu` 数据初始化
- `UserService.Register()` 菜单初始化
- `frontend/src/utils/router/index.ts` 的名称 / 图标映射
- 相关 i18n 文案

只写 `src/view/...` 页面本身，不会自动出现在系统菜单中。

### 3.10 i18n 与文案风格

当前项目绝大多数显示文案都通过：

- 模板内：`$t('...')`
- 脚本内：`i18n.global.t('...')`

新增页面时：

- 优先补 i18n key
- 不要把按钮、弹窗、列标题长期硬编码在组件里
- 文件导出名、提示语、tab 名称也应尽量走 i18n

### 3.11 前端格式化与 lint 细节

当前前端已有明确的工具约束：

- ESLint 基于：TypeScript + Vue 3 + Airbnb Base
- Prettier 基于：
  - 单引号
  - 不加分号
  - `tabWidth = 2`
  - `printWidth = 150`
  - `trailingComma = none`
- `.eslintrc` 中的关键现状：
  - `camelcase` 关闭（因为项目大量使用 `snake_case`）
  - `@typescript-eslint/no-explicit-any` 关闭
  - `vue/html-indent = 2`
  - 多行模板属性尽量一行一个
- `tsconfig.json` 当前是 `strict: true`，但 `noImplicitAny: false`

因此新增前端代码应至少遵守：

- 默认单引号
- 默认不写分号
- 不要为了“看起来现代”强行把 API 字段名改成 camelCase
- 保持 `@/` 别名导入习惯

### 3.12 UX 反馈风格

当前统一使用：

- `hookComponent.$message()`：提示
- `hookComponent.$dialog()`：确认弹窗

不要在新增页面里临时发明第三套全局 message / modal 调用方式。

---

## 4. 新增页面 / 新增菜单的建议顺序

### 4.1 新增标准管理页

建议顺序：

1. 定义 `types/*`
2. 新增 `api/*`
3. 搭建 `view/*` 列表页
4. 补 `add-or-update-*` 弹窗
5. 补 i18n key
6. 补 `actionList.ts` 权限码
7. 补种子菜单 / 角色权限
8. 补 `utils/router/index.ts` 的菜单名和图标映射

### 4.2 新增需要出现在菜单中的模块

必须额外检查：

- `scripts/seeds/database_mysql.sql`
- `backend/ModernWMS.WMS/Services/User/UserService.cs`
- `frontend/src/utils/router/index.ts`
- `frontend/src/view/base/roleMenu/actionList.ts`

否则常见结果是：

- 页面文件已经存在，但用户登录后看不到菜单
- 菜单能显示，但没有按钮权限码
- 管理员新租户注册后没有该菜单

---

## 5. 当前应避免的新写法

在不做系统级重构的前提下，新增代码应尽量避免：

1. 在页面里直接写 axios
2. 新接口单独改成 `/api/v2/...` 风格
3. 把现有 `snake_case` 业务字段改成另一套命名
4. 引入与现有 `ResultModel<T>` 冲突的第二套响应包装
5. 仅在前端隐藏按钮，却不评估高风险接口的服务端授权需求
6. 新增菜单但不更新数据库种子与租户初始化逻辑
7. 新增变更型接口却不补 `systemLog.ts`，导致操作日志难以阅读
8. 在普通列表页中绕开 `custom-pager / BtnGroup / hookComponent` 重造基础组件

---

## 6. 一句话版本

如果要用一句话概括当前项目的风格，那就是：

> **后端保持“薄 controller + 厚 service + ResultModel + 手工 tenant 过滤”，前端保持“API 封装 + 类型先行 + data/method 页面结构 + 动态菜单权限 + 统一组件骨架”，新增代码优先兼容这套存量协作方式。**
