#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/macos-dev-test-lib.sh
source "$SCRIPT_DIR/lib/macos-dev-test-lib.sh"

PRACTICE_SEED_SCRIPT="$REPO_ROOT/scripts/load-picking-practice-seed.sh"

assert_picking_practice_seed_loaded() {
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
  local suppliers
  local asn_masters
  local asn_bug_a
  local asn_bug_b
  local mainline_asn
  local mainline_dispatch
  local dispatch_snapshots
  local stockfreeze_count
  local stockmove_count
  local stockadjust_count
  local stocktaking_count
  local stockprocess_count
  local mainline_stock_rows

  users="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.user WHERE user_num IN ('picker01','checker01');")"
  [ "$users" = "2" ] || fail "Expected 2 practice users, got: $users"

  roles="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.userrole WHERE role_name IN ('picker','checker');")"
  [ "$roles" = "2" ] || fail "Expected 2 practice roles, got: $roles"

  warehouse="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.warehouse WHERE id=51001;")"
  [ "$warehouse" = "1" ] || fail "Expected practice warehouse to exist"

  locations="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.goodslocation WHERE location_name IN ('PICK-A-01','PICK-A-02','STOCK-A-01','STOCK-A-02');")"
  [ "$locations" = "4" ] || fail "Expected 4 practice locations, got: $locations"

  suppliers="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.supplier WHERE id BETWEEN 50901 AND 50903;")"
  [ "$suppliers" = "3" ] || fail "Expected 3 practice suppliers, got: $suppliers"

  asn_masters="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.asnmaster WHERE asn_no IN ('ASN-E2E-001','ASN-BUG-001','ASN-BUG-002','ASN-DEMO-UNLOAD-001','ASN-DEMO-SORT-001','ASN-DEMO-GROUND-001','ASN-DEMO-RECEIPT-001');")"
  [ "$asn_masters" = "7" ] || fail "Expected 7 ASN master scenarios, got: $asn_masters"

  asn_bug_a="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.asn a JOIN \`${MYSQL_DATABASE}\`.sku s ON s.id = a.sku_id WHERE a.asn_no='ASN-BUG-001' AND a.supplier_name='华东供应商A' AND s.sku_name='ASN查询演练箱-基础款';")"
  [ "$asn_bug_a" = "1" ] || fail "Expected ASN-BUG-001 to match supplier and SKU bug scenario, got: $asn_bug_a"

  asn_bug_b="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.asn a JOIN \`${MYSQL_DATABASE}\`.sku s ON s.id = a.sku_id WHERE a.asn_no='ASN-BUG-002' AND a.supplier_name='华南供应商B' AND s.sku_name='ASN查询演练袋-基础款';")"
  [ "$asn_bug_b" = "1" ] || fail "Expected ASN-BUG-002 to match supplier and SKU bug scenario, got: $asn_bug_b"

  mainline_asn="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.asn WHERE asn_no='ASN-E2E-001' AND asn_status=0 AND sku_id=51703 AND asn_qty=8;")"
  [ "$mainline_asn" = "1" ] || fail "Expected ASN-E2E-001 mainline notice data to exist, got: $mainline_asn"

  mainline_stock_rows="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stock WHERE sku_id=51703;")"
  [ "$mainline_stock_rows" = "0" ] || fail "Expected no pre-existing stock for mainline SKU 51703, got: $mainline_stock_rows"

  mainline_dispatch="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.dispatchlist WHERE dispatch_no='DP-E2E-001' AND dispatch_status=0 AND sku_id=51703;")"
  [ "$mainline_dispatch" = "1" ] || fail "Expected DP-E2E-001 pre-shipment mainline data to exist, got: $mainline_dispatch"

  dispatches="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.dispatchlist WHERE dispatch_no IN ('DP-TRAIN-001','DP-TRAIN-002','DP-TRAIN-003');")"
  [ "$dispatches" = "3" ] || fail "Expected 3 picking training dispatchlists, got: $dispatches"

  dispatch_snapshots="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.dispatchlist WHERE dispatch_no IN ('DP-DEMO-NEW-001','DP-DEMO-PICKED-001','DP-DEMO-PACKAGED-001','DP-DEMO-WEIGHED-001','DP-DEMO-DELIVERED-001','DP-DEMO-SIGNED-001');")"
  [ "$dispatch_snapshots" = "6" ] || fail "Expected 6 dispatch lifecycle snapshot rows, got: $dispatch_snapshots"

  picklists="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.dispatchpicklist WHERE id BETWEEN 52001 AND 52009;")"
  [ "$picklists" = "9" ] || fail "Expected 9 practice dispatchpicklist rows, got: $picklists"

  stockfreeze_count="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stockfreeze WHERE id BETWEEN 54101 AND 54102;")"
  [ "$stockfreeze_count" = "2" ] || fail "Expected 2 stockfreeze demo rows, got: $stockfreeze_count"

  stockmove_count="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stockmove WHERE id BETWEEN 54001 AND 54002;")"
  [ "$stockmove_count" = "2" ] || fail "Expected 2 stockmove demo rows, got: $stockmove_count"

  stockadjust_count="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stockadjust WHERE id BETWEEN 54201 AND 54204;")"
  [ "$stockadjust_count" = "4" ] || fail "Expected 4 stockadjust demo rows, got: $stockadjust_count"

  stocktaking_count="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stocktaking WHERE id BETWEEN 54301 AND 54302;")"
  [ "$stocktaking_count" = "2" ] || fail "Expected 2 stocktaking demo rows, got: $stocktaking_count"

  stockprocess_count="$(mysql_exec "SELECT COUNT(*) FROM \`${MYSQL_DATABASE}\`.stockprocess WHERE id BETWEEN 54401 AND 54402;")"
  [ "$stockprocess_count" = "2" ] || fail "Expected 2 stockprocess demo rows, got: $stockprocess_count"

  picker_name_hex="$(mysql_exec "SELECT HEX(user_name) FROM \`${MYSQL_DATABASE}\`.user WHERE user_num='picker01';")"
  [ "$picker_name_hex" = "E68BA3E8B4A7E591982DE69D8EE6988E" ] || fail "Expected picker01 user_name to be stored as UTF-8 Chinese, got HEX: $picker_name_hex"

  checker_name_hex="$(mysql_exec "SELECT HEX(user_name) FROM \`${MYSQL_DATABASE}\`.user WHERE user_num='checker01';")"
  [ "$checker_name_hex" = "E5A48DE6A0B8E591982DE78E8BE6958F" ] || fail "Expected checker01 user_name to be stored as UTF-8 Chinese, got HEX: $checker_name_hex"

  warehouse_name_hex="$(mysql_exec "SELECT HEX(warehouse_name) FROM \`${MYSQL_DATABASE}\`.warehouse WHERE id=51001;")"
  [ "$warehouse_name_hex" = "E7BB83E4B9A0E4B880E58FB7E4BB93" ] || fail "Expected warehouse_name to be stored as UTF-8 Chinese, got HEX: $warehouse_name_hex"

  admin_actions="$(mysql_exec "SELECT menu_actions_authority FROM \`${MYSQL_DATABASE}\`.rolemenu WHERE userrole_id=1 AND menu_id=19;")"
  printf '%s' "$admin_actions" | grep -q 'picked-pick' || fail "Expected admin deliveryManagement actions to include picked-pick"
}

main() {
  init_test_env 'test-load-picking-practice-seed' '33309' '22014' '5276'
  trap cleanup_runtime EXIT

  require_test_tools
  cleanup_runtime

  info 'Resetting managed MySQL to the bundled base seed'
  "$MACOS_DEV_SCRIPT" reset-db >/dev/null
  assert_managed_mysql_running

  info 'Loading the integrated WMS practice supplement seed'
  "$PRACTICE_SEED_SCRIPT" >/dev/null

  info 'Verifying the integrated supplement seed data'
  assert_picking_practice_seed_loaded

  info 'PASS'
}

main "$@"
