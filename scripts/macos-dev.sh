#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$REPO_ROOT/backend/ModernWMS"
FRONTEND_DIR="$REPO_ROOT/frontend"
RUNTIME_DIR="/tmp/modernwms-macos"
BACKEND_LOG="$RUNTIME_DIR/backend.log"
FRONTEND_LOG="$RUNTIME_DIR/frontend.log"
MYSQL_INIT_SQL_FILE="${MODERNWMS_MYSQL_INIT_SQL_FILE:-$REPO_ROOT/scripts/seeds/database_mysql.sql}"
BACKEND_SESSION="modernwms-macos-backend"
FRONTEND_SESSION="modernwms-macos-frontend"
HOST="${MODERNWMS_HOST:-127.0.0.1}"
BACKEND_PORT="${MODERNWMS_BACKEND_PORT:-20011}"
FRONTEND_PORT="${MODERNWMS_FRONTEND_PORT:-5173}"
LOG_LINES="${MODERNWMS_LOG_LINES:-80}"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="${MODERNWMS_MYSQL_PORT:-33306}"
MYSQL_CONTAINER="${MODERNWMS_MYSQL_CONTAINER:-modernwms-macos-mysql}"
MYSQL_VOLUME="${MODERNWMS_MYSQL_VOLUME:-modernwms-macos-mysql-data}"
MYSQL_IMAGE="${MODERNWMS_MYSQL_IMAGE:-docker.m.daocloud.io/library/mysql:8.0}"
MYSQL_ROOT_PASSWORD="${MODERNWMS_MYSQL_ROOT_PASSWORD:-123456}"
MYSQL_DATABASE="wms"

usage() {
  cat <<EOF
Usage: ./scripts/macos-dev.sh <command>

Commands:
  start     Start Docker MySQL (auto-init when needed), then start backend and frontend in tmux
  stop      Stop backend and frontend tmux sessions; keep Docker MySQL running
  status    Show frontend, backend, login, and Docker MySQL status
  logs      Tail backend/frontend logs and show recent Docker MySQL logs
  reset-db  Recreate the managed Docker MySQL data volume and re-import the bundled seed SQL
  help      Show this help message

Environment overrides:
  MODERNWMS_HOST                 Default: 127.0.0.1
  MODERNWMS_BACKEND_PORT         Default: 20011
  MODERNWMS_FRONTEND_PORT        Default: 5173
  MODERNWMS_MYSQL_PORT           Default: 33306
  MODERNWMS_MYSQL_CONTAINER      Default: modernwms-macos-mysql
  MODERNWMS_MYSQL_VOLUME         Default: modernwms-macos-mysql-data
  MODERNWMS_MYSQL_IMAGE          Default: docker.m.daocloud.io/library/mysql:8.0
  MODERNWMS_MYSQL_ROOT_PASSWORD  Default: 123456
  MODERNWMS_MYSQL_INIT_SQL_FILE  Default: <repo>/scripts/seeds/database_mysql.sql
  MODERNWMS_LOG_LINES            Default: 80
EOF
}

info() {
  printf '[modernwms] %s\n' "$*"
}

die() {
  printf '[modernwms] ERROR: %s\n' "$*" >&2
  exit 1
}

shell_quote() {
  printf '%q' "$1"
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || die "Missing required command: $command_name"
}

mysql_connection_string() {
  printf 'Server=%s;Database=%s;Port=%s;charset=utf8;uid=root;pwd=%s;' \
    "$MYSQL_HOST" "$MYSQL_DATABASE" "$MYSQL_PORT" "$MYSQL_ROOT_PASSWORD"
}

prepare_runtime() {
  mkdir -p "$RUNTIME_DIR"
}

ensure_prerequisites() {
  require_command tmux
  require_command zsh
  require_command curl
  require_command lsof
  require_command dotnet
  require_command node
  require_command yarn
  require_command python3
  require_command docker

  case "$(yarn --version 2>/dev/null || true)" in
    1.*) ;;
    *) die "Yarn Classic 1.x is required. Please install yarn@1.22.x." ;;
  esac

  [ -d "$BACKEND_DIR" ] || die "Backend directory not found: $BACKEND_DIR"
  [ -d "$FRONTEND_DIR" ] || die "Frontend directory not found: $FRONTEND_DIR"
  [ -f "$MYSQL_INIT_SQL_FILE" ] || die "MySQL seed SQL file not found: $MYSQL_INIT_SQL_FILE"
  docker info >/dev/null 2>&1 || die "Docker daemon is not available. Start Docker Desktop (or the Docker daemon) and try again."
}

session_exists() {
  tmux has-session -t "$1" 2>/dev/null
}

container_exists() {
  docker container inspect "$MYSQL_CONTAINER" >/dev/null 2>&1
}

mysql_running() {
  docker inspect -f '{{.State.Running}}' "$MYSQL_CONTAINER" 2>/dev/null | grep -q '^true$'
}

mysql_volume_exists() {
  docker volume inspect "$MYSQL_VOLUME" >/dev/null 2>&1
}

ensure_session_stopped() {
  local session_name="$1"
  if session_exists "$session_name"; then
    die "Session already running: $session_name. Use './scripts/macos-dev.sh stop' first."
  fi
}

ensure_port_free() {
  local port="$1"
  if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    die "Port $port is already in use. Stop the existing process or override the port with MODERNWMS_*_PORT."
  fi
}

ensure_mysql_port_free() {
  if mysql_running; then
    return 0
  fi

  if lsof -nP -iTCP:"$MYSQL_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    die "MySQL port $MYSQL_PORT is already in use. Stop the existing process or override MODERNWMS_MYSQL_PORT."
  fi
}

ensure_mysql_image() {
  if docker image inspect "$MYSQL_IMAGE" >/dev/null 2>&1; then
    return 0
  fi

  info "Pulling Docker MySQL image: $MYSQL_IMAGE"
  docker pull "$MYSQL_IMAGE" >/dev/null
}

wait_for_mysql() {
  local attempt=0
  while [ "$attempt" -lt 120 ]; do
    if docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$MYSQL_CONTAINER" mysql --default-character-set=utf8mb4 -uroot -e 'SELECT 1' >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    attempt=$((attempt + 1))
  done
  return 1
}

start_mysql_container() {
  ensure_mysql_port_free
  ensure_mysql_image
  info "Creating managed Docker MySQL container: $MYSQL_CONTAINER"
  docker run -d \
    --name "$MYSQL_CONTAINER" \
    -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    -v "$MYSQL_VOLUME:/var/lib/mysql" \
    -p "$MYSQL_HOST:$MYSQL_PORT:3306" \
    "$MYSQL_IMAGE" \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_general_ci >/dev/null

  wait_for_mysql || die "Managed Docker MySQL did not become ready in time."
}

ensure_mysql_service() {
  if mysql_running; then
    return 0
  fi

  if container_exists; then
    info "Starting managed Docker MySQL container: $MYSQL_CONTAINER"
    docker start "$MYSQL_CONTAINER" >/dev/null
    wait_for_mysql || die "Managed Docker MySQL did not become ready in time."
    return 0
  fi

  start_mysql_container
}

mysql_exec() {
  docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$MYSQL_CONTAINER" mysql --default-character-set=utf8mb4 -uroot -N -B -e "$1"
}

mysql_schema_ready() {
  local menu_actions
  local rolemenu_actions

  menu_actions="$(mysql_exec "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='${MYSQL_DATABASE}' AND table_name='menu' AND column_name='menu_actions';" 2>/dev/null || echo 0)"
  rolemenu_actions="$(mysql_exec "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='${MYSQL_DATABASE}' AND table_name='rolemenu' AND column_name='menu_actions_authority';" 2>/dev/null || echo 0)"

  [ "$menu_actions" = "1" ] && [ "$rolemenu_actions" = "1" ]
}

initialize_mysql_schema() {
  info "Initializing managed Docker MySQL schema from bundled SQL: $MYSQL_INIT_SQL_FILE"
  mysql_exec "DROP DATABASE IF EXISTS \`${MYSQL_DATABASE}\`;"
  docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" -i "$MYSQL_CONTAINER" mysql --default-character-set=utf8mb4 -uroot < "$MYSQL_INIT_SQL_FILE"
  mysql_schema_ready || die "Managed Docker MySQL schema initialization failed."
}

ensure_mysql_schema() {
  mysql_schema_ready || initialize_mysql_schema
}

run_tmux_session() {
  local session_name="$1"
  local workdir="$2"
  local inner_command="$3"
  local q_workdir
  local q_inner_command

  q_workdir="$(shell_quote "$workdir")"
  q_inner_command="$(shell_quote "source \"$HOME/.zshrc\" && $inner_command")"
  tmux new-session -d -s "$session_name" "cd $q_workdir && zsh -c $q_inner_command"
}

install_frontend_dependencies() {
  info "Installing frontend dependencies with Yarn Classic (lockfile stays unchanged)..."
  (
    cd "$FRONTEND_DIR"
    COREPACK_ENABLE_AUTO_PIN=0 yarn install --ignore-engines --frozen-lockfile
  )
}

start_backend() {
  local backend_url="http://$HOST:$BACKEND_PORT"
  local backend_command
  local mysql_conn

  mysql_conn="$(mysql_connection_string)"
  backend_command="env Database__db=MySql ConnectionStrings__MySqlConn=$(shell_quote "$mysql_conn") dotnet run --urls $(shell_quote "$backend_url") > $(shell_quote "$BACKEND_LOG") 2>&1"
  run_tmux_session "$BACKEND_SESSION" "$BACKEND_DIR" "$backend_command"
}

start_frontend() {
  local frontend_command

  frontend_command="env COREPACK_ENABLE_AUTO_PIN=0 VITE_BASE_PATH=$(shell_quote "http://$HOST") VITE_SERVER_PORT=$(shell_quote "$BACKEND_PORT") yarn dev --host $(shell_quote "$HOST") --port $(shell_quote "$FRONTEND_PORT") --strictPort > $(shell_quote "$FRONTEND_LOG") 2>&1"
  run_tmux_session "$FRONTEND_SESSION" "$FRONTEND_DIR" "$frontend_command"
}

backend_ready() {
  curl --noproxy '*' -fsS -X POST "http://$HOST:$BACKEND_PORT/hello-world" -H 'Content-Type: application/json' -d '{}' >/dev/null 2>&1
}

frontend_ready() {
  curl --noproxy '*' -fsS "http://$HOST:$FRONTEND_PORT/" >/dev/null 2>&1
}

login_flow_ready() {
  local login_json
  local parsed
  local token
  local role_id
  local authority_json

  login_json="$(curl --noproxy '*' -fsS "http://$HOST:$BACKEND_PORT/login?culture=en-us" -H 'Content-Type: application/json' -d '{"user_name":"admin","password":"c4ca4238a0b923820dcc509a6f75849b"}' 2>/dev/null)" || return 1
  parsed="$(printf '%s' "$login_json" | python3 -c '
import json
import sys

data = json.load(sys.stdin)
if not data.get("isSuccess"):
    raise SystemExit(1)
login_data = data.get("data") or {}
token = login_data.get("access_token")
role_id = login_data.get("userrole_id")
if not token or not role_id:
    raise SystemExit(1)
print(token)
print(role_id)
')" || return 1
  token="$(printf '%s' "$parsed" | sed -n '1p')"
  role_id="$(printf '%s' "$parsed" | sed -n '2p')"
  authority_json="$(curl --noproxy '*' -fsS "http://$HOST:$BACKEND_PORT/rolemenu/authority?userrole_id=${role_id}&culture=en-us" -H "Authorization: Bearer ${token}" 2>/dev/null)" || return 1
  printf '%s' "$authority_json" | python3 -c '
import json
import sys

data = json.load(sys.stdin)
if not data.get("isSuccess"):
    raise SystemExit(1)
if not (data.get("data") or []):
    raise SystemExit(1)
' >/dev/null 2>&1
}

wait_for_backend() {
  local attempt=0
  while [ "$attempt" -lt 60 ]; do
    if backend_ready; then
      return 0
    fi
    sleep 1
    attempt=$((attempt + 1))
  done
  return 1
}

wait_for_frontend() {
  local attempt=0
  while [ "$attempt" -lt 60 ]; do
    if frontend_ready; then
      return 0
    fi
    sleep 1
    attempt=$((attempt + 1))
  done
  return 1
}

wait_for_login_flow() {
  local attempt=0
  while [ "$attempt" -lt 20 ]; do
    if login_flow_ready; then
      return 0
    fi
    sleep 1
    attempt=$((attempt + 1))
  done
  return 1
}

tail_if_exists() {
  local label="$1"
  local file_path="$2"

  if [ -f "$file_path" ]; then
    printf '==> %s (%s)\n' "$label" "$file_path"
    tail -n "$LOG_LINES" "$file_path"
  else
    printf '==> %s (%s)\n' "$label" "$file_path"
    echo 'Log file not created yet.'
  fi
}

print_mysql_logs() {
  if mysql_running; then
    printf '==> mysql (docker:%s)\n' "$MYSQL_CONTAINER"
    docker logs --tail "$LOG_LINES" "$MYSQL_CONTAINER"
  else
    printf '==> mysql (docker:%s)\n' "$MYSQL_CONTAINER"
    echo 'Managed Docker MySQL is not running.'
  fi
}

print_access_info() {
  cat <<EOF

Frontend: http://$HOST:$FRONTEND_PORT
Backend:  http://$HOST:$BACKEND_PORT
MySQL:    docker:$MYSQL_CONTAINER -> $MYSQL_HOST:$MYSQL_PORT/$MYSQL_DATABASE
Account:  admin
Password: 1

Common commands:
  ./scripts/macos-dev.sh status
  ./scripts/macos-dev.sh logs
  ./scripts/macos-dev.sh stop
  ./scripts/macos-dev.sh reset-db
EOF
}

start_all() {
  ensure_prerequisites
  ensure_session_stopped "$BACKEND_SESSION"
  ensure_session_stopped "$FRONTEND_SESSION"
  ensure_port_free "$BACKEND_PORT"
  ensure_port_free "$FRONTEND_PORT"
  prepare_runtime
  ensure_mysql_service
  ensure_mysql_schema
  install_frontend_dependencies

  info "Starting backend session: $BACKEND_SESSION"
  start_backend
  if ! wait_for_backend; then
    tail_if_exists 'backend' "$BACKEND_LOG"
    stop_all
    die "Backend did not become ready in time."
  fi

  if ! wait_for_login_flow; then
    tail_if_exists 'backend' "$BACKEND_LOG"
    print_mysql_logs
    stop_all
    die "Backend started, but the login flow check failed."
  fi

  info "Starting frontend session: $FRONTEND_SESSION"
  start_frontend
  if ! wait_for_frontend; then
    tail_if_exists 'frontend' "$FRONTEND_LOG"
    stop_all
    die "Frontend did not become ready in time."
  fi

  info "ModernWMS started successfully on macOS."
  print_access_info
}

stop_session() {
  local session_name="$1"
  if session_exists "$session_name"; then
    tmux kill-session -t "$session_name"
    info "Stopped session: $session_name"
  fi
}

stop_all() {
  stop_session "$FRONTEND_SESSION"
  stop_session "$BACKEND_SESSION"
}

reset_db() {
  ensure_prerequisites
  prepare_runtime
  stop_all

  if container_exists; then
    info "Removing managed Docker MySQL container: $MYSQL_CONTAINER"
    docker rm -f "$MYSQL_CONTAINER" >/dev/null
  fi

  if mysql_volume_exists; then
    info "Removing managed Docker MySQL volume: $MYSQL_VOLUME"
    docker volume rm -f "$MYSQL_VOLUME" >/dev/null
  fi

  rm -rf "$RUNTIME_DIR"
  prepare_runtime
  start_mysql_container
  initialize_mysql_schema

  info "Managed Docker MySQL database has been reset and is still running on $MYSQL_HOST:$MYSQL_PORT."
}

service_state() {
  local session_name="$1"
  if session_exists "$session_name"; then
    echo 'running'
  else
    echo 'stopped'
  fi
}

mysql_state() {
  if mysql_running; then
    echo 'running'
  elif container_exists; then
    echo 'stopped'
  else
    echo 'missing'
  fi
}

health_state() {
  local service_name="$1"
  case "$service_name" in
    backend)
      backend_ready && echo 'healthy' || echo 'unavailable'
      ;;
    frontend)
      frontend_ready && echo 'healthy' || echo 'unavailable'
      ;;
    login)
      login_flow_ready && echo 'ready' || echo 'unavailable'
      ;;
    mysql)
      mysql_running && mysql_schema_ready && echo 'ready' || echo 'unavailable'
      ;;
    *)
      echo 'unknown'
      ;;
  esac
}

show_status() {
  cat <<EOF
Backend session:  $(service_state "$BACKEND_SESSION") ($BACKEND_SESSION)
Frontend session: $(service_state "$FRONTEND_SESSION") ($FRONTEND_SESSION)
MySQL container:  $(mysql_state) ($MYSQL_CONTAINER)
MySQL health:     $(health_state mysql) -> $MYSQL_HOST:$MYSQL_PORT/$MYSQL_DATABASE
Backend health:   $(health_state backend) -> http://$HOST:$BACKEND_PORT
Login health:     $(health_state login) -> http://$HOST:$BACKEND_PORT/login
Frontend health:  $(health_state frontend) -> http://$HOST:$FRONTEND_PORT
MySQL volume:     $MYSQL_VOLUME
Runtime dir:      $RUNTIME_DIR
Backend log:      $BACKEND_LOG
Frontend log:     $FRONTEND_LOG
EOF
}

show_logs() {
  tail_if_exists 'backend' "$BACKEND_LOG"
  echo
  tail_if_exists 'frontend' "$FRONTEND_LOG"
  echo
  print_mysql_logs
}

main() {
  case "${1:-help}" in
    start)
      start_all
      ;;
    stop)
      stop_all
      ;;
    status)
      show_status
      ;;
    logs)
      show_logs
      ;;
    reset-db)
      reset_db
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
