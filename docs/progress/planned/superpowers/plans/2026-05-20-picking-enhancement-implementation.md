# Picking Enhancement Implementation Plan

> **Execution model:** This plan is designed for a single continuous executor. Start it with `/run-plan docs/progress/planned/superpowers/plans/2026-05-20-picking-enhancement-implementation.md` after approval. The runner creates task branches for the touched repo(s), keeps status in `.pi/runs/...`, and only stops early for explicit stop conditions.

**Goal:** Add a runtime picking-sheet workflow to ModernWMS outbound fulfillment so users can generate a field-friendly picking view from待拣货 tasks, confirm/revoke item-level picking, record picker/checker identities, and still preserve the legacy direct whole-dispatch advance path.

**Architecture:** Extend the existing `DispatchlistService` / `Dispatchpicklist` model with a runtime read model plus two item-level command endpoints, while keeping `Delivery()` as the only stock-deduction point and treating `confirm-pick-dispatchlistno` as whole-dispatch review/fallback. Adapt the current delivery management UI by enhancing the待拣货 tab and adding a focused dialog instead of introducing a new persisted picking module.

**Tech Stack:** ASP.NET Core/.NET 7, EF Core/MySQL, xUnit unit tests, Reqnroll API E2E tests, Vue 3 + TypeScript + Vuetify + VXETable + vue3-print-nb, Playwright smoke verification.

**Repo Scope:** Single repo: `ModernWMS/`.

---

## Design and Standards References

Read these files completely before implementation and keep them open while making changes:

- `docs/progress/planned/superpowers/specs/2026-05-20-picking-enhancement-design.md`
- `docs/requirements/classroom-practice/modernwms-picking-enhancement-student-guide.md`
- `docs/domain-model/outbound-fulfillment/overview.md`
- `docs/software-design/api-design.md`
- `docs/software-design/ui-ux-style-guide.md`
- `docs/development-standards/backend-conventions.md`
- `docs/development-standards/frontend-conventions.md`
- `docs/development-standards/testing-conventions.md`

## Non-Negotiable Constraints

- **Do not read from or copy code from `ModernWMS-picking-restore/` at any point.**
- **Do not add new database tables or persisted picking-sheet identifiers.**
- **Do not change the main outbound status machine shape (`2 -> 3 -> 4 -> 5 -> 6 -> 7`).**
- **Do not move stock deduction earlier than `DispatchlistService.Delivery()`.**
- Reuse existing action codes `picked-pick`, `picked-revoke`, `picked-confirm`; do not expand the permission model unless a failing UI path proves it is necessary.

---

## File Structure / Responsibility Map

### Backend production files

- Modify: `backend/ModernWMS.WMS/Controllers/Dispatchlist/DispatchlistController.cs` — add runtime picking-sheet query endpoint and item confirm/revoke endpoints; keep whole-dispatch review endpoint in place.
- Modify: `backend/ModernWMS.WMS/IServices/Dispatchlist/IDispatchlistService.cs` — declare new query/command methods and any adjusted signatures.
- Modify: `backend/ModernWMS.WMS/Services/Dispatchlist/DispatchlistService.cs` — implement aggregation query, item-level confirm/revoke, enhanced whole-dispatch review semantics, and enriched read projections.
- Modify: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchpicklistViewModel.cs` — expose picker-related fields for detail views.
- Modify only if a failing compile/projection test proves it necessary: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistViewModel.cs` — align `pick_checker` / `pick_checker_id` exposure with the actual entity/projection contract.
- Create: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistPickingSheetQueryViewModel.cs` — request body for runtime picking-sheet generation.
- Create: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistPickingSheetViewModel.cs` — top-level response envelope for dispatch numbers plus aggregated lines.
- Create: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistPickingSheetLineViewModel.cs` — aggregated picking-line contract.
- Create: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistPickingSheetDispatchRefViewModel.cs` — related-dispatch breakdown per aggregated line.
- Create: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistPickItemsOperationViewModel.cs` — request body for item-level confirm/revoke operations.

### Backend test files

- Modify: `backend/ModernWMS.Tests.Unit/Services/DispatchlistServiceTests.cs` — cover aggregation, item-level confirm/revoke, checker recording, and legacy direct-review compatibility.
- Modify: `backend/ModernWMS.Tests.ApiE2E/Features/OutboundFulfillment/dispatch-lifecycle.feature` — add API scenarios for runtime picking-sheet query, item confirm/revoke, and review semantics.
- Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Repositories/DispatchlistRepositories.cs` — expose `picker`, `pick_checker`, and related assertion fields for model checks.

### Frontend production files

- Modify: `frontend/src/api/wms/deliveryManagement.ts` — add API wrappers for runtime picking sheet and item confirm/revoke; adjust legacy review action naming as needed.
- Modify: `frontend/src/types/DeliveryManagement/DeliveryManagement.ts` — add picking-sheet, related-dispatch, picker, and checker types.
- Modify: `frontend/src/view/deliveryManagement/deliveryManagement/tabGoodsToBePicked.vue` — add checkbox selection and open the new picking-sheet dialog from the existing待拣货 tab.
- Create: `frontend/src/view/deliveryManagement/deliveryManagement/picking-sheet-dialog.vue` — aggregated picking-sheet UI, related-dispatch view, item confirm/revoke actions, review list, and print DOM.
- Modify: `frontend/src/view/deliveryManagement/deliveryManagement/tabPicked.vue` — display checker information in已拣货 results.
- Modify: `frontend/src/view/deliveryManagement/deliveryManagement/search-delivered-detail.vue` — show `pick_qty`, `picked_qty`, and `picker` in detail modal.
- Modify: `frontend/src/view/deliveryManagement/deliveryManagement/tabShipment.vue` — keep the legacy direct action but update wording/behavior to reflect whole-dispatch review fallback.
- Modify: `frontend/src/utils/systemLog.ts` — add readable log text for new endpoints and adjust legacy review wording if semantics changed.
- Modify: `frontend/src/languages/langsJson/cn.json` — add/adjust picking-sheet, picker, checker, and review labels.
- Modify: `frontend/src/languages/langsJson/en.json` — same as above.
- Modify: `frontend/src/languages/langsJson/tw.json` — same as above.

### Frontend smoke verification files

- Create: `frontend/e2e/specs/dispatch-picking-sheet.spec.ts` — minimal seeded browser smoke for opening the picking-sheet dialog and exercising the new UI flow.

### Long-lived docs to promote after code is stable

- Modify: `docs/domain-model/outbound-fulfillment/overview.md` — document the runtime picking-sheet concept, item execution vs whole-dispatch review, and picker/checker traceability.
- Modify: `docs/software-design/api-design.md` — document the new `/dispatchlist/picking-sheet`, `/dispatchlist/confirm-pick-items`, `/dispatchlist/revoke-pick-items` endpoints and the revised semantics of `confirm-pick-dispatchlistno`.

---

## Global Verification Command Guidance

Short targeted `dotnet test` or `yarn build` runs may execute directly if they finish quickly.

Anything that starts the local dev stack or waits on web services must run in `tmux` with a project-specific session name. Use this exact pattern for browser verification:

```bash
tmux new-session -d -s modernwms-picking-ui \
  "cd /Users/wuke/code/course-practice/modernWMS/ModernWMS && zsh -c 'source \"$HOME/.zshrc\" && ./scripts/macos-dev.sh start > /tmp/modernwms-picking-ui.log 2>&1'"
```

Inspect/cleanup with:

```bash
tmux list-sessions
tail -n 120 /tmp/modernwms-picking-ui.log
tmux kill-session -t modernwms-picking-ui
```

If a `dotnet test --filter ...` expression does not match the generated Reqnroll test names, run the whole relevant test project instead of silently skipping tests.

---

### Gate 1: Backend read-model contract for runtime picking-sheet query

**Goal:**
- Add a runtime picking-sheet query that aggregates `Dispatchpicklist` rows by the approved stock-layer identity, returns related dispatch breakdowns, and exposes enough fields for the new UI without creating any persisted picking-sheet table.

**Files:**
- Create: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistPickingSheetQueryViewModel.cs`
- Create: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistPickingSheetViewModel.cs`
- Create: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistPickingSheetLineViewModel.cs`
- Create: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistPickingSheetDispatchRefViewModel.cs`
- Modify: `backend/ModernWMS.WMS/IServices/Dispatchlist/IDispatchlistService.cs`
- Modify: `backend/ModernWMS.WMS/Services/Dispatchlist/DispatchlistService.cs`
- Modify: `backend/ModernWMS.WMS/Controllers/Dispatchlist/DispatchlistController.cs`
- Modify: `backend/ModernWMS.Tests.Unit/Services/DispatchlistServiceTests.cs`
- Modify: `backend/ModernWMS.Tests.ApiE2E/Features/OutboundFulfillment/dispatch-lifecycle.feature`

**Preconditions / Notes:**
- Treat this as a pure read-model gate first; do not change item mutation behavior yet.
- Aggregate only records whose parent `dispatchlist` rows are still `dispatch_status = 2`.
- The grouping key must follow the approved stock-layer identity: `sku_id`, `goods_location_id`, `goods_owner_id`, `series_number`, `expiry_date`, `price`, `putaway_date`.
- Do not introduce a synthetic persisted `picking_sheet_no`; `group_key` is response-only.

**Verification:**
- Run unit RED first:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~DispatchlistServiceTests"
  ```
- Run API E2E RED first:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~OutboundFulfillment"
  ```
- After implementation, rerun both commands.
- Expected GREEN behavior:
  - same-SKU/same-location/same-stock-layer rows aggregate into one runtime line;
  - same-SKU/different-location rows remain split;
  - each runtime line exposes `pick_detail_ids` and `related_dispatches`.

**Continue when:**
- The runtime picking-sheet endpoint compiles and passes both unit/API tests.
- No schema changes were made.

**Stop and report when:**
- A new persisted table or schema change appears necessary.
- The approved grouping key is insufficient and product/teacher judgment is required.
- The query would need to include records outside `dispatch_status = 2` to make sense.

- [ ] Step 1: Add failing unit tests for same-layer aggregation and different-location split.
- [ ] Step 2: Run the targeted unit tests and confirm RED for the expected missing behavior.
- [ ] Step 3: Add failing API E2E scenarios for `POST /dispatchlist/picking-sheet` in `dispatch-lifecycle.feature`.
- [ ] Step 4: Run the targeted API E2E and confirm RED for the expected missing endpoint/contract.
- [ ] Step 5: Implement the new read-model viewmodels, service method, and controller endpoint with the smallest change set.
- [ ] Step 6: Re-run the targeted unit and API tests until GREEN.

---

### Gate 2: Backend item-level pick commands and whole-dispatch review compatibility

**Goal:**
- Add item-level confirm/revoke commands, record picker/checker identities, enrich existing projections, and reinterpret `confirm-pick-dispatchlistno` as whole-dispatch review/fallback without breaking the old direct path.

**Files:**
- Create: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistPickItemsOperationViewModel.cs`
- Modify: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchpicklistViewModel.cs`
- Modify only if a failing compile/projection test proves it necessary: `backend/ModernWMS.WMS/Entities/ViewModels/Dispatchlist/DispatchlistViewModel.cs`
- Modify: `backend/ModernWMS.WMS/IServices/Dispatchlist/IDispatchlistService.cs`
- Modify: `backend/ModernWMS.WMS/Services/Dispatchlist/DispatchlistService.cs`
- Modify: `backend/ModernWMS.WMS/Controllers/Dispatchlist/DispatchlistController.cs`
- Modify: `backend/ModernWMS.Tests.Unit/Services/DispatchlistServiceTests.cs`
- Modify: `backend/ModernWMS.Tests.ApiE2E/Features/OutboundFulfillment/dispatch-lifecycle.feature`
- Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Repositories/DispatchlistRepositories.cs`

**Preconditions / Notes:**
- `confirm-pick-items` and `revoke-pick-items` must only operate while the parent dispatch rows remain in `dispatch_status = 2`.
- Item-level confirm updates `Dispatchpicklist` only; it must not move `Dispatchlist.dispatch_status` to `3`.
- Whole-dispatch review still uses `confirm-pick-dispatchlistno`; it should auto-fill any unconfirmed pick rows, then write `pick_checker` / `pick_checker_id` and move the dispatch rows to `3`.
- Keep `Delivery()` as the only stock deduction point.
- Reuse existing `cancel-order` semantics for post-review rollback; do not add new post-review item-level revoke paths.

**Verification:**
- Run unit RED first:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~DispatchlistServiceTests"
  ```
- Run API E2E RED first:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~OutboundFulfillment"
  ```
- After implementation, rerun both commands.
- Expected GREEN behavior:
  - item confirm writes `picked_qty = pick_qty` and `picker` / `picker_id`;
  - item revoke clears `picked_qty` and picker info while status remains `2`;
  - whole-dispatch review writes `pick_checker` / `pick_checker_id`, moves status to `3`, and still works when no item-level confirmations were done first;
  - `GET /dispatchlist/pick-list` returns picker information for detail views.

**Continue when:**
- Unit and API tests prove both the new workflow and the legacy direct workflow.
- Existing package/weight/delivery behavior in the outbound feature still passes.

**Stop and report when:**
- Implementing checker/picker traceability appears to require schema changes.
- Any change would make stock deduction happen before `Delivery()`.
- Legacy direct review and new item-level workflow cannot coexist without a product decision.

- [ ] Step 1: Add failing unit tests for item confirm, item revoke, checker persistence, and direct-review fallback.
- [ ] Step 2: Run the targeted unit tests and confirm RED for the expected reasons.
- [ ] Step 3: Add failing API E2E scenarios for `PUT /dispatchlist/confirm-pick-items`, `PUT /dispatchlist/revoke-pick-items`, and the revised whole-dispatch review semantics.
- [ ] Step 4: Run the targeted API E2E and confirm RED.
- [ ] Step 5: Implement the new command endpoints plus the minimal service/projection changes to satisfy the tests.
- [ ] Step 6: Re-run the targeted unit and API tests until GREEN.

---

### Gate 3: Frontend integration in the existing delivery management flow

**Goal:**
- Surface the runtime picking-sheet workflow in the current delivery management UI, using the待拣货 tab as the entry point, a focused dialog for execution/review, and stable copy/logging that matches the revised backend semantics.

**Files:**
- Modify: `frontend/src/api/wms/deliveryManagement.ts`
- Modify: `frontend/src/types/DeliveryManagement/DeliveryManagement.ts`
- Modify: `frontend/src/view/deliveryManagement/deliveryManagement/tabGoodsToBePicked.vue`
- Create: `frontend/src/view/deliveryManagement/deliveryManagement/picking-sheet-dialog.vue`
- Modify: `frontend/src/view/deliveryManagement/deliveryManagement/tabPicked.vue`
- Modify: `frontend/src/view/deliveryManagement/deliveryManagement/search-delivered-detail.vue`
- Modify: `frontend/src/view/deliveryManagement/deliveryManagement/tabShipment.vue`
- Modify: `frontend/src/utils/systemLog.ts`
- Modify: `frontend/src/languages/langsJson/cn.json`
- Modify: `frontend/src/languages/langsJson/en.json`
- Modify: `frontend/src/languages/langsJson/tw.json`
- Create: `frontend/e2e/specs/dispatch-picking-sheet.spec.ts`

**Preconditions / Notes:**
- Do not add a new top-level menu or a new delivery-management tab.
- Reuse `picked-pick`, `picked-revoke`, and `picked-confirm`; only adjust UI meaning/copy.
- The new dialog should own: aggregated line display, related-dispatch view, item confirm/revoke actions, whole-dispatch review list, and print DOM.
- Start this gate with a failing browser smoke spec if the provided seed scripts can produce deterministic待拣货 data. If a stable browser precondition cannot be established within one bounded attempt using the provided seed workflow, stop and report instead of silently shipping the UI untested.
- Any long-running local stack startup must use `tmux`.

**Verification:**
- Seed data for browser verification:
  ```bash
  cd /Users/wuke/code/course-practice/modernWMS/ModernWMS && ./scripts/macos-dev.sh reset-db
  cd /Users/wuke/code/course-practice/modernWMS/ModernWMS && ./scripts/load-picking-practice-seed.sh
  ```
- Start the app stack in `tmux`:
  ```bash
  tmux new-session -d -s modernwms-picking-ui \
    "cd /Users/wuke/code/course-practice/modernWMS/ModernWMS && zsh -c 'source \"$HOME/.zshrc\" && ./scripts/macos-dev.sh start > /tmp/modernwms-picking-ui.log 2>&1'"
  ```
- Run frontend build:
  ```bash
  cd frontend && yarn build
  ```
- Run the targeted browser smoke:
  ```bash
  cd frontend && yarn e2e --grep "dispatch picking sheet"
  ```
- Expected GREEN behavior:
  - users can multi-select rows in待拣货 and open the picking-sheet dialog;
  - the dialog renders aggregated lines and related dispatches;
  - item confirm/revoke buttons call the new APIs and refresh state;
  - whole-dispatch review remains reachable from the legacy shipment view and uses updated wording;
  - print UI renders without crashing.

**Continue when:**
- `yarn build` is GREEN.
- The new Playwright smoke spec is GREEN against seeded data.

**Stop and report when:**
- A stable seeded browser path cannot be created within one bounded attempt.
- The UI would require new route/menu/permission architecture outside the approved scope.
- The smoke spec remains flaky after one bounded stabilization pass.

- [ ] Step 1: Write `frontend/e2e/specs/dispatch-picking-sheet.spec.ts` to fail against the current UI.
- [ ] Step 2: Seed the practice data, run the targeted smoke spec, and confirm RED for the expected missing UI behavior.
- [ ] Step 3: Update frontend API wrappers and TypeScript contracts to match the backend endpoints.
- [ ] Step 4: Implement `picking-sheet-dialog.vue` and wire it into `tabGoodsToBePicked.vue` with checkbox selection and dialog lifecycle.
- [ ] Step 5: Update `tabPicked.vue`, `search-delivered-detail.vue`, `tabShipment.vue`, `systemLog.ts`, and i18n copy to reflect picker/checker and review semantics.
- [ ] Step 6: Run `yarn build` and rerun the targeted smoke spec until GREEN.

---

### Gate 4: Full regression of touched outbound fulfillment behavior

**Goal:**
- Verify that the new picking flow works end-to-end and that existing outbound fulfillment stages still behave correctly after the change.

**Files:**
- No new files by default; reuse the touched backend/frontend/test files from Gates 1-3.

**Preconditions / Notes:**
- Prefer targeted regression first, then broaden only as needed.
- If the Reqnroll filter is brittle, run the entire API E2E project rather than skipping the new scenarios.
- Keep the `modernwms-picking-ui` `tmux` session alive only as long as browser verification needs it.

**Verification:**
- Backend build:
  ```bash
  cd backend && dotnet build ModernWMS.sln
  ```
- Targeted unit regression:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~DispatchlistServiceTests"
  ```
- API E2E regression:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~OutboundFulfillment"
  ```
- Frontend build:
  ```bash
  cd frontend && yarn build
  ```
- Browser smoke (if created in Gate 3):
  ```bash
  cd frontend && yarn e2e --grep "dispatch picking sheet"
  ```
- Expected:
  - backend builds cleanly;
  - outbound fulfillment tests cover the new query/command endpoints and still pass package/weight/delivery/sign flows;
  - frontend build is clean;
  - the browser smoke still passes.

**Continue when:**
- All targeted verification commands are GREEN.
- No regression indicates stock is deducted before `Delivery()` or that status progression broke after review.

**Stop and report when:**
- A regression remains after one bounded local fix attempt.
- The new flow and an existing outbound stage disagree on the intended status/quantity semantics.
- Verification depends on unstable environment behavior that cannot be reproduced.

- [ ] Step 1: Run the backend solution build.
- [ ] Step 2: Run the targeted backend unit regression.
- [ ] Step 3: Run the outbound API E2E regression.
- [ ] Step 4: Run the frontend build and browser smoke regression.
- [ ] Step 5: If any result regresses, make one bounded fix attempt and rerun the affected verification before continuing.

---

### Gate 5: Promote durable knowledge into long-lived project docs

**Goal:**
- Move the lasting business/API rules introduced by the implementation into the project’s maintained docs, leaving the spec/plan in `docs/progress/...` as process history only.

**Files:**
- Modify: `docs/domain-model/outbound-fulfillment/overview.md`
- Modify: `docs/software-design/api-design.md`

**Preconditions / Notes:**
- Only do this gate after Gate 4 is fully GREEN.
- Document stable behavior only; do not copy temporary execution notes, per-run logs, or speculative future work.
- Preserve the distinction between:
  - runtime picking-sheet view vs persisted business entity;
  - item-level execution vs whole-dispatch review;
  - review vs stock deduction.

**Verification:**
- Inspect the final doc diffs:
  ```bash
  git diff -- docs/domain-model/outbound-fulfillment/overview.md docs/software-design/api-design.md
  ```
- Expected:
  - docs accurately describe the final code behavior;
  - no temporary task notes leaked into long-lived docs.

**Continue when:**
- The docs match the implemented and verified behavior.

**Stop and report when:**
- The final code behavior differs materially from the approved spec and needs a product/teaching decision before being documented as stable.

- [ ] Step 1: Update `docs/domain-model/outbound-fulfillment/overview.md` with the new picking execution/review rules.
- [ ] Step 2: Update `docs/software-design/api-design.md` with the new endpoints and revised review semantics.
- [ ] Step 3: Review the doc diffs and confirm they describe only durable project knowledge.
- [ ] Step 4: Commit the final implementation and documentation changes on the task branch.
