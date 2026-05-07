# macOS Docker MySQL Startup Implementation Plan

> **Execution model:** This plan is designed for a single continuous executor. Start it with `/run-plan <plan-file>` after approval. The runner creates task branches for the touched repo(s), keeps status in `.pi/runs/...`, and only stops early for explicit stop conditions.

**Goal:** 将 macOS 快速启动改为脚本自动托管 Docker MySQL，并保持 `scripts/macos-dev.sh` 作为唯一入口。

**Architecture:** `scripts/macos-dev.sh` 在启动前先确保 Docker MySQL 容器与持久化 volume 可用，必要时自动导入官方 MySQL 种子 SQL。后端通过环境变量覆盖数据库配置，避免要求用户手工修改 `appsettings.json`。脚本继续用 tmux 托管前后端，并用登录链路作为健康检查标准。

**Tech Stack:** Bash, tmux, Docker, MySQL 8.0, .NET 7, Vite, Python 3

**Repo Scope:** single repo (`ModernWMS`)

---

## File Structure / Responsibility Map

### Production files
- Modify: `scripts/macos-dev.sh` — 托管 Docker MySQL、注入后端环境变量、更新 stop/reset-db/status/logs 行为
- Modify: `README.zh_CN.md` — 更新 macOS 快速启动说明
- Modify: `README.md` — 更新英文 macOS 快速启动说明
- Modify: `docs/macOS-setup.md` — 写明 Docker MySQL 自动托管流程

### Test files
- Create/Modify: `scripts/tests/lib/macos-dev-test-lib.sh` — 复用的脚本级集成测试辅助函数
- Modify: `scripts/tests/test-macos-dev-mysql-start.sh` — 验证自动托管 Docker MySQL 与环境变量覆盖
- Create: `scripts/tests/test-macos-dev-stop-keeps-db.sh` — 验证 stop 不停止 MySQL，且重启后数据仍保留
- Modify: `scripts/tests/test-macos-dev-reset-db.sh` — 验证 reset-db 真正重建数据库并恢复初始状态

### Docs / working artifacts
- Modify: `docs/superpowers/specs/2026-05-07-macos-mysql-startup-design.md`
- Modify: `docs/superpowers/plans/2026-05-07-macos-mysql-startup.md`

## Gate 1: 写出失败测试并确认当前脚本不满足目标

**Goal:**
- 用脚本级集成测试证明：当前脚本仍依赖手工 MySQL 配置，不能自动托管 Docker MySQL

**Files:**
- Modify: `scripts/tests/test-macos-dev-mysql-start.sh`
- Create: `scripts/tests/test-macos-dev-stop-keeps-db.sh`
- Modify: `scripts/tests/test-macos-dev-reset-db.sh`
- Create: `scripts/tests/lib/macos-dev-test-lib.sh`

**Verification:**
- Run: `bash scripts/tests/test-macos-dev-mysql-start.sh`
- Expected: FAIL，失败点为脚本仍依赖 `appsettings.json` 中的手工 MySQL 配置

**Continue when:**
- 失败原因与目标差距一致

**Stop and report when:**
- 失败来自测试环境缺失 Docker，而不是脚本当前行为

- [ ] Step 1: 写测试与测试辅助库
- [ ] Step 2: 运行失败测试并确认原因正确

## Gate 2: 切换脚本为自动托管 Docker MySQL

**Goal:**
- `start` 自动拉起/初始化 Docker MySQL，并用环境变量覆盖后端配置

**Files:**
- Modify: `scripts/macos-dev.sh`

**Verification:**
- Run: `bash scripts/tests/test-macos-dev-mysql-start.sh`
- Expected: PASS

**Continue when:**
- 无需手工修改 `appsettings.json`，登录链路通过

**Stop and report when:**
- 脚本实现需要引入超出批准范围的新外部依赖

- [ ] Step 1: 增加 Docker MySQL 容器与 volume 管理逻辑
- [ ] Step 2: 增加官方 SQL 自动下载与导入逻辑
- [ ] Step 3: 用环境变量覆盖后端连接串
- [ ] Step 4: 运行目标测试确认通过

## Gate 3: 调整 stop/reset-db/status/logs 语义

**Goal:**
- 让 `stop`、`reset-db`、`status`、`logs` 与新的 Docker MySQL 方案一致

**Files:**
- Modify: `scripts/macos-dev.sh`
- Create: `scripts/tests/test-macos-dev-stop-keeps-db.sh`
- Modify: `scripts/tests/test-macos-dev-reset-db.sh`

**Verification:**
- Run: `bash scripts/tests/test-macos-dev-stop-keeps-db.sh`
- Expected: PASS
- Run: `bash scripts/tests/test-macos-dev-reset-db.sh`
- Expected: PASS

**Continue when:**
- stop 不停 DB，reset-db 会真正重建 DB

**Stop and report when:**
- 需要改变已批准的命令名或交互方式

- [ ] Step 1: 调整 stop 行为
- [ ] Step 2: 实现 reset-db 真重建
- [ ] Step 3: 补充 status/logs 的 Docker MySQL 输出
- [ ] Step 4: 跑回归测试确认通过

## Gate 4: 更新长期文档并做最终验证

**Goal:**
- 保证 README 与 macOS 文档准确反映最终行为，并提供 fresh verification evidence

**Files:**
- Modify: `README.zh_CN.md`
- Modify: `README.md`
- Modify: `docs/macOS-setup.md`

**Verification:**
- Run: `bash scripts/tests/test-macos-dev-mysql-start.sh`
- Expected: PASS
- Run: `bash scripts/tests/test-macos-dev-stop-keeps-db.sh`
- Expected: PASS
- Run: `bash scripts/tests/test-macos-dev-reset-db.sh`
- Expected: PASS
- Run: `./scripts/macos-dev.sh help`
- Expected: 帮助文案体现 Docker MySQL 自动托管

**Continue when:**
- 文档和脚本行为一致，所有验证通过

**Stop and report when:**
- 任一验证失败，且一次局部修复后仍失败

- [ ] Step 1: 更新 README.zh_CN.md / README.md / docs/macOS-setup.md
- [ ] Step 2: 运行全部验证命令
- [ ] Step 3: 检查 diff 仅限批准范围
- [ ] Step 4: 总结结果并向用户报告证据
