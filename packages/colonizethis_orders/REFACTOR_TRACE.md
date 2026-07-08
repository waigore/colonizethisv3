# Orders refactor trace (wave 3)

Wave-3 maintenance for `packages/colonizethis_orders` (Refs #3949). Pattern mirrors
economy phase 3 (#3939): support consolidation, scenario harness, description
baseline, prefer-scenario-tables advisory.

## Wave 3 — Slice 1 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| support-tree | relocate non-`*_test.dart` fixtures/helpers under `test/orders/support/` | former `test/orders/*_test_support.dart`, `*fixtures*`, `*helpers*`, `validators/**/*_test_support.dart` | `test/orders/support/{diplomatic,incremental,engine,application,suggestion,validators/**}` | #3949 |
| scenario-harness | add `runLabeledScenario` / `runLabeledScenarios` | — | `test/orders/support/scenario_runner.dart` | #3949 |
| description-baseline | commit 475 single-line `test`/`testWidgets` descriptions | `test/**/*_test.dart` | `test/DESCRIPTION_BASELINE.txt` + `repo.orders_test_preserved_descriptions` | #3949 |
| support-layout-gate | CI forbids new non-test Dart at `test/orders/` root | — | `tool/check_orders_test_support_layout.dart` | #3949 |
| prefer-scenario-tables-gate | advisory prefer-scenario-tables (baseline allow-all on at kickoff) | — | `tool/check_orders_scenario_table_runner.dart` | #3949 |
| gp-minor-path | update GP–Minor fixture canonical path | `tool/check_orders_test_dedup_gp_minor_game.dart` | `support/diplomatic/diplomatic_orders_test_fixtures.dart` | #3877, #3949 |

test/ LOC: **33,048** baseline (unchanged this slice — support moves only). Family scenario migrations and ≥20% LOC reduction deferred to later slices.

## Wave 3 — Slice 2 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| move-civilian-gp | civilian cannot move into other GP territory | `move_validator_part1_test.dart` | `support/validators/move_validator_scenarios.dart` + `move_validator_test.dart` | #3949 |
| move-military-regiment | military regiment MoveOrder is rejected; use army move | `move_validator_part1_test.dart` | same | #3949 |
| army-move-gp-no-war | ArmyMoveValidator military cannot move into other GP province without war | `move_validator_part1_test.dart` | same | #3949 |
| move-civilian-minor | civilian worker cannot move into Minor/Tribe territory | `move_validator_part1_test.dart` | same | #3949 |
| move-explorer-minor | Explorer may move onto Minor province tile (cross-region style) | `move_validator_part2_test.dart` | same | #3949 |
| move-spy-gp | Spy may move onto other Great Power province tile without declare war | `move_validator_part2_test.dart` | same | #3949 |
| move-explorer-tribe-xregion | explorer can move cross-region into tribe-owned province | `move_validator_part2_test.dart` | same | #3949 |
| move-builder-tribe-xregion | builder cross-region into tribe-owned province is still invalid | `move_validator_part2_test.dart` | same | #3949 |
| move-prev-rejected | short-circuits when previous order rejected | `move_validator_part3_test.dart` | same | #3949 |
| army-move-minor-no-war | ArmyMoveValidator military cannot move into Minor province without war | `move_validator_part3_test.dart` | same | #3949 |
| army-move-gp-declare | ArmyMoveValidator military may move into other GP province with same-turn declareWar | `move_validator_part3_test.dart` | same | #3949 |
| army-move-minor-declare | ArmyMoveValidator military may move into Minor province with same-turn declareWar | `move_validator_part3_test.dart` | same | #3949 |
| army-move-tribe-declare | ArmyMoveValidator military may move into Tribe province with same-turn declareWar | `move_validator_part3_test.dart` | same | #3949 |
| army-move-minor-tribe-no-war | ArmyMoveValidator military cannot move into Minor/Tribe province without war | `move_validator_part3_test.dart` | same | #3949 |

Merged `move_validator_part{1,2,3}_test.dart` → `validators/move_validator_test.dart` (≤400 lines). Family LOC moved into `move_validator_expectations.dart` + `move_validator_scenarios.dart`.

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| naval-move-prev-rejected | validateNavalMove rejects when previousRejected | `naval_order_validator_part1_test.dart` | `support/validators/naval_order_validator_scenarios.dart` + `naval_order_validator_test.dart` | #3949 |
| naval-move-fleet-not-found | validateNavalMove rejects when fleet not found | `naval_order_validator_part1_test.dart` | same | #3949 |
| naval-move-fleet-not-owned | validateNavalMove rejects when fleet not owned by player | `naval_order_validator_part1_test.dart` | same | #3949 |
| naval-move-home-fleet | validateNavalMove rejects when home fleet | `naval_order_validator_part1_test.dart` | same | #3949 |
| naval-move-adjacent-sea | validateNavalMove accept move to adjacent sea zone when at sea | `naval_order_validator_part1_test.dart` | same | #3949 |
| naval-move-non-adjacent-sea | validateNavalMove reject move to non-adjacent sea zone | `naval_order_validator_part1_test.dart` | same | #3949 |
| naval-move-dock-not-adjacent | validateNavalMove dock reject when sea zone not adjacent to province | `naval_order_validator_part2_test.dart` | same | #3949 |
| naval-move-undock | validateNavalMove accept undock from port to adjacent sea zone | `naval_order_validator_part2_test.dart` | same | #3949 |
| naval-move-prov-as-sea | validateNavalMove at sea rejects province id as destinationSeaZoneId | `naval_order_validator_part2_test.dart` | same | #3949 |
| naval-move-inport-direct-ps | validateNavalMove in-port accepts any sea with direct P–S edge to port | `naval_order_validator_part2_test.dart` | same | #3949 |
| naval-move-inport-ss-only | validateNavalMove in-port rejects sea only reachable via S–S from port sea | `naval_order_validator_part2_test.dart` | same | #3949 |
| naval-move-broken-inport | validateNavalMove reject when in port but inPortAtProvinceId null | `naval_order_validator_part2_test.dart` | same | #3949 |
| naval-dock-adjacent-owned | validateNavalMove dock accept when at sea adjacent owned province | `naval_order_validator_docking_test.dart` | same | #3949 |
| naval-dock-local-port-id | validateNavalMove dock accept when port province id is local (unprefixed) | `naval_order_validator_docking_test.dart` | same | #3949 |
| naval-dock-fleet-in-port | validateNavalMove dock reject when fleet in port | `naval_order_validator_docking_test.dart` | same | #3949 |
| naval-dock-not-owned | validateNavalMove dock reject when port province not owned | `naval_order_validator_docking_test.dart` | same | #3949 |
| naval-dock-port-not-found | validateNavalMove dock reject when port province not found | `naval_order_validator_docking_test.dart` | same | #3949 |
| naval-mission-prev-rejected | validateNavalMission rejects when previousRejected | `naval_order_validator_mission_test.dart` | same | #3949 |
| naval-mission-blockade-no-target | validateNavalMission blockade requires target province | `naval_order_validator_mission_test.dart` | same | #3949 |
| naval-mission-blockade-unprefixed | validateNavalMission blockade reject when target not prefixed | `naval_order_validator_mission_test.dart` | same | #3949 |
| naval-mission-blockade-own | validateNavalMission blockade reject when blockading own province | `naval_order_validator_mission_test.dart` | same | #3949 |
| naval-mission-patrol | validateNavalMission accept non-blockade mission when fleet at sea | `naval_order_validator_mission_test.dart` | same | #3949 |

Merged `naval_order_validator_{part1,part2,docking,mission}_test.dart` → `validators/naval_order_validator_test.dart` (≤400 lines). Family LOC moved into `naval_order_validator_expectations.dart` + `naval_order_validator_scenarios.dart`.

test/ LOC after slice 2: **32,982** (down ~66 from pre-slice working tree; ≥20% target ≤26,400 still deferred). Validator move + naval families are table-driven; further family migrations deferred.

## Wave 3 — Slice 3 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| vwt-unknown-unit | returns empty for unknown unit id | `order_suggestion_valid_work_tiles_part1_basic_test.dart` | `support/suggestion/valid_work_tiles_scenarios.dart` + `order_suggestion_valid_work_tiles_test.dart` | #3949 |
| vwt-target-not-allowed | returns empty when workTarget not allowed for unit type | same | same | #3949 |
| vwt-unknown-unit-vis | returns empty for unknown unit id with visibility | same | same | #3949 |
| vwt-target-not-allowed-vis | returns empty when workTarget not allowed for unit type with visibility | same | same | #3949 |
| vwt-filter-visibility | filters by visibility before order engine validation | same | same | #3949 |
| vwt-build-controlled | build_improvement returns only controlled tiles with resources | `…_part1_build_improvement_test.dart` | same | #3949 |
| vwt-build-mineral | build_improvement excludes owned mineral tile until prospected; includes after prospected | same (was multi-line `test()`; label joined) | same | #3949 |
| vwt-build-purchased | build_improvement includes purchased tiles with resources | same | same | #3949 |
| vwt-build-sea | build_improvement excludes sea zone tiles | same | same | #3949 |
| vwt-prospect-exclude | getValidWorkOrderTileKeysWithVisibility prospect excludes non-mineral and already prospected | `…_part1_prospect_test.dart` (was multi-line; label joined) | same | #3949 |
| vwt-prospect-eligible | getValidWorkOrderTileKeysWithVisibility prospect includes eligible tile | same | same | #3949 |
| vwt-prospect-wool-hills | getValidWorkOrderTileKeysWithVisibility prospect excludes wool on hills when tile map marks hills (terrain-only eligibility must not apply) | same (was multi-line; label joined) | same | #3949 |
| vwt-explore-partial | getValidWorkOrderTileKeysWithVisibility explore only scans partially revealed provinces | `…_part2a_test.dart` | same | #3949 |
| vwt-explore-latency | getValidWorkOrderTileKeysWithVisibility explore remains under one second on large map fixture | same | same | #3949 |
| vwt-move-exclude-gp | suggestMoveOrders excludes moves to other Great Power provinces | `…_part2b_test.dart` | same | #3949 |
| vwt-suggest-sort | suggestWorkOrders sorts by targetTileKey when unitId and target match | `…_part2c_test.dart` | same | #3949 |
| vwt-suggest-exclude-existing | suggestWorkOrders excludes targets from existing work orders for same unit | same | same | #3949 |
| vwt-explore-suggest-include | suggestWorkOrders explore includes partially revealed province when first sorted entry tile is unknown but later tile is fogged | `…_part2d_test.dart` | same | #3949 |
| vwt-explore-suggest-exclude | suggestWorkOrders explore excludes partially revealed province when no bundled entry tile passes move validation | same | same | #3949 |
| vwt-prospect-suggest-include | suggestWorkOrders prospect includes mineral tile in partially revealed province when first sorted entry tile is unknown | `…_part2e_test.dart` | same | #3949 |
| vwt-prospect-suggest-exclude | suggestWorkOrders prospect excludes partially revealed province when only non-eligible or already prospected mineral tiles remain | same | same | #3949 |
| vwt-purchase-include | suggestWorkOrders purchase_land includes target in partially revealed minor or tribe province when embassy and diplomacy gates pass | `…_part2f_test.dart` | same | #3949 |
| vwt-purchase-exclude | suggestWorkOrders purchase_land excludes partially revealed target when embassy or diplomacy preconditions fail | same | same | #3949 |

Merged nine `order_suggestion_valid_work_tiles_part*_test.dart` shards → `order_suggestion_valid_work_tiles_test.dart` (≤400 lines). Bodies live in `valid_work_tiles_expectations.dart`; labels in `valid_work_tiles_scenarios.dart`.

test/ LOC after slice 3: **33,068** (nine part runners → one family runner + support tables; slight LOC uptick from enum/switch/scenario harness overhead — further compaction deferred with remaining families). ≥20% target ≤26,400 still deferred. Remaining: `order_engine_validate_*`, `order_suggestion_core_part*`, `orders_application_*`, incremental equivalence, lib DRY.

## Wave 3 — documented exceptions (kickoff)

| file | retained test description(s) | rationale | refs |
|------|------------------------------|-----------|------|
| (all pre-wave `*_test.dart`) | see `DESCRIPTION_BASELINE.txt` | Imperative suites allowlisted via `ordersPreferScenarioTablesBaselineAllowAll` until table migration; tighten allowlist as families migrate | #3949 |
