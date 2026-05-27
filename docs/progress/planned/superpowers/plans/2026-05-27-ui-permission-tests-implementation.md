# UI Permission Tests Implementation Plan

> **Execution model:** This plan is designed for a single continuous executor. Start it with `/run-plan docs/progress/planned/superpowers/plans/2026-05-27-ui-permission-tests-implementation.md` after approval. The runner creates task branches for the touched repo(s), keeps status in `.pi/runs/...`, and only stops early for explicit stop conditions.

**Goal:** Add role-driven Playwright UI permission coverage for ModernWMS so menu visibility and action enable/disable behavior are protected across the current reachable frontend permission surface.

**Architecture:** Extend the existing Playwright smoke suite with API-based role/user bootstrap, reusable business-state bundles, and a permission manifest that maps the approved 24 menu entries and 146 reachable `menu + code` coverage points. Add only minimal production test hooks (`data-menu-path`, `aria-label`, optional `data-auth-code`) so permission selectors are stable without changing business behavior.

**Tech Stack:** Vue 3, Vuetify, Playwright, Yarn Classic, existing ModernWMS backend HTTP APIs, `scripts/macos-dev.sh` local stack.

**Repo Scope:** Single repo: `ModernWMS/`.

---

## Design and Standards References

Before implementing, read these files completely:

- `docs/progress/planned/superpowers/specs/2026-05-27-ui-permission-test-design.md`
- `docs/development-standards/testing-conventions.md`
- `docs/development-standards/frontend-conventions.md`
- `docs/software-design/api-design.md`
- `docs/domain-model/user-journeys.md`
- `docs/domain-model/system-management/overview.md`
- `docs/domain-model/master-data/overview.md`
- `docs/domain-model/inbound-execution/overview.md`
- `docs/domain-model/inventory-visibility/overview.md`
- `docs/domain-model/internal-operations/overview.md`
- `docs/domain-model/outbound-fulfillment/overview.md`

Do not change the approved permission semantics during implementation:

- no menu permission → sidebar entry absent
- menu permission but no action permission → related control visible but disabled
- orphan codes and currently unreachable commented-out controls remain out of scope

---

## File Structure / Responsibility Map

### Existing production files to modify

- Modify: `frontend/src/view/home/homeSideBar.vue` — expose stable `data-menu-path` attributes for sidebar permission assertions.
- Modify: `frontend/src/components/tooltip-btn.vue` — expose stable button hooks (`aria-label` from tooltip text, optional `data-auth-code`) without changing behavior.
- Modify: `frontend/src/components/system/btnGroup.vue` — pass each configured `code` into the tooltip button hook so top action buttons are machine-addressable.
- Modify only if a failing test proves current row-scoped `aria-label` selectors are insufficient:
  - `frontend/src/view/wms/stockAsn/tabNotice.vue`
  - `frontend/src/view/wms/stockAsn/tabToDoArrival.vue`
  - `frontend/src/view/wms/stockAsn/tabToDoUnload.vue`
  - `frontend/src/view/wms/stockAsn/tabToDoSorting.vue`
  - `frontend/src/view/wms/stockAsn/tabToDoGrounding.vue`
  - `frontend/src/view/warehouseWorking/warehouseMove/warehouseMove.vue`
  - `frontend/src/view/warehouseWorking/warehouseProcessing/warehouseProcessing.vue`
  - `frontend/src/view/warehouseWorking/warehouseTaking/warehouseTaking.vue`
  - `frontend/src/view/warehouseWorking/warehouseFreeze/warehouseFreeze.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabShipment.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabPackaged.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabWeighed.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabDelivered.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabSignIn.vue`

Production changes must stay minimal and must be driven by a failing Playwright permission test.

### Existing e2e files to modify

- Modify: `frontend/e2e/playwright.config.ts` — force serial execution for permission specs and keep failure artifacts.
- Modify: `frontend/e2e/support/auth.ts` — keep `loginAsAdmin()` compatibility while adding generic role-user login helpers.
- Modify: `frontend/e2e/support/test-system.ts` — add stack/shell helpers reused by both smoke and permission specs.
- Keep green as regression checks:
  - `frontend/e2e/specs/login.spec.ts`
  - `frontend/e2e/specs/inventory-navigation.spec.ts`
  - `frontend/e2e/specs/asn-navigation.spec.ts`
  - `frontend/e2e/specs/dispatch-navigation.spec.ts`

### New e2e support files

- Create: `frontend/e2e/support/api-client.ts` — authenticated backend API helper for login, roles, menus, users, and bundle setup.
- Create: `frontend/e2e/support/permission-bootstrap.ts` — idempotent creation/alignment of the seven approved business roles and their test users.
- Create: `frontend/e2e/support/business-bundles.ts` — reusable setup for `system-and-masterdata-baseline`, `asn-workbench-bundle`, `stock-and-statistics-bundle`, `internal-operations-bundle`, and `dispatch-workbench-bundle`.
- Create: `frontend/e2e/support/selectors.ts` — stable locators for sidebar entries, tabs, top buttons, and row buttons.
- Create: `frontend/e2e/support/permission-assertions.ts` — common assertions for visible/hidden/enabled/disabled semantics.
- Create: `frontend/e2e/support/permission-manifest.ts` — the approved coverage manifest for 24 menus and 146 reachable `menu + code` entries, grouped by context/spec.

### New permission spec files

- Create: `frontend/e2e/specs/permissions/sidebar-visibility.spec.ts`
- Create: `frontend/e2e/specs/permissions/system-management-permissions.spec.ts`
- Create: `frontend/e2e/specs/permissions/master-data-permissions.spec.ts`
- Create: `frontend/e2e/specs/permissions/inbound-permissions.spec.ts`
- Create: `frontend/e2e/specs/permissions/inventory-and-statistics-permissions.spec.ts`
- Create: `frontend/e2e/specs/permissions/internal-operations-permissions.spec.ts`
- Create: `frontend/e2e/specs/permissions/outbound-fulfillment-permissions.spec.ts`

### Durable documentation to update at the end

- Modify: `docs/development-standards/testing-conventions.md` — add the role-driven UI permission test pattern, manifest expectation, and bundle setup conventions.
- Modify: `docs/development-standards/frontend-conventions.md` — document the stable permission test hooks (`data-menu-path`, button `aria-label`, optional `data-auth-code`) for future frontend work.

---

## Global Verification Command Guidance

Use `./scripts/macos-dev.sh start` / `status` / `stop` for the real UI stack. The script already manages backend/frontend tmux sessions internally; do not invent a second long-running startup path.

For full or slow UI verification, run the Playwright command inside tmux so the executor can inspect logs without blocking the shell:

```bash
tmux new-session -d -s modernwms-permission-ui \
  "cd /Users/wuke/code/course-practice/modernWMS/ModernWMS && zsh -c 'source \"$HOME/.zshrc\" && ./scripts/macos-dev.sh start && cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/permissions && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn build; status=$?; cd ..; ./scripts/macos-dev.sh stop; exit $status' > /tmp/modernwms-permission-ui.log 2>&1"
```

Inspect with:

```bash
tail -n 120 /tmp/modernwms-permission-ui.log
tmux list-sessions
```

Short targeted Playwright specs may run directly once the stack is already healthy.

---

## Gate 1: Selector hooks and permission test foundation

**Goal:**
- Add the minimal production hooks and generic e2e helpers needed to write stable permission tests without changing permission behavior.
- Keep the existing smoke specs working.

**Files:**
- Modify: `frontend/src/view/home/homeSideBar.vue`
- Modify: `frontend/src/components/tooltip-btn.vue`
- Modify: `frontend/src/components/system/btnGroup.vue`
- Modify: `frontend/e2e/playwright.config.ts`
- Modify: `frontend/e2e/support/auth.ts`
- Modify: `frontend/e2e/support/test-system.ts`
- Create: `frontend/e2e/support/api-client.ts`
- Create: `frontend/e2e/support/selectors.ts`
- Create: `frontend/e2e/support/permission-assertions.ts`
- Create: `frontend/e2e/support/permission-bootstrap.ts`
- Create: `frontend/e2e/specs/permissions/sidebar-visibility.spec.ts`

**Preconditions / Notes:**
- Keep `loginAsAdmin()` backward compatible so the existing smoke specs do not need gratuitous rewrites.
- `tooltip-btn.vue` should derive `aria-label` from the existing tooltip text so direct row-button callers can be located without adding props everywhere.
- Do not touch page-level business components unless a failing test proves `aria-label` plus row scoping is insufficient.

**Verification:**
- Start or confirm stack health:
  ```bash
  ./scripts/macos-dev.sh start
  ./scripts/macos-dev.sh status
  ```
- Run the first failing/then passing targeted spec:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/permissions/sidebar-visibility.spec.ts
  ```
- Re-run existing smoke login after helper changes:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/login.spec.ts
  ```

**Continue when:**
- Sidebar entries expose stable `data-menu-path` values.
- Top action buttons expose stable labels and optional auth hooks.
- The new sidebar spec can drive one positive and one negative menu case.
- Existing smoke login still passes.

**Stop and report when:**
- Vuetify component structure prevents stable selector hooks without a broad refactor.
- The first permission spec requires a test-only backend endpoint rather than existing login/role/user APIs.
- Existing smoke specs fail after a bounded helper compatibility fix attempt.

- [ ] Step 1: Write `frontend/e2e/specs/permissions/sidebar-visibility.spec.ts` for one approved menu visibility case and watch it fail.
- [ ] Step 2: Add the minimal selector hooks in `homeSideBar.vue`, `tooltip-btn.vue`, and `btnGroup.vue`.
- [ ] Step 3: Implement generic auth/API/selector/assertion helpers.
- [ ] Step 4: Re-run the targeted permission spec until it passes.
- [ ] Step 5: Re-run `login.spec.ts` as a regression check.

---

## Gate 2: Full role bootstrap and sidebar visibility matrix

**Goal:**
- Encode the approved seven-role model and cover all 24 sidebar visibility expectations.
- Establish the authoritative permission manifest skeleton early.

**Files:**
- Modify: `frontend/e2e/support/permission-bootstrap.ts`
- Create: `frontend/e2e/support/permission-manifest.ts`
- Modify: `frontend/e2e/specs/permissions/sidebar-visibility.spec.ts`

**Preconditions / Notes:**
- `permission-bootstrap.ts` must be idempotent: if a role or user already exists under the `E2E-PERM-*` / `e2e_perm_*` prefixes, align it instead of duplicating it.
- Capture the generated password from the backend user-creation response and persist it in test memory only; do not hardcode credentials.
- The manifest must distinguish menu entries from action entries so later gates can fill in the remaining 146 action points incrementally.

**Verification:**
- Confirm stack health if needed:
  ```bash
  ./scripts/macos-dev.sh status
  ```
- Run the sidebar suite:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/permissions/sidebar-visibility.spec.ts
  ```

**Continue when:**
- All 24 approved menu entries are represented in the manifest and exercised by the sidebar suite.
- The seven roles from the approved spec can be created/aligned automatically.
- Positive and negative sidebar cases both pass.

**Stop and report when:**
- The current backend APIs cannot align role/menu/action assignments without destructive cleanup.
- The executor finds a reachable menu not accounted for in the approved 24-entry list and cannot prove whether it is in or out of scope.
- Manifest counts diverge from the approved design and the difference cannot be traced to a real reachable-vs-unreachable code distinction.

- [ ] Step 1: Expand the sidebar spec to cover the approved role/menu matrix and confirm the new cases fail.
- [ ] Step 2: Implement idempotent role/user/menu alignment for the seven approved roles.
- [ ] Step 3: Create the permission manifest with all 24 menu entries and placeholder action coverage groups.
- [ ] Step 4: Re-run the sidebar suite until all approved menu cases pass.

---

## Gate 3: System management and master data permission suites

**Goal:**
- Cover the system-management and master-data contexts with role-driven specs and a reusable baseline data bundle.

**Files:**
- Create: `frontend/e2e/support/business-bundles.ts`
- Modify: `frontend/e2e/support/permission-manifest.ts`
- Create: `frontend/e2e/specs/permissions/system-management-permissions.spec.ts`
- Create: `frontend/e2e/specs/permissions/master-data-permissions.spec.ts`
- Modify only if a failing selector proves necessary:
  - `frontend/src/view/base/companySetting/companySetting.vue`
  - `frontend/src/view/base/userRoleSetting/userRoleSetting.vue`
  - `frontend/src/view/base/userManagement/userManagement.vue`
  - `frontend/src/view/base/print/print.vue`
  - `frontend/src/view/base/commodityCategorySetting/commodityCategorySetting.vue`
  - `frontend/src/view/base/commodityManagement/commodityManagement.vue`
  - `frontend/src/view/base/supplier/supplier.vue`
  - `frontend/src/view/base/warehouseSetting/tab-warehouse.vue`
  - `frontend/src/view/base/warehouseSetting/tab-reservoir.vue`
  - `frontend/src/view/base/warehouseSetting/tab-location.vue`
  - `frontend/src/view/base/ownerOfCargo/ownerOfCargo.vue`
  - `frontend/src/view/base/freightSetting/freightSetting.vue`
  - `frontend/src/view/base/customer/customer.vue`

**Preconditions / Notes:**
- `business-bundles.ts` should add `system-and-masterdata-baseline` first and reuse it in later gates instead of duplicating setup logic.
- For master-data and system pages, prefer top-button assertions for `BtnGroup`-driven permissions and row-scoped `aria-label` assertions for direct row buttons.
- `roleMenu` remains entry-only; do not invent action assertions for it.

**Verification:**
- Run the targeted system-management suite:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/permissions/system-management-permissions.spec.ts
  ```
- Run the targeted master-data suite:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/permissions/master-data-permissions.spec.ts
  ```

**Continue when:**
- The manifest covers the approved system-management and master-data action entries.
- The baseline bundle is reusable and idempotent.
- Both suites pass with the approved positive/negative role semantics.

**Stop and report when:**
- Existing APIs cannot build the baseline master data without unstable hidden defaults or ambiguous required fields.
- A page requires broad template refactoring just to expose one selector.
- A permission point behaves inconsistently with the approved semantics and the difference appears to be a product decision rather than a test bug.

- [ ] Step 1: Write failing system-management permission specs for one positive and one auditor-negative case.
- [ ] Step 2: Implement `system-and-masterdata-baseline` in `business-bundles.ts`.
- [ ] Step 3: Fill the manifest entries for system-management coverage and make the suite pass.
- [ ] Step 4: Write failing master-data permission specs, including `warehouseSetting` tab coverage.
- [ ] Step 5: Fill the manifest entries for master-data coverage and make the suite pass.
- [ ] Step 6: Commit a checkpoint if the executor benefits from a stable halfway save.

---

## Gate 4: Inbound and inventory/statistics permission suites

**Goal:**
- Cover `stockAsn` and the inventory/statistics pages with approved role semantics and stable bundle data.

**Files:**
- Modify: `frontend/e2e/support/business-bundles.ts`
- Modify: `frontend/e2e/support/permission-manifest.ts`
- Create: `frontend/e2e/specs/permissions/inbound-permissions.spec.ts`
- Create: `frontend/e2e/specs/permissions/inventory-and-statistics-permissions.spec.ts`
- Modify only if a failing selector proves necessary:
  - `frontend/src/view/wms/stockAsn/tabNotice.vue`
  - `frontend/src/view/wms/stockAsn/tabToDoArrival.vue`
  - `frontend/src/view/wms/stockAsn/tabToDoUnload.vue`
  - `frontend/src/view/wms/stockAsn/tabToDoSorting.vue`
  - `frontend/src/view/wms/stockAsn/tabToDoGrounding.vue`
  - `frontend/src/view/wms/stockAsn/tabReceiptDetails.vue`
  - `frontend/src/view/wms/stockManagement/tabStock.vue`
  - `frontend/src/view/wms/stockManagement/tabStockLocation.vue`
  - `frontend/src/view/statisticAnalysis/saftyStock/saftyStock.vue`
  - `frontend/src/view/statisticAnalysis/asnStatistic/asnStatistic.vue`
  - `frontend/src/view/statisticAnalysis/deliveryStatistic/deliveryStatistic.vue`
  - `frontend/src/view/statisticAnalysis/stockageStatistic/stockageStatistic.vue`

**Preconditions / Notes:**
- Build `asn-workbench-bundle` so each inbound action is asserted against the correct workflow state: do not let status-based disablement masquerade as permission disablement.
- Build `stock-and-statistics-bundle` so the inventory/statistics pages load real rows and can assert export-related permissions.
- Respect the approved reachable-surface scope: do not reintroduce commented-out `notice-printQrCode` coverage.

**Verification:**
- Run the inbound suite:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/permissions/inbound-permissions.spec.ts
  ```
- Run the inventory/statistics suite:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/permissions/inventory-and-statistics-permissions.spec.ts
  ```

**Continue when:**
- The manifest covers the approved inbound and inventory/statistics action entries.
- The bundles can be rerun without manual cleanup.
- Both suites pass using positive role and auditor-negative role expectations.

**Stop and report when:**
- A required inbound or statistics state cannot be reached reliably through existing APIs or approved fixture logic after one bounded retry.
- The executor discovers a page whose reachable permission behavior contradicts the approved counts and cannot determine whether the design or the app is wrong.

- [ ] Step 1: Write failing inbound permission specs covering at least one row-action and one top-button case.
- [ ] Step 2: Implement `asn-workbench-bundle` and make those cases pass.
- [ ] Step 3: Fill all inbound manifest entries and finish the suite.
- [ ] Step 4: Write failing inventory/statistics permission specs for the approved reachable export controls.
- [ ] Step 5: Implement `stock-and-statistics-bundle`, fill the manifest entries, and make the suite pass.

---

## Gate 5: Internal operations permission suite

**Goal:**
- Cover the internal stock-operation pages with stable bundle setup and correct role semantics.

**Files:**
- Modify: `frontend/e2e/support/business-bundles.ts`
- Modify: `frontend/e2e/support/permission-manifest.ts`
- Create: `frontend/e2e/specs/permissions/internal-operations-permissions.spec.ts`
- Modify only if a failing selector proves necessary:
  - `frontend/src/view/warehouseWorking/warehouseMove/warehouseMove.vue`
  - `frontend/src/view/warehouseWorking/warehouseProcessing/warehouseProcessing.vue`
  - `frontend/src/view/warehouseWorking/warehouseTaking/warehouseTaking.vue`
  - `frontend/src/view/warehouseWorking/warehouseFreeze/warehouseFreeze.vue`
  - `frontend/src/view/warehouseWorking/warehouseAdjust/warehouseAdjust.vue`

**Preconditions / Notes:**
- `internal-operations-bundle` must produce rows in states where `confirm`, `confirmOpeartion`, `confirmAdjust`, `freeze`, and `unfreeze` would be enabled for a fully authorized user.
- Scope delete assertions to rows whose workflow state permits deletion; otherwise the test will conflate workflow disablement with permission disablement.
- Reuse the `system-and-masterdata-baseline` and stock-producing bundles instead of duplicating upstream setup.

**Verification:**
- Run the suite:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/permissions/internal-operations-permissions.spec.ts
  ```

**Continue when:**
- The manifest covers all approved internal-operations action entries.
- The suite passes for both authorized and auditor-negative cases.
- Bundle setup is deterministic across reruns.

**Stop and report when:**
- Existing APIs cannot create one of the required pending/confirmable internal-operation states without an unapproved shortcut.
- One internal-operation page needs selector changes broader than the minimal hook strategy from Gate 1.

- [ ] Step 1: Write failing internal-operations specs for one row-action and one top-button case.
- [ ] Step 2: Implement `internal-operations-bundle` and make those cases pass.
- [ ] Step 3: Fill all internal-operations manifest entries and finish the suite.

---

## Gate 6: Outbound fulfillment permission suite

**Goal:**
- Cover the current reachable `deliveryManagement` permission surface with state-correct dispatch bundle data.

**Files:**
- Modify: `frontend/e2e/support/business-bundles.ts`
- Modify: `frontend/e2e/support/permission-manifest.ts`
- Create: `frontend/e2e/specs/permissions/outbound-fulfillment-permissions.spec.ts`
- Modify only if a failing selector proves necessary:
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabShipment.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabPreShipment.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabNewShipment.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabGoodsToBePicked.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabPicked.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabPackaged.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabWeighed.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabDelivered.vue`
  - `frontend/src/view/deliveryManagement/deliveryManagement/tabSignIn.vue`

**Preconditions / Notes:**
- The dispatch bundle must create representative rows for each reachable tab/state so the suite can distinguish permission disablement from state disablement.
- Stay within the approved reachable surface: do not pull commented/unmounted legacy tabs back into scope.
- Keep `invoice-*`, `picked-*`, `packaged-*`, `weighed-*`, `delivered-*`, and `signedIn-*` assertions grouped by the approved business journey rather than by raw code enumeration.

**Verification:**
- Run the suite:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/permissions/outbound-fulfillment-permissions.spec.ts
  ```

**Continue when:**
- The manifest covers all approved outbound action entries.
- The suite passes for both fully authorized outbound role and auditor-negative role.
- Dispatch bundle setup is repeatable and leaves the stack reusable for a full suite run.

**Stop and report when:**
- A required dispatch state cannot be reached reliably with existing APIs after one bounded retry.
- The outbound page exposes a reachable permission control that is not in the approved manifest and the difference cannot be resolved from the spec.
- Stabilizing one outbound selector would require broad template rewrites beyond minimal testability hooks.

- [ ] Step 1: Write failing outbound specs for one representative positive and one auditor-negative fulfillment case.
- [ ] Step 2: Implement `dispatch-workbench-bundle` and make those cases pass.
- [ ] Step 3: Fill all outbound manifest entries and finish the suite.

---

## Gate 7: Full verification and documentation promotion

**Goal:**
- Prove the full permission suite runs end-to-end against the real stack.
- Promote the durable testing/hook conventions into long-term project docs.

**Files:**
- Modify: `docs/development-standards/testing-conventions.md`
- Modify: `docs/development-standards/frontend-conventions.md`
- Modify only if final suite learnings require tiny stabilization tweaks:
  - `frontend/e2e/playwright.config.ts`
  - `frontend/e2e/support/*`

**Preconditions / Notes:**
- Keep the manifest count aligned with the approved design: 24 menus and 146 reachable action entries.
- Promote only durable conventions; do not dump transient run notes into long-term docs.
- Because the full UI run and build are long operations, use tmux for the combined verification command.

**Verification:**
- Health check:
  ```bash
  ./scripts/macos-dev.sh status
  ```
- Full permission suite:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e e2e/specs/permissions
  ```
- Full frontend e2e regression:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn e2e
  ```
- Frontend build:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 corepack yarn build
  ```

**Continue when:**
- The full permission suite passes.
- Existing smoke specs still pass as part of the full e2e run.
- `yarn build` passes.
- Long-term docs describe the stable permission-test hooks and role/bundle conventions.

**Stop and report when:**
- The full suite only passes in isolation but fails when run as a group after one bounded isolation fix attempt.
- Build failures reveal unrelated frontend debt outside the approved permission-test scope.
- The executor would need to weaken or remove a documented selector hook convention to get green.

- [ ] Step 1: Run the full permission suite and record the first integrated failure, if any.
- [ ] Step 2: Fix one bounded integration/isolation issue if needed, then rerun.
- [ ] Step 3: Run the full frontend e2e suite.
- [ ] Step 4: Run `yarn build`.
- [ ] Step 5: Update `testing-conventions.md` and `frontend-conventions.md` with durable learnings only.
- [ ] Step 6: Commit final implementation and documentation updates.

---

## Success Criteria Checklist

The executor should consider the plan complete only when all of the following are true:

- [ ] Sidebar visibility coverage exists for all 24 approved menus.
- [ ] Action coverage exists for all 146 approved reachable `menu + code` entries.
- [ ] The permission manifest is checked into the repo and matches the approved scope.
- [ ] Authorized-role specs and auditor-negative specs both pass for every covered context.
- [ ] Existing navigation/login smoke specs still pass.
- [ ] `frontend` builds successfully.
- [ ] Durable UI permission testing conventions have been promoted to long-term docs.

## Explicit Non-Goals

Do **not** do any of the following as part of this plan:

- add backend test-only permission endpoints
- expand scope to orphan codes, commented-out controls, or currently unmounted legacy tabs
- change the product semantics from “disabled” to “hidden” for action permissions
- refactor unrelated frontend pages just to make tests prettier
- touch `ModernWMS-picking-restore/`
