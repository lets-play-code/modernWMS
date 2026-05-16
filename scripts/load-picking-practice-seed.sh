#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRACTICE_SEED_FILE="${MODERNWMS_PRACTICE_SEED_FILE:-$REPO_ROOT/wip/modernwms-picking-enhancement-practice-seed.sql}"
MYSQL_CONTAINER="${MODERNWMS_MYSQL_CONTAINER:-modernwms-macos-mysql}"
MYSQL_ROOT_PASSWORD="${MODERNWMS_MYSQL_ROOT_PASSWORD:-123456}"
MYSQL_DATABASE="${MODERNWMS_MYSQL_DATABASE:-wms}"

usage() {
  cat <<EOF
Usage: ./scripts/load-picking-practice-seed.sh [load|help]

Commands:
  load    Import the picking practice supplement seed, then verify it (default)
  help    Show this help message

Environment overrides:
  MODERNWMS_MYSQL_CONTAINER      Default: modernwms-macos-mysql
  MODERNWMS_MYSQL_ROOT_PASSWORD  Default: 123456
  MODERNWMS_MYSQL_DATABASE       Default: wms
  MODERNWMS_PRACTICE_SEED_FILE   Default: <repo>/wip/modernwms-picking-enhancement-practice-seed.sql
EOF
}

info() {
  printf '[practice-seed] %s\n' "$*"
}

die() {
  printf '[practice-seed] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

container_exists() {
  docker container inspect "$MYSQL_CONTAINER" >/dev/null 2>&1
}

mysql_running() {
  docker inspect -f '{{.State.Running}}' "$MYSQL_CONTAINER" 2>/dev/null | grep -q '^true$'
}

mysql_exec() {
  docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$MYSQL_CONTAINER" mysql --default-character-set=utf8mb4 -uroot -N -B -e "$1"
}

ensure_prerequisites() {
  require_command docker
  [ -f "$PRACTICE_SEED_FILE" ] || die "Practice seed SQL file not found: $PRACTICE_SEED_FILE"
  container_exists || die "Managed Docker MySQL container not found: $MYSQL_CONTAINER. Start it with './scripts/macos-dev.sh start' or './scripts/macos-dev.sh reset-db'."
  mysql_running || die "Managed Docker MySQL container is not running: $MYSQL_CONTAINER"
  local schema_count
  schema_count="$(mysql_exec "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='${MYSQL_DATABASE}';" 2>/dev/null || echo 0)"
  [ "$schema_count" = "1" ] || die "Database '${MYSQL_DATABASE}' does not exist inside container '${MYSQL_CONTAINER}'"
}

verify_seed() {
  local users
  local roles
  local warehouse
  local locations
  local dispatches
  local picklists
  local admin_actions
  local picker_name_hex
  local checker_name_hex
  local warehouse_name_hex

  users="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.user WHERE user_num IN ('picker01','checker01');")"
  [ "$users" = "2" ] || die "Expected 2 practice users, found: $users"

  roles="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.userrole WHERE role_name IN ('picker','checker');")"
  [ "$roles" = "2" ] || die "Expected 2 practice roles, found: $roles"

  warehouse="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.warehouse WHERE warehouse_name='练习一号仓';")"
  [ "$warehouse" = "1" ] || die "Expected practice warehouse to exist"

  locations="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.goodslocation WHERE location_name IN ('PICK-A-01','PICK-A-02','STOCK-A-01','STOCK-A-02');")"
  [ "$locations" = "4" ] || die "Expected 4 practice locations, found: $locations"

  dispatches="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.dispatchlist WHERE dispatch_no IN ('DP-TRAIN-001','DP-TRAIN-002','DP-TRAIN-003');")"
  [ "$dispatches" = "3" ] || die "Expected 3 practice dispatchlists, found: $dispatches"

  picklists="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.dispatchpicklist WHERE id BETWEEN 52001 AND 52004;")"
  [ "$picklists" = "4" ] || die "Expected 4 practice dispatchpicklist rows, found: $picklists"

  picker_name_hex="$(mysql_exec "SELECT HEX(user_name) FROM \`${MYSQL_DATABASE}\`.user WHERE user_num='picker01';")"
  [ "$picker_name_hex" = "E68BA3E8B4A7E591982DE69D8EE6988E" ] || die "Expected picker01 user_name to be stored as UTF-8 Chinese, found HEX: $picker_name_hex"

  checker_name_hex="$(mysql_exec "SELECT HEX(user_name) FROM \`${MYSQL_DATABASE}\`.user WHERE user_num='checker01';")"
  [ "$checker_name_hex" = "E5A48DE6A0B8E591982DE78E8BE6958F" ] || die "Expected checker01 user_name to be stored as UTF-8 Chinese, found HEX: $checker_name_hex"

  warehouse_name_hex="$(mysql_exec "SELECT HEX(warehouse_name) FROM \`${MYSQL_DATABASE}\`.warehouse WHERE id=51001;")"
  [ "$warehouse_name_hex" = "E7BB83E4B9A0E4B880E58FB7E4BB93" ] || die "Expected warehouse_name to be stored as UTF-8 Chinese, found HEX: $warehouse_name_hex"

  admin_actions="$(mysql_exec "SELECT menu_actions_authority FROM \`${MYSQL_DATABASE}\`.rolemenu WHERE userrole_id=1 AND menu_id=19;")"
  printf '%s' "$admin_actions" | grep -q 'picked-pick' || die "Expected admin deliveryManagement actions to include picked-pick"

  info 'Verification passed.'
  info 'Accounts: admin / 1, picker01 / 1, checker01 / 1'
}

load_seed() {
  info "Importing practice seed SQL: $PRACTICE_SEED_FILE"
  docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" -i "$MYSQL_CONTAINER" mysql --default-character-set=utf8mb4 -uroot "$MYSQL_DATABASE" < "$PRACTICE_SEED_FILE"
  verify_seed
  info "Practice supplement seed has been loaded into ${MYSQL_CONTAINER}:${MYSQL_DATABASE}."
}

main() {
  local command="${1:-load}"

  case "$command" in
    load)
      ensure_prerequisites
      load_seed
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
