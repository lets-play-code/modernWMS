# ModernWMS macOS 配置与快速启动说明

> 本文档提供 **macOS 本地开发 / 本地体验** 的快速启动方式。它是对仓库现有 Linux / Windows 文档的补充，**不会替代现有启动命令**。

## 适用场景

- 想在 macOS 上快速启动 ModernWMS 前后端
- 不想手工安装、配置或导入本地 MySQL
- 希望通过一个脚本统一管理启动、停止、日志和数据库重置

## 方案说明

`scripts/macos-dev.sh` 现在会自动托管一个 **Docker MySQL** 开发数据库，并在启动后端时通过环境变量覆盖数据库配置。

脚本会做这些事：

1. 检查 `tmux`、`docker`、`dotnet`、`node`、`yarn`、`python3` 是否可用
2. 自动拉起或复用脚本管理的 Docker MySQL 容器
3. 如果数据库未初始化，自动导入仓库内置的官方 MySQL 初始化脚本
4. 通过环境变量覆盖后端数据库配置，不修改仓库里的 `appsettings.json`
5. 通过 `tmux` 在后台启动后端和前端
6. 在启动后执行登录链路检查：`/login` + `/rolemenu/authority`

默认资源：

- MySQL 镜像：`docker.m.daocloud.io/library/mysql:8.0`
- MySQL 容器：`modernwms-macos-mysql`
- MySQL 数据卷：`modernwms-macos-mysql-data`
- MySQL 端口：`33306`
- 数据库名：`wms`

## 前置依赖

建议准备以下工具：

- `tmux`
- `Docker Desktop`（或可用的 Docker daemon）
- `.NET SDK`（推荐 7.x，或已验证可构建 `net7.0` 的兼容版本）
- `Node.js`
- `Yarn Classic 1.x`
- `Python 3`

### 参考安装方式

#### 1. 安装 tmux

```bash
brew install tmux
```

#### 2. 安装 Docker Desktop

- https://www.docker.com/products/docker-desktop/

安装后请确认 Docker daemon 已启动：

```bash
docker info
```

#### 3. 安装 Node.js / Yarn（推荐使用 asdf）

如果你使用 `asdf`，仓库根目录已经提供 `.tool-versions`，推荐直接在仓库根目录执行：

```bash
asdf plugin add nodejs   # 首次使用时执行一次
asdf plugin add yarn     # 首次使用时执行一次
asdf install
```

当前仓库固定版本：

- `nodejs 22.12.0`
- `yarn 1.22.22`

如果 `asdf install` 在安装 Yarn 时提示缺少 `gpg`，先执行：

```bash
brew install gnupg
```

如果你不使用 `asdf`，也可以继续用自己熟悉的版本管理工具（如 `nvm` / `fnm`）安装 Node.js。

#### 4. 不使用 asdf 时安装 Yarn Classic 1.x

```bash
npm install -g yarn@1.22.22
```

确认版本：

```bash
yarn --version
```

输出应为 `1.x`。

#### 5. 安装 .NET SDK

项目目标框架为 `net7.0`。如果你本机还没有可用的 .NET SDK，建议从 Microsoft 官方下载安装：

- https://dotnet.microsoft.com/en-us/download/dotnet/7.0

确认版本：

```bash
dotnet --version
```

## 快速启动

在仓库根目录执行：

```bash
chmod +x ./scripts/macos-dev.sh
./scripts/macos-dev.sh start
```

首次启动会自动：

- 拉取 MySQL 镜像（如果本机还没有）
- 创建 Docker MySQL 容器和持久化数据卷
- 导入仓库内置的官方 MySQL 初始化脚本（默认路径：`scripts/seeds/database_mysql.sql`）
- 安装前端依赖
- 启动后端和前端

启动成功后默认访问地址：

- 前端：`http://127.0.0.1:5173`
- 后端：`http://127.0.0.1:20011`
- MySQL：`127.0.0.1:33306`
- 默认账号：`admin`
- 默认密码：`1`

## 常用命令

### 查看状态

```bash
./scripts/macos-dev.sh status
```

状态输出会显示：

- 前后端会话状态
- Docker MySQL 容器状态
- MySQL 健康状态
- 登录链路健康状态

### 查看日志

```bash
./scripts/macos-dev.sh logs
```

除了前后端日志外，还会输出最近的 Docker MySQL 日志。

### 停止前后端

```bash
./scripts/macos-dev.sh stop
```

> 注意：`stop` **不会停止 Docker MySQL**。这样下次 `start` 可以更快地复用现有数据库。

### 重置数据库

```bash
./scripts/macos-dev.sh reset-db
```

`reset-db` 会执行：

1. 停止前后端 tmux 会话
2. 删除脚本管理的 MySQL 容器
3. 删除脚本管理的 MySQL 数据卷
4. 重新创建 MySQL 容器
5. 重新导入仓库内置的官方初始化 SQL
6. 保持 MySQL 容器继续运行

这意味着课程环境不再依赖在线下载 seed SQL，网络不稳定时也能完成重置。

这等价于把本地数据库恢复到“刚初始化完成”的状态。

## 运行时文件说明

脚本的本地运行时文件会放在：

```bash
/tmp/modernwms-macos
```

其中包括：

- `/tmp/modernwms-macos/backend.log`
- `/tmp/modernwms-macos/frontend.log`

数据库初始化 SQL 默认保存在仓库内：

- `scripts/seeds/database_mysql.sql`

这意味着：

- 仓库里的 `appsettings.json` 不需要为 macOS 本地开发而修改
- 本地日志和临时文件不会写回仓库目录
- 数据库数据由 Docker volume 持久化保存
- 数据库重置不依赖额外网络下载

## 可选环境变量

默认配置：

- `MODERNWMS_HOST=127.0.0.1`
- `MODERNWMS_BACKEND_PORT=20011`
- `MODERNWMS_FRONTEND_PORT=5173`
- `MODERNWMS_MYSQL_PORT=33306`
- `MODERNWMS_MYSQL_CONTAINER=modernwms-macos-mysql`
- `MODERNWMS_MYSQL_VOLUME=modernwms-macos-mysql-data`
- `MODERNWMS_MYSQL_IMAGE=docker.m.daocloud.io/library/mysql:8.0`
- `MODERNWMS_MYSQL_ROOT_PASSWORD=123456`
- `MODERNWMS_MYSQL_INIT_SQL_FILE=<repo>/scripts/seeds/database_mysql.sql`

例如，如果你本机端口冲突，可以临时覆盖：

```bash
MODERNWMS_BACKEND_PORT=22011 \
MODERNWMS_FRONTEND_PORT=5273 \
MODERNWMS_MYSQL_PORT=33316 \
./scripts/macos-dev.sh start
```

## 常见问题

### 1. `Docker daemon is not available`

说明 Docker Desktop 没启动，或者当前 shell 无法连接 Docker daemon。

处理方式：

- 启动 Docker Desktop
- 再执行 `docker info` 确认可用
- 然后重试 `./scripts/macos-dev.sh start`

### 2. `MySQL port xxxx is already in use`

说明脚本准备使用的 MySQL 端口已被别的进程占用。

处理方式：

- 先停止占用端口的程序
- 或者覆盖 `MODERNWMS_MYSQL_PORT`

### 3. 首次启动比较慢

这是正常现象，首次启动可能会包含：

- 拉取 MySQL 镜像
- 导入初始化 SQL
- 安装前端依赖

后续启动通常会快很多。

### 4. 启动失败，想看详细日志

执行：

```bash
./scripts/macos-dev.sh logs
```

或者分别查看：

```bash
tail -n 100 /tmp/modernwms-macos/backend.log
tail -n 100 /tmp/modernwms-macos/frontend.log
docker logs --tail 100 modernwms-macos-mysql
```

### 5. 已经有 tmux session 在运行

可以先查看状态：

```bash
./scripts/macos-dev.sh status
```

停止旧会话：

```bash
./scripts/macos-dev.sh stop
```

## 说明

该脚本更适合：

- macOS 本地开发
- 本地联调前后端
- 快速重置和验证数据库状态
- 快速验证启动、登录和基础菜单加载链路

如果你要做正式部署、Nginx 部署、容器部署或远程数据库部署，仍建议继续使用仓库原有的 Linux / Windows / Docker 文档。
