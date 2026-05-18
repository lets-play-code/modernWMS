# ModernWMS 前后端开发规范导览

> 旧的合并文档已经按职责拆分，保留本文件作为兼容入口，避免已有引用失效。

## 推荐阅读顺序

1. 前端开发规范：`./frontend-conventions.md`
2. 后端开发规范：`./backend-conventions.md`
3. UI / UX 风格规范：`../software-design/ui-ux-style-guide.md`
4. API 设计与协作约定：`../software-design/api-design.md`

## 一句话概括

- 前端：**API 封装 + 类型先行 + 统一列表/弹窗骨架 + 动态菜单权限 + i18n**
- 后端：**薄 Controller + 厚 Service + `ResultModel<T>` / `PageData<T>` + 手工 tenant 过滤 + DataAnnotations 校验**
- UI / UX：**桌面优先、浅色后台、紫色品牌强调、表格为中心的高信息密度管理界面**

## 使用方式

- 需要新增页面、弹窗、菜单、权限时，优先查看：`frontend-conventions.md`
- 需要新增接口、服务、DTO、日志时，优先查看：`backend-conventions.md`
- 需要保持页面视觉与交互一致时，优先查看：`../software-design/ui-ux-style-guide.md`

## 迁移说明

后续如果要更新规范，请直接修改拆分后的专题文档，而不是再把规则混写回本文件。
