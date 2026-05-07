#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/macos-dev-test-lib.sh
source "$SCRIPT_DIR/lib/macos-dev-test-lib.sh"

main() {
  init_test_env 'test-macos-dev-mysql-start' '33306' '22011' '5273'
  trap cleanup_runtime EXIT

  require_test_tools
  cleanup_runtime
  backup_mismatched_appsettings

  info 'Starting ModernWMS with script-managed Docker MySQL'
  "$MACOS_DEV_SCRIPT" start >/dev/null

  info 'Verifying Docker MySQL is running and login flow is healthy'
  assert_managed_mysql_running
  assert_login_flow_ready

  info 'PASS'
}

main "$@"
