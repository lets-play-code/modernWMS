#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/macos-dev-test-lib.sh
source "$SCRIPT_DIR/lib/macos-dev-test-lib.sh"

main() {
  local probe_table='pi_reset_db_probe'

  init_test_env 'test-macos-dev-reset-db' '33308' '22013' '5275'
  trap cleanup_runtime EXIT

  require_test_tools
  cleanup_runtime
  backup_mismatched_appsettings

  info 'Starting ModernWMS and creating probe data'
  "$MACOS_DEV_SCRIPT" start >/dev/null
  create_probe_table "$probe_table"
  assert_probe_table_exists "$probe_table"

  info 'Resetting database'
  "$MACOS_DEV_SCRIPT" reset-db >/dev/null
  assert_managed_mysql_running
  assert_probe_table_missing "$probe_table"

  info 'Starting again and verifying login still works after reset'
  "$MACOS_DEV_SCRIPT" start >/dev/null
  assert_login_flow_ready

  info 'PASS'
}

main "$@"
