#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/macos-dev-test-lib.sh
source "$SCRIPT_DIR/lib/macos-dev-test-lib.sh"

main() {
  local probe_table='pi_stop_keeps_db_probe'

  init_test_env 'test-macos-dev-stop-keeps-db' '33307' '22012' '5274'
  trap cleanup_runtime EXIT

  require_test_tools
  cleanup_runtime
  backup_mismatched_appsettings

  info 'Starting ModernWMS and creating probe data'
  "$MACOS_DEV_SCRIPT" start >/dev/null
  create_probe_table "$probe_table"
  assert_probe_table_exists "$probe_table"

  info 'Stopping frontend and backend only'
  "$MACOS_DEV_SCRIPT" stop >/dev/null
  assert_managed_mysql_running

  info 'Starting again and verifying probe data is preserved'
  "$MACOS_DEV_SCRIPT" start >/dev/null
  assert_probe_table_exists "$probe_table"
  assert_login_flow_ready

  info 'PASS'
}

main "$@"
