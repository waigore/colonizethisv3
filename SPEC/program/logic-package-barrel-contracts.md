# Logic package barrel contracts

**SPEC/program** — Public barrel contract for the split logic-domain packages and the narrow `colonizethis_logic` contract libraries. Companion to `SPEC/program/logic-package-split-phase0.md` (epic #3290) and `SPEC/program/repo-and-packages.md`. Phase 3 of the barrel-refactor umbrella (Refs #3393).

## Principle: consume siblings through barrels

Each domain package (`world`, `combat`, `economy`, `diplomacy`, `orders`, `turn`, `setup`) exposes its public surface through its top-level barrel `package:colonizethis_<domain>/colonizethis_<domain>.dart`. Files under `lib/src/**` that the barrel does **not** re-export are package-internal.

Consumers (sibling domains, the thin `colonizethis_logic` core, the AI contract libraries) MUST import a sibling symbol through that sibling's barrel whenever the barrel already publishes the owning file. A deep `package:colonizethis_<domain>/src/...` import/export is permitted only for a symbol the domain barrel does not yet publish; promoting such a file into its barrel (a future Phase 1 barrel-bypass slice) is preferred over widening deep-import usage.

## AI narrow contract (`ai_api.dart`)

`packages/colonizethis_logic/lib/ai_api.dart` is the explicit, narrow logic surface consumed by `colonizethis_ai` (`colonizethis-logic-ai-decoupling.mdc`). It deliberately avoids re-exporting the broad `colonizethis_logic.dart` barrel.

Contract:

- Sibling-domain symbols are re-exported through the domain barrel
  (`package:colonizethis_<domain>/colonizethis_<domain>.dart show ...`), never
  through a deep `src/` path that the barrel already re-exports.
- The package-local `src/constants.dart` is owned by the thin `colonizethis_logic`
  core itself (no sibling barrel exists), so it remains a package-relative export.
- The remaining deep `src/` exports are grouped under an in-code justification
  block and are permitted **only** because the owning domain barrel does not
  publish those files. As of Phase 3 these are:
  `orders/feedstock_bootstrap_cost.dart`,
  `orders/feedstock_extraction_targets.dart`, and
  `world/sea_reachable_provinces.dart`.
- The exported **symbol set** consumed by `colonizethis_ai` is unchanged by the
  Phase 3 narrowing; only the export routing (deep `src/` → domain barrel)
  changes, so AI planner behaviour and tests are preserved.

## Enforcement: `repo.ai_api_narrow_surface`

`tool/check_ai_api_narrow_surface.dart` (rule `repo.ai_api_narrow_surface`) scans `ai_api.dart`. For every `export 'package:colonizethis_<domain>/src/<file>'` directive it resolves the owning domain barrel's transitive `export` closure (following `package:` and relative `export` directives within that package's `lib/`). The directive is a **violation** when the barrel's closure already contains `<file>` — i.e. a barrel re-export alternative exists.

The predicate is derived purely from the live barrel contents; the rule loads **no keyed waiver / allowlist data** (`SPEC/program/repo-lint.md` § Policy: no violation allowlists). Deep exports of files the barrel does not publish are not flagged because no barrel alternative exists.

The rule is registered in `tool/ct_repo_lint_manifest.yaml` and dispatched in-process by `tool/ct_repo_lint_lib.dart`; the repository test `test/check_ai_api_narrow_surface_test.dart` asserts the real workspace stays green and exercises positive/negative fixtures.

### Acceptance criteria (`repo.ai_api_narrow_surface`)

- **Given** the post-Phase-3 `packages/colonizethis_logic/lib/ai_api.dart` on `dev`, **when** `repo.ai_api_narrow_surface` resolves each domain barrel's transitive export closure, **then** no `export 'package:colonizethis_<domain>/src/<file>'` directive targets a file already published by that domain barrel and the rule exits `0`.
- **Given** an `ai_api.dart` that deep-exports `package:colonizethis_world/src/world/ai_control.dart` while the `colonizethis_world` barrel already re-exports that file, **when** `runCheckAiApiNarrowSurface` scans the workspace, **then** it returns exit code `1` and lists the offending `ai_api.dart:<line>` with a "bypasses the colonizethis_world barrel" message.
- **Given** an `ai_api.dart` that re-exports a symbol through `package:colonizethis_<domain>/colonizethis_<domain>.dart show ...`, **when** `runCheckAiApiNarrowSurface` scans the workspace, **then** that directive is not flagged.
- **Given** an `ai_api.dart` deep export of a file the owning domain barrel does **not** re-export (e.g. `world/sea_reachable_provinces.dart`), **when** `runCheckAiApiNarrowSurface` scans the workspace, **then** that directive is not flagged (no barrel alternative exists).
- **Given** a deep export whose file is reachable only transitively through a sub-barrel (e.g. `orders/orders.dart` re-exporting it), **when** `runCheckAiApiNarrowSurface` scans the workspace, **then** the directive is flagged as a barrel bypass.
- **Given** the `packages/colonizethis_logic/lib/ai_api.dart` file is missing, **when** `runCheckAiApiNarrowSurface` runs, **then** it returns exit code `1` and reports `Missing AI contract file`.
- **Given** a domain referenced by an `ai_api.dart` deep export whose barrel file `lib/<domain>.dart` is missing, **when** `runCheckAiApiNarrowSurface` runs, **then** it returns exit code `1` and reports the missing barrel.

## Enforcement: `repo.domain_package_barrel_import` (Phase 1)

`tool/check_domain_package_barrel_import.dart` (rule `repo.domain_package_barrel_import`) enforces the "consume siblings through barrels" principle for **deep `import` directives** between split domain packages, complementing the `ai_api.dart`-scoped Phase 3 rule.

Scope and predicate:

- The rule carries an explicit set of enforced **consumer → target** boundaries. It covers `turn → {economy, diplomacy, world}` — `economy`/`diplomacy` migrated by the Phase 1 lead slice and `world` migrated by the `turn → world` slice — and grows as later Phase 1 slices migrate `combat`, `orders`, and the `orders → world` deep imports. Boundaries not yet migrated are intentionally **not** enforced so the rule stays green while Phase 1 lands incrementally.
- For each enforced target, the rule resolves the target domain barrel's transitive `export` closure (following `package:` and relative `export` directives within that package's `lib/`) to the set of published `lib/src/...` files.
- **Combinator-aware publication.** A barrel `export` directive that carries a `show`/`hide` combinator publishes only a subset of its target file's symbols, so the file is treated as **not fully published** and deep imports of it remain allowed (a consumer may legitimately need a symbol the barrel withholds). Only combinator-free (full) re-exports contribute files to the published closure. Example: `colonizethis_world` re-exports `world/fog_resolution.dart` with `show` of only the coastal-visibility helpers, so `colonizethis_turn` keeps a deep import for the internal fog-decay helpers (`applyFogDecay`, `applySpyRevealTimerDecay`, `applyDistantSeaZoneFogRevert`).
- For each enforced consumer, it scans `lib/**` (excluding generated `*.g.dart` / `*.freezed.dart` / `*.mocks.dart`). An `import 'package:colonizethis_<target>/src/<file>'` directive is a **violation** when `<file>` is in that target's published closure.
- Granularity is **per file** (matching the issue's "files the barrel does not publish at all" carve-out): deep imports of files the barrel omits remain allowed until a later slice promotes them into the barrel.
- Only `import` directives are scanned. A deliberate narrow deep `export` re-export of a single internal file (for example `turn_resolution_result.dart` re-exporting `diplomacy/diplomacy_phase_result.dart`, or `naval_resolution.dart` re-exporting `world/naval_coastal_visibility.dart`/`world/naval_mission_orders.dart` to preserve a narrow consumer surface) is out of scope.

### `colonizethis_world` barrel contract (Phase 1 `turn → world` slice)

The `colonizethis_world` barrel publishes the world-state helper files that `colonizethis_turn` previously reached via deep `src/` imports, so the turn package consumes them through the barrel:

- Newly published in full: `world/game_world_mutations.dart`, `world/province_visibility_index.dart`, `world/province_traversal.dart`, `world/topology_helpers.dart`, `world/naval_mission_orders.dart`, `world/faction_membership.dart`.
- Published with a `hide` carve-out for a duplicate symbol:
  - `world/naval_coastal_visibility.dart` hides `landTileKeysForProvinceBucket` (also defined in the already-published `world/province_lookup.dart`; the latter remains the single public source).
  - `world/tile_key_coordinates.dart` hides `parseTileKeyCoordinates` (also published by the `colonizethis_orders` barrel as a thin forwarder to this canonical implementation; the orders barrel remains the single public source for the combined `colonizethis_logic` barrel).
- Intentionally still partial: `world/fog_resolution.dart` remains a `show`-restricted export (coastal-visibility helpers only); its internal fog-decay helpers stay package-internal and are consumed by `colonizethis_turn` via a deep import.

The predicate is derived purely from live barrel contents; the rule loads **no keyed waiver / allowlist data** (`SPEC/program/repo-lint.md` § Policy: no violation allowlists). The rule is registered in `tool/ct_repo_lint_manifest.yaml`; the repository test `test/check_domain_package_barrel_import_test.dart` asserts the real workspace stays green and exercises positive/negative fixtures.

### Acceptance criteria (`repo.domain_package_barrel_import`)

- **Given** the post-Phase-1-lead-slice `colonizethis_turn` package on `dev`, **when** `repo.domain_package_barrel_import` resolves the `economy` and `diplomacy` barrel export closures, **then** no `import 'package:colonizethis_economy/src/<file>'` or `import 'package:colonizethis_diplomacy/src/<file>'` directive in `colonizethis_turn/lib/**` targets a file published by that barrel and the rule exits `0`.
- **Given** a `colonizethis_turn` lib file that imports `package:colonizethis_economy/src/economy/economy_production.dart` while the `colonizethis_economy` barrel already re-exports that file, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** it returns exit code `1` and lists the offending file with a "use import 'package:colonizethis_economy/colonizethis_economy.dart'" message.
- **Given** a `colonizethis_turn` lib file that deep-imports a target file the owning barrel does **not** publish, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** that directive is not flagged (no barrel alternative exists).
- **Given** a `colonizethis_turn` lib file with a deliberate narrow deep `export` (not `import`) of an enforced-target file, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** that directive is not flagged.
- **Given** a generated file (`*.g.dart`) containing a bypassing deep import, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** that file is skipped and not flagged.
- **Given** an enforced consumer package whose `lib/` tree is missing, **when** `runCheckDomainPackageBarrelImport` runs, **then** it returns exit code `1`.
- **Given** the post-`turn → world`-slice `colonizethis_turn` package on `dev`, **when** `repo.domain_package_barrel_import` resolves the `world` barrel export closure, **then** no `import 'package:colonizethis_world/src/<file>'` directive in `colonizethis_turn/lib/**` targets a fully published world file and the rule exits `0`.
- **Given** a `colonizethis_world` barrel that re-exports `src/world/fog_resolution.dart` with a `show` combinator, **when** `barrelPublishedSrcFiles` resolves the world closure, **then** `src/world/fog_resolution.dart` is **not** in the published set.
- **Given** a `colonizethis_turn` lib file that deep-imports `package:colonizethis_world/src/world/fog_resolution.dart` while the world barrel re-exports that file only with a `show` combinator, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** that directive is not flagged and the rule exits `0`.

## Cross-cutting

- The broad `colonizethis_logic.dart` barrel continues to re-export the full domain barrels for `app/`, `ctdev/`, and package tests; narrowing `ai_api.dart` does not change that surface.
- Because the AI package is forbidden from importing the broad `colonizethis_logic.dart` barrel in `lib/**` (`colonizethis-logic-ai-decoupling.mdc`), symbols genuinely required by AI stay published by `ai_api.dart`; the Phase 3 work re-routes them through domain barrels rather than removing them.
