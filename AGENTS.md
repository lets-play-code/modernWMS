# ModernWMS Agent Guide

## 使用范围
- 默认工作目录：仓库根目录 `ModernWMS/`
- 本文件面向 **Agent 执行**，只保留高频、可操作、跨会话有价值的信息。
- 不要大段重复 `README`；需要对外说明时看 `README`，需要执行与定位时优先看本文件。

## Agent 快速入口 / 建议阅读顺序
1. `AGENTS.md`
2. `docs/README.md`
3. `.understand-anything/knowledge-graph.json`
4. `scripts/macos-dev.sh`
5. `docs/macOS-setup.md`
6. 启动入口：
   - `backend/ModernWMS/Program.cs`
   - `frontend/src/main.ts`
7. 再进入目标模块目录做局部阅读

如果任务是：
- **架构理解 / 影响分析 / onboarding / diff 理解**：先看 knowledge graph，再读代码
- **本地运行 / 端口 / 启动异常**：先看 `scripts/macos-dev.sh`
- **业务实现**：优先看 `backend/ModernWMS.WMS` 和 `frontend/src`

## 高价值路径 / 低价值路径

### 高价值路径
- `backend/ModernWMS`：后端宿主 / API 启动入口
- `backend/ModernWMS.Core`：共享基础设施（DBContext、JWT、Middleware、基类、通用模型等）
- `backend/ModernWMS.WMS`：WMS 业务域（Controllers / Services / Entities）
- `frontend/src`：前端应用源码
- `scripts`：开发/初始化/辅助脚本
- `docs`：补充文档（先看 `docs/README.md` 了解目录规范）

### 通常不应优先扫描的路径
除非任务明确涉及，否则不要把时间花在这些目录上：
- `frontend/node_modules`
- `frontend/dist`
- `backend/**/bin`
- `backend/**/obj`
- `.vs`
- `backend/.idea`
- `frontend/public/unity/Build`（通常是构建产物；只有处理 Unity/WebGL 资源问题时才进入）

## 大模块划分
- `backend/ModernWMS`
  - 后端启动项目 / API 宿主
  - 关注服务注册、配置装配、监听地址、启动流程
- `backend/ModernWMS.Core`
  - 后端共享基础设施
  - 包含控制器基类、数据库上下文、认证授权、中间件、通用模型、通用工具
- `backend/ModernWMS.WMS`
  - WMS 业务域实现
  - 重点看 `Controllers`、`Services`、`IServices`、`Entities`
- `frontend`
  - Vue 前端应用
  - 重点看 `src/api`、`src/router`、`src/store`、`src/view`、`src/components`
- `docker`
  - 容器化与部署相关文件
- `scripts`
  - 本地开发、数据库初始化、数据导入、辅助运行脚本
- `docs`
  - 文档入口见 `docs/README.md`
  - 长期文档按 `domain-model / software-design / requirements / development-standards` 分类
  - `docs/progress` 记录 `planned / active / archive` 三类进度文档
  - AI 工作流文档默认放 `docs/progress/planned/superpowers/...`，完成后归档到 `docs/progress/archive/...`

## 端口约定
默认本地端口：
- Frontend: `5173`
- Backend: `20011`
- MySQL: `33306`
- understand-anything Dashboard: `5673`（保留给 dashboard，不要占用 `5173`）

如果端口冲突，优先使用环境变量覆盖脚本参数，**不要先改源码或配置文件**。

例如：

```bash
MODERNWMS_BACKEND_PORT=22011 \
MODERNWMS_FRONTEND_PORT=5273 \
MODERNWMS_MYSQL_PORT=33316 \
./scripts/macos-dev.sh start
```

## 本地运行约定

### 首选：统一脚本
优先使用：

```bash
chmod +x ./scripts/macos-dev.sh
./scripts/macos-dev.sh start
```

常用命令：

```bash
./scripts/macos-dev.sh status
./scripts/macos-dev.sh logs
./scripts/macos-dev.sh stop
./scripts/macos-dev.sh reset-db
```

说明：
- 这是本仓库的首选开发入口。
- 脚本内部已经使用 `tmux` 管理前后端长运行进程。
- 如果只是常规本地调试，优先复用这套脚本，不要重复发明启动方式。

### 单独启动后端
只调试后端时：

```bash
cd backend/ModernWMS
env \
  Database__db=MySql \
  ConnectionStrings__MySqlConn="Server=127.0.0.1;Database=wms;Port=33306;charset=utf8;uid=root;pwd=123456;" \
  dotnet run --urls http://127.0.0.1:20011
```

### 单独启动前端
只调试前端时：

```bash
cd frontend
COREPACK_ENABLE_AUTO_PIN=0 \
VITE_BASE_PATH=http://127.0.0.1 \
VITE_SERVER_PORT=20011 \
yarn dev --host 127.0.0.1 --port 5173 --strictPort
```

补充：
- 前端使用 `Yarn Classic 1.x`
- 需要安装依赖时，优先使用：

```bash
cd frontend && COREPACK_ENABLE_AUTO_PIN=0 yarn install --ignore-engines --frozen-lockfile
```

## 常用验证命令
根据改动范围选择最小充分验证，不要无差别全量运行。**构建命令只能证明可编译，不能替代测试命令。**

### 后端单元测试
适用：service / core 复杂分支、边界条件、状态流转、库存计算等；验证点主要在后端内部逻辑，不需要真实 HTTP 或浏览器。

```bash
cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~<ServiceTests>"
```

### 后端 API E2E
适用：真实 HTTP 契约、Controller + Service + DB 联动、关键业务流程；验证点在 API 层，不需要浏览器 UI。

```bash
cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~<ContextOrFeature>"
```

### UI 驱动 E2E（Playwright）
适用：需要同时验证 **UI + API + DB** 正常协作；验证点在菜单 / 按钮权限、页面可达、前端展示语义、以及前后端一致性逻辑。它**不是“只是前端测试”**，而是包含真实 UI 的更大 E2E。

目标 spec：
```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/<spec>.ts)
./scripts/macos-dev.sh stop
```

全量 UI 回归：
```bash
./scripts/macos-dev.sh start
(cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e)
./scripts/macos-dev.sh stop
```

### 仅前端构建验证
适用：纯前端静态结构、类型或样式改动；**不能证明真实 API / 权限 / 路由链路正确**。

```bash
cd frontend && yarn build
```

### 仅后端构建验证
适用：确认后端可编译；**不能替代单元测试或 API E2E**。

```bash
cd backend && dotnet build ModernWMS.sln
```

### 启动脚本 / 端口 / 联调相关改动
适用：验证脚本、端口、服务拉起、登录链路与本地联调状态。

```bash
./scripts/macos-dev.sh status
```

必要时再看：
```bash
./scripts/macos-dev.sh logs
```

### 后端全量验证（含覆盖率，不含 UI）
适用：后端改动范围较大，或需要覆盖率验收。

```bash
./scripts/test-all.sh --skip-ui
```

### 全量验证（含 UI 驱动 E2E）
适用：需要后端测试、覆盖率、以及真实 UI 端到端一起通过。

```bash
./scripts/test-all.sh
```

## 手动启动长运行进程的约定
- 长运行命令必须放在 `tmux` 中
- 会话名使用项目前缀：`modernwms-*` 或 `pi-modernwms-*`
- 避免使用无前缀的通用名字如 `backend`、`frontend`

如果不是使用 `scripts/macos-dev.sh`，请至少遵守：

```bash
tmux new-session -d -s modernwms-backend "<command>"
tmux new-session -d -s modernwms-frontend "<command>"
```

## 开发时的优先理解路径
- 先看文档入口与目录规范：`docs/README.md`
- 看系统如何启动：`backend/ModernWMS/Program.cs`、`frontend/src/main.ts`
- 看后端公共能力：`backend/ModernWMS.Core`
- 看 WMS 业务：`backend/ModernWMS.WMS`
- 看前端页面流转：`frontend/src/router` → `frontend/src/view` → `frontend/src/api`
- 看环境与端口：`scripts/macos-dev.sh`、`docs/macOS-setup.md`

## 使用 understand-anything 管理项目知识
本项目使用 `understand-anything` 管理结构化项目知识。

知识文件：
- `.understand-anything/knowledge-graph.json`
- `.understand-anything/meta.json`
- `.understand-anything/fingerprints.json`
- `.understand-anything/.understandignore`

### 更新知识的命令
在仓库根目录内执行：

```text
/skill:understand
```

需要强制全量重建时：

```text
/skill:understand --full
```

如果只需要复查 / 重新校验图谱：

```text
/skill:understand --review
```

### 应触发知识更新的时间点
以下情况应主动更新：
- 新增、删除、重命名顶层目录或核心模块
- 后端启动方式、配置装配、数据库接入方式变化
- `Controllers / Services / Entities / Middleware / DBContext` 结构明显变化
- 前端 `router / store / api / view` 结构明显变化
- `docker/`、`scripts/`、部署入口、本地开发流程发生变化
- 大分支合并后，准备继续做架构理解、影响分析、onboarding、diff 分析之前

以下情况通常不用立即更新：
- 文案改动
- 不改变结构的细小逻辑修复
- 纯注释、纯格式、少量样式改动

### 使用图谱的工作习惯
- 在做全局理解前，先看 `.understand-anything/knowledge-graph.json`
- 如果 `meta.json` 中的 `gitCommitHash` 与当前 `HEAD` 不一致，并且任务依赖结构理解，先更新图谱
- 做架构说明、模块关系说明、影响范围分析时，优先基于图谱而不是重新全仓扫描
- 如果图谱与代码明显不一致，先更新图谱，再继续分析

### 提交约定
如果本次改动**明确影响结构化知识**，应一并提交：
- `.understand-anything/knowledge-graph.json`
- `.understand-anything/meta.json`
- `.understand-anything/fingerprints.json`
- `.understand-anything/.understandignore`（如果有调整）

如果改动不影响项目结构知识，不要为了“顺手”重写图谱并提交噪音变更。

## understand-anything Dashboard 端口约定
- **不要占用 `5173`**；该端口留给项目 `frontend` 开发服务器
- Dashboard 固定使用：`5673`
- **不要直接使用默认的 `/skill:understand-dashboard` 启动方式**；默认方式会优先尝试 `5173`，与本项目前端冲突

推荐在仓库根目录执行：

```bash
PROJECT_DIR="$(pwd)"
LOG_FILE="/tmp/pi-modernwms-understand-dashboard.log"
tmux new-session -d -s pi-modernwms-understand-dashboard \
  "cd $HOME/.understand-anything-plugin/packages/dashboard && GRAPH_DIR=$PROJECT_DIR npx vite --host 127.0.0.1 --port 5673 2>&1 | tee $LOG_FILE"
```

查看 token URL：

```bash
python3 - <<'PY'
import re
from pathlib import Path
text = Path('/tmp/pi-modernwms-understand-dashboard.log').read_text(errors='ignore')
matches = re.findall(r'http://127\.0\.0\.1:5673/?\?token=[^\s]+', text)
print(matches[-1] if matches else '')
PY
```

停止 dashboard：

```bash
tmux kill-session -t pi-modernwms-understand-dashboard
```

## 协作建议
- 对本仓库做结构说明时，优先按“后端宿主 / 共享基础设施 / WMS 业务域 / 前端应用 / 环境脚本 / 知识图谱”来组织
- 先用知识图谱缩小范围，再读具体文件
- 不要把 README 大段搬运到输出；AGENTS 负责执行效率，README 负责项目介绍
