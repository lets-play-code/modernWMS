#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKIP_UI=0
THRESHOLD="${MODERNWMS_COVERAGE_THRESHOLD:-0.80}"

for arg in "$@"; do
  case "$arg" in
    --skip-ui) SKIP_UI=1 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

export DOTNET_ROLL_FORWARD="${DOTNET_ROLL_FORWARD:-Major}"
export PATH="/Users/wuke/.asdf/installs/nodejs/24.15.0/bin:$PATH"

cd "$REPO_ROOT/backend"
echo "[test-all] Running backend tests with coverage"
find . -path '*/TestResults' -type d -prune -exec rm -rf {} +
dotnet test ModernWMS.sln --collect:"XPlat Code Coverage" --settings coverlet.runsettings

mapfile -t coverage_files < <(find . -path '*/TestResults/*/coverage.cobertura.xml' -type f -print | sort)
if [[ "${#coverage_files[@]}" -eq 0 ]]; then
  echo "[test-all] coverage.cobertura.xml not found" >&2
  exit 1
fi
python3 "$REPO_ROOT/scripts/check-dotnet-coverage.py" "${coverage_files[@]}" --threshold "$THRESHOLD"

if [[ "$SKIP_UI" -eq 1 ]]; then
  echo "[test-all] Skipping UI E2E"
  exit 0
fi

cd "$REPO_ROOT"
echo "[test-all] Running UI E2E"
./scripts/macos-dev.sh start
set +e
(
  cd frontend
  COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e
)
ui_status=$?
set -e
./scripts/macos-dev.sh stop
exit "$ui_status"
