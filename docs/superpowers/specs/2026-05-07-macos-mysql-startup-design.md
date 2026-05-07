# macOS 快速启动切换为脚本托管 Docker MySQL 设计说明

## 背景

当前仓库中的 SQLite 样例库 `backend/ModernWMS/wms.db` 已落后于当前后端代码使用的表结构，导致登录后的权限接口 `/rolemenu/authority` 查询失败。用户希望保留 `scripts/macos-dev.sh` 作为唯一启动入口，但不再手工安装、配置或导入 MySQL。

## 目标

- 保留 `scripts/macos-dev.sh` 作为 macOS 本地启动入口。
- 由脚本自动托管一个 Docker MySQL 容器与持久化数据卷。
- 由脚本自动下载并导入官方 MySQL 初始化脚本。
- 启动后端时通过环境变量覆盖数据库配置，不修改仓库中的 `appsettings.json`。
- `stop` 只停前后端，不停止 MySQL。
- `reset-db` 彻底重建脚本管理的 MySQL 数据并恢复初始状态。

## 方案

### 数据库资源

脚本管理以下默认资源：

- MySQL 镜像：`docker.m.daocloud.io/library/mysql:8.0`
- MySQL 容器：`modernwms-macos-mysql`
- MySQL 数据卷：`modernwms-macos-mysql-data`
- MySQL 端口：`33306`
- 数据库名：`wms`

资源名与端口允许通过环境变量覆盖，以便测试或多实例隔离。

### 启动流程

`./scripts/macos-dev.sh start` 的流程：

1. 校验 `docker`、`tmux`、`dotnet`、`node`、`yarn`、`python3` 等依赖。
2. 启动或复用脚本管理的 Docker MySQL 容器。
3. 检查目标 schema 是否已初始化；如果未初始化，则下载并导入官方 SQL：
   `https://modernwms.ikeyly.com/assets/staticFile/database_mysql.sql`
4. 使用环境变量覆盖后端配置：
   - `Database__db=MySql`
   - `ConnectionStrings__MySqlConn=...`
5. 启动前端与后端 tmux 会话。
6. 校验 `/hello-world`、`/login`、`/rolemenu/authority`，只有链路可用才报告成功。

### stop / reset-db

- `stop`：只停止前后端 tmux 会话，保持 MySQL 容器继续运行。
- `reset-db`：
  1. 停止前后端
  2. 删除脚本管理的 MySQL 容器
  3. 删除脚本管理的数据卷
  4. 重新创建 MySQL 容器
  5. 重新导入官方 SQL
  6. 保持 MySQL 容器继续运行

### 文档

更新以下文档，使其与脚本行为一致：

- `README.zh_CN.md`
- `README.md`
- `docs/macOS-setup.md`

## 验收标准

1. `./scripts/macos-dev.sh start` 无需手工配置 MySQL。
2. 首次启动会自动创建 Docker MySQL 并导入初始化 SQL。
3. `admin / 1` 可以完成完整登录链路。
4. `./scripts/macos-dev.sh stop` 后 MySQL 容器仍然运行。
5. `./scripts/macos-dev.sh reset-db` 后数据库恢复到初始种子状态。
