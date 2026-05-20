# 开发规范

本目录存放跨需求复用的研发规范，关注“以后都应该怎么做”。

## 当前文档

- `frontend-conventions.md`：前端目录结构、API 封装、页面骨架、权限接入、i18n 与代码风格约定
- `backend-conventions.md`：后端分层、控制器 / 服务职责、分页搜索、租户、日志与接口契约约定
- `testing-conventions.md`：测试分层、API E2E / BDD DSL、测试数据准备、结构化断言与覆盖率约定
- `frontend-backend-conventions.md`：前后端规范导览页，兼容旧链接并指向拆分后的专题文档
- `ai-collaboration-sop/README.md`：AI 协作 project skills 索引与详细 SOP 参考，映射到 `.pi/skills/` 下的需求分析 / 需求变更 / 后端与前端实现 / 功能变更 / 代码重构 skills

## 建议放置的内容

- 代码风格
- 数据库设计风格
- 跨需求公共检查项
- 测试设计规范
- 接口兼容性约束
- 发布前检查清单
- AI / 人机协作的标准作业流程（SOP）

## 写作要求

- 优先写可执行、可检查的规则
- 避免只对单次需求有效的临时说明
- 若规范已经稳定，应优先更新已有规范文档，而不是重复新增
- 流程性规范如果需要多篇文档，优先使用目录索引模式，例如 `ai-collaboration-sop/README.md`
