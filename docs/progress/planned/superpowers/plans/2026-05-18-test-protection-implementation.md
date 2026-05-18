# Test Protection Implementation Plan

> **Execution model:** This plan is designed for a single continuous executor. Start it with `/run-plan docs/progress/planned/superpowers/plans/2026-05-18-test-protection-implementation.md` after approval. The runner creates task branches for the touched repo(s), keeps status in `.pi/runs/...`, and only stops early for explicit stop conditions.

**Goal:** Add sustainable automated test protection for ModernWMS, prioritizing API-exposed domain models, then backend core modules, with a small UI E2E smoke suite and backend coverage above 80%.

**Architecture:** Build .NET-native test projects for API E2E/BDD and backend unit/component tests, using real ASP.NET Core pipeline and real MySQL test databases. Reuse the Test-charm style as a DSL pattern: few generic steps, domain specs/repositories, and structure-based assertions rather than scenario-specific steps.

**Tech Stack:** .NET 7 test projects, xUnit, Reqnroll, Testcontainers MySQL, Microsoft.AspNetCore.Mvc.Testing or equivalent in-process host, coverlet, Playwright, Yarn Classic.

**Repo Scope:** Single repo: `ModernWMS/`.

---

## Design and Standards References

Before implementing, read these files completely:

- `docs/progress/planned/superpowers/specs/2026-05-18-test-protection-design.md`
- `docs/development-standards/testing-conventions.md`
- `docs/development-standards/backend-conventions.md`
- `docs/software-design/api-design.md`
- `docs/domain-model/README.md`
- `docs/domain-model/user-journeys.md`
- `docs/domain-model/bounded-contexts.md`
- Relevant context docs under `docs/domain-model/*/overview.md`

Do not weaken the DSL standard during implementation. If a desired scenario seems to require a new natural-language step, first try to express it through a domain spec, repository, object pattern assertion, or HTTP step.

---

## File Structure / Responsibility Map

### Existing production files to modify only if required

- Modify only if a testability issue is proven by a failing test:
  - `backend/ModernWMS/Program.cs` — allow test host configuration if current hardcoded URL/config blocks in-process E2E host.
  - `backend/ModernWMS/Startup.cs` — allow safe test service overrides only if needed.
  - `backend/ModernWMS.Core/Extentions/StartupExtensions.cs` — avoid changes unless Hangfire/test host lifecycle prevents API E2E from starting reliably.

Production changes must be minimal and must be preceded by a failing test or host-start failure captured in the test suite.

### Backend solution/config files

- Modify: `backend/ModernWMS.sln` — add test projects.
- Create: `backend/coverlet.runsettings` — coverage collection filters and output settings.
- Create: `backend/ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj` — API E2E/BDD test project.
- Create: `backend/ModernWMS.Tests.ApiE2E/reqnroll.json` — Reqnroll config for zh-CN feature files.
- Create: `backend/ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj` — backend unit/component test project.

### API E2E feature files

- Create: `backend/ModernWMS.Tests.ApiE2E/Features/Authentication/login-and-authority.feature`
- Create: `backend/ModernWMS.Tests.ApiE2E/Features/MasterData/warehouse-and-sku.feature`
- Create: `backend/ModernWMS.Tests.ApiE2E/Features/InboundExecution/asn-lifecycle.feature`
- Create: `backend/ModernWMS.Tests.ApiE2E/Features/InventoryVisibility/stock-availability.feature`
- Create: `backend/ModernWMS.Tests.ApiE2E/Features/InternalOperations/internal-stock-operations.feature`
- Create: `backend/ModernWMS.Tests.ApiE2E/Features/OutboundFulfillment/dispatch-lifecycle.feature`

### API E2E step definitions

- Create: `backend/ModernWMS.Tests.ApiE2E/Steps/AuthenticationSteps.cs` — login identity setup only.
- Create: `backend/ModernWMS.Tests.ApiE2E/Steps/HttpSteps.cs` — generic `GET/POST/PUT/DELETE` steps.
- Create: `backend/ModernWMS.Tests.ApiE2E/Steps/DataPreparationSteps.cs` — generic `假如存在"<规格名>"` step.
- Create: `backend/ModernWMS.Tests.ApiE2E/Steps/ResponseAssertionSteps.cs` — generic `response should be` step.
- Create: `backend/ModernWMS.Tests.ApiE2E/Steps/ModelAssertionSteps.cs` — generic `所有"<模型名>"应为` and `数据应为` steps.

### API E2E support / host / database

- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ModernWmsApiHost.cs` — starts the API host against test DB.
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ModernWmsDatabase.cs` — Testcontainers MySQL lifecycle and seed import.
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ModernWmsTestCollection.cs` — xUnit collection fixture for DB/API host reuse.
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ApiClient.cs` — HTTP client, auth token handling, latest response capture.
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ScenarioDataContext.cs` — current scenario id, aliases, created ids, latest response.
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ScenarioHooks.cs` — per-scenario cleanup and default login if needed.

### API E2E DSL / object pattern

- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ObjectPatterns/ObjectPatternParser.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ObjectPatterns/ObjectPatternAssertions.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ObjectPatterns/ObjectPatternNode.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ObjectPatterns/JsonProjection.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ObjectPatterns/ObjectPatternParserTests.cs`

### API E2E domain specs and repositories

- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/DomainSpec.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/DomainSpecRegistry.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/DomainRepository.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/DomainRepositoryRegistry.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/TestDataFactory.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/FieldAliasMap.cs`
- Create specs under `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Specs/`:
  - `MasterDataSpecs.cs`
  - `StockSpecs.cs`
  - `AsnSpecs.cs`
  - `DispatchlistSpecs.cs`
  - `InternalOperationSpecs.cs`
- Create repositories under `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Repositories/`:
  - `MasterDataRepositories.cs`
  - `StockRepositories.cs`
  - `AsnRepositories.cs`
  - `DispatchlistRepositories.cs`
  - `InternalOperationRepositories.cs`

### Backend unit/component tests

- Create: `backend/ModernWMS.Tests.Unit/Support/ModernWmsServiceTestDatabase.cs`
- Create: `backend/ModernWMS.Tests.Unit/Support/ServiceTestFixture.cs`
- Create: `backend/ModernWMS.Tests.Unit/Support/TestCurrentUser.cs`
- Create: `backend/ModernWMS.Tests.Unit/Services/StockServiceTests.cs`
- Create: `backend/ModernWMS.Tests.Unit/Services/AsnServiceTests.cs`
- Create: `backend/ModernWMS.Tests.Unit/Services/DispatchlistServiceTests.cs`
- Create: `backend/ModernWMS.Tests.Unit/Services/StockmoveServiceTests.cs`
- Create: `backend/ModernWMS.Tests.Unit/Services/StockfreezeServiceTests.cs`
- Create: `backend/ModernWMS.Tests.Unit/Services/StockprocessServiceTests.cs`
- Create: `backend/ModernWMS.Tests.Unit/Services/StocktakingServiceTests.cs`
- Create: `backend/ModernWMS.Tests.Unit/Core/DynamicSearchTests.cs`
- Create: `backend/ModernWMS.Tests.Unit/Core/ResultModelTests.cs`
- Create: `backend/ModernWMS.Tests.Unit/Core/TokenManagerTests.cs`

### Frontend UI E2E

- Modify: `frontend/package.json` — add Playwright test scripts/dev dependency.
- Modify: `frontend/package-lock.json` / `frontend/yarn.lock` only as package manager output requires. Prefer Yarn Classic; do not hand-edit lockfiles.
- Create: `frontend/e2e/playwright.config.ts`
- Create: `frontend/e2e/support/auth.ts`
- Create: `frontend/e2e/support/test-system.ts`
- Create: `frontend/e2e/specs/login.spec.ts`
- Create: `frontend/e2e/specs/inventory-navigation.spec.ts`
- Create: `frontend/e2e/specs/asn-navigation.spec.ts`
- Create: `frontend/e2e/specs/dispatch-navigation.spec.ts`

### Scripts and docs

- Create: `scripts/test-all.sh` — orchestrates backend tests, coverage check, and optional UI E2E.
- Create: `scripts/check-dotnet-coverage.py` — parses cobertura XML and enforces 80% line coverage for backend assemblies.
- Modify: `docs/development-standards/testing-conventions.md` — add final runnable commands and any DSL deviations discovered during implementation.
- Optionally modify: `.gitignore` — ignore coverage/test artifacts such as `TestResults/`, `coverage.cobertura.xml`, Playwright reports.

---

## Global Verification Command Guidance

Potentially long-running commands must run in `tmux` sessions with project-specific names.

Use this pattern for full/long verification:

```bash
tmux new-session -d -s modernwms-test-<name> \
  "cd /Users/wuke/code/course-practice/modernWMS/ModernWMS && zsh -c 'source \"$HOME/.zshrc\" && <command> > /tmp/modernwms-test-<name>.log 2>&1'"
```

Then inspect:

```bash
tmux list-sessions
tail -n 120 /tmp/modernwms-test-<name>.log
```

Short targeted compiler/test runs may run directly only if they complete quickly; if they start containers, install packages, build the frontend, or run Playwright, use `tmux`.

---

## Gate 1: Baseline, package compatibility, and test project scaffold

**Goal:**
- Establish test projects and confirm current backend can build under the local SDK/tooling.
- Add no production behavior changes.

**Files:**
- Modify: `backend/ModernWMS.sln`
- Create: `backend/ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj`
- Create: `backend/ModernWMS.Tests.ApiE2E/reqnroll.json`
- Create: `backend/ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj`
- Create: `backend/coverlet.runsettings`

**Preconditions / Notes:**
- The repo targets `net7.0`. If the machine only has .NET 8 SDK/runtime and cannot build `net7.0`, stop and report the missing runtime/targeting pack rather than retargeting production projects.
- Use package versions compatible with `net7.0`. Prefer stable versions; record exact versions in `.csproj`.
- Do not introduce Java/Test-charm runtime.

**Verification:**
- Run baseline first:
  ```bash
  cd backend && dotnet build ModernWMS.sln
  ```
- After scaffolding:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --no-restore
  cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --no-restore
  ```
- Expected: existing backend builds; empty/smoke test projects compile and run.

**Continue when:**
- Both new test projects are in the solution and compile.
- No production code was changed.

**Stop and report when:**
- NuGet restore cannot access required packages after one bounded retry.
- `.NET 7` targeting/runtime is unavailable and build cannot proceed.
- Reqnroll packages cannot be made compatible with `net7.0`; propose fallback `.feature` runner options before switching frameworks.

- [ ] Step 1: Run `cd backend && dotnet build ModernWMS.sln` and record baseline.
- [ ] Step 2: Create API E2E xUnit/Reqnroll project.
- [ ] Step 3: Create Unit xUnit project.
- [ ] Step 4: Add both projects to `backend/ModernWMS.sln`.
- [ ] Step 5: Add initial `backend/coverlet.runsettings`.
- [ ] Step 6: Run targeted test project builds.

---

## Gate 2: API E2E host/database/authentication spike

**Goal:**
- Prove a Reqnroll feature can start the real ModernWMS API pipeline, connect to a real MySQL Testcontainer seeded from `scripts/seeds/database_mysql.sql`, login as admin, and call an authorized endpoint.

**Files:**
- Create: `backend/ModernWMS.Tests.ApiE2E/Features/Authentication/login-and-authority.feature`
- Create: `backend/ModernWMS.Tests.ApiE2E/Steps/HttpSteps.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Steps/ResponseAssertionSteps.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ModernWmsApiHost.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ModernWmsDatabase.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ModernWmsTestCollection.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ApiClient.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ScenarioDataContext.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ScenarioHooks.cs`
- Modify only if necessary after a failing test: `backend/ModernWMS/Program.cs`, `backend/ModernWMS/Startup.cs`, `backend/ModernWMS.Core/Extentions/StartupExtensions.cs`

**Preconditions / Notes:**
- API E2E must not mock controllers/services/database.
- Prefer in-process host via `Microsoft.AspNetCore.Mvc.Testing` for coverage. It is acceptable if it uses ASP.NET Core TestServer internally, provided the full middleware/controller/service/EF pipeline runs against real MySQL.
- If in-process host cannot start because `Program.cs` hardcodes URLs or Hangfire server startup causes failures, make the smallest production change needed to allow test host configuration. Capture the failing test/host failure first.
- `ModernWmsDatabase` should import `scripts/seeds/database_mysql.sql` into the container and verify login flow data exists.

**Verification:**
- First write the feature and run it to see RED:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~Authentication"
  ```
- After implementation, run the same command again.
- Expected GREEN scenarios:
  - `POST /login` with admin/1 returns `isSuccess=true`, token, refresh token, user role id.
  - `GET /rolemenu/authority?userrole_id=...` with token returns non-empty authority list.
  - an unauthenticated business API call returns 401/authorization failure.

**Continue when:**
- Authentication feature passes repeatedly.
- Testcontainer is created/disposed or safely reused by test collection.
- No API services are mocked.

**Stop and report when:**
- The API host only works by bypassing middleware/auth/db.
- A production startup change larger than test configuration seams is required.
- MySQL seed import fails due incompatible SQL not fixable in test harness.

- [ ] Step 1: Write `login-and-authority.feature` with RED expectations.
- [ ] Step 2: Run targeted API E2E and confirm expected failure due missing infrastructure.
- [ ] Step 3: Implement MySQL Testcontainer startup and seed import.
- [ ] Step 4: Implement API host with test configuration overrides for `Database__db` and `ConnectionStrings__MySqlConn`.
- [ ] Step 5: Implement generic HTTP steps and minimal response assertions.
- [ ] Step 6: Re-run targeted feature until GREEN.

---

## Gate 3: Generic BDD DSL core and object-pattern assertions

**Goal:**
- Implement the reusable DSL mechanism required by `testing-conventions.md`: generic data preparation, generic model assertion, domain spec registry, model repository registry, and object-pattern assertions.

**Files:**
- Create: `backend/ModernWMS.Tests.ApiE2E/Steps/DataPreparationSteps.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Steps/ModelAssertionSteps.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ObjectPatterns/ObjectPatternParser.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ObjectPatterns/ObjectPatternAssertions.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ObjectPatterns/ObjectPatternNode.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ObjectPatterns/JsonProjection.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/ObjectPatterns/ObjectPatternParserTests.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/DomainSpec.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/DomainSpecRegistry.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/DomainRepository.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/DomainRepositoryRegistry.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/TestDataFactory.cs`
- Create: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/FieldAliasMap.cs`

**Preconditions / Notes:**
- This gate is infrastructure; use TDD by writing parser/assertion tests first.
- Do not add entity-specific step definitions here.
- Object-pattern support should start with the minimum needed by initial features:
  - root operators `=` and `:`;
  - objects and arrays;
  - unquoted keys;
  - single or double quoted strings;
  - numbers, booleans, null;
  - wildcard `*`;
  - field-path projection such as `body.json.data.rows.size`;
  - deterministic equality for arrays returned by model repositories.
- Add more grammar only when a feature needs it.

**Verification:**
- Run:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~ObjectPattern"
  ```
- Expected: parser/assertion unit tests pass.
- Also re-run authentication feature to ensure infrastructure did not regress.

**Continue when:**
- Generic data/model/assertion steps compile.
- Parser tests demonstrate the DSL can express critical field-level model assertions.
- No scenario-specific step was added.

**Stop and report when:**
- Implementing a DAL-like parser becomes too large for this plan. In that case propose a smaller documented subset before proceeding.

- [ ] Step 1: Write failing tests for object-pattern parsing/assertion behavior.
- [ ] Step 2: Implement the minimal parser and assertion engine.
- [ ] Step 3: Implement domain spec/repository abstractions.
- [ ] Step 4: Implement generic Given/Then steps that dispatch through registries.
- [ ] Step 5: Re-run parser tests and authentication feature.

---

## Gate 4: Master data and inventory visibility API E2E

**Goal:**
- Prove domain specs/repositories can prepare and assert core master data and stock views without adding entity-specific steps.

**Files:**
- Create: `backend/ModernWMS.Tests.ApiE2E/Features/MasterData/warehouse-and-sku.feature`
- Create: `backend/ModernWMS.Tests.ApiE2E/Features/InventoryVisibility/stock-availability.feature`
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Specs/MasterDataSpecs.cs`
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Specs/StockSpecs.cs`
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Repositories/MasterDataRepositories.cs`
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Repositories/StockRepositories.cs`

**Preconditions / Notes:**
- Use generic steps only:
  - `假如存在"<规格名>":`
  - `当POST/GET...`
  - `那么response should be:`
  - `那么所有"<模型名>"应为:`
- Specs must create required support rows for `warehouse`, `warehousearea`, `goodslocation`, `goodsowner`, `supplier`, `customer`, `category`, `spu`, `sku`, `stock` while exposing only key fields in feature files.
- Model repositories must default to current scenario data only.

**Verification:**
- Run RED after writing each feature, then implement specs/repositories until GREEN:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~MasterData|FullyQualifiedName~InventoryVisibility"
  ```
- Expected scenarios:
  - master data can be prepared and observed through relevant list/detail/select APIs;
  - stock view shows `qty`, `qty_frozen`, `qty_locked`, `qty_available` based on stock/freeze/lock data;
  - damage-area stock does not inflate normal available quantity.

**Continue when:**
- Both feature files pass.
- No entity-specific Given/Then step was added.
- Feature text exposes key identifiers and quantities, not low-level support fields.

**Stop and report when:**
- Required fields are too ambiguous to create valid master data from specs; document the missing field mapping and ask for a decision.

- [ ] Step 1: Write `warehouse-and-sku.feature` using only generic DSL.
- [ ] Step 2: Confirm RED for missing specs/repositories.
- [ ] Step 3: Implement master data specs/repositories.
- [ ] Step 4: Write `stock-availability.feature` using `可用库存`, `冻结库存`, and model assertions.
- [ ] Step 5: Implement stock specs/repositories and stock view query repository.
- [ ] Step 6: Re-run targeted features until GREEN.

---

## Gate 5: Inbound execution API E2E

**Goal:**
- Cover ASN lifecycle as API E2E: create or prepare ASN, confirm arrival, unload, sort, sorted, putaway, and assert stock facts.

**Files:**
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Features/InboundExecution/asn-lifecycle.feature`
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Specs/AsnSpecs.cs`
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Repositories/AsnRepositories.cs`
- Reuse/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Repositories/StockRepositories.cs`

**Preconditions / Notes:**
- Test the public endpoints in `backend/ModernWMS.WMS/Controllers/Asn/AsnController.cs`:
  - `PUT /asn/confirm`
  - `PUT /asn/unload`
  - `PUT /asn/sorting`
  - `PUT /asn/sorted`
  - `GET /asn/pending-putaway`
  - `PUT /asn/putaway`
  - `POST /asn/list`
- Use direct DB specs for hard-to-reach pre-states only when the scenario is not testing the upstream action itself.
- For the main happy path, prefer exercising the API actions in sequence.
- Assert `AsnEntity`, `AsnsortEntity`, and `StockEntity` model facts through repositories.

**Verification:**
- Run:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~InboundExecution"
  ```
- Expected scenarios:
  - sorted ASN can be put away and creates/updates stock layer preserving sku, goods owner, location, series number, expiry date, price, putaway date;
  - putaway quantity cannot exceed sorted quantity or invalid state fails without changing stock;
  - ASN list reflects status transitions.

**Continue when:**
- Inbound feature passes.
- Assertions show key state/quantity/stock-layer fields, not only natural-language outcomes.

**Stop and report when:**
- API contract requires undocumented payload shape not derivable from view models/controllers.
- Service behavior differs from domain docs in a way that requires product judgment.

- [ ] Step 1: Write failing ASN lifecycle feature using generic DSL.
- [ ] Step 2: Implement `到货通知`, `已分拣的 到货通知`, `分拣记录`, `库存层` specs/repositories as needed.
- [ ] Step 3: Add helper in `ApiClient` for variable interpolation only if needed, e.g. `${到货通知:ASN-E2E-001.id}`.
- [ ] Step 4: Run targeted feature until GREEN.

---

## Gate 6: Outbound fulfillment API E2E

**Goal:**
- Cover dispatch lifecycle as API E2E: create/prep dispatch, confirm order locks stock, confirm pick, package, weight, delivery deducts stock, sign completes.

**Files:**
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Features/OutboundFulfillment/dispatch-lifecycle.feature`
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Specs/DispatchlistSpecs.cs`
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Repositories/DispatchlistRepositories.cs`
- Reuse/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Specs/StockSpecs.cs`
- Reuse/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Repositories/StockRepositories.cs`

**Preconditions / Notes:**
- Test public endpoints in `backend/ModernWMS.WMS/Controllers/Dispatchlist/DispatchlistController.cs`:
  - `GET /dispatchlist/confirm-check`
  - `POST /dispatchlist/confirm-order`
  - `PUT /dispatchlist/confirm-pick-dispatchlistno`
  - `POST /dispatchlist/package`
  - `POST /dispatchlist/weight`
  - `POST /dispatchlist/delivery`
  - `POST /dispatchlist/sign`
  - `GET /dispatchlist/by-dispatch_no`
- Use `可用库存` and `新发货单` specs for setup.
- Assert `dispatch_status`, `qty`, `lock_qty`, `picked_qty`, `package_qty`, `weighing_qty`, `actual_qty`, `damage_qty`, `sign_qty`, `stock.qty`, and stock view lock/available quantities.

**Verification:**
- Run:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~OutboundFulfillment"
  ```
- Expected scenarios:
  - confirm order locks stock but does not deduct stock;
  - delivery deducts stock and marks pick rows updated;
  - sign sets final status and sign quantity;
  - insufficient stock cannot confirm order and leaves dispatch/stock unchanged.

**Continue when:**
- Outbound feature passes.
- Feature text exposes key data fields proving lock-vs-deduct behavior.

**Stop and report when:**
- Existing service behavior has a suspected bug; capture failing feature and current DB facts before proposing production fixes.

- [ ] Step 1: Write failing dispatch lifecycle feature.
- [ ] Step 2: Implement dispatch specs/repositories and picklist model assertions.
- [ ] Step 3: Run targeted feature until GREEN.

---

## Gate 7: Internal operations API E2E

**Goal:**
- Cover key internal stock operations as API E2E: move, freeze/unfreeze, process, taking/adjustment where currently exposed.

**Files:**
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Features/InternalOperations/internal-stock-operations.feature`
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Specs/InternalOperationSpecs.cs`
- Create/Modify: `backend/ModernWMS.Tests.ApiE2E/Support/Domain/Repositories/InternalOperationRepositories.cs`
- Reuse/Modify: stock specs/repositories.

**Preconditions / Notes:**
- Use controller files to confirm exact endpoint payloads before writing feature steps:
  - `backend/ModernWMS.WMS/Controllers/Stockmove/StockmoveController.cs`
  - `backend/ModernWMS.WMS/Controllers/Stockfreeze/StockfreezeController.cs`
  - `backend/ModernWMS.WMS/Controllers/Stockprocess/StockprocessController.cs`
  - `backend/ModernWMS.WMS/Controllers/Stocktaking/StocktakingController.cs`
  - `backend/ModernWMS.WMS/Controllers/Stockadjust/StockadjustController.cs`
- `StockadjustController` currently only exposes list; do not invent missing API. Cover available behavior and use service unit tests for adjustment logic if no API exists.

**Verification:**
- Run:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.ApiE2E/ModernWMS.Tests.ApiE2E.csproj --filter "FullyQualifiedName~InternalOperations"
  ```
- Expected scenarios:
  - stock move confirmation changes source/target stock layers;
  - freeze affects stock availability and can be observed through stock view;
  - process confirmation updates source/product stock facts;
  - stocktaking confirmation/adjustment behavior is covered where API exposes it.

**Continue when:**
- Internal operations feature passes and documents any intentionally uncovered API gaps.

**Stop and report when:**
- A key domain operation is not exposed by API and cannot be tested E2E without adding production API.

- [ ] Step 1: Inspect the listed controllers/view models for payload shapes.
- [ ] Step 2: Write failing feature scenarios with generic DSL.
- [ ] Step 3: Implement internal operation specs/repositories.
- [ ] Step 4: Run targeted feature until GREEN.

---

## Gate 8: Backend service/unit/component tests for coverage and edge cases

**Goal:**
- Add backend service/core tests that cover complex branches not efficiently covered by API E2E and push backend coverage above 80%.

**Files:**
- Create/Modify: `backend/ModernWMS.Tests.Unit/Support/ModernWmsServiceTestDatabase.cs`
- Create/Modify: `backend/ModernWMS.Tests.Unit/Support/ServiceTestFixture.cs`
- Create/Modify: `backend/ModernWMS.Tests.Unit/Support/TestCurrentUser.cs`
- Create/Modify:
  - `backend/ModernWMS.Tests.Unit/Services/StockServiceTests.cs`
  - `backend/ModernWMS.Tests.Unit/Services/AsnServiceTests.cs`
  - `backend/ModernWMS.Tests.Unit/Services/DispatchlistServiceTests.cs`
  - `backend/ModernWMS.Tests.Unit/Services/StockmoveServiceTests.cs`
  - `backend/ModernWMS.Tests.Unit/Services/StockfreezeServiceTests.cs`
  - `backend/ModernWMS.Tests.Unit/Services/StockprocessServiceTests.cs`
  - `backend/ModernWMS.Tests.Unit/Services/StocktakingServiceTests.cs`
  - `backend/ModernWMS.Tests.Unit/Core/DynamicSearchTests.cs`
  - `backend/ModernWMS.Tests.Unit/Core/ResultModelTests.cs`
  - `backend/ModernWMS.Tests.Unit/Core/TokenManagerTests.cs`

**Preconditions / Notes:**
- Prefer real MySQL component tests for EF-heavy services to avoid SQLite/provider behavior mismatch.
- Pure utility/core tests may use in-memory objects.
- Reuse data builders/specs where practical, but do not create a hard dependency from Unit tests to the ApiE2E project unless intentionally factored into a shared test support project. If sharing becomes necessary, create `backend/ModernWMS.Tests.Shared/` and add it to the solution; do not duplicate large builder logic.
- For each bug/edge case, write a failing test first and observe RED.

**Verification:**
- Run targeted tests by service while developing:
  ```bash
  cd backend && dotnet test ModernWMS.Tests.Unit/ModernWMS.Tests.Unit.csproj --filter "FullyQualifiedName~StockServiceTests"
  ```
- Run all backend tests with coverage:
  ```bash
  cd backend && dotnet test ModernWMS.sln --collect:"XPlat Code Coverage" --settings coverlet.runsettings
  ```
- Expected: tests pass; coverage artifacts generated.

**Continue when:**
- Each listed service/core area has meaningful tests.
- Edge cases from the design are covered.
- Coverage is trending toward 80%; if not, proceed to Gate 10 coverage hardening.

**Stop and report when:**
- Achieving coverage requires broad production refactors unrelated to testing.
- Existing service behavior appears wrong and needs a product decision before fixing.

- [ ] Step 1: Implement service test fixture and prove one service can be constructed against test DB.
- [ ] Step 2: Add RED/GREEN tests for `StockService` availability calculations.
- [ ] Step 3: Add RED/GREEN tests for ASN putaway/status edge cases.
- [ ] Step 4: Add RED/GREEN tests for dispatch lock/delivery/sign rules.
- [ ] Step 5: Add RED/GREEN tests for stock move/freeze/process/taking.
- [ ] Step 6: Add Core utility tests.
- [ ] Step 7: Run all unit/component tests.

---

## Gate 9: UI Playwright E2E smoke suite

**Goal:**
- Add a small UI E2E suite that runs against real backend, real MySQL, and real frontend dev server.

**Files:**
- Modify: `frontend/package.json`
- Modify: `frontend/yarn.lock` and/or `frontend/package-lock.json` only through package manager output.
- Create: `frontend/e2e/playwright.config.ts`
- Create: `frontend/e2e/support/auth.ts`
- Create: `frontend/e2e/support/test-system.ts`
- Create: `frontend/e2e/specs/login.spec.ts`
- Create: `frontend/e2e/specs/inventory-navigation.spec.ts`
- Create: `frontend/e2e/specs/asn-navigation.spec.ts`
- Create: `frontend/e2e/specs/dispatch-navigation.spec.ts`

**Preconditions / Notes:**
- Use Yarn Classic 1.x.
- UI tests must run against a real system. Prefer reusing `scripts/macos-dev.sh start` for local orchestration because it already starts Docker MySQL, backend, and frontend via tmux.
- Avoid excessive UI assertions. Assert login success, route/menu availability, page load, and successful API/list rendering.
- Use stable selectors where available. If selectors are missing, prefer accessible labels/text before adding production `data-testid`. If production attributes are needed, add them minimally with tests first.

**Verification:**
- Install Playwright package/browser dependencies as needed using tmux for long installs:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 yarn add -D @playwright/test --ignore-engines
  cd frontend && npx playwright install chromium
  ```
- Run UI E2E through a tmux session because it starts/uses long-running services:
  ```bash
  tmux new-session -d -s modernwms-test-ui \
    "cd /Users/wuke/code/course-practice/modernWMS/ModernWMS && zsh -c 'source \"$HOME/.zshrc\" && ./scripts/macos-dev.sh start && cd frontend && COREPACK_ENABLE_AUTO_PIN=0 yarn e2e > /tmp/modernwms-test-ui.log 2>&1; status=\$?; cd .. && ./scripts/macos-dev.sh stop; exit \$status'"
  ```
- Expected: all UI specs pass.

**Continue when:**
- UI E2E suite passes locally.
- `yarn build` still passes.

**Stop and report when:**
- UI cannot be tested reliably without significant production selector or routing changes.
- `scripts/macos-dev.sh` cannot start the stack after one bounded diagnostic attempt.

- [ ] Step 1: Add Playwright dev dependency and scripts.
- [ ] Step 2: Write failing login spec.
- [ ] Step 3: Implement UI helpers and make login spec pass.
- [ ] Step 4: Add inventory/ASN/dispatch navigation specs.
- [ ] Step 5: Run UI E2E and frontend build.

---

## Gate 10: Test orchestration, coverage enforcement, and documentation updates

**Goal:**
- Provide one repeatable test entrypoint, enforce coverage threshold, and update long-term testing docs with actual commands.

**Files:**
- Create: `scripts/test-all.sh`
- Create: `scripts/check-dotnet-coverage.py`
- Modify: `docs/development-standards/testing-conventions.md`
- Modify if needed: `.gitignore`

**Preconditions / Notes:**
- `scripts/test-all.sh` should support flags to skip slow UI tests if needed, e.g. `--skip-ui`, but default full verification should include backend and API E2E.
- Coverage check should parse cobertura XML generated by coverlet and enforce line coverage >= 80% for backend assemblies.
- Do not hide meaningful application logic from coverage. If excluding DTO/entity getter/setter files is necessary to make coverage meaningful, document the filter and rationale in `testing-conventions.md`.

**Verification:**
- Run backend full test with coverage, preferably in tmux:
  ```bash
  tmux new-session -d -s modernwms-test-backend-full \
    "cd /Users/wuke/code/course-practice/modernWMS/ModernWMS && zsh -c 'source \"$HOME/.zshrc\" && cd backend && dotnet test ModernWMS.sln --collect:\"XPlat Code Coverage\" --settings coverlet.runsettings > /tmp/modernwms-test-backend-full.log 2>&1'"
  ```
- Run coverage checker against generated cobertura path.
- Run full script:
  ```bash
  tmux new-session -d -s modernwms-test-all \
    "cd /Users/wuke/code/course-practice/modernWMS/ModernWMS && zsh -c 'source \"$HOME/.zshrc\" && ./scripts/test-all.sh > /tmp/modernwms-test-all.log 2>&1'"
  ```
- Expected: backend tests pass, coverage >= 80%, UI E2E passes unless explicitly skipped.

**Continue when:**
- `scripts/test-all.sh` runs successfully.
- Testing docs list accurate commands and prerequisites.

**Stop and report when:**
- Coverage remains below 80% after reasonable tests for all listed core services, and closing the gap requires broad unrelated production work.

- [ ] Step 1: Implement coverage parser/checker.
- [ ] Step 2: Implement `scripts/test-all.sh` with backend/API/UI phases and clear logs.
- [ ] Step 3: Run full backend coverage.
- [ ] Step 4: Add missing service tests until coverage threshold is met.
- [ ] Step 5: Update docs with actual commands and coverage scope.

---

## Gate 11: Final stabilization and regression verification

**Goal:**
- Ensure all new tests are stable, project builds still pass, and no unrelated files changed.

**Files:**
- Review all files touched by previous gates.
- No new planned files unless stabilization exposes a missing helper/doc.

**Verification:**
- Backend build:
  ```bash
  cd backend && dotnet build ModernWMS.sln
  ```
- Backend/API tests with coverage:
  ```bash
  cd backend && dotnet test ModernWMS.sln --collect:"XPlat Code Coverage" --settings coverlet.runsettings
  ```
- Frontend build:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 yarn build
  ```
- UI E2E:
  ```bash
  cd frontend && COREPACK_ENABLE_AUTO_PIN=0 yarn e2e
  ```
- Full script:
  ```bash
  ./scripts/test-all.sh
  ```

Use tmux wrappers for long/full commands per project guidance.

**Continue when:**
- All required verification passes.
- Backend coverage is above 80%.
- Git diff contains only planned test/docs/support changes or explicitly justified minimal production seams.

**Stop and report when:**
- Verification fails after one bounded diagnostic/fix attempt.
- A production bug is found that requires a separate bugfix decision.
- Full coverage target conflicts with current architecture and requires broad refactor.

- [ ] Step 1: Run full verification.
- [ ] Step 2: Inspect `git status --short` and `git diff --stat`.
- [ ] Step 3: Remove temporary files/logs/artifacts from git.
- [ ] Step 4: Ensure docs are updated.
- [ ] Step 5: Prepare final summary with verification evidence.

---

## Documentation Promotion Gate

**Goal:**
- Promote durable testing knowledge into long-term docs.

**Files:**
- Modify: `docs/development-standards/testing-conventions.md`
- Modify: `docs/development-standards/README.md` only if index changes are needed.
- Optionally modify: `AGENTS.md` only if test commands become important agent workflow conventions.

**Verification:**
- Read the updated testing conventions end-to-end.
- Confirm it includes:
  - test commands;
  - DSL rules;
  - coverage scope;
  - data isolation rules;
  - how to add a new domain spec/repository without adding a new step.

**Continue when:**
- Long-term docs accurately reflect implemented behavior.

**Stop and report when:**
- There is disagreement between implemented DSL and approved DSL standard.

- [ ] Step 1: Update docs after implementation, not before.
- [ ] Step 2: Verify docs match actual commands and file paths.

---

## General Stop Conditions for the Executor

Stop and report instead of continuing when any of these occurs:

- The plan needs an additional repo outside `ModernWMS/`.
- The public API contract must change beyond adding harmless testability seams.
- Required NuGet/npm packages cannot be restored after one bounded retry.
- Testcontainers/Docker cannot run in the environment.
- A test reveals a production behavior bug whose desired business behavior is ambiguous.
- Achieving 80% coverage requires broad production refactoring unrelated to tests.
- The implementation would violate `docs/development-standards/testing-conventions.md` by adding many scenario-specific steps.

## Success Criteria

The work is complete only when all are true:

- API E2E BDD features exist and pass for Authentication, Master Data, Inbound Execution, Inventory Visibility, Internal Operations, and Outbound Fulfillment.
- API E2E tests run against a real API pipeline and real MySQL database.
- BDD DSL uses generic data/API/assertion steps; domain growth happens through specs/repositories.
- Backend unit/component tests cover core services and core utilities.
- Backend coverage is above 80% according to the documented coverage command/scope.
- UI Playwright smoke tests pass against a real frontend/backend/database stack.
- `scripts/test-all.sh` provides a repeatable verification entrypoint.
- `docs/development-standards/testing-conventions.md` documents the final DSL, commands, and data isolation rules.
