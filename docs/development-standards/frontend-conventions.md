# ModernWMS 前端开发规范

> 本文总结当前仓库前端已经稳定形成的工程约定，目标是让新增页面、弹窗、列表、菜单与现有系统保持一致，而不是在局部突然引入另一套写法。
>
> 这是一份**基于当前代码库真实实现**整理出来的规范，不是脱离存量系统的理想化重构方案。

主要分析依据：
- `frontend/package.json`
- `frontend/.eslintrc`
- `frontend/.prettierrc.json`
- `frontend/tsconfig.json`
- `frontend/src/view/home/*`
- `frontend/src/view/base/**/*`
- `frontend/src/view/wms/**/*`
- `frontend/src/view/warehouseWorking/**/*`
- `frontend/src/view/deliveryManagement/**/*`
- `frontend/src/view/statisticAnalysis/**/*`
- `frontend/src/components/system/*`
- `frontend/src/components/custom-pager.vue`
- `frontend/src/components/tooltip-btn.vue`
- `frontend/src/utils/http/request.ts`
- `frontend/src/utils/router/index.ts`
- `frontend/src/utils/systemLog.ts`

相关文档：
- 后端开发规范：`./backend-conventions.md`
- API 设计：`../software-design/api-design.md`
- UI / UX 风格规范：`../software-design/ui-ux-style-guide.md`

---

## 1. 总体原则

1. **优先贴合现有页面骨架，不先为“更现代”而重写结构。**
2. **新增功能先补类型、API 封装、i18n，再写页面交互。**
3. **业务字段优先保持现有 `snake_case`，不要在前端局部改造成 camelCase。**
4. **页面尽量复用现有通用组件，而不是为单页再造按钮组、分页器、对话框封装。**
5. **新增页面不仅要能跑，还要接入菜单、权限、日志、文案和导出习惯。**

---

## 2. 技术栈与目录分工

当前前端主栈：
- Vue 3
- TypeScript
- Vite
- Vuetify 3
- VXETable
- Vue Router 4
- Vuex 4
- Vue I18n
- Axios

当前稳定目录分工：

```text
frontend/src/
├── api/          # 接口封装
├── components/   # 可复用组件
├── constant/     # 常量、颜色、表格配置
├── languages/    # i18n 文案与语言切换
├── router/       # 路由入口
├── store/        # Vuex 状态
├── types/        # TS 类型定义
├── utils/        # 请求、路由转换、格式化、日志等工具
└── view/         # 页面实现
```

新增页面通常至少会同步涉及：
- `src/view/...`
- `src/api/...`
- `src/types/...`
- `src/languages/...`

如果页面需要登录后出现在菜单中，还要额外检查：
- `frontend/src/utils/router/index.ts`
- `frontend/src/view/base/roleMenu/actionList.ts`
- `scripts/seeds/database_mysql.sql`
- `backend/ModernWMS.WMS/Services/User/UserService.cs`

---

## 3. API 调用与数据契约

### 3.1 页面不要直接写 axios

统一做法：
- 在 `src/api/**` 中封装请求函数
- 页面中只 import API 方法并消费返回值

当前常见调用方式：

```ts
const { data: res } = await someApi(params)
```

原因：
- `src/utils/http/request.ts` 已统一处理 `baseURL`
- 自动注入 `Authorization`
- 自动附加 `culture`
- 自动处理 token 刷新
- 自动发送页面操作日志头 `X-Vue-Path` / `X-Action-Content`
- 统一 loading 与错误提示

### 3.2 保持现有响应读取方式

当前请求封装返回的仍然接近 `AxiosResponse`，因此新增代码不要自行改成另一套 `await api().then(res => res.data.data)` 读取风格。

### 3.3 分页与查询遵循现有契约

列表查询通常围绕以下结构：
- `pageIndex`
- `pageSize`
- `searchObjects`
- 可选 `sqlTitle`

前端对应类型通常放在：
- `TablePage`
- `PageConfigProps`
- `SearchObject`

如果页面已有 `setSearchObject()` 可满足需求，优先复用，不要再定义第三套查询协议。

### 3.4 变更型接口要补操作日志文案

`request.ts` 会自动从 `parseOperation(config)` 生成操作描述。

因此新增会写库的前端 API 时，要同步维护：
- `frontend/src/utils/systemLog.ts`

否则系统日志里虽然会记录请求，但缺少对业务用户可读的操作描述。

---

## 4. 类型、命名与脚本组织

### 4.1 类型命名惯例

当前项目较稳定的命名方式：
- 单条业务对象：`*VO`
- 页面状态：`DataProps`
- 表格分页：`TablePage`
- 按钮项：`btnGroupItem`

新增页面建议先定义类型，再写页面逻辑。

### 4.2 业务字段命名

当前系统前后端协作的关键现实是：
- TypeScript 接口名、文件名：PascalCase
- 业务字段：大量保留数据库式 `snake_case`

例如：
- `CompanyVO`
- `company_name`
- `goods_owner_id`

因此新增前端类型时：
- **不要擅自把接口字段整体转成 camelCase**
- **不要为了局部“好看”而引入二次映射层**

### 4.3 页面脚本组织风格

当前管理页主流写法是：
- `script setup`
- `lang="ts"`
- `reactive({ ...data })` 聚合状态
- `reactive({ ...method })` 聚合行为
- `ref()` 主要用于表格、表单、弹窗、子组件引用

新增页面时，优先延续这种结构；只有出现明确跨页复用价值时，再抽公共 composable。

---

## 5. 页面骨架约定

### 5.1 后台壳层布局

后台壳层由以下部分组成：
- `HomeSideBar`
- `HomeHeader`
- `RouterView + keep-alive`

新增业务页面默认挂在这套壳层下，不要绕开 `home.vue` 单独造后台布局。

### 5.2 标准列表页骨架

当前多数后台页面共享以下结构：

1. 顶部操作区 `operateArea`
2. 左侧 `BtnGroup`
3. 右侧搜索区域或 `SearchGroup`
4. `v-card > v-card-text`
5. `vxe-table`
6. `custom-pager`
7. `add-or-update-*.vue` 对话框

如果是普通台账页，优先按这套骨架落地。

### 5.3 Tab / 流程型页面

入库、出库、库内作业中的流程页通常采用：
- `v-tabs`
- `v-window`
- 子 Tab 组件 `ref`
- 切换时 `nextTick()` 调用子组件的 `getXxx()` / `list()` 方法

因此新增流程页时，优先复用“父页面切 tab，子页面负责本 tab 数据加载”的模式。

### 5.4 高度计算方式

多数表格页不直接写死高度，而是复用：
- `computedCardHeight()`
- `computedTableHeight()`
- `SYSTEM_HEIGHT`

不要在单个页面里随意再写一套固定高度常量，优先先看 `src/constant/style.ts` 能否满足。

---

## 6. 搜索、表格、分页与导出

### 6.1 搜索习惯

当前项目主流搜索模式：
- 页面维护 `searchForm`
- 通过 `watch(searchForm, { deep: true })` 做自动查询
- 防抖时间使用 `DEBOUNCE_TIME`
- 复杂列表可复用 `SearchGroup`

如果只是常规列表筛选，不要重新发明新的查询交互。

### 6.2 表格习惯

当前主流表格组件是 `vxe-table`。

常见列顺序：
1. `seq`
2. `checkbox`（如需批量操作）
3. 业务列
4. `operate`

常见约定：
- 空数据提示统一走 `system.page.noData`
- 日期列优先复用 `vxe-date-column`
- 行内危险操作使用 `mdi-delete-outline` + `errorColor`
- 有权限但当前状态不可执行时，优先禁用按钮，而不是静默移除

### 6.3 分页习惯

统一复用 `custom-pager` 与：
- `PAGE_SIZE`
- `DEFAULT_PAGE_SIZE`
- `PAGE_LAYOUT`

不要单页临时换成另一套分页组件。

### 6.4 导出习惯

表格导出统一走 `exportData()`。

导出时通常会排除：
- `checkbox`
- `operate`

如果页面有“导出全部”，当前常用做法是：
- 临时以 `pageIndex = 0`、`pageSize = 0` 拉全量数据
- 替换表格数据导出后再恢复页面数据

---

## 7. 弹窗、表单与反馈

### 7.1 弹窗组件命名与通信

新增新增/编辑弹窗时，优先沿用：
- 文件名：`add-or-update-xxx.vue`
- props：`showDialog`、`form`
- emits：`close`、`saveSuccess`

### 7.2 表单写法

当前常见表单习惯：
- `v-form` + `formRef.validate()`
- `variant="outlined"`
- 本地 `rules` 数组校验
- 提交前调用 `removeObjectNull()`

不要把表单校验散落到按钮点击逻辑里手写 if/else。

### 7.3 用户反馈

统一使用：
- `hookComponent.$message()`
- `hookComponent.$dialog()`

不要在新页面里再接入另一套全局 message / confirm 机制。

---

## 8. 菜单、权限与路由

### 8.1 动态路由是默认模式

当前不是“前端静态路由写完即可上线”的模式，而是：
- 后端返回菜单权限
- 前端把菜单转成动态路由与侧边栏

因此新增页面如果要让用户登录后可见，不能只创建 `src/view/...` 文件，还必须评估菜单初始化和路由映射。

### 8.2 按钮权限接入方式

当前稳定模式：
1. 页面通过 `getMenuAuthorityList()` 获取 `authorityList`
2. 顶部操作按钮交给 `BtnGroup`
3. 行内按钮通过 `tooltip-btn` 的 `disabled` 控制
4. action code 在 `frontend/src/view/base/roleMenu/actionList.ts` 中维护

新增动作时，至少检查：
- `btnList`
- `actionList.ts`
- 菜单种子数据

#### 8.2.1 权限 UI 测试钩子约定

为了让 Playwright 权限测试保持稳定，涉及菜单和按钮权限的前端代码要额外遵守下面的测试钩子约定：

- **侧边栏菜单项**
  - 可断言的菜单入口应输出 `data-menu-path="<vue_path>"`
  - 这个值必须直接对应真实菜单路径，例如 `stockAsn`、`warehouseSetting`、`deliveryManagement`
- **`tooltip-btn` 按钮**
  - 按钮应输出 `aria-label`，默认复用已有 tooltip 文案
  - 允许可选输出 `data-auth-code`
  - 这些钩子只用于稳定定位，不改变业务语义
- **`BtnGroup` 顶部操作按钮**
  - 当 `btnList` 中存在 `code` 时，必须把该 `code` 透传给 `tooltip-btn` 的 `data-auth-code`
  - 这样权限套件可以稳定断言顶部按钮的 visible / enabled / disabled 状态
- **行内按钮**
  - 优先复用 `tooltip-btn + aria-label + 行级作用域` 断言
  - 只有在失败测试证明不够稳定时，才给个别页面补额外最小钩子
- **菜单种子数据**
  - 如果新增了真实可达菜单，除了路由和页面，还必须同步更新：
    - `scripts/seeds/database_mysql.sql`
    - `backend/ModernWMS.WMS/Services/User/UserService.cs`
  - 否则默认开发环境与新租户初始化会出现菜单漂移

### 8.3 i18n 是默认要求

当前页面绝大多数文案都通过：
- 模板：`$t('...')`
- 脚本：`i18n.global.t('...')`

新增页面时：
- 按钮文字
- 表格列标题
- 弹窗标题
- 导出文件名
- 提示语
- tab 标题

都应优先走 i18n，而不是直接硬编码。

---

## 9. 格式化与代码风格细节

当前前端已有明确配置：
- 默认单引号
- 默认不加分号
- `tabWidth = 2`
- `printWidth = 150`
- `trailingComma = none`
- 使用 `@/` 路径别名

ESLint 现状也反映了存量系统特点：
- `camelcase` 关闭
- `@typescript-eslint/no-explicit-any` 关闭
- `vue/html-indent = 2`
- `strict: true`，但 `noImplicitAny: false`

新增代码应优先与现有配置对齐，而不是在个别文件里体现另一套格式偏好。

---

## 10. 新增页面最小检查清单

### 10.1 普通列表页

至少检查：
- [ ] 补 `src/types/**`
- [ ] 补 `src/api/**`
- [ ] 页面采用现有列表页骨架
- [ ] 搜索与分页沿用现有模式
- [ ] 提示、确认框走 `hookComponent`
- [ ] 文案走 i18n
- [ ] 导出使用 `exportData()`

### 10.2 需要出现在菜单中的页面

还要额外检查：
- [ ] `frontend/src/utils/router/index.ts`
- [ ] `frontend/src/view/base/roleMenu/actionList.ts`
- [ ] `scripts/seeds/database_mysql.sql`
- [ ] `backend/ModernWMS.WMS/Services/User/UserService.cs`

### 10.3 写操作页面

还要额外检查：
- [ ] `src/utils/systemLog.ts` 是否补了可读日志
- [ ] 是否按权限禁用高风险操作按钮
- [ ] 是否沿用现有对话框和表单提交方式

---

## 11. 当前应避免的新写法

1. 在页面里直接写 axios
2. 仅为单页喜好重做状态组织方式
3. 把既有 `snake_case` 接口字段改成 camelCase 再映射回去
4. 在普通列表页绕过 `BtnGroup / custom-pager / tooltip-btn / SearchGroup`
5. 新增页面文件后，不同步菜单、权限和种子数据
6. 新增写操作但不补 `systemLog.ts`
7. 大量硬编码按钮、表头、提示语
8. 在桌面后台页面里引入与现有 UI 风格割裂的新主题

---

## 12. 一句话版本

> ModernWMS 前端的核心约定是：**API 封装、类型先行、`script setup + TypeScript`、列表页统一骨架、动态菜单权限、全局 i18n 与统一消息反馈**。新增页面优先兼容这套存量协作方式。