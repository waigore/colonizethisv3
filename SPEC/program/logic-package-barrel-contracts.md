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
  publish those files. As of the #3543 slice these are:
  `orders/feedstock_bootstrap_cost.dart` and
  `orders/feedstock_extraction_targets.dart`.
  (`world/sea_reachable_provinces.dart` was a deep export through Phase 3 but
  was promoted into the `colonizethis_world` barrel by the #3543 slice, so
  `ai_api.dart` now re-exports its two symbols through the world barrel `show`
  list — see the orders/world sea-reachable promotion section below.)
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
- **Given** an `ai_api.dart` deep export of a file the owning domain barrel does **not** re-export (e.g. `orders/feedstock_extraction_targets.dart`), **when** `runCheckAiApiNarrowSurface` scans the workspace, **then** that directive is not flagged (no barrel alternative exists).
- **Given** a deep export whose file is reachable only transitively through a sub-barrel (e.g. `orders/orders.dart` re-exporting it), **when** `runCheckAiApiNarrowSurface` scans the workspace, **then** the directive is flagged as a barrel bypass.
- **Given** the `packages/colonizethis_logic/lib/ai_api.dart` file is missing, **when** `runCheckAiApiNarrowSurface` runs, **then** it returns exit code `1` and reports `Missing AI contract file`.
- **Given** a domain referenced by an `ai_api.dart` deep export whose barrel file `lib/<domain>.dart` is missing, **when** `runCheckAiApiNarrowSurface` runs, **then** it returns exit code `1` and reports the missing barrel.

## Enforcement: `repo.domain_package_barrel_import` (Phase 1)

`tool/check_domain_package_barrel_import.dart` (rule `repo.domain_package_barrel_import`) enforces the "consume siblings through barrels" principle for **deep `import` directives** between split domain packages, complementing the `ai_api.dart`-scoped Phase 3 rule.

Scope and predicate:

- The rule carries an explicit set of enforced **consumer → target** boundaries. It covers `turn → {combat, diplomacy, economy, orders, world}`, `orders → {diplomacy, economy, world}`, `combat → {world}`, `economy → {world}`, `logic → {orders, world}`, `diplomacy → {world}`, and `setup → {diplomacy, world}` — the latter two migrated by the `diplomacy/setup → sibling` slice, which completes the Phase 1 consumer set across the split domain packages. Any boundary not yet migrated is intentionally **not** enforced so the rule stays green while Phase 1 lands incrementally.
- For each enforced target, the rule resolves the target domain barrel's transitive `export` closure (following `package:` and relative `export` directives within that package's `lib/`) to the set of published `lib/src/...` files.
- **Combinator-aware publication.** A barrel `export` directive that carries a `show`/`hide` combinator publishes only a subset of its target file's symbols, so the file is treated as **not fully published** and deep imports of it remain allowed (a consumer may legitimately need a symbol the barrel withholds). Only combinator-free (full) re-exports contribute files to the published closure. Example: `colonizethis_world` re-exports `world/fog_resolution.dart` with `show` of only the coastal-visibility helpers, so `colonizethis_turn` keeps a deep import for the internal fog-decay helpers (`applyFogDecay`, `applySpyRevealTimerDecay`, `applyDistantSeaZoneFogRevert`).
- For each enforced consumer, it scans `lib/**` (excluding generated `*.g.dart` / `*.freezed.dart` / `*.mocks.dart`). An `import 'package:colonizethis_<target>/src/<file>'` directive is a **violation** when `<file>` is in that target's published closure.
- Granularity is **per file** (matching the issue's "files the barrel does not publish at all" carve-out): deep imports of files the barrel omits remain allowed until a later slice promotes them into the barrel.
- Only `import` directives are scanned. A deliberate narrow deep `export` re-export of a single internal file (for example `turn_resolution_result.dart` re-exporting `diplomacy/diplomacy_phase_result.dart`, or `naval_resolution.dart` re-exporting `world/naval_coastal_visibility.dart`/`world/naval_mission_orders.dart` to preserve a narrow consumer surface) is out of scope.

### `colonizethis_world` barrel contract (Phase 1 `turn → world` slice)

The `colonizethis_world` barrel publishes the world-state helper files that `colonizethis_turn` previously reached via deep `src/` imports, so the turn package consumes them through the barrel:

- Newly published in full: `world/game_world_mutations.dart`, `world/province_visibility_index.dart`, `world/province_traversal.dart`, `world/topology_helpers.dart`, `world/naval_mission_orders.dart`, `world/faction_membership.dart`.
- Published with a `hide` carve-out for a duplicate symbol:
  - `world/tile_key_coordinates.dart` hides `parseTileKeyCoordinates` (also published by the `colonizethis_orders` barrel as a thin forwarder to this canonical implementation; the orders barrel remains the single public source for the combined `colonizethis_logic` barrel).
- Single canonical definition (Refs #3403 Phase 1): `landTileKeysForProvinceBucket` is defined only in `world/province_lookup.dart`. The former duplicate in `world/naval_coastal_visibility.dart` was removed; the canonical function takes an opt-in `allowLocalIdFallback` flag (default `false`, strict full-id only) that naval/fog ship-reveal callers pass `true` to preserve the legacy/fixture local-id bucket fallback. Because there is no longer a second definition, `world/naval_coastal_visibility.dart` re-exports (barrel and `naval_resolution.dart`) no longer carry a `hide`/`show` carve-out for this symbol.
- Single province-lookup surface (Refs #3403 Phase 1 Step 2, wrapper removal #3843): the `WorldStateProvinceLookup` extension methods on `WorldState` (`world.getProvince`, `world.tryGetProvince`, `world.getProvinceByRegion`, `world.tryGetProvinceByRegion`) are the canonical province-lookup API. The former top-level standalone wrappers in `world/province_lookup.dart` were removed after the deprecation window; `repo.world_no_top_level_province_lookup` fails if those wrapper definitions or unqualified top-level calls reappear in `colonizethis_world/lib/**`.
- Intentionally still partial: `world/fog_resolution.dart` remains a `show`-restricted export (coastal-visibility helpers only); its internal fog-decay helpers stay package-internal and are consumed by `colonizethis_turn` via a deep import.

### `colonizethis_orders → colonizethis_world` slice

`colonizethis_orders/lib/**` previously reached the world barrel-published helper files through deep `package:colonizethis_world/src/...` imports (province/unit/player lookups, world constants, movement, naval, topology, mutations, army movement/ids, trace runtime). These are now consumed through the `colonizethis_world` barrel:

- All `colonizethis_orders/lib/**` deep `world/src` imports of fully published world files are replaced with `import 'package:colonizethis_world/colonizethis_world.dart'` (one `show allUnitsFromWorld` narrow import is rerouted to the barrel while keeping its combinator).
- Files the world barrel publishes only with a combinator stay deep imports in `colonizethis_orders` (for example `world/tile_key_coordinates.dart`, imported with an `as tile_key_coordinates` prefix for `parseTileKeyCoordinates`, which the world barrel `hide`s — see the `turn → world` contract above).
- Deep `diplomacy/src/diplomacy_resolver.dart` imports that the world barrel now satisfies transitively are removed from the affected `colonizethis_orders/lib/**` files (no behaviour change; the same symbols resolve through the world barrel).

#### Follow-up: promote remaining orders-consumed world files

A subsequent `orders → world` slice promotes two more `colonizethis_world` files that `colonizethis_orders` still reached via deep `src/` imports into the world barrel, then routes those imports through the barrel:

- Newly published in full: `world/civilian_tile_occupancy.dart` (civilian land-tile occupancy/legality helpers: `isLandTileKeyForGame`, `sortedLandTileKeys`, `civilianMayOccupyLandTileKey`) and `world/ship_instance_allocate.dart` (`mintShipInstances`).
- The four `colonizethis_orders/lib/**` deep imports of these files (in `validators/work_order_validator.dart`, `validators/move_validator.dart`, and `orders_application_build_phase.dart`) become redundant against the existing world-barrel import already present in each consumer and are removed.
- Not promoted by this slice (later promoted by the #3543 slice below): `world/sea_reachable_provinces.dart` stayed package-internal through Phase 3 and this follow-up. At the time, publishing it would have made the `ai_api.dart` deep export of it a barrel-bypass violation, so `colonizethis_orders/lib/src/orders/order_suggestion_helpers.dart` kept its deep import. The #3543 slice resolved this by promoting the file **and** re-routing the `ai_api.dart` export through the world barrel — see the orders/world sea-reachable promotion section below.

### `colonizethis_turn → {colonizethis_combat, colonizethis_orders}` follow-up slice

A subsequent slice promotes the last `colonizethis_combat` and `colonizethis_orders` files that `colonizethis_turn` still reached via deep `src/` imports into their owning domain barrels, then routes those imports through the barrels:

- Newly published by the `colonizethis_combat` barrel: `combat/military_attack_economy.dart` (land-battle attack treasury costs: `applyLandBattleAttackTreasuryCosts`, `landBattleAttackTreasuryCostForPlayer`, `militaryAttackTreasuryCostMultiplier`, `kLandBattleAttackTreasuryCostBase`) and `combat/unopposed_province_capture.dart` (`applyUnopposedProvinceCaptures`).
- Newly published by the `colonizethis_orders` barrel (via its `src/orders/orders.dart` sub-barrel): `orders/bundled_civilian_work_order.dart` (bundled civilian work move-leg validation helpers) and `orders/validators/work_order_cost_calculator.dart` (`WorkOrderCostCalculator`).
- The four `colonizethis_turn/lib/**` deep imports of these files (`turn/phases/combat_phase.dart`, `turn/combat_phase_helpers.dart`, `turn/phases/movement_phase.dart`, `turn/economy_preview_pipeline.dart`) are migrated to the owning domain barrel. The combat/orders barrel was already imported in three of the four consumers, so removing the deep import leaves the symbols resolved through the barrel; `economy_preview_pipeline.dart` gains a narrow `import 'package:colonizethis_orders/colonizethis_orders.dart' show WorkOrderCostCalculator`.
- The broad `colonizethis_logic.dart` barrel's prior deep re-export of `orders/validators/work_order_cost_calculator.dart` is dropped because the `colonizethis_orders` barrel now re-exports it transitively (no change to the combined barrel's published symbol set).

### `colonizethis_{combat, economy, logic} → sibling` slice

A subsequent slice migrates the `combat`, `economy`, and `logic` consumers off barrel-bypassing deep `src/` imports of sibling packages whose barrels already publish the owning file, then enforces those new consumer → target boundaries:

- `colonizethis_combat/lib/**` no longer deep-imports `colonizethis_world` files the world barrel publishes in full (for example `game_player_lookup.dart`, `world/province_lookup.dart`, `world/unit_lookup.dart`, `world/army_migration.dart`, `world/province_ownership_transfer.dart`, `world/faction_membership.dart`, `world/game_world_mutations.dart`); these are consumed through `import 'package:colonizethis_world/colonizethis_world.dart'`. Files the world barrel does not publish in full (for example `world/diplomatic_relation_lookup.dart`, consumed with a `show enemiesOf` combinator) keep their deep import.
- `colonizethis_economy/lib/**` no longer deep-imports fully published `colonizethis_world` files (for example `world/player_state_pipeline.dart`, `world/connectivity_resolver.dart`, `world/province_lookup.dart`, `world/faction_membership.dart`, `world/naval.dart`); these route through the world barrel (one consumer narrows the barrel import to `show GamePlayerLookup, resolveConnectivity`). Files the barrel omits (for example `world/tile_key_coordinates.dart`) keep their deep import.
- `colonizethis_logic/lib/**` routes `world/src/event_bus/game_event_bus.dart` through the world barrel and `orders/src/orders/order_suggestion_api.dart` / `order_suggestion_api_impl.dart` through the `colonizethis_orders` barrel.
- The enforced boundary map gains `combat → {world}`, `economy → {world}`, and `logic → {orders, world}`.

The predicate is derived purely from live barrel contents; the rule loads **no keyed waiver / allowlist data** (`SPEC/program/repo-lint.md` § Policy: no violation allowlists). The rule is registered in `tool/ct_repo_lint_manifest.yaml`; the repository test `test/check_domain_package_barrel_import_test.dart` asserts the real workspace stays green and exercises positive/negative fixtures.

### `colonizethis_{diplomacy, setup} → sibling` slice

A subsequent slice migrates the `diplomacy` and `setup` consumers off barrel-bypassing deep `src/` imports of sibling packages whose barrels already publish the owning file, then enforces those new consumer → target boundaries (the last Phase 1 consumers):

- `colonizethis_diplomacy/lib/**` no longer deep-imports fully published `colonizethis_world` files (for example `game_player_lookup.dart`, `world/province_lookup.dart`, `world/faction_membership.dart`, `world/army_migration.dart`, `world/game_world_mutations.dart`, `world/province_owner_cache.dart`, `world/province_ownership_transfer.dart`, `world/player_view.dart`, `world/movement.dart`, `world/ai_control.dart`, `world_constants.dart`); these route through `import 'package:colonizethis_world/colonizethis_world.dart'`. Files the world barrel publishes only with a combinator (for example `world/diplomatic_relation_lookup.dart`) or omits (for example `utils/expando_index.dart`, `world/tile_key_coordinates.dart`) keep their deep import. (`world/sea_reachable_provinces.dart` was in this omitted set through the diplomacy/setup slice but was promoted into the world barrel by the #3543 slice, so `colonizethis_diplomacy/lib/src/diplomacy/known_diplomatic_targets.dart` now consumes its symbols through the world barrel.) Deliberate narrow deep `export` re-exports (for example `diplomacy_relation_lookup.dart` re-exporting `world/diplomatic_relation_lookup.dart`, `diplomacy_resolver.dart` re-exporting `world/faction_membership.dart`) are out of scope.
- `colonizethis_setup/lib/**` no longer deep-imports fully published `colonizethis_world` files (for example `world_constants.dart`, `world/province_lookup.dart`, `world/unit_lookup.dart`, `world/game_world_mutations.dart`, `world/player_state_pipeline.dart`, `world/player_view.dart`, `world/naval.dart`, `world/ship_instance_allocate.dart`, `world/army_migration.dart`) or the fully published `colonizethis_diplomacy` file `diplomacy/diplomacy_relation_lookup.dart` (in `game_setup_create.dart`); these route through the owning domain barrel. Files the world barrel omits (for example `world/tile_key_coordinates.dart`, `world/capital_reassignment.dart`, `utils/graph_traversal.dart`) keep their deep import.
- The enforced boundary map gains `diplomacy → {world}` and `setup → {diplomacy, world}`.

The predicate is derived purely from live barrel contents; the rule loads **no keyed waiver / allowlist data**. The repository test `test/check_domain_package_barrel_import_test.dart` asserts the real workspace stays green and exercises positive/negative fixtures.

### `colonizethis_orders → colonizethis_world` sea-reachable promotion (Refs #3543)

A subsequent slice promotes the last `colonizethis_world` file that `colonizethis_orders` still reached via a deep `src/` import — `world/sea_reachable_provinces.dart` — into the world barrel, removing the final cross-package `src/` import from the orders package and resolving the encapsulation violation recorded in #3543:

- Newly published in full by the `colonizethis_world` barrel: `world/sea_reachable_provinces.dart` (`reachableNonOwnedProvinceIdsViaSeas`, `reachableNonOwnedProvinceDistancesViaSeas`).
- The deep `src/` import is removed from `colonizethis_orders/lib/src/orders/order_suggestion_helpers.dart` and `colonizethis_diplomacy/lib/src/diplomacy/known_diplomatic_targets.dart`; both already import the world barrel, which now supplies the two symbols.
- The `packages/colonizethis_logic/lib/ai_api.dart` deep export of the file is converted to a `package:colonizethis_world/colonizethis_world.dart show reachableNonOwnedProvinceDistancesViaSeas, reachableNonOwnedProvinceIdsViaSeas` re-export, keeping the AI contract symbol set unchanged while satisfying `repo.ai_api_narrow_surface` (the deep export would otherwise become a barrel bypass once the file is published).
- After this slice, **zero** `colonizethis_orders/lib/**` files import any other colonizethis package's `lib/src/**` tree. The new `repo.orders_no_cross_package_src_imports` rule (`tool/check_orders_no_cross_package_src_imports.dart`, see `SPEC/program/repo-lint.md`) gates this invariant against regression.

#### Acceptance criteria (sea-reachable promotion)

- **Given** the `colonizethis_world` barrel on `dev` after the #3543 slice, **when** `barrelPublishedSrcFiles(repoRoot, 'world')` resolves the world export closure, **then** the closure contains `src/world/sea_reachable_provinces.dart`.
- **Given** the `colonizethis_orders` and `colonizethis_diplomacy` packages on `dev` after the #3543 slice, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** no `lib/**` file in those packages deep-imports `package:colonizethis_world/src/world/sea_reachable_provinces.dart`, and the rule exits `0`.
- **Given** the `packages/colonizethis_logic/lib/ai_api.dart` file on `dev` after the #3543 slice, **when** `runCheckAiApiNarrowSurface` scans the workspace, **then** it exits `0` (the sea-reachable symbols route through the world barrel `show` list, not a deep `src/` export).

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
- **Given** the post-`orders → world`-slice `colonizethis_orders` package on `dev`, **when** `repo.domain_package_barrel_import` resolves the `world` barrel export closure, **then** no `import 'package:colonizethis_world/src/<file>'` directive in `colonizethis_orders/lib/**` targets a fully published world file and the rule exits `0`.
- **Given** the enforced consumer → target boundary map, **when** the rule is loaded, **then** the map includes `orders → {world}` (asserted by `test/check_domain_package_barrel_import_test.dart`).
- **Given** a `colonizethis_orders` lib file that imports `package:colonizethis_world/src/world/province_lookup.dart` while the `colonizethis_world` barrel already re-exports that file, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** it returns exit code `1` and lists the offending file with a "use import 'package:colonizethis_world/colonizethis_world.dart'" message.
- **Given** the `colonizethis_world` barrel on `dev` after the orders-consumed follow-up slice, **when** `barrelPublishedSrcFiles(repoRoot, 'world')` resolves the world export closure, **then** the closure contains both `src/world/civilian_tile_occupancy.dart` and `src/world/ship_instance_allocate.dart`.
- **Given** the `colonizethis_orders` package on `dev` after the orders-consumed follow-up slice, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** no `colonizethis_orders/lib/**` file imports `package:colonizethis_world/src/world/civilian_tile_occupancy.dart` or `package:colonizethis_world/src/world/ship_instance_allocate.dart` and the rule exits `0`.
- **Given** the `colonizethis_world` barrel on `dev` after the #3543 slice, **when** `barrelPublishedSrcFiles(repoRoot, 'world')` resolves the world export closure, **then** the closure contains `src/world/sea_reachable_provinces.dart` (promoted into the barrel), so any deep `import` of it from an enforced consumer's `lib/**` is flagged as a barrel bypass.
- **Given** the `colonizethis_combat` barrel on `dev` after the `turn → combat` follow-up slice, **when** `barrelPublishedSrcFiles(repoRoot, 'combat')` resolves the combat export closure, **then** the closure contains both `src/combat/military_attack_economy.dart` and `src/combat/unopposed_province_capture.dart`.
- **Given** the `colonizethis_orders` barrel on `dev` after the `turn → orders` follow-up slice, **when** `barrelPublishedSrcFiles(repoRoot, 'orders')` resolves the orders export closure, **then** the closure contains both `src/orders/bundled_civilian_work_order.dart` and `src/orders/validators/work_order_cost_calculator.dart`.
- **Given** the `colonizethis_turn` package on `dev` after the `turn → {combat, orders}` follow-up slice, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** no `colonizethis_turn/lib/**` file deep-imports `combat/military_attack_economy.dart`, `combat/unopposed_province_capture.dart`, `orders/bundled_civilian_work_order.dart`, or `orders/validators/work_order_cost_calculator.dart`, and the rule exits `0`.
- **Given** the enforced consumer → target boundary map after the `combat/economy/logic → sibling` slice, **when** the rule is loaded, **then** the map includes `combat → {world}`, `economy → {world}`, and `logic → {orders, world}` (asserted by `test/check_domain_package_barrel_import_test.dart`).
- **Given** the `colonizethis_combat`, `colonizethis_economy`, and `colonizethis_logic` packages on `dev` after the `combat/economy/logic → sibling` slice, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** no `lib/**` file in those packages deep-imports a fully published `colonizethis_world` or `colonizethis_orders` file on the enforced boundaries, and the rule exits `0`.
- **Given** a `colonizethis_combat` lib file that imports `package:colonizethis_world/src/world/unit_lookup.dart` while the `colonizethis_world` barrel already re-exports that file, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** it returns exit code `1` and lists the offending file with a "use import 'package:colonizethis_world/colonizethis_world.dart'" message.
- **Given** the enforced consumer → target boundary map after the `diplomacy/setup → sibling` slice, **when** the rule is loaded, **then** the map includes `diplomacy → {world}` and `setup → {diplomacy, world}` (asserted by `test/check_domain_package_barrel_import_test.dart`).
- **Given** the `colonizethis_diplomacy` and `colonizethis_setup` packages on `dev` after the `diplomacy/setup → sibling` slice, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** no `lib/**` file in those packages deep-imports a fully published `colonizethis_world` or `colonizethis_diplomacy` file on the enforced boundaries, and the rule exits `0`.
- **Given** a `colonizethis_setup` lib file that imports `package:colonizethis_diplomacy/src/diplomacy/diplomacy_relation_lookup.dart` while the `colonizethis_diplomacy` barrel already re-exports that file, **when** `runCheckDomainPackageBarrelImport` scans the workspace, **then** it returns exit code `1` and lists the offending file with a "use import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'" message.

## Cross-cutting

- The broad `colonizethis_logic.dart` barrel continues to re-export the full domain barrels for `app/`, `ctdev/`, and package tests; narrowing `ai_api.dart` does not change that surface.
- Because the AI package is forbidden from importing the broad `colonizethis_logic.dart` barrel in `lib/**` (`colonizethis-logic-ai-decoupling.mdc`), symbols genuinely required by AI stay published by `ai_api.dart`; the Phase 3 work re-routes them through domain barrels rather than removing them.
