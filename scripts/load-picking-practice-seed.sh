#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRACTICE_SEED_FILE="${MODERNWMS_PRACTICE_SEED_FILE:-$REPO_ROOT/docs/requirements/classroom-practice/modernwms-picking-enhancement-practice-seed.sql}"
MYSQL_CONTAINER="${MODERNWMS_MYSQL_CONTAINER:-modernwms-macos-mysql}"
MYSQL_ROOT_PASSWORD="${MODERNWMS_MYSQL_ROOT_PASSWORD:-123456}"
MYSQL_DATABASE="${MODERNWMS_MYSQL_DATABASE:-wms}"

usage() {
  cat <<EOF
Usage: ./scripts/load-picking-practice-seed.sh [load|help]

Commands:
  load    Import the integrated WMS practice supplement seed, then verify it (default)
  help    Show this help message

Environment overrides:
  MODERNWMS_MYSQL_CONTAINER      Default: modernwms-macos-mysql
  MODERNWMS_MYSQL_ROOT_PASSWORD  Default: 123456
  MODERNWMS_MYSQL_DATABASE       Default: wms
  MODERNWMS_PRACTICE_SEED_FILE   Default: <repo>/docs/requirements/classroom-practice/modernwms-picking-enhancement-practice-seed.sql
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
  local suppliers
  local asn_masters
  local asn_bug_a
  local asn_bug_b
  local mainline_asn
  local mainline_stock_rows
  local mainline_dispatch
  local dispatches
  local dispatch_snapshots
  local picklists
  local stockfreeze_count
  local stockmove_count
  local stockadjust_count
  local stocktaking_count
  local stockprocess_count
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

  suppliers="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.supplier WHERE id BETWEEN 50901 AND 50903;")"
  [ "$suppliers" = "3" ] || die "Expected 3 practice suppliers, found: $suppliers"

  asn_masters="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.asnmaster WHERE asn_no IN ('ASN-E2E-001','ASN-BUG-001','ASN-BUG-002','ASN-DEMO-UNLOAD-001','ASN-DEMO-SORT-001','ASN-DEMO-GROUND-001','ASN-DEMO-RECEIPT-001');")"
  [ "$asn_masters" = "7" ] || die "Expected 7 ASN master scenarios, found: $asn_masters"

  asn_bug_a="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.asn a JOIN \`${MYSQL_DATABASE}\`.sku s ON s.id = a.sku_id WHERE a.asn_no='ASN-BUG-001' AND a.supplier_name='华东供应商A' AND s.sku_name='ASN查询演练箱-基础款';")"
  [ "$asn_bug_a" = "1" ] || die "Expected ASN-BUG-001 supplier / SKU bug data, found: $asn_bug_a"

  asn_bug_b="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.asn a JOIN \`${MYSQL_DATABASE}\`.sku s ON s.id = a.sku_id WHERE a.asn_no='ASN-BUG-002' AND a.supplier_name='华南供应商B' AND s.sku_name='ASN查询演练袋-基础款';")"
  [ "$asn_bug_b" = "1" ] || die "Expected ASN-BUG-002 supplier / SKU bug data, found: $asn_bug_b"

  mainline_asn="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.asn WHERE asn_no='ASN-E2E-001' AND asn_status=0 AND sku_id=51703 AND asn_qty=8;")"
  [ "$mainline_asn" = "1" ] || die "Expected ASN-E2E-001 mainline notice data, found: $mainline_asn"

  mainline_stock_rows="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stock WHERE sku_id=51703;")"
  [ "$mainline_stock_rows" = "0" ] || die "Expected no pre-existing stock for mainline SKU 51703, found: $mainline_stock_rows"

  mainline_dispatch="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.dispatchlist WHERE dispatch_no='DP-E2E-001' AND dispatch_status=0 AND sku_id=51703;")"
  [ "$mainline_dispatch" = "1" ] || die "Expected DP-E2E-001 pre-shipment mainline data, found: $mainline_dispatch"

  dispatches="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.dispatchlist WHERE dispatch_no IN ('DP-TRAIN-001','DP-TRAIN-002','DP-TRAIN-003');")"
  [ "$dispatches" = "3" ] || die "Expected 3 picking training dispatchlists, found: $dispatches"

  dispatch_snapshots="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.dispatchlist WHERE dispatch_no IN ('DP-DEMO-NEW-001','DP-DEMO-PICKED-001','DP-DEMO-PACKAGED-001','DP-DEMO-WEIGHED-001','DP-DEMO-DELIVERED-001','DP-DEMO-SIGNED-001');")"
  [ "$dispatch_snapshots" = "6" ] || die "Expected 6 dispatch lifecycle snapshots, found: $dispatch_snapshots"

  picklists="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.dispatchpicklist WHERE id BETWEEN 52001 AND 52009;")"
  [ "$picklists" = "9" ] || die "Expected 9 practice dispatchpicklist rows, found: $picklists"

  stockfreeze_count="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stockfreeze WHERE id BETWEEN 54101 AND 54102;")"
  [ "$stockfreeze_count" = "2" ] || die "Expected 2 stockfreeze demo rows, found: $stockfreeze_count"

  stockmove_count="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stockmove WHERE id BETWEEN 54001 AND 54002;")"
  [ "$stockmove_count" = "2" ] || die "Expected 2 stockmove demo rows, found: $stockmove_count"

  stockadjust_count="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stockadjust WHERE id BETWEEN 54201 AND 54204;")"
  [ "$stockadjust_count" = "4" ] || die "Expected 4 stockadjust demo rows, found: $stockadjust_count"

  stocktaking_count="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stocktaking WHERE id BETWEEN 54301 AND 54303;")"
  [ "$stocktaking_count" = "3" ] || die "Expected 3 stocktaking demo rows, found: $stocktaking_count"

  stockprocess_count="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stockprocess WHERE id BETWEEN 54401 AND 54403;")"
  [ "$stockprocess_count" = "3" ] || die "Expected 3 stockprocess demo rows, found: $stockprocess_count"

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
  info "Importing integrated WMS practice seed SQL: $PRACTICE_SEED_FILE"
  docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" -i "$MYSQL_CONTAINER" mysql --default-character-set=utf8mb4 -uroot "$MYSQL_DATABASE" < "$PRACTICE_SEED_FILE"
  verify_seed
  info "Integrated WMS practice supplement seed has been loaded into ${MYSQL_CONTAINER}:${MYSQL_DATABASE}."
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
