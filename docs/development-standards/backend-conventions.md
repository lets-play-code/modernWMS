# ModernWMS 后端开发规范

> 本文总结当前仓库后端已经稳定形成的实现约定，目标是让新增接口、服务、DTO、日志与权限接入方式保持一致，而不是在单个模块突然切换到另一种架构风格。
>
> 这是一份**基于当前代码库真实实现**整理出来的规范，不是理想化重构清单。

主要分析依据：
- `backend/ModernWMS/Startup.cs`
- `backend/ModernWMS.Core/Extentions/StartupExtensions.cs`
- `backend/ModernWMS.Core/Controller/BaseController.cs`
- `backend/ModernWMS.Core/Models/*`
- `backend/ModernWMS.Core/Middleware/*`
- `backend/ModernWMS.Core/Filters/ApiLogFilter.cs`
- `backend/ModernWMS.Core/Services/*`
- `backend/ModernWMS.WMS/Controllers/**/*`
- `backend/ModernWMS.WMS/IServices/**/*`
- `backend/ModernWMS.WMS/Services/**/*`
- `backend/ModernWMS.WMS/Entities/ViewModels/**/*`

相关文档：
- 前端开发规范：`./frontend-conventions.md`
- API 设计：`../software-design/api-design.md`
- UI / UX 风格规范：`../software-design/ui-ux-style-guide.md`

---

## 1. 总体原则

1. **保持“薄 Controller + 厚 Service”的现有分层。**
2. **优先复用现有基础设施，不在局部新造 repository / unit of work / response wrapper。**
3. **新增接口默认要显式考虑租户隔离，而不是假设系统会自动过滤。**
4. **接口契约优先兼容现有前端和数据库字段命名。**
5. **校验、日志、本地化、分页、动态搜索都应接入现有统一机制。**

---

## 2. 解决方案结构与职责边界

后端当前稳定结构：

```text
backend/
├── ModernWMS/        # 宿主、启动、配置、Swagger、中间件装配
├── ModernWMS.Core/   # 基础设施：JWT、DBContext、公共模型、过滤器、中间件、工具类
└── ModernWMS.WMS/    # 业务实现：Controller / Service / Entity / ViewModel
```

业务模块内部常见目录：

```text
Controllers/
IServices/
Services/
Entities/Models/
Entities/ViewModels/
```

职责约定：
- `Controller`：接参、调用 service、包装 `ResultModel<T>`
- `Service`：业务规则、查询组合、状态流转、租户过滤
- `Entities/Models`：数据库实体
- `Entities/ViewModels`：接口输入输出模型

新增模块优先延续这套目录划分，不要为了单个需求改造成新的模块组织方式。

---

## 3. 依赖注入与接口组织

当前依赖注入依赖以下机制：
- `IBaseService<TEntity>` 继承 `IDependency`
- `StartupExtensions.RegisterAssembly()` 会扫描 `ModernWMS*.dll`
- 实现类与接口会按现有规则自动注册为 `Scoped`

因此新增业务 service 时，建议：
- 接口放在 `IServices/...`
- 接口继承 `IBaseService<TEntity>`
- 实现类放在 `Services/...`
- 实现类实现对应接口

这样可以继续复用当前自动注册机制。

---

## 4. Controller 规范

### 4.1 控制器基础写法

新增控制器时，优先贴近现有风格：
- 继承 `BaseController`
- 使用 `[Route("resource")]`
- 使用 `[ApiController]`
- 使用 `[ApiExplorerSettings(GroupName = "Base" | "WMS")]`
- 构造函数注入对应 service 与 `IStringLocalizer<MultiLanguage>`
- 返回 `Task<ResultModel<T>>`

### 4.2 控制器职责边界

Controller 应主要负责：
- 接收参数
- 读取 `CurrentUser`
- 调用 service
- 按成功/失败包装 `ResultModel<T>`

不要在 controller 中：
- 写大段业务规则
- 手工拼复杂查询
- 自己维护数据库事务细节
- 返回裸对象或多套响应格式

### 4.3 当前接口风格现实

当前代码库的真实接口风格不是严格 REST，而是：
- 资源前缀直接暴露，如 `/company`、`/dispatchlist`
- 列表分页常用 `POST /resource/list`
- 删除和详情常通过 query 参数传主键
- 流程命令常用“资源 + 动作子路由”，如 `/asn/confirm`、`/dispatchlist/package`

因此新增接口时，应优先挂到现有资源前缀下，保持同域一致性。

---

## 5. Service 规范

### 5.1 数据访问方式

当前 service 层主流做法：
- 构造函数直接注入 `SqlDBContext`
- 通过 `_dBContext.GetDbSet<TEntity>()` 获取实体集合
- 读操作优先 `AsNoTracking()`
- 删除场景可直接使用 `ExecuteDeleteAsync()`

新增 service 时，优先沿用这种方式，不要在局部突然引入新的 ORM 包装层。

### 5.2 查询与投影

当前查询习惯：
- 简单实体 / ViewModel 转换可用 `Mapster.Adapt()`
- 复杂列表、关联查询、派生字段优先手写 LINQ 投影
- 查询结果通常先做 tenant 过滤，再套动态搜索表达式

当 DTO 只是实体字段平移时，`Adapt()` 足够；当存在 join、状态衍生、汇总字段时，应直接手写投影，保持查询意图清晰。

### 5.3 常见返回约定

当前 service 方法常见返回形式：
- 分页：`(List<T> data, int totals)`
- 新增：`(int id, string msg)`
- 更新 / 删除 / 命令：`(bool flag, string msg)`

新增 service 建议继续沿用这组 tuple 风格，避免同仓库出现多套成功/失败约定。

### 5.4 时间与租户字段

新增写操作时，通常要显式处理：
- `create_time`
- `last_update_time`
- `tenant_id`

不要假设这些字段会由框架自动填充。

---

## 6. 分页、搜索与查询契约

当前分页查询统一围绕：
- `PageSearch`
- `PageData<T>`
- `SearchObject`
- `QueryCollection`

典型模式：
1. 把 `pageSearch.searchObjects` 加入 `QueryCollection`
2. 拼接基础查询
3. 显式加 `tenant_id` 条件
4. `CountAsync()` 取总数
5. 根据 `pageIndex` / `pageSize` 做分页
6. 返回 `PageData<T> { Rows, Totals }`

新增分页接口时，不要自造另一套分页响应结构。

---

## 7. 租户、认证与权限

### 7.1 当前用户来源

`BaseController.CurrentUser` 会从 JWT 中解析当前用户。

因此新增 service 方法如果涉及租户数据边界，通常应接收 `CurrentUser currentUser` 参数。

### 7.2 租户隔离是显式实现，不是自动能力

当前系统不是自动多租户过滤，而是：
- controller 读取 `CurrentUser`
- service 手工使用 `currentUser.tenant_id`
- 查询 / 写入都显式带租户条件

因此新增接口时必须检查：
- 是否只读取当前租户数据
- 是否把 `tenant_id` 写入新记录
- 是否在关联查询里遗漏租户过滤

### 7.3 权限现实

当前按钮权限主要由前端菜单 / action code 控制，后端并没有普遍覆盖到细粒度业务授权。

因此对于高风险操作，新增接口时要主动评估：
- 前端隐藏按钮是否足够
- 是否需要在 service 层补更强的业务判断

---

## 8. ViewModel、命名与序列化

### 8.1 命名现实

当前项目的稳定现状是：
- C# 类型名 / 文件名 / 方法名：PascalCase
- 大量业务属性名：`snake_case`

例如：
- `CompanyController`
- `CompanyViewModel`
- `company_name`
- `goods_owner_id`

新增 DTO 或实体属性时，除非会系统性重构前后端契约，否则不要局部改成另一套命名体系。

### 8.2 ViewModel 校验

当前输入校验主要依赖：
- `Display`
- `Required`
- `MaxLength`
- `DataType`

模型错误统一由 `ViewModelActionFiter` 收敛，而不是每个 controller 重复手写 `ModelState` 判断。

### 8.3 序列化规则

当前控制器通过 `AddNewtonsoftJson()` 使用：
- `CamelCasePropertyNamesContractResolver`
- `yyyy-MM-dd HH:mm:ss` 日期格式
- `JsonStringTrimConverter`

这意味着：
- `ResultModel<T>.IsSuccess` 会序列化为 `isSuccess`
- `PageData<T>.Rows` 会序列化为 `rows`
- DTO 中本身已经是 `snake_case` 的业务字段会继续保持 `snake_case`

这也是前端同时看到 `isSuccess` 与 `tenant_id` 的原因。

---

## 9. 日志、本地化与中间件

### 9.1 本地化

当前控制器和 service 普遍注入：
- `IStringLocalizer<ModernWMS.Core.MultiLanguage>`

新增错误信息、存在性提示、保存结果时，优先复用已有本地化资源，而不是直接硬编码中文或英文。

### 9.2 已存在的日志能力

当前至少有三层日志相关能力：
1. `ApiLogFilter`：记录 API 请求与结果
2. `RequestResponseMiddleware`：记录请求耗时，并落页面操作日志
3. `ActionLogService` / `RequestLogger`：保存页面行为日志

因此新增接口时：
- 一般不需要再造一套请求审计框架
- 如果是用户可见的重要变更操作，应确保前端补了 `systemLog.ts` 对应文案

### 9.3 中间件与统一能力

当前全局链路中已统一接入：
- JWT 鉴权
- Swagger
- 全局异常处理
- Request / Response 日志
- 模型校验过滤器
- 本地化

新增接口应尽量复用这些已有能力，而不是在控制器内部再写一套重复逻辑。

---

## 10. 新增后端能力时必须同步关注的文件

如果是一个真正的新业务能力，通常至少会涉及：
- `backend/ModernWMS.WMS/Controllers/...`
- `backend/ModernWMS.WMS/IServices/...`
- `backend/ModernWMS.WMS/Services/...`
- `backend/ModernWMS.WMS/Entities/ViewModels/...`
- 必要时 `backend/ModernWMS.WMS/Entities/Models/...`

如果能力要在前端菜单中可见，还要额外检查：
- `scripts/seeds/database_mysql.sql`
- `backend/ModernWMS.WMS/Services/User/UserService.cs`
- `frontend/src/utils/router/index.ts`
- `frontend/src/view/base/roleMenu/actionList.ts`

---

## 11. 新增接口最小检查清单

- [ ] 路由是否挂在现有资源前缀下
- [ ] controller 是否继承 `BaseController`
- [ ] 返回是否统一包在 `ResultModel<T>` 中
- [ ] 分页是否复用 `PageSearch / PageData<T>`
- [ ] service 是否显式处理 `tenant_id`
- [ ] 读操作是否优先 `AsNoTracking()`
- [ ] DTO 是否补了 DataAnnotations 校验
- [ ] 错误消息是否走 `IStringLocalizer`
- [ ] 若有前端菜单或按钮，是否同步补种子、权限与路由映射
- [ ] 若是变更型操作，前端是否补了操作日志文案

---

## 12. 当前应避免的新写法

1. 在局部模块引入全新的 repository / unit of work 风格
2. controller 直接承载业务规则、状态流转或复杂查询
3. 返回裸对象、`IActionResult` 杂糅多种结构，绕开 `ResultModel<T>`
4. 新接口单独切到完全不同的路由语义体系
5. 忽略 `tenant_id` 过滤，假设系统会自动隔离
6. 跳过 DataAnnotations 与统一模型校验
7. 用硬编码字符串替代本地化错误消息
8. 仅做前端按钮隐藏，却不评估高风险操作的服务端防护需求

---

## 13. 一句话版本

> ModernWMS 后端的核心约定是：**薄 Controller、厚 Service、`SqlDBContext` 直连、`ResultModel<T>` / `PageData<T>` 统一契约、显式租户过滤、DataAnnotations 校验、本地化消息与现有日志链路复用**。新增接口优先兼容这套存量实现方式。