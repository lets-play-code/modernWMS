#!/usr/bin/env bash
set -euo pipefail

TEST_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TEST_LIB_DIR/../../.." && pwd)"
MACOS_DEV_SCRIPT="$REPO_ROOT/scripts/macos-dev.sh"
APPSETTINGS_PATH="$REPO_ROOT/backend/ModernWMS/appsettings.json"
APPSETTINGS_BACKUP="$APPSETTINGS_PATH.pi-test-backup"
MYSQL_ROOT_PASSWORD="${MODERNWMS_TEST_MYSQL_ROOT_PASSWORD:-123456}"
MYSQL_DATABASE="${MODERNWMS_TEST_MYSQL_DATABASE:-wms}"
MYSQL_IMAGE="${MODERNWMS_TEST_MYSQL_IMAGE:-docker.m.daocloud.io/library/mysql:8.0}"
TEST_NAME=""
MYSQL_CONTAINER=""
MYSQL_VOLUME=""
MYSQL_PORT=""
BACKEND_PORT=""
FRONTEND_PORT=""

info() {
  printf '[%s] %s\n' "$TEST_NAME" "$*"
}

fail() {
  printf '[%s] FAIL: %s\n' "$TEST_NAME" "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

init_test_env() {
  TEST_NAME="$1"
  MYSQL_PORT="$2"
  BACKEND_PORT="$3"
  FRONTEND_PORT="$4"
  MYSQL_CONTAINER="${TEST_NAME}-mysql"
  MYSQL_VOLUME="${TEST_NAME}-mysql-data"

  export MODERNWMS_HOST="127.0.0.1"
  export MODERNWMS_MYSQL_CONTAINER="$MYSQL_CONTAINER"
  export MODERNWMS_MYSQL_VOLUME="$MYSQL_VOLUME"
  export MODERNWMS_MYSQL_PORT="$MYSQL_PORT"
  export MODERNWMS_MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD"
  export MODERNWMS_MYSQL_DATABASE="$MYSQL_DATABASE"
  export MODERNWMS_MYSQL_IMAGE="$MYSQL_IMAGE"
  export MODERNWMS_BACKEND_PORT="$BACKEND_PORT"
  export MODERNWMS_FRONTEND_PORT="$FRONTEND_PORT"
}

require_test_tools() {
  require_command docker
  require_command tmux
  require_command curl
  require_command python3
}

backup_mismatched_appsettings() {
  cp "$APPSETTINGS_PATH" "$APPSETTINGS_BACKUP"
  python3 - "$APPSETTINGS_PATH" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
data['Database']['db'] = 'SQLLITE'
data['ConnectionStrings']['MySqlConn'] = 'Server=127.0.0.1;Database=broken;Port=1;uid=broken;pwd=broken;'
path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
PY
}

restore_appsettings() {
  if [ -f "$APPSETTINGS_BACKUP" ]; then
    mv "$APPSETTINGS_BACKUP" "$APPSETTINGS_PATH"
  fi
}

cleanup_runtime() {
  "$MACOS_DEV_SCRIPT" stop >/dev/null 2>&1 || true
  docker rm -f "$MYSQL_CONTAINER" >/dev/null 2>&1 || true
  docker volume rm -f "$MYSQL_VOLUME" >/dev/null 2>&1 || true
  restore_appsettings
}

managed_mysql_running() {
  docker inspect -f '{{.State.Running}}' "$MYSQL_CONTAINER" 2>/dev/null | grep -q '^true$'
}

assert_managed_mysql_running() {
  managed_mysql_running || fail "Expected MySQL container '$MYSQL_CONTAINER' to be running"
}

mysql_exec() {
  docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$MYSQL_CONTAINER" mysql -uroot -N -B -e "$1"
}

assert_probe_table_exists() {
  local table_name="$1"
  local count

  count="$(mysql_exec "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${MYSQL_DATABASE}' AND table_name='${table_name}';")"
  [ "$count" = "1" ] || fail "Expected table ${MYSQL_DATABASE}.${table_name} to exist"
}

assert_probe_table_missing() {
  local table_name="$1"
  local count

  count="$(mysql_exec "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${MYSQL_DATABASE}' AND table_name='${table_name}';")"
  [ "$count" = "0" ] || fail "Expected table ${MYSQL_DATABASE}.${table_name} to be absent"
}

create_probe_table() {
  local table_name="$1"

  mysql_exec "CREATE TABLE \`${MYSQL_DATABASE}\`.\`${table_name}\` (id INT PRIMARY KEY); INSERT INTO \`${MYSQL_DATABASE}\`.\`${table_name}\` (id) VALUES (1);"
}

assert_login_flow_ready() {
  local login_json
  local parsed
  local token
  local role_id
  local authority_json

  login_json="$(curl --noproxy '*' -fsS "http://127.0.0.1:${BACKEND_PORT}/login?culture=en-us" -H 'Content-Type: application/json' -d '{"user_name":"admin","password":"c4ca4238a0b923820dcc509a6f75849b"}')" || fail "Login request failed"
  parsed="$(printf '%s' "$login_json" | python3 -c '
import json
import sys

data = json.load(sys.stdin)
if not data.get("isSuccess"):
    raise SystemExit("login isSuccess=false")
login_data = data.get("data") or {}
token = login_data.get("access_token")
role_id = login_data.get("userrole_id")
if not token or not role_id:
    raise SystemExit("missing token or role_id")
print(token)
print(role_id)
')" || fail "Login response missing token or role id"
  token="$(printf '%s' "$parsed" | sed -n '1p')"
  role_id="$(printf '%s' "$parsed" | sed -n '2p')"
  authority_json="$(curl --noproxy '*' -fsS "http://127.0.0.1:${BACKEND_PORT}/rolemenu/authority?userrole_id=${role_id}&culture=en-us" -H "Authorization: Bearer ${token}")" || fail "Authority request failed"
  printf '%s' "$authority_json" | python3 -c '
import json
import sys

data = json.load(sys.stdin)
if not data.get("isSuccess"):
    raise SystemExit("authority isSuccess=false")
if not (data.get("data") or []):
    raise SystemExit("authority list empty")
' >/dev/null 2>&1 || fail "Authority response was not usable"
}
