#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

python3 - <<'PY'
from pathlib import Path
import sys

system_path = Path('frontend/src/store/module/system.ts')
types_path = Path('frontend/src/types/System/Store.ts')
home_path = Path('frontend/src/view/home/home.vue')
sidebar_path = Path('frontend/src/view/home/homeSideBar.vue')

system = system_path.read_text(encoding='utf-8')
types = types_path.read_text(encoding='utf-8')
home = home_path.read_text(encoding='utf-8')
sidebar = sidebar_path.read_text(encoding='utf-8')

failures = []

required_usages = {
    'home.vue uses system/sideBarWidth getter': "system/sideBarWidth",
    'homeSideBar.vue uses system/sideBarWidth getter': "system/sideBarWidth",
    'homeSideBar.vue uses system/isSideBarCollapsed getter': "system/isSideBarCollapsed",
    'homeSideBar.vue uses system/toggleSideBar mutation': "system/toggleSideBar",
}

usage_sources = {
    'home.vue uses system/sideBarWidth getter': home,
    'homeSideBar.vue uses system/sideBarWidth getter': sidebar,
    'homeSideBar.vue uses system/isSideBarCollapsed getter': sidebar,
    'homeSideBar.vue uses system/toggleSideBar mutation': sidebar,
}

for label, marker in required_usages.items():
    if marker not in usage_sources[label]:
        failures.append(f'missing usage marker: {label}')

required_store_contract = {
    'system state defines sideBarWidth': 'sideBarWidth: 300',
    'system state defines isSideBarCollapsed': 'isSideBarCollapsed: false',
    'system mutation defines toggleSideBar': 'toggleSideBar(state',
    'system mutation defines setSideBarWidth': 'setSideBarWidth(state: StateProps, width: number)',
    'system getter exposes sideBarWidth': 'sideBarWidth(state: StateProps)',
    'system getter exposes isSideBarCollapsed': 'isSideBarCollapsed(state: StateProps)',
}

for label, marker in required_store_contract.items():
    if marker not in system:
        failures.append(f'missing store contract: {label}')

required_type_contract = {
    'StateProps defines sideBarWidth': 'sideBarWidth: number',
    'StateProps defines isSideBarCollapsed': 'isSideBarCollapsed: boolean',
}

for label, marker in required_type_contract.items():
    if marker not in types:
        failures.append(f'missing type contract: {label}')

if failures:
    print('Frontend sidebar contract test failed:')
    for failure in failures:
        print(f' - {failure}')
    sys.exit(1)

print('Frontend sidebar contract test passed.')
PY
