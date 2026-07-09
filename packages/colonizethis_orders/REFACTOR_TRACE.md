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

## Wave 3 — Slice 4 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| woa-prospect-eligible | prospect adds tile to playerProspectedTiles when terrain eligible | `orders_application_work_order_application_part1_test.dart` | `support/application/work_order_application_scenarios.dart` + `orders_application_work_order_application_test.dart` | #3949 |
| woa-prospect-non-mineral | prospect on non-mineral-eligible terrain does not add tile | same | same | #3949 |
| woa-prospect-mineral-no-map | prospect adds tile when mineral resource present without tile map | same | same | #3949 |
| woa-prospect-non-mineral-no-map | prospect does not add tile when non-mineral resource present without tile map | same | same | #3949 |
| woa-build-improvement-complete | build_improvement work order sets currentWork then completes when totalTurns=1 | same | same | #3949 |
| woa-build-fort-total-turns | build_fort assigns currentWork.totalTurns from totalTurnsForWork (fort level) | same | same | #3949 |
| woa-counter-spy-assign | counter_spy work order sets currentWork for Spy unit | `…_part2_test.dart` | same | #3949 |
| woa-purchase-success | purchase_land success: treasury deducted and tile recorded in purchasedTilesByTileKey | same | same | #3949 |
| woa-purchase-no-embassy | purchase_land rejected when no Embassy with province owner (Minor/Tribe) | same | same | #3949 |
| woa-purchase-at-war | purchase_land rejected when at war with province owner (Minor/Tribe) | same | same | #3949 |
| woa-purchase-first-wins | purchase_land same tile by two GPs: first wins, second does not deduct or overwrite | same | same | #3949 |
| woa-build-fort-deduct | build_fort with sufficient materials deducts materials | `…_part3_test.dart` | same | #3949 |
| woa-build-fort-l2-tech | build_fort to level 2 is skipped without Mine Engineering | same | same | #3949 |
| woa-build-fort-l3-tech | build_fort to level 3 is skipped without Modern Forts | same | same | #3949 |
| woa-upgrade-town | upgrade_town completion increases province townDevelopmentLevel | same | same | #3949 |
| woa-counter-spy-process | counter_spy processWork keeps ongoing assignment without killing in build/work | same | same | #3949 |
| woa-unknown-target | unknown work target is skipped and unit stays idle | `…_part4_test.dart` | same | #3949 |
| woa-build-road-insufficient | build_road with insufficient materials does not set currentWork or deduct stockpile | same | same | #3949 |
| woa-build-road-sufficient | build_road with sufficient materials deducts materials and sets currentWork | same | same | #3949 |
| woa-counter-spy-owned-capital | counter_spy work order sets currentWork for Spy unit on owned capital province | `…_part5_test.dart` (was duplicate label; disambiguated) | same | #3949 |
| woa-explore-assign | explore work order sets currentWork when province has tiles | same | same | #3949 |
| woa-explore-formula | explore work order totalTurns uses region-scoped formula ceil(3 * tilesInP / maxTilesInRegion) | same | same | #3949 |
| woa-engineer-road | Engineer build_road work order sets currentWork | same | same | #3949 |
| woa-build-port | build_port work order sets currentWork when materials sufficient | same | same | #3949 |

Merged five `orders_application_work_order_application_part*_test.dart` → `orders_application_work_order_application_test.dart` (≤400 lines). Bodies live in `work_order_application_expectations.dart`; labels in `work_order_application_scenarios.dart`.

test/ LOC after slice 4: **33,241** (five part runners → one family runner + support tables; slight LOC uptick from enum/switch/scenario harness — further compaction deferred). ≥20% target ≤26,400 still deferred. Remaining: `order_engine_validate_*`, `order_suggestion_core_part*`, other `orders_application_*`, incremental equivalence, lib DRY.

## Wave 3 — Slice 5 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osc-move-pass | suggestMoveOrders only returns moves that pass validation | `order_suggestion_core_part1_move_and_explore_test.dart` | `support/suggestion/order_suggestion_core_scenarios.dart` + `order_suggestion_core_test.dart` | #3949 |
| osc-move-unknown-vis | suggestMoveOrders throws when source province has unknown visibility | same | same | #3949 |
| osc-move-location | move suggestions use unit locationProvinceId (tileKey-derived for civilians) | same | same | #3949 |
| osc-explore-unknown | no explore suggestion when province unknown | same | same | #3949 |
| osc-explore-target | suggestWorkOrders explore target uses kWorkTargetExplore | same | same | #3949 |
| osc-explore-cache | suggestWorkOrders explore aligns with partially revealed province cache scope | same | same | #3949 |
| osc-prospect-fog | no prospect suggestion when province not at least fogged | `…_part1_prospect_player_view_test.dart` | same | #3949 |
| osc-prospect-ok | prospect suggestion when province fogged and tiles in province | same | same | #3949 |
| osc-prospect-order | PlayerView.provincesById matches allProvinces for prospect iteration order | same | same | #3949 |
| osc-vwt-reserved | getValidWorkOrderTileKeysWithVisibility excludes tile reserved by another unit pending order | `…_part1_valid_work_tiles_visibility_test.dart` (was multi-line; label joined) | same | #3949 |
| osc-work-any-tile | work suggestions for worker use unit id; targets may be any valid tile | `…_part1_work_targets_and_build_test.dart` | same | #3949 |
| osc-build-later-tile | suggestWorkOrders includes build_improvement when first province tile has no resource but a later tile does | same (was multi-line; label joined) | same | #3949 |
| osc-build-other-prov | suggestWorkOrders includes build_improvement on another owned province when the builder’s province has no valid resource tile | same (was multi-line; label joined) | same | #3949 |
| osc-build-reserved | suggestWorkOrders second Builder skips tile reserved by another Builder pending work order | same (was multi-line; label joined) | same | #3949 |
| osc-naval-mission | suggestNavalMissionOrders returns list | `…_part2_naval_mission_test.dart` | same | #3949 |
| osc-build-list | suggestBuildOrders returns list | `order_suggestion_core_part2_test.dart` | same | #3949 |
| osc-build-ship | suggestBuildOrders returns ship when affordable | same | same | #3949 |
| osc-build-both | suggestBuildOrders can return both regiment and ship when both affordable | same | same | #3949 |
| osc-research | suggestResearchOrders returns list | same | same | #3949 |
| osc-naval-move | suggestNavalMoveOrders returns list | same | same | #3949 |
| osc-counter-spy | counter_spy work suggested for Spy in owned province with tiles | same | same | #3949 |
| osc-purchase | purchase_land work suggested for Merchant when minor province has resource tile | same | same | #3949 |

Merged six `order_suggestion_core_part*_test.dart` shards → `order_suggestion_core_test.dart` (≤400 lines). Bodies live in `order_suggestion_core_expectations.dart`; labels in `order_suggestion_core_scenarios.dart`.

test/ LOC after slice 5: **33,273** (six part runners → one family runner + support tables; slight LOC uptick from enum/switch/scenario harness — further compaction deferred). ≥20% target ≤26,400 still deferred. Remaining after slice 5: `order_engine_validate_*`, other `orders_application_*`, incremental equivalence, lib DRY.


## Wave 3 — Slice 6 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oevw-unique | rejects second pending work order for same unit in one turn | `order_engine_validate_work_single_order_per_unit_test.dart` | `support/engine/order_engine_validate_work_scenarios.dart` + `order_engine_validate_work_test.dart` | #3949 |
| oevw-purchase-no-embassy | rejects purchase_land when no embassy with Minor | `order_engine_validate_work_purchase_land_test.dart` | same | #3949 |
| oevw-purchase-at-war | rejects purchase_land when at war with faction | same | same | #3949 |
| oevw-purchase-treasury | rejects purchase_land when insufficient treasury | same | same | #3949 |
| oevw-purchase-no-resource | rejects purchase_land when tile has no resource | same | same | #3949 |
| oevw-purchase-mineral | rejects purchase_land when mineral tile not prospected | same | same | #3949 |
| oevw-purchase-accept | accepts purchase_land with embassy, at peace, sufficient treasury, tile with resource | same (was multi-line; label joined) | same | #3949 |
| oevw-purchase-exclusivity | rejects second Builder/Engineer/Merchant work order on same tile for same player (per-tile exclusivity) | `…_purchase_land_part2_test.dart` (was multi-line; label joined) | same | #3949 |
| oevw-purchase-mineral-ok | accepts purchase_land for mineral when prospected | same | same | #3949 |
| oevw-purchase-other-gp | rejects purchase_land when tile already purchased by another GP | same (was multi-line; label joined) | same | #3949 |
| oevw-purchase-owned | rejects purchase_land when tile already owned by same player | same | same | #3949 |
| oevw-bi-mineral-no | rejects build_improvement on mineral tile when not prospected | `order_engine_validate_work_build_improvement_test.dart` (was multi-line; label joined) | same | #3949 |
| oevw-bi-mineral-ok | accepts build_improvement on mineral tile after prospected | same (was multi-line; label joined) | same | #3949 |
| oevw-bi-grain | accepts build_improvement on grain when tile not prospected | same (was multi-line; label joined) | same | #3949 |
| oevw-bi-no-resource | rejects build_improvement when tile has no resource | same | same | #3949 |
| oevw-bi-max-level | rejects build_improvement when improvement level already 4 | same | same | #3949 |
| oevw-bi-tech-empty | rejects build_improvement when tech cap would be exceeded (empty tech) | same (was multi-line; label joined) | same | #3949 |
| oevw-bi-tech-cap | rejects build_improvement when tech cap would be exceeded | same | same | #3949 |
| oevw-bi-grain-tech | accepts grain upgrade when exact next-level grain tech is unlocked | same (was multi-line; label joined) | same | #3949 |
| oevw-bi-accept | accepts build_improvement when tile has resource, level < 4, tech cap allows | same (was multi-line; label joined) | same | #3949 |
| oevw-bi-foreign | rejects build_improvement in foreign, unpurchased province | same | same | #3949 |
| oevw-scrub-raise | rejects raising scrub timber from level 1 even with circular_saw | `…_scrub_cap_test.dart` (was multi-line; label joined) | same | #3949 |
| oevw-scrub-hardwood | accepts raising hardwood timber from level 1 with circular_saw | same | same | #3949 |
| oevw-scrub-initial | accepts initial scrub timber improvement (level 0 -> 1) | same | same | #3949 |
| oevw-bi-purchased | accepts build_improvement on purchased tile in foreign province | `…_purchased_foreign_tile_test.dart` (was multi-line; label joined) | same | #3949 |
| oevw-fort-l2 | rejects build_fort to level 2 without Mine Engineering | `order_engine_validate_work_build_fort_test.dart` | same | #3949 |
| oevw-fort-l3 | rejects build_fort to level 3 without Modern Forts | same | same | #3949 |
| oevw-rail-terrain | rejects build_rail when tile terrain data is missing | `order_engine_validate_work_build_rail_test.dart` | same | #3949 |
| oevw-rail-road0 | rejects build_rail when road level is 0 | same | same | #3949 |
| oevw-rail-hills | rejects build_rail on hills with only Early Steam | same | same | #3949 |
| oevw-rail-plains | accepts build_rail on plains with Early Steam and road 1 | same | same | #3949 |
| oevw-embassy-path | rejects build_road in minor province without embassy path | `order_engine_validate_work_minor_embassy_test.dart` | same | #3949 |
| oevw-embassy-occupy | rejects build_road in minor province even with embassy when occupancy disallows tile | same (was multi-line; label joined) | same | #3949 |
| oevw-town-reject | rejects upgrade_town without National Bureaucracy | `order_engine_validate_work_upgrade_town_test.dart` | same | #3949 |
| oevw-town-accept | accepts upgrade_town when National Bureaucracy unlocked | same | same | #3949 |

Merged ten `order_engine_validate_work_*_test.dart` suites (35 scenarios) → `order_engine_validate_work_test.dart` (≤400 lines). Bodies live in `order_engine_validate_work_expectations.dart` + shared builders in `order_engine_validate_work_fixtures.dart`; labels in `order_engine_validate_work_scenarios.dart`. Joined formerly multi-line descriptions added to `DESCRIPTION_BASELINE.txt`.

test/ LOC after slice 6: **33,481** (ten imperative runners → one family runner + support tables; slight LOC uptick from enum/switch/scenario harness — further compaction deferred with remaining families / lib DRY). ≥20% target ≤26,400 still deferred. Remaining after slice 6: other `order_engine_validate_*` (build_civilian / diplomatic / recruit / trade), other `orders_application_*`, incremental equivalence, lib DRY.


## Wave 3 — Slice 7 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oevbc-unknown | rejects unknown unit type | `order_engine_validate_build_civilian_test.dart` | `support/engine/order_engine_validate_build_civilian_scenarios.dart` + `order_engine_validate_build_civilian_test.dart` | #3949 |
| oevbc-treasury | rejects Builder when treasury too low | same | same | #3949 |
| oevbc-paper | rejects Builder when paper insufficient | same | same | #3949 |
| oevbc-merchant-tech | rejects Merchant when merchant_companies not unlocked | same | same | #3949 |
| oevbc-builder-ok | accepts Builder when treasury and paper sufficient | same | same | #3949 |
| oevbc-merchant-ok | accepts Merchant when tech and resources ok | same (+ removed duplicate `…_merchant_and_spawn_test.dart`) | same | #3949 |
| oevbc-spawn-empty | accepts build when spawnProvinceId is empty (falls back to capital) | same (was multi-line; label joined; duplicate suite removed) | same | #3949 |
| oevbc-spawn-foreign | accepts build when spawnProvinceId is foreign (falls back to capital) | same (was multi-line; label joined; duplicate suite removed) | same | #3949 |

Merged `order_engine_validate_build_civilian_test.dart` (+ dropped duplicate `order_engine_validate_build_civilian_merchant_and_spawn_test.dart` with identical descriptions) → thin family runner. Expectations reuse `order_engine_validate_build_civilian_test_support.dart`.

test/ LOC after slice 7: see `find … wc -l` in PR. Remaining after slice 7: diplomatic / recruit / trade validate suites, other `orders_application_*`, incremental equivalence, lib DRY. ≥20% target ≤26,400 still deferred.


## Wave 3 — Slice 8 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oevd-war-already | declareWar rejected when already at war | `order_engine_validate_diplomatic_relations_test.dart` | `support/engine/order_engine_validate_diplomatic_scenarios.dart` + `order_engine_validate_diplomatic_test.dart` | #3949 |
| oevd-peace-nowar | offerPeace rejected when not at war | same | same | #3949 |
| oevd-overture-war | establishOverture rejected when target is at war with GP | same | same | #3949 |
| oevd-trade-tech | establishOverture trade consulate rejected without diplomatic_expertise | same (was multi-line; label joined) | same | #3949 |
| oevd-consulate-treasury | establishOverture consulate rejected when treasury too low | same | same | #3949 |
| oevd-embassy-consulate | establishOverture embassy requires existing consulate | same | same | #3949 |
| oevd-overture-second | establishOverture second order for same faction in same turn rejected | same | same | #3949 |
| oevd-second-type | second diplomatic order to same target different type is rejected | same | same | #3949 |
| oevd-aid-embassy | grantAid requires embassy and sufficient treasury | `order_engine_validate_diplomatic_aid_subsidy_test.dart` | same | #3949 |
| oevd-aid-multiple | grantAid rejects amounts not a multiple of £1000 | same | same | #3949 |
| oevd-aid-subsidy | grantAid then setSubsidy toward same target both accepted | same | same | #3949 |
| oevd-subsidy-embassy | setSubsidy requires an embassy (Refs #3753 R2) | same | same | #3949 |
| oevd-subsidy-treasury | setSubsidy with an embassy is accepted regardless of treasury (no upfront cost, Refs #3753 R3) | same (was multi-line; label joined) | same | #3949 |
| oevd-subsidy-percent | setSubsidy with an embassy and a valid percent is accepted | same | same | #3949 |
| oevd-subsidy-range | setSubsidy rejects a percent outside 5-20 in steps of 5 | same | same | #3949 |
| oevd-aid-second | second grantAid toward same target rejected | same | same | #3949 |
| oevd-war-aid | declareWar then grantAid toward same target rejected | same | same | #3949 |

Merged `order_engine_validate_diplomatic_{relations,aid_subsidy}_test.dart` (17 scenarios) → `order_engine_validate_diplomatic_test.dart`. Bodies reuse `gpMinorGame` / `emptyTopology` via diplomatic fixtures re-export.

test/ LOC after slice 8: see PR. Remaining: recruit / trade validate suites, other `orders_application_*`, incremental equivalence, lib DRY. ≥20% target ≤26,400 still deferred.

## Wave 3 — Slice 9 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oevrw-peasant | accepts a single peasant recruit when fabric is available | `order_engine_validate_recruit_worker_test.dart` | `support/engine/order_engine_validate_recruit_worker_scenarios.dart` + thin runner | #3949 |
| oevrw-tech | rejects apprentice train when required tech is locked | same | same | #3949 |
| oevrw-military | recruit consumes last peasant before military build, so subsequent regiment build is rejected with Insufficient workers | same (was multi-line; label joined) | same | #3949 |
| oevrw-civilian | civilian build (no peasant consume) is accepted after recruit consumes the only peasant | same (was multi-line; label joined) | same | #3949 |
| oevt-offer | accepts a valid offer when stockpile covers quantity | `order_engine_validate_trade_test.dart` | `support/engine/order_engine_validate_trade_scenarios.dart` + thin runner | #3949 |
| oevt-mutex | rejects mutual exclusion when bid and offer share a commodity | same | same | #3949 |
| oevt-stockpile | rejects offer exceeding available stockpile | same | same | #3949 |
| oevt-first-bid | accepts first bid when player has no embassy (baseline bid type cap 1 per Refs #2924; SPEC/game/world-market.md § Bid type cap) | same (was multi-line; label joined) | same | #3949 |
| oevt-cap | rejects second distinct-commodity bid when no embassy (baseline bid type cap == 1 exhausted; Refs #2924) | same (was multi-line; label joined) | same | #3949 |

Migrated remaining `order_engine_validate_{recruit_worker,trade}_test.dart` suites (9 scenarios) → thin family runners. Completes the `order_engine_validate_*` family migration from Current behavior §2. Joined formerly multi-line descriptions added to `DESCRIPTION_BASELINE.txt`.

test/ LOC after slice 9: see PR. Remaining after slice 9: other `orders_application_*`, incremental equivalence, lib DRY, ≥20% LOC target ≤26,400, tighten prefer-scenario-tables allow-all.

## Wave 3 — Slice 10 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ice-move-own | move: builder onto own province (accepted) | `incremental_candidate_validator_equivalence_test.dart` | `support/incremental/incremental_candidate_validator_equivalence_scenarios.dart` + thin runner | #3949 |
| ice-move-gp | move: builder onto other GP province (rejected) | same | same | #3949 |
| ice-move-minor | move: explorer onto Minor province (accepted) | same | same | #3949 |
| ice-move-spy | move: spy onto other GP province (accepted) | same | same | #3949 |
| ice-move-regiment | move: military regiment via MoveOrder (rejected) | same | same | #3949 |
| ice-move-missing | move: missing unit (rejected) | same | same | #3949 |
| ice-move-empty | move: empty destination tile (rejected) | same | same | #3949 |
| ice-move-xor | move: rejected because basePrefix has work order for same unit (move XOR work cascade) | same (was multi-line; label joined) | same | #3949 |
| ice-move-prefix | move: with non-empty accepted basePrefix (accepted) | same | same | #3949 |
| ice-build | build: candidate remains equivalent to full-pass path | same | same | #3949 |
| ice-build-seq | build: successive candidate probes stay full-pass equivalent (#2394) | same (was multi-line; label joined) | same | #3949 |
| ice-work | work: non-empty basePrefix replay remains equivalent | same | same | #3949 |
| ice-diplo | diplomatic: non-empty basePrefix replay remains equivalent | same | same | #3949 |
| ice-diplo-seq | diplomatic: sequential probes on one validator stay equivalent (#2394) | same (was multi-line; label joined) | same | #3949 |
| ice-prefetch | prefetched DiplomacyFactionMembership matches lazy membership (#2394) | same (was multi-line; label joined) | same | #3949 |
| ice-army-own | army move: into own adjacent province (accepted) | `…_army_naval_test.dart` | same | #3949 |
| ice-army-gp | army move: into other GP without war (rejected) | same | same | #3949 |
| ice-army-declare | army move: into other GP with same-turn declare war (accepted) | same (was multi-line; label joined) | same | #3949 |
| ice-army-minor | army move: into Minor without war (rejected) | same | same | #3949 |
| ice-army-missing | army move: missing army (rejected) | same | same | #3949 |
| ice-naval-adj | naval move: at-sea fleet to adjacent sea zone (accepted) | same | same | #3949 |
| ice-naval-nonadj | naval move: at-sea fleet to non-adjacent sea zone (rejected) | same | same | #3949 |
| ice-naval-undock | naval move: in-port fleet undock to adjacent sea zone (accepted) | same (was multi-line; label joined) | same | #3949 |
| ice-naval-missing | naval move: missing fleet (rejected) | same | same | #3949 |
| ice-mission-patrol | naval mission: patrol owned fleet (accepted) | same | same | #3949 |
| ice-mission-blockade | naval mission: blockade without target province (rejected) | same | same | #3949 |
| ice-mission-missing | naval mission: missing fleet (rejected) | same | same | #3949 |

Merged `incremental_candidate_validator_equivalence_{,_army_naval}_test.dart` (27 scenarios) → one thin family runner. Bodies in `…_expectations.dart`; labels in `…_scenarios.dart`. Joined formerly multi-line descriptions added to `DESCRIPTION_BASELINE.txt`.

test/ LOC after slice 10: see PR. Remaining: other `orders_application_*`, lib DRY, ≥20% LOC target ≤26,400, tighten prefer-scenario-tables allow-all.


## Wave 3 — Slice 11 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| wc-build-improve | build_improvement completion increases improvement level and clears currentWork | `orders_application_work_completion_build_improvement_test.dart` | `support/application/work_completion_scenarios.dart` + thin runner | #3949 |
| wc-envy-hint | build_improvement completion sets envy mirror hint for human on extraction tile | same | same | #3949 |
| wc-envy-ai | build_improvement completion adds envy evidence when AI mirrors human gathering hint | same | same | #3949 |
| wc-level-4 | build_improvement completion raises stored level from 3 to 4 (global max) | same | same | #3949 |
| wc-tech-cap | build_improvement completion does not re-apply extraction tech cap (#1291) | same (was multi-line; label joined) | same | #1291, #3949 |
| wc-conquer | work cancelled when province containing target tile is conquered (#376) | same | same | #376, #3949 |
| wc-multi-turn | multi-turn work decrements remainingTurns and completes only when zero | same | same | #3949 |
| wc-explore | explore completion sets visibility and clears currentWork | `…_explore_and_roads_test.dart` | same | #3949 |
| wc-explore-bucket | explore completion reveals every tile in canonical full-id bucket | same (was multi-line; label joined) | same | #3949 |
| wc-road | build_road completion increases road level | same | same | #3949 |
| wc-road-capital | build_road completion propagates transport level to adjacent capital tile (no downgrade) | same (was multi-line; label joined) | same | #3949 |
| wc-road-port | build_road completion propagates transport level to adjacent port tile and upgrades it | same (was multi-line; label joined) | same | #3949 |
| wc-port | build_port completion sets port and road level 4 when topology has sea | `…_infrastructure_test.dart` (was multi-line; label joined) | same | #3949 |
| wc-fort | build_fort completion increases province fortLevel | same | same | #3949 |
| wc-rail-no-road | build_rail completion leaves road when tile has no road | same | same | #3949 |
| wc-rail-valid | build_rail completion sets road level to 4 when valid | same | same | #3949 |
| wc-dispatch-rail | routes kWorkTargetBuildRail through handler map entry | `orders_application_completed_work_dispatch_test.dart` | same | #3949 |
| wc-dispatch-noop | build_rail completion no-ops when rejectionReasonForBuildRailOrder applies | same | same | #3949 |
| wc-dispatch-town | upgrade_town threads getProvinces/replaceProvinces through the CompletedWorkContext record | same (was multi-line; label joined) | same | #3949 |
| wc-dispatch-explore | explore invokes the applyExploreCompletion closure with the unit region via the CompletedWorkContext record | same (was multi-line; label joined) | same | #3949 |

Merged four imperative work-completion / dispatch suites (20 scenarios) → `orders_application_work_completion_test.dart`. Bodies in `work_completion_expectations.dart`; labels in `work_completion_scenarios.dart`. Joined formerly multi-line descriptions added to `DESCRIPTION_BASELINE.txt`.

test/ LOC after slice 11: see PR. Remaining: other `orders_application_*` (military/ship, training costs, worker pool, helpers, civilian spawn, clear current work), lib DRY, ≥20% LOC target ≤26,400, tighten prefer-scenario-tables allow-all.

## Wave 3 — Slice 12 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| but-unknown | skips build when unitType unknown in RegimentEconomyCatalog | `orders_application_military_ship_skip_test.dart` | `support/application/build_unit_training_scenarios.dart` + thin runner | #3949 |
| but-zero-peasants | skips military build when zero peasants | same | same | #3949 |
| but-mil-tech | skips military build when tech not unlocked | same | same | #3949 |
| but-ship-tech | skips ship build when tech not unlocked | same | same | #3949 |
| but-topo-null | ship build with topology null does not add fleet | same | same | #3949 |
| but-cap-null | ship build with capitalProvinceId null does not add fleet | same | same | #3949 |
| but-no-sea | ship build with capital not adjacent to sea does not add ship | same | same | #3949 |
| but-treasury | rejects build when treasury is insufficient | `orders_application_military_training_costs_test.dart` | same | #3949 |
| but-materials | rejects build when materials are insufficient | same | same | #3949 |
| but-apply | applies treasury, stockpile and worker costs when valid | same | same | #3949 |
| but-noop | returns game unchanged when no build or work orders | same | same | #3949 |
| but-ship-ok | ship build adds ship to fleet when topology and capital with sea | same | same | #3949 |
| but-naval-peasants | rejects naval build when peasants are zero | same | same | #3949 |
| but-second-ship | second naval build adds ship to existing home fleet | same | same | #3949 |
| but-civ-treasury | rejects civilian build when treasury insufficient | `orders_application_civilian_training_costs_test.dart` | same | #3949 |
| but-civ-paper | rejects civilian build when paper insufficient | same | same | #3949 |
| but-civ-ok | applies treasury and paper cost when civilian build valid | same | same | #3949 |
| but-merchant | Merchant requires merchant_companies tech | same | same | #3949 |
| wpp-peasant | accepted recruit peasant order adds 1 peasant and deducts fabric | `orders_application_worker_pool_phase_test.dart` | `support/application/worker_pool_phase_scenarios.dart` + thin runner | #2692, #3949 |
| wpp-apprentice | accepted apprentice train consumes peasant, paper, and treasury | same | same | #2692, #3949 |
| wpp-afford | recruit that fails affordability checks does not mutate the player (no partial deduction) | same (was multi-line; label joined) | same | #2692, #3949 |
| wpp-journeyman | accepted journeyman train consumes peasant, paper, and treasury (#2692 S9 tier coverage) | `…_s9_test.dart` (was multi-line; label joined) | same | #2692, #3949 |
| wpp-master | accepted master train consumes peasant, paper, and treasury (#2692 S9 tier coverage; AC #3 master tail) | same (was multi-line; label joined) | same | #2692, #3949 |
| wpp-tech-gate | master recruit with required tech locked is silently skipped (#2692 S9 tech-gate coverage) | same (was multi-line; label joined) | same | #2692, #3949 |
| wpp-ordering | later recruit order observes the running state of earlier accepted order in the same submission list (#2692 S9 ordering semantics) | same (was multi-line; label joined) | same | #2692, #3949 |
| wpp-skip-middle | middle order silently skips when peasants are exhausted; later orders still resolve against the running state (#2692 S9; AC #4 resolver behavior) | same (was multi-line; label joined) | same | #2692, #3949 |
| wpp-multi | per-player order lists apply in isolation (#2692 S9 multi-player pin) | same (was multi-line; label joined) | same | #2692, #3949 |
| cs-capital-other | civilian spawn uses capitalTile key even when spawnProvinceId is different owned province | `orders_application_civilian_new_world_spawn_test.dart` (was multi-line; label joined) | `support/application/civilian_spawn_scenarios.dart` + thin runner | #3949 |
| cs-empty-spawn | civilian build with empty spawnProvinceId uses capital tile and province | same (was multi-line; label joined) | same | #3949 |
| cs-missing-cap | civilian build with missing capital tile throws explicit error | same | same | #3949 |
| cs-new-world | New World spawn adds unit to newWorld | same | same | #3949 |
| ah-parse | returns parsed coordinates for a valid tile key | `orders_application_helpers_test.dart` | `support/application/application_helpers_scenarios.dart` + thin runner | #3949 |
| ah-malformed | returns null for malformed tile key | same | same | #3949 |
| ah-cancel | clears work state and restores origin tile by default | same | same | #3949 |
| ah-override | uses explicit restored tile override | same | same | #3949 |
| ah-clear-noop | returns game unchanged when unit has no currentWork | `orders_application_clear_unit_current_work_test.dart` | same | #3949 |
| ah-clear | clears currentWork, restores origin tile, and sets status idle | same | same | #3949 |
| ah-prospect-terrain | returns true for prospectable terrain even when no resource is present | `orders_application_helpers_mineral_eligible_test.dart` | same | #3949 |
| ah-non-prospect | returns false for non-prospectable terrain even when mineral resource exists | same | same | #3949 |
| ah-wool | returns false for wool on hills when tile map shows prospectable terrain | same | same | #3949 |
| ah-iron | returns true for iron on hills with tile map when not prospected | same | same | #3949 |
| ah-absent | returns false when resource is absent | same | same | #3949 |
| ah-non-mineral | returns false for non-mineral resource | same | same | #3949 |
| ah-mineral | returns true for mineral resource | same | same | #3949 |

Merged remaining imperative `orders_application_*` suites (ship-skip, military/civilian training, worker-pool S4+S9, civilian spawn, helpers, mineral eligible, clear current work) → thin family runners. Completes the `orders_application_*` family migration from Current behavior §2 / PR remaining list. Joined formerly multi-line descriptions added to `DESCRIPTION_BASELINE.txt`.

test/ LOC after slice 12: see PR. Remaining: lib DRY (validation orchestration + explorer pipeline), ≥20% LOC target ≤26,400, tighten prefer-scenario-tables allow-all.

## Wave 3 — Slice 13: projected-economy prefix DRY + validateWork compaction + prefer-scenario-tables tighten

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| lib-prefix-replay | extract shared `ensureProjectedResourcePrefixReplay` for recruit/build incremental prefix caches | `incremental_candidate_validator_replay.dart` | `projected_economy_prefix_replay.dart` + replay callers | #3949 |
| vw-compact | compact validateWork build-improvement / fort / rail / scrub bodies onto shared fixtures + validate helpers | `support/engine/order_engine_validate_work_expectations.dart` | same + `order_engine_validate_work_fixtures.dart` | #3949 |
| gate-prefer-tables | set `ordersPreferScenarioTablesBaselineAllowAll=false`; populate explicit allowlist of remaining long-form imperative `*_test.dart` | kickoff allow-all | `tool/check_orders_scenario_table_runner.dart` | #3949 |
| gate-hot-files | extend `ordersFileSizeGatedFiles` for replay / explorer / prefix-replay modules | `tool/check_orders_file_size.dart` | same | #3949 |

Explorer suggestion already routes through `WorkSuggestionPipeline` (explore + prospect); no further behavior-preserving fold this slice.

test/ LOC after slice 13: see PR. Remaining: further scenario-data compaction toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 14: valid-work-tiles expectation fixtures + helper compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| vwt-fixtures | extract NW partial-reveal + OW builder/prospect/suggest helpers; compact expectation bodies onto fixtures | `support/suggestion/valid_work_tiles_expectations.dart` | `valid_work_tiles_fixtures.dart` + compacted expectations | #3949 |

test/ LOC after slice 14: see PR (`find … wc -l`). Remaining: further expectation compaction (`work_order_application_*`, `order_suggestion_core_*`, `work_completion_*`, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 15: work-application/completion expectation fixtures

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| work-app-fixtures | extract shared OW unit/province/player/game/order/purchase-land helpers; compact application + completion expectation bodies | `work_order_application_expectations.dart`, `work_completion_expectations.dart` | `work_application_fixtures.dart` + compacted expectations | #3949 |

test/ LOC after slice 15: **32,385** (down ~751 from ~33,136 post–slice 14). Remaining: further expectation compaction (`order_suggestion_core_*`, `order_engine_validate_work_*`, `build_unit_training_*`, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 16: order_suggestion_core expectation fixtures

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osc-fixtures | extract shared GP/province/unit/topology/game helpers + dual-builder grain tile pair; compact core expectation bodies | `order_suggestion_core_expectations.dart` | `order_suggestion_core_fixtures.dart` + compacted expectations | #3949 |

test/ LOC after slice 16: **32,079** (down ~306 from post–slice 15). Remaining: further expectation compaction (`order_engine_validate_work_*`, `build_unit_training_*`, `incremental_*`, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 17: validateWork expectation fixtures + helper compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| vw-fixtures-2 | extract dual-tile pending work, tile exclusivity, minor-province road, upgrade-town helpers; compact purchase-land / road / upgrade expectation bodies | `order_engine_validate_work_expectations.dart` | extended `order_engine_validate_work_fixtures.dart` + compacted expectations | #3949 |

test/ LOC after slice 17: **31,872** (down ~207 from post–slice 16). Remaining: further expectation compaction (`build_unit_training_*`, `incremental_*`, `valid_work_tiles_*`, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 18: build-unit/training expectation fixtures

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| but-fixtures | extract OW game/player/order/topology/stockpile helpers; compact build-unit + training expectation bodies | `build_unit_training_expectations_part1.dart`, `build_unit_training_expectations_part2.dart` | `build_unit_training_fixtures.dart` + compacted expectations | #3949 |

test/ LOC after slice 18: **32,043** (down ~60 from post–slice 17). Remaining: further expectation compaction (`incremental_*`, `valid_work_tiles_*`, `worker_pool_phase_*`, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 19: worker-pool / incremental / valid-work-tiles expectation fixtures

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| wpp-fixtures | extract OW empty-world player/recruit helpers; compact worker-pool phase expectation bodies | `worker_pool_phase_expectations_part1.dart` | `worker_pool_phase_fixtures.dart` + compacted expectations | #3949 |
| ice-corpus-shorthand | add corpus `iceExpect*` wrappers + build corpus helpers on shared test_helpers | `incremental_candidate_validator_equivalence_expectations_part{1,2}.dart` | extended `incremental_candidate_validator_equivalence_test_helpers.dart` + compacted expectations | #3949 |
| vwt-query-shorthand | add `vwtPlainKeys` / `vwtVisKeys` / `vwtBuildVisKeys` + single-tile game helpers; compact part1 bodies | `valid_work_tiles_expectations_part1.dart` | extended `valid_work_tiles_fixtures.dart` + compacted expectations | #3949 |

test/ LOC after slice 19: **32,038** (down ~5 from post–slice 18). Remaining: further expectation compaction (`valid_work_tiles_*` part2/3, `order_engine_validate_*`, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 20: valid-work-tiles part2/3 expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| vwt-partial-reveal-shorthand | add tribe/minor partial-reveal game + suggest filter helpers; compact part2/3 explore/prospect/purchase bodies | `valid_work_tiles_expectations_part2.dart`, `valid_work_tiles_expectations_part3.dart` | `valid_work_tiles_expectation_shorthand.dart` + compacted expectations | #3949 |
| ice-corpus-split | split `iceExpect*` wrappers into dedicated support file to satisfy `repo.domain_package_test_file_size` | `incremental_candidate_validator_equivalence_test_helpers.dart` | `incremental_candidate_validator_equivalence_corpus_shorthand.dart` | #3949 |

test/ LOC after slice 20: **32,043** (net ~0 from post–slice 19; part2/3 bodies shortened, shorthand modules added). Remaining: further expectation compaction (`order_engine_validate_*`, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 21: diplomatic + ICE corpus expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ved-shorthand | add `vedSubmit` / `vedExpect*` wrappers + common diplomatic order builders; compact validate-diplomatic expectation bodies | `order_engine_validate_diplomatic_expectations_part{1,2}.dart` | `order_engine_validate_diplomatic_expectation_shorthand.dart` + compacted expectations | #3949 |
| ice-move-shorthand | add `iceTile` / `iceExpectMoveTo` / `iceExpectArmyMoveTo` / naval `*To` / `*For` helpers; compact ICE equivalence part1/2 bodies | `incremental_candidate_validator_equivalence_expectations_part{1,2}.dart` | extended `incremental_candidate_validator_equivalence_corpus_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 21: **31,860** (down ~183 from post–slice 20). Remaining: further expectation compaction (`order_engine_validate_work_*`, `order_engine_validate_trade_*`, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 22: validateWork + validateTrade expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| vw-shorthand | add `vwRun*` / `vwExpect*` purchase-land, build-improvement, OW-work-target wrappers; compact validateWork expectation bodies | `order_engine_validate_work_expectations_part{1,2}.dart` | `order_engine_validate_work_expectation_shorthand.dart` + compacted expectations | #3949 |
| vet-shorthand | add `vetGameWith` / `vetGp1` / `vetExpect*` trade validation helpers; compact validateTrade expectation bodies | `order_engine_validate_trade_expectations.dart` | `order_engine_validate_trade_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 22: **31,966** (net +106 from post–slice 21; expectation bodies shortened, new `vw*`/`vet*` shorthand modules added). Remaining: further expectation compaction (`order_suggestion_core_*`, `work_order_application_*`, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 23: order_suggestion_core + work_order_application expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osc-shorthand | add `oscSuggest*` / `oscExpect*` / game-builder wrappers; compact core expectation bodies | `order_suggestion_core_expectations_part{1,2}.dart` | `order_suggestion_core_expectation_shorthand.dart` + compacted expectations | #3949 |
| waa-shorthand | add `waaApply` / `waaExpect*` / engineer-road/fort helpers; compact application expectation bodies | `work_order_application_expectations_part{1,2}.dart` | `work_order_application_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 23: **32,115** (net +149 from post–slice 22; expectation bodies shortened, new `osc*`/`waa*` shorthand modules added). Remaining: further expectation compaction (`work_completion_*`, `incremental_*`, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 24: work-completion expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| wcc-shorthand | add `wccApply` / `wccExpect*` / rail/dispatch setup helpers; compact work-completion expectation bodies | `work_completion_expectations_part{1,2}.dart` | `work_completion_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 24: **32,147** (net +32 from post–slice 23; expectation bodies shortened, new `wcc*` shorthand module added). Remaining: further expectation compaction (`incremental_*`, `worker_pool_phase_*`, lib DRY items 5–6, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 25: worker-pool + incremental expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| wpp-shorthand | add `wppStock` / `wppAfter` / `wppExpect*` / `wppExpectApprenticeTrain` helpers; compact worker-pool phase expectation bodies | `worker_pool_phase_expectations_part1.dart` | `worker_pool_phase_expectation_shorthand.dart` + compacted expectations | #3949 |
| ice-equiv-shorthand | add `iceBuildUnit` / `ice*Prefix` / `iceExpect*Probes` / `iceExpectPrefetchedArmyMove` helpers; compact incremental equivalence part1 bodies | `incremental_candidate_validator_equivalence_expectations_part1.dart` | `incremental_candidate_validator_equivalence_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 25: **32,127** (net −20 from post–slice 24; expectation bodies shortened, new `wpp*`/`ice-equiv*` shorthand modules added). Remaining: further expectation compaction, lib DRY items 5–6, … toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 26: move + naval validator expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| mv-shorthand | add `mvExpectUnitMove` / `mvExpectArmyMove` / tribe-army game helpers; compact move-validator expectation bodies | `move_validator_expectations_cases_{a,b}.dart` | `move_validator_expectation_shorthand.dart` + compacted expectations | #3949 |
| nov-shorthand | add `novExpectNavalMove` / `novExpectNavalMission` / dock+sea order builders; compact naval-validator expectation bodies | `naval_order_validator_expectations_move*.dart`, `naval_order_validator_expectations_mission.dart` | `naval_order_validator_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 26: **32,135** (net +8 from post–slice 25; expectation bodies shortened, new `mv*`/`nov*` shorthand modules added). Remaining: further expectation compaction (`order_engine_validate_build_civilian`, `civilian_spawn`, lib DRY items 5–6, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 27: build_civilian + recruit_worker + civilian_spawn expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| vbc-shorthand | add `vbcOrder` / `vbcExpect*` wrappers; compact validateBuild(civilian) expectation bodies | `order_engine_validate_build_civilian_expectations.dart` | `order_engine_validate_build_civilian_expectation_shorthand.dart` + compacted expectations | #3949 |
| vrw-shorthand | add `vrwGameWith` / `vrwAddRecruit` / `vrwExpect*` helpers; compact validateRecruitWorker expectation bodies | `order_engine_validate_recruit_worker_expectations.dart` | `order_engine_validate_recruit_worker_expectation_shorthand.dart` + compacted expectations | #3949 |
| csp-shorthand | add `cspExplorerGame` / `cspBuildOrders` / `cspExpect*` helpers; compact civilian/New World spawn expectation bodies | `civilian_spawn_expectations.dart` | `civilian_spawn_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 27: **32,158** (net +23 from post–slice 26; expectation bodies shortened, new `vbc*`/`vrw*`/`csp*` shorthand modules added). Remaining: further expectation compaction (`order_engine_validate_work_fixtures_*`, lib DRY items 5–6, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 28: application_helpers + build_unit_training expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ah-shorthand | add `ahExpectParseTileKey` / `ahWorkingUnit` / `ahExpectMineralEligible` helpers; compact application-helpers expectation bodies | `application_helpers_expectations.dart` | `application_helpers_expectation_shorthand.dart` + compacted expectations | #3949 |
| but-shorthand | add `butApply` / `butExpectNoOwUnitsAfter` / `butExpectValidRegimentBuild` / civilian-build helpers; compact build-unit/training expectation bodies | `build_unit_training_expectations_part{1,2}.dart` | `build_unit_training_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 28: **32,293** (net +135 from post–slice 27; expectation bodies shortened, new `ah*`/`but*` shorthand modules added). Remaining: further expectation compaction (`valid_work_tiles_*`, `order_suggestion_core_*`, lib DRY items 5–6, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 29: valid_work_tiles part2 expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| vwt-vis-shorthand | add `vwtExpectVisProspect*` / `vwtExpectVisExplore*` / `vwtExpectVisExploreLatencyUnder` helpers; compact prospect/explore visibility expectation bodies | `valid_work_tiles_expectations_part2.dart` | `valid_work_tiles_expectation_shorthand.dart` + compacted expectations | #3949 |
| vwt-suggest-shorthand | add `vwtExpectNoMovesToProvince` / `vwtExpectBuildSuggestionsSorted` / `vwtExpectNoBuildSuggestionForReservedTile`; compact suggest move/work expectation bodies | `valid_work_tiles_expectations_part2.dart` | same + `valid_work_tiles_fixtures.dart` (`owTribeExploreMultiProvinceFixture`, `owTribeExploreLatencyGame`, `owGpAdjacentMoveFixture`, `vwtHillsWoolTileMap`) | #3949 |

test/ LOC after slice 29: **32,413** (net +120 from post–slice 28; expectation bodies shortened, new `vwt*` fixtures/shorthand added). Remaining: further expectation compaction (`valid_work_tiles_part1`, `order_suggestion_core_*`, lib DRY items 5–6, …) toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 30: valid_work_tiles part1 + order_suggestion_core expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| vwt-part1-shorthand | add `vwtExpectKeysEmpty` / `vwtExpectVisMatchesPlain` / `vwtExpectBuildVisMembership` / `vwtExpectVisProspectExcludesAll` / suggest-explore/prospect helpers; compact build-improvement + empty-key expectation bodies | `valid_work_tiles_expectations_part1.dart`, `valid_work_tiles_expectations_part2.dart` | `valid_work_tiles_expectation_shorthand.dart` + `valid_work_tiles_fixtures.dart` (`vwtOwnedProvince`, `vwtExplorerDisallowedBuildGame`, `vwtColonistVisibilityFilterGame`) | #3949 |
| osc-core-shorthand | add `oscExpectThrowsSuggestMoveOnUnknownVisibility` / `oscExpectProvinceViewMatchesAll` / `oscExpectExploreTargetsProvince` / dual-builder + build-target helpers; compact core suggestion expectation bodies | `order_suggestion_core_expectations_part{1,2}.dart` | `order_suggestion_core_expectation_shorthand.dart` + `order_suggestion_core_fixtures.dart` (`oscPartialRevealExploreCacheGame`) | #3949 |

test/ LOC after slice 30: **32,548** (net +135 from post–slice 29; expectation bodies shortened, new `vwt*`/`osc*` shorthand and fixture modules added). Remaining: further expectation compaction (remaining large support files, imperative suites), lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 31: work_order_application + work_completion part1 expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| waa-part1-shorthand | add `waaProspectApply` / `waaApplyBuildImprovement` / `waaApplyBuildFort` / `waaExpectCurrentWorkTiming` / `waaCounterSpyForeignProvinceGame` / `waaEmbassyOverture` / `waaDualGpPurchaseLandGame` / `waaDualPurchaseLandOrders` / `waaExpectTownDevelopmentLevel` / `waaExpectUnitIdsPresent`; compact work-order application expectation bodies | `work_order_application_expectations_part1.dart` | `work_order_application_expectation_shorthand.dart` + compacted expectations | #3949 |
| wcc-part1-shorthand | add `wccEngineerWorking` / `wccExplorerWorking` / `wccEngineerCompletionGame` / `wccBuilderImprovementAtLevel` / `wccExpectUnitCancelledToOrigin` / `wccExpectRemainingTurns` / `wccExpectPortRegisteredForProvince` / `wccBuildRoadCapitalAdjacentGame` / `wccBuildRoadPortAdjacentGame`; compact work-completion expectation bodies | `work_completion_expectations_part1.dart` | `work_completion_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 31: **32,595** (net +47 from post–slice 30; part1 expectation bodies shortened, new `waa*`/`wcc*` shorthand helpers added). Remaining: further expectation compaction (remaining large support files, imperative suites), lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 32: build_unit_training + validateWork + osc core + vwt part1 compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| but-part2-shorthand | add `butExpectFluyteShipBuildApplied` / `butExpectNavalBuildRejectedWhenNoPeasants` / `butExpectSecondFluyteAddsToHomeFleet` / `butExpectMerchantTechGate`; compact build-unit/training part2 bodies | `build_unit_training_expectations_part2.dart` | `build_unit_training_expectation_shorthand.dart` + compacted expectations | #3949 |
| vw-part1-shorthand | add `vwExpectDualWorkOrders`; compact validateWork part1 dual-order bodies | `order_engine_validate_work_expectations_part1.dart` | `order_engine_validate_work_expectation_shorthand.dart` + compacted expectations | #3949 |
| osc-part1-shorthand | add `oscFoggedDestinationMoveGame` / `oscMislocatedExplorerMoveGame` / `oscExpectProspectTargetsTile` / `oscExpectWorkerSuggestStayInProvince`; compact core suggestion part1 bodies | `order_suggestion_core_expectations_part1.dart` | `order_suggestion_core_expectation_shorthand.dart` + compacted expectations | #3949 |
| vwt-part1-shorthand | add `vwtExpectMineralBuildGate` / `vwtExpectBuildResourceFilter`; compact valid-work-tiles part1 build-improvement bodies | `valid_work_tiles_expectations_part1.dart` | `valid_work_tiles_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 32: **32,687** (net +92 from post–slice 31; expectation bodies shortened, new `but*`/`vw*`/`osc*`/`vwt*` shorthand helpers added). Remaining: further expectation compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 33: work application/completion part2 + validateWork part2 compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| waa-part2-shorthand | add `waaApplyBuildRoad` / `waaExpectBuildRoadInsufficientMaterials` / `waaExpectBuildRoadWithMaterialsDeductsStockpile` / `waaCounterSpyCapitalGame` / `waaExpectCounterSpyOnCapital` / `waaExploreTwoTileGame` / `waaExpectExploreWorkStarted` / `waaExploreFormulaGame` / `waaExpectExploreFormulaTiming` / `waaExpectEngineerBuildRoadApplied` / `waaExpectBuildPortApplied`; compact work-order application part2 bodies | `work_order_application_expectations_part2.dart` | `work_order_application_expectation_shorthand.dart` + compacted expectations | #3949 |
| wcc-part2-shorthand | add `wccSteamPlayers` / `wccExpectRailCompletionLeavesRoadWhenTileHasNoRoad` / `wccExpectRailCompletionSetsRoadLevelTo4WhenValid` / `wccExpectRailDispatchSetsRoadLevel` / `wccExpectUpgradeTownProvinceLevel` / `wccExpectExploreDispatchCapturesRegion`; compact work-completion part2 bodies | `work_completion_expectations_part2.dart` | `work_completion_expectation_shorthand.dart` + compacted expectations | #3949 |
| vw-part2-shorthand | add `vwExpectScrubTimberRejected` / `vwExpectScrubTimberAccepted` / `vwExpectFortRejected` / `vwExpectRailRejected` / `vwExpectRailAccepted` / `vwExpectUpgradeTownOutcome`; compact validateWork part2 bodies | `order_engine_validate_work_expectations_part2.dart` | `order_engine_validate_work_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 33: **32,799** (net +112 from post–slice 32; part2 expectation bodies shortened, new `waa*`/`wcc*`/`vw*` shorthand helpers added). Remaining: further expectation compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 34: worker-pool / diplomatic / validateWork fixture compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| wpp-tier-shorthand | add `wppExpectJourneymanTrain` / `wppExpectMasterTrain` / `wppExpectMasterTrainSkipped` / `wppExpectSequentialTiers` / `wppExpectMultiPlayerApprenticeIsolation`; compact worker-pool phase expectation bodies | `worker_pool_phase_expectations_part1.dart` | `worker_pool_phase_expectation_shorthand.dart` + compacted expectations | #3949 |
| ved-dup-shorthand | add `vedExpectSecondOrderRejected` / `vedExpectGrantAidThenSubsidyAccepted`; compact validate-diplomatic part1 bodies | `order_engine_validate_diplomatic_expectations_part1.dart` | `order_engine_validate_diplomatic_expectation_shorthand.dart` + compacted expectations | #3949 |
| vw-fixture-shorthand | add `vwSingleProvinceUnitGame` / `_vwProvince`; refactor build-improvement/scrub-cap/rail/fort fixtures onto shared builder | `order_engine_validate_work_fixtures_part1.dart` | `order_engine_validate_work_fixture_shorthand.dart` + thin fixture wrappers | #3949 |

test/ LOC after slice 34: **32,847** (net +48 from post–slice 33; fixture/expectation bodies shortened, new `wpp*`/`ved*`/`vw*` shorthand modules added). Remaining: further expectation compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 35: move-validator fixtures + multi-family part1 compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| mv-fixtures | extract `mvTwoProvinceUnitGame` / `mvTwoProvinceArmyGame` / `mvCrossRegionTribeGame` / `mvOwTopology`; thin move-validator expectation runners | `move_validator_expectations.dart` | `move_validator_fixtures.dart` + compacted cases_a/b | #3949 |
| wcc-part1-shorthand | add `wccExpectImprovementWithEnvyHint` / `wccExpectAiEnvyEvidenceOnCoalCompletion` / `wccExpectSawMillCapStillAllowsLevel4` / `wccExpectConqueredProvinceCancelsWork` / `wccExpectTwoTurnImprovementCompletesOnSecondApply` / `wccExpectExploreSetsVisibility` / `wccExpectExploreRevealsBucketOnly`; compact work-completion part1 bodies | `work_completion_expectations_part1.dart` | `work_completion_expectation_shorthand.dart` + compacted expectations | #3949 |
| osc-part1-shorthand | add `oscTwoProvinceExplorerUnknownVisibilityGame` / `oscExpectMoveThrowsOnUnknownSourceVisibility` / `oscExpectFoggedExploreSuggestion` / `oscExpectFoggedProspectTargetsIron` / `oscExpectProvinceViewForProspectIteration` / `oscBuilderWorkerSuggestGame`; compact core suggestion part1 bodies | `order_suggestion_core_expectations_part1.dart` | `order_suggestion_core_expectation_shorthand.dart` + compacted expectations | #3949 |
| ah-shorthand | add `ahIdleBuilderUnit` / `ahBuilderWithImprovementWork`; compact application-helpers clear-work bodies | `application_helpers_expectations.dart` | `application_helpers_expectation_shorthand.dart` + compacted expectations | #3949 |
| ved-part2-shorthand | add `vedExpectGrantAidRejectedAfterPrior`; compact validate-diplomatic part2 bodies | `order_engine_validate_diplomatic_expectations_part2.dart` | `order_engine_validate_diplomatic_expectation_shorthand.dart` + compacted expectations | #3949 |
| waa-part1-shorthand | add `waaPurchaseLandNoEmbassyGame` / `waaPurchaseLandAtWarGame` / `waaExpectPurchaseLandRejected` / `waaCounterSpyOngoingAssignmentGame` / `waaExpectCounterSpyOngoingAssignmentPreservesUnits`; compact work-order application part1 bodies | `work_order_application_expectations_part1.dart` | `work_order_application_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 35: **32,946** (net +99 from post–slice 34; expectation bodies shortened, new `mv*`/`wcc*`/`osc*`/`ah*`/`ved*`/`waa*` shorthand and fixture modules added). Remaining: further expectation compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 36: naval fixtures + validateWork purchase/rail compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| nov-fixtures | add `novTwoAdjacentSeas` / `novThreeSeasLinear` / `novSeaProvinceAdjacent` / `novPortDualSea` / `novPortSeaChain` topology presets + `novValidatorAtSea` / `novValidatorInPort`; compact naval move expectation bodies | `naval_order_validator_expectations_move.dart`, `naval_order_validator_expectations_move_b.dart` | `naval_order_validator_fixtures.dart` + `naval_order_validator_expectation_shorthand.dart` + compacted expectations | #3949 |
| vw-part1-shorthand | add `vwExpectPurchaseLandRejectedNoEmbassy` / `vwExpectPurchaseLandRejectedAtWar` / `vwExpectPurchaseLandRejectedInsufficientTreasury` / `vwExpectPurchaseLandRejectedNoResource` / `vwExpectPurchaseLandRejectedMineralNotProspected` / `vwExpectPurchaseLandAcceptedEmbassy` / `vwExpectPurchaseLandAcceptedMineralProspected` / `vwExpectPurchaseLandRejectedAlreadyPurchasedByOther` / `vwExpectPurchaseLandRejectedAlreadyOwnedBySelf`; compact validateWork part1 bodies | `order_engine_validate_work_expectations_part1.dart` | `order_engine_validate_work_expectation_shorthand.dart` + compacted expectations | #3949 |
| vw-part2-shorthand | add `vwExpectEmptyTechCapBuildImprovementRejected` / `vwExpectTechCapBuildImprovementRejected` / `vwExpectRailTerrainRejected` / `vwExpectRailTerrainAccepted` / `vwExpectMinorProvinceRoadRejected`; compact validateWork part2 bodies | `order_engine_validate_work_expectations_part2.dart` | `order_engine_validate_work_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 36: **33,002** (net +56 from post–slice 35; expectation bodies shortened, new `nov*`/`vw*` shorthand and fixture modules added). Remaining: further expectation compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 37: multi-family mineral/spawn/build/vwt/ved/osc/wpp compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ah-mineral-shorthand | add `ahExpectMountainProspectableWithoutResource` / `ahExpectPlainsGoldNotProspectable` / `ahExpectHillsWoolNotProspectable` / `ahExpectHillsIronProspectable` / `ahExpectAbsentResourceNotMineral` / `ahExpectGrainNotMineral` / `ahExpectCoalMineral`; compact application-helpers mineral eligibility bodies | `application_helpers_expectations.dart` | `application_helpers_expectation_shorthand.dart` + compacted expectations | #3949 |
| csp-spawn-shorthand | add `cspExpectExplorerSpawnAtCapital` / `cspExpectNewWorldMilitarySpawn`; compact civilian spawn expectation bodies | `civilian_spawn_expectations.dart` | `civilian_spawn_expectation_shorthand.dart` + compacted expectations | #3949 |
| but-part1-shorthand | add `butExpectFluyteSpentNoFleet` / `butExpectTreasuryInsufficientRegimentBuildRejected`; compact build-unit/training part1 ship-failure and treasury bodies | `build_unit_training_expectations_part1.dart` | `build_unit_training_expectation_shorthand.dart` + compacted expectations | #3949 |
| vwt-part1-part3-shorthand | add `vwtExpectControlledTilesWithResourcesOnly` / `vwtExpectPurchasedTileIncluded` / `vwtExpectSeaZoneTileExcluded` / `vwtExpectProspectExcludedWhenIronProspected` / `vwtExpectPurchaseLandIncluded` / `vwtExpectPurchaseLandExcluded`; compact valid-work-tiles part1/part3 bodies | `valid_work_tiles_expectations_part{1,3}.dart` | `valid_work_tiles_expectation_shorthand.dart` + compacted expectations | #3949 |
| ved-part1-shorthand | add `vedExpectDeclareWarRejectedWhenAtWar` / `vedExpectOfferPeaceRejectedWhenNotAtWar` / `vedExpectOvertureRejectedAtWar` / `vedExpectConsulateRejectedNoDiplomaticExpertise` / `vedExpectConsulateRejectedLowTreasury` / `vedExpectEmbassyRequiresConsulate` / `vedExpectSubsidyEmbassyRequired` / `vedExpectSubsidyAcceptedLowTreasury` / `vedExpectSubsidyAcceptedValidPercent` / `vedExpectSubsidyRejectedInvalidPercent`; compact validate-diplomatic part1 bodies | `order_engine_validate_diplomatic_expectations_part1.dart` | `order_engine_validate_diplomatic_expectation_shorthand.dart` + compacted expectations | #3949 |
| osc-core-shorthand | add `oscExpectCapitalBuildSuggestList` / `oscExpectAffordableShipBuildSuggestions` / `oscExpectAffordableRegimentAndShipBuildSuggestions` / `oscExpectResearchSuggestList` / `oscExpectNavalMoveSuggestList` / `oscExpectNavalMissionSuggestList` / `oscExpectMerchantPurchaseLandWorkSuggested`; compact core suggestion part1/part2 bodies | `order_suggestion_core_expectations_part{1,2}.dart` | `order_suggestion_core_expectation_shorthand.dart` + compacted expectations | #3949 |
| wpp-tier-shorthand | add `wppExpectRecruitPeasantFromFabric` / `wppExpectApprenticeTrainSkippedWhenUnaffordable`; compact worker-pool phase expectation bodies | `worker_pool_phase_expectations_part1.dart` | `worker_pool_phase_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 37: **33,113** (net +111 from post–slice 36; expectation bodies shortened, new `ah*`/`csp*`/`but*`/`vwt*`/`ved*`/`osc*`/`wpp*` shorthand helpers added). Remaining: further expectation compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 38: waa/wcc/vw/osc/vwt/but multi-family part1 compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| waa-part1-shorthand | add `waaExpectProspectEligible` / `waaExpectProspectIneligible` / `waaExpectPurchaseLandSuccess` / `waaExpectDualGpPurchaseLandFirstWins` / `waaExpectBuildImprovementCompletesIdle` / `waaExpectBuildFortCurrentWork` / `waaExpectCounterSpyForeignCurrentWork` / `waaExpectBuildFortMaterialsDeducted` / `waaExpectBuildFortSkipped` / `waaExpectUpgradeTownDevelopmentApplied`; compact work-order application part1 bodies | `work_order_application_expectations_part1.dart` | `work_order_application_expectation_shorthand.dart` + compacted expectations | #3949 |
| wcc-part1-shorthand | add `wccExpectBasicImprovementCompletion` / `wccExpectImprovementCapsAtLevel4` / `wccExpectBuildRoadLevelIncrease` / `wccExpectBuildRoadCapitalAdjacentPropagation` / `wccExpectBuildRoadPortAdjacentPropagation` / `wccExpectBuildPortCompletion` / `wccExpectBuildFortCompletion`; compact work-completion part1 bodies | `work_completion_expectations_part1.dart` | `work_completion_expectation_shorthand.dart` + compacted expectations | #3949 |
| vw-part2-shorthand | add `vwExpectMineralBuildImprovement*` / `vwExpectGrainBuildImprovement*` / `vwExpectBuildImprovementRejectedNoResource` / `vwExpectBuildImprovementRejectedAtLevel4` / `vwExpectGrainUpgradeWithLandEnclosure` / `vwExpectBuildImprovementAcceptedAtLevel4TechCap` / `vwExpectBuildImprovementRejectedForeignUnpurchased` / `vwExpectBuildImprovementAcceptedOnPurchasedForeignTile` / `vwExpectMinorProvinceRoadRejected*`; compact validateWork part2 bodies | `order_engine_validate_work_expectations_part2.dart` | `order_engine_validate_work_expectation_shorthand.dart` + compacted expectations | #3949 |
| osc-part1-shorthand | add `oscExpectFoggedDestinationFirstMove` / `oscExpectMislocatedExplorerMoveUsesTileProvince` / `oscExpectNoExploreWhenProvinceUnknown` / `oscExpectNoProspectWhenProvinceNotFogged` / `oscExpectBuildImprovementOnSecondTileInProvince` / `oscExpectBuildImprovementOnOtherOwnedProvince`; compact core suggestion part1 bodies | `order_suggestion_core_expectations_part1.dart` | `order_suggestion_core_expectation_shorthand.dart` + compacted expectations | #3949 |
| vwt-part1-shorthand | add `vwtExpectVisProspectExcludesGrassAndProspectedIron`; compact valid-work-tiles part1 prospect-excludes body | `valid_work_tiles_expectations_part1.dart` | `valid_work_tiles_expectation_shorthand.dart` + compacted expectations | #3949 |
| but-part2-shorthand | add `butExpectCivilianTreasuryInsufficientRejected`; compact civilian treasury rejection body | `build_unit_training_expectations_part2.dart` | `build_unit_training_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 38: **33,276** (net +163 from post–slice 37; expectation bodies shortened, new `waa*`/`wcc*`/`vw*`/`osc*`/`vwt*`/`but*` shorthand helpers added). Remaining: further expectation compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 39: vrw/vet/vw/vwt engine+suggestion expectation compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| vrw-shorthand | add `vrwPlayer` / `vrwExpectPeasantRecruitAccepted` / `vrwExpectApprenticeTrainRejectedTechLocked` / `vrwExpectRecruitConsumesPeasantBeforeMilitaryBuild` / `vrwExpectRecruitThenCivilianBuildAccepted`; compact validateRecruitWorker bodies | `order_engine_validate_recruit_worker_expectations.dart` | `order_engine_validate_recruit_worker_expectation_shorthand.dart` + compacted expectations | #3949 |
| vet-shorthand | add `vetExpectValidOfferAccepted` / `vetExpectMutualExclusionRejected` / `vetExpectOfferExceedsStockpileRejected` / `vetExpectFirstBidAcceptedNoEmbassy` / `vetExpectSecondBidRejectedNoEmbassy`; compact validateTrade bodies | `order_engine_validate_trade_expectations.dart` | `order_engine_validate_trade_expectation_shorthand.dart` + compacted expectations | #3949 |
| vw-part1-shorthand | add `vwExpectSecondPendingWorkOrderRejected` / `vwExpectSameTileDevelopmentExclusivityRejected`; compact validateWork part1 dual-order bodies | `order_engine_validate_work_expectations_part1.dart` | `order_engine_validate_work_expectation_shorthand.dart` + compacted expectations | #3949 |
| vwt-part2-shorthand | add `vwtExpectVisProspectIncludesEligibleIronTile` / `vwtExpectVisProspectExcludesWoolOnHillsTerrain` / `vwtExpectVisExplorePartialProvincesOnly` / `vwtExpectVisExploreLargeMapUnderOneSecond` / `vwtExpectNoMovesToOtherGpProvince` / `vwtExpectBuildSuggestionsSortedThreeTiles` / `vwtExpectNoBuildForReservedTilePair`; compact valid-work-tiles part2 bodies | `valid_work_tiles_expectations_part2.dart` | `valid_work_tiles_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 39: **33,347** (net +71 from post–slice 38; expectation bodies shortened, new `vrw*`/`vet*`/`vw*`/`vwt*` shorthand helpers added). Remaining: further expectation compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 40: ved/vw/vwt/but/wpp preset compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ved-part1-shorthand | add `vedExpectDuplicateOvertureRejected` / `vedExpectGpAllianceDeclareWarConflictRejected` / `vedExpectGrantAidEmbassyTreasuryRejected` / `vedExpectGrantAidMultipleRejected`; compact validate-diplomatic part1 duplicate-order and grant-aid bodies | `order_engine_validate_diplomatic_expectations_part1.dart` | `order_engine_validate_diplomatic_expectation_shorthand.dart` + compacted expectations | #3949 |
| vw-part2-shorthand | add `vwExpectFortLevel2RejectedWithoutMineEngineering` / `vwExpectFortLevel3RejectedWithoutModernForts` / `vwExpectRailMissingTerrainDataRejected`; compact validateWork part2 fort/rail bodies | `order_engine_validate_work_expectations_part2.dart` | `order_engine_validate_work_expectation_shorthand.dart` + compacted expectations | #3949 |
| vwt-part2-shorthand | add `vwtExpectPartialRevealExploreIncluded` / `vwtExpectPartialRevealExploreExcluded` / `vwtExpectPartialRevealProspectIncluded`; compact valid-work-tiles part2 partial-reveal bodies | `valid_work_tiles_expectations_part2.dart` | `valid_work_tiles_expectation_shorthand.dart` + compacted expectations | #3949 |
| but-part1-shorthand | add `butExpectTechLockedRegimentSkipped` / `butExpectTechLockedShipSkipped`; compact build-unit/training part1 tech-gate bodies | `build_unit_training_expectations_part1.dart` | `build_unit_training_expectation_shorthand.dart` + compacted expectations | #3949 |
| but-part2-shorthand | add `butExpectPeasantLevyBuildApplied`; compact build-unit/training part2 valid-regiment body | `build_unit_training_expectations_part2.dart` | `build_unit_training_expectation_shorthand.dart` + compacted expectations | #3949 |
| wpp-part1-shorthand | add `wppExpectJourneymanTrain2692S9` / `wppExpectMasterTrain2692S9` / `wppExpectMasterTrainSkipped2692S9TechGate` / `wppExpectSequentialPeasantThenApprentice2692S9` / `wppExpectSequentialApprenticeSkipThenPeasant2692S9`; compact worker-pool phase part1 tier/ordering bodies | `worker_pool_phase_expectations_part1.dart` | `worker_pool_phase_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 40: **33,419** (net +72 from post–slice 39; expectation bodies shortened, new preset shorthand helpers added). Remaining: further expectation compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 41: mv/nov/vbc/waa/vwt validator preset compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| mv-cases-shorthand | add `mvExpectBuilderCannotEnterGp` / `mvExpectMilitaryRegimentRejected` / `mvExpectArmyIntoGpNoWar` / `mvExpectBuilderCannotEnterMinor` / `mvExpectExplorerOntoMinor` / `mvExpectSpyOntoOtherGp` / `mvExpectExplorerCrossRegionTribe` / `mvExpectBuilderCrossRegionTribeInvalid` / `mvExpectShortCircuitPreviousRejected` / `mvExpectArmyIntoMinorNoWar` / `mvExpectArmyIntoGpWithDeclareWar` / `mvExpectArmyIntoMinorWithDeclareWar` / `mvExpectArmyIntoTribeWithDeclareWar` / `mvExpectArmyIntoMinorTribeNoWar`; compact move-validator cases_a/cases_b bodies | `move_validator_expectations_cases_{a,b}.dart` | `move_validator_expectation_shorthand.dart` + compacted expectations | #3949 |
| nov-mission-shorthand | add `novExpectMissionPreviousRejected` / `novExpectBlockadeNoTarget` / `novExpectBlockadeUnprefixedTarget` / `novExpectBlockadeOwnProvince` / `novExpectPatrolAcceptedAtSea`; compact naval mission expectation bodies | `naval_order_validator_expectations_mission.dart` | `naval_order_validator_expectation_shorthand.dart` + compacted expectations | #3949 |
| vbc-shorthand | add `vbcExpectUnknownUnitTypeRejected` / `vbcExpectBuilderRejectedLowTreasury` / `vbcExpectBuilderRejectedInsufficientPaper` / `vbcExpectMerchantRejectedNoTech` / `vbcExpectBuilderAcceptedDefaultSpawn` / `vbcExpectMerchantAcceptedWithTech` / `vbcExpectBuilderAcceptedEmptySpawnProvince` / `vbcExpectBuilderAcceptedForeignSpawnFallsBackToCapital`; compact validateBuild(civilian) bodies | `order_engine_validate_build_civilian_expectations.dart` | `order_engine_validate_build_civilian_expectation_shorthand.dart` + compacted expectations | #3949 |
| waa-part2-shorthand | add `waaExpectUnknownTargetIdle`; compact unknown-work-target body | `work_order_application_expectations_part2.dart` | `work_order_application_expectation_shorthand.dart` + compacted expectations | #3949 |
| vwt-part3-shorthand | add `vwtExpectMinorPurchaseLandIncludedWithEmbassy` / `vwtExpectMinorPurchaseLandExcludedWithoutEmbassy` / `vwtExpectOwnedMineralBuildGateDefaultTiles`; compact valid-work-tiles part1/part3 bodies | `valid_work_tiles_expectations_part{1,3}.dart` | `valid_work_tiles_expectation_shorthand.dart` + compacted expectations | #3949 |

test/ LOC after slice 41: **33,527** (net +108 from post–slice 40; expectation bodies shortened, new `mv*`/`nov*`/`vbc*`/`waa*`/`vwt*` preset shorthand helpers added). Remaining: further expectation compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 42: naval move + ICE equivalence preset compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| nov-move-shorthand | add `novExpectMovePreviousRejected` / `novExpectFleetNotFound` / `novExpectFleetNotOwned` / `novExpectHomeFleetRejected` / `novExpectAdjacentSeaAccepted` / `novExpectNonAdjacentSeaRejected` / `novExpectDockSeaNotAdjacent` / `novExpectUndockAccepted` / `novExpectProvinceAsSeaRejected` / `novExpectInPortDirectPsEdgeAccepted` / `novExpectInPortSsOnlyReachability` / `novExpectBrokenInPortRejected` / `novExpectDockAdjacentOwnedAccepted` / `novExpectDockLocalPortIdAccepted` / `novExpectDockFleetInPortRejected` / `novExpectDockNotOwnedRejected` / `novExpectDockPortNotFoundRejected`; compact naval move expectation bodies | `naval_order_validator_expectations_move.dart`, `naval_order_validator_expectations_move_b.dart` | `naval_order_validator_expectation_shorthand.dart` + compacted expectations | #3949 |
| ice-corpus-shorthand | add `iceExpectMoveBuilderOwnProvince` / `iceExpectBuildSuccessiveProbes` / `iceExpectDiplomaticSequentialProbes` / `iceExpectArmyMoveGpDeclareWar` / `iceExpectNavalMoveAdjacentSea` / … (full move/build/work/diplomatic/army/naval preset set); compact ICE equivalence expectation bodies | `incremental_candidate_validator_equivalence_expectations_part{1,2}.dart` | `incremental_candidate_validator_equivalence_expectation_shorthand.dart` + compacted expectations | #3949 |
| nov-fixtures-import | break circular import: `naval_order_validator_fixtures.dart` uses `navalOrderValidatorForTest` directly so shorthand can import topology presets | `naval_order_validator_fixtures.dart` | same | #3949 |

test/ LOC after slice 42: **33,733** (net +206 from post–slice 41; expectation bodies shortened, new `nov*`/`ice*` preset helpers added). Remaining: further expectation compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 43: dispatch inline + ah/osc/vwt/wcc/waa/ved preset compaction

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| dispatch-inline-ice | call `iceExpect*` directly from `runIncrementalEquivalenceExpectation`; delete part wrappers | `incremental_candidate_validator_equivalence_expectations_part{1,2}.dart` | `incremental_candidate_validator_equivalence_expectations.dart` | #3949 |
| dispatch-inline-mv-nov | call `mvExpect*`/`novExpect*` directly from validator dispatch; delete part wrappers | `move_validator_expectations_cases_{a,b}.dart`, `naval_order_validator_expectations_{move,move_b,mission}.dart` | consolidated expectation runners | #3949 |
| dispatch-inline-engine-app-sugg | call `ved*`/`vw*`/`vet*`/`wcc*`/`waa*`/`osc*`/`vwt*`/`ah*` presets directly from scenario dispatch; delete part wrappers | `order_engine_validate_*_expectations_part*.dart`, `work_*_expectations_part*.dart`, `order_suggestion_core_expectations_part*.dart`, `valid_work_tiles_expectations_part*.dart`, `application_helpers_expectations.dart` | consolidated expectation runners + shorthand presets | #3949 |
| preset-shorthand-43 | add `vedExpectSecondGrantAidRejected` / `vedExpectDeclareWarThenGrantAidRejected`; `vwExpectScrubTimberLevel*` / `vwExpectRailRejected*` / `vwExpectUpgradeTown*`; `wccExpectRailDispatch*`; `waaExpectBuildFortLevel*Skipped*`; `ahExpectParse*` / `ahExpectCancelWork*` / `ahExpectClearWork*`; `oscExpectPartialRevealExploreCacheAligned` / `oscExpectDualBuilder*` / `oscExpectCapitalBuildSuggestDefaultList` / `oscExpectCounterSpyOnOwnedProvince`; `vwtExpectUnknownUnit*` / `vwtExpectExplorerDisallowed*` / `vwtExpectColonistVisibilityFilterMatchesPlain` | various `*_expectation_shorthand*.dart` | same + compacted dispatch bodies | #3949 |

test/ LOC after slice 43: **32,866** (net −867 from post–slice 42; deleted 20 part-wrapper files, inlined dispatch to shorthand presets). Remaining: further imperative-suite compaction, lib DRY items 5–6, scenario-table migration harness + CI gates toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 44: order_merge scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| merge-moves | prefers human move orders over AI for same unit | `order_merge_part1_test.dart` | `support/merge/order_merge_scenarios.dart` + `order_merge_test.dart` | #3949 |
| merge-moves-ai | keeps AI move orders when human has none for unit | same | same | #3949 |
| merge-diplomatic | merges diplomatic orders with human precedence per (type,target) | same | same | #3949 |
| merge-null-ai | returns human orders when aiOrders is null | same | same | #3949 |
| merge-empty-ai | returns human orders when aiOrders is empty (all maps empty) | same | same | #3949 |
| merge-build | merge build orders: human and AI both contribute | same | same | #3949 |
| merge-work | merge work orders: human for unit A, AI for unit B | same | same | #3949 |
| merge-research-human | merge research orders: human wins when both have orders | same | same | #3949 |
| merge-research-ai | merge research orders: AI used when human has none | same | same | #3949 |
| merge-naval-move | merge naval move orders: human and AI for different fleets | `order_merge_part2_test.dart` | same | #3949 |
| merge-naval-mission | merge naval mission orders: human and AI for different fleets | same | same | #3949 |
| merge-multi-player | multiple players: both get merged lists | same | same | #3949 |
| merge-trade-ai | merges AI trade orders when human has none (Refs #2924) | same | same | #2924, #3949 |
| merge-trade-human | human trade orders replace AI trade for same player | same | same | #3949 |
| merge-diplomatic-dedup | diplomatic merge drops AI order duplicating human (type,target) | same | same | #3949 |
| merge-build-append | build merge appends AI after human, capped at combined count | same | same | #3949 |
| merge-stable-order | merge uses stable player ordering | same | same | #3949 |

Merged `order_merge_part{1,2}_test.dart` → `orders/order_merge_test.dart` (≤400 lines). Family LOC moved into `order_merge_expectations.dart` + `order_merge_scenarios.dart`. Removed part files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 44: **33,003** (net +137 from post–slice 43; scenario tables add support modules but remove two part runners). Remaining: further imperative-suite compaction, lib DRY items 5–6, scenario-table migration toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 45: order_engine_core scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oec-add-order | add order and validate | `order_engine_core_part1_test.dart` | `support/engine/order_engine_core_scenarios.dart` + `order_engine_core_test.dart` | #3949 |
| oec-remove-move | removeMoveOrder removes order at index | same | same | #3949 |
| oec-remove-build | removeBuildOrder removes order at index | same | same | #3949 |
| oec-work-rejected | addWorkOrderWithContext returns rejected when order invalid | same | same | #3949 |
| oec-invalid-chain | first invalid order plus subsequent rejected | same | same | #3949 |
| oec-projected-workers | projected effects returns worker count | same | same | #3949 |
| oec-projected-locations | projectedEffects returns unitLocations when engine has move order | same | same | #3949 |
| oec-projected-no-mutate | projectedEffects does not mutate passed-in game | same | same | #3949 |
| oec-move-context | addMoveOrderWithContext uses world-state validation | same | same | #3949 |
| oec-civilian-gp | civilian cannot move into other GP territory | `order_engine_core_part2_test.dart` | same | #3949 |
| oec-military-no-war | military cannot move into other GP province without war | same | same | #943, #3949 |
| oec-military-declare | military may move into other GP province with same-turn declareWar | same | same | #3949 |
| oec-explorer-tribe | explorer may move into tribal province | same | same | #3949 |
| oec-move-unknown-src | move order rejected when source province unknown | same | same | #3949 |

Merged `order_engine_core_part{1,2}_test.dart` → `orders/order_engine_core_test.dart` (≤400 lines). Family LOC moved into `order_engine_core_expectations.dart` + `order_engine_core_fixtures.dart` + `order_engine_core_scenarios.dart`. Removed part files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 45: **32,881** (net −122 from post–slice 44; scenario tables add support modules but remove two part runners). Remaining: further imperative-suite compaction (`order_engine_move_and_work_context_part*`, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 46: order_engine_move_and_work_context scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oemwc-move-dest-unknown | move order rejected when destination province unknown | `order_engine_move_and_work_context_part1_test.dart` | `support/engine/order_engine_move_and_work_context_scenarios.dart` + `order_engine_move_and_work_context_test.dart` | #3949 |
| oemwc-explore-unknown | work order explore rejected when province unknown | same | same | #3949 |
| oemwc-explore-gp | work order explore rejected on foreign GP tile for explorer | same | same | #3949 |
| oemwc-prospect-not-fogged | work order prospect rejected when province not fogged or better | same | same | #3949 |
| oemwc-prospect-not-mineral | work order prospect rejected when tile is not mineral-eligible | same | same | #3949 |
| oemwc-prospect-accepted | work order prospect accepted when mineral-eligible and visibility ok | `order_engine_move_and_work_context_part2_test.dart` | same | #3949 |
| oemwc-prospect-no-consulate | work order prospect rejected in Tribe province without a consulate (Refs #3753 R4) | same | same | #3753, #3949 |
| oemwc-prospect-gp | work order prospect rejected on foreign GP tile for explorer | same | same | #3949 |
| oemwc-move-not-adjacent | move order rejected when destination not adjacent and not own province | same | same | #3949 |
| oemwc-civilian-own-province | civilian move order accepted when destination not adjacent but own province | same | same | #3949 |
| oemwc-prospect-already | work order prospect rejected when tile already prospected | `order_engine_move_and_work_context_part3_test.dart` | same | #3949 |

Merged `order_engine_move_and_work_context_part{1,2,3}_test.dart` → `orders/order_engine_move_and_work_context_test.dart` (≤400 lines). Family LOC moved into `order_engine_move_and_work_context_expectations.dart` + `order_engine_move_and_work_context_fixtures.dart` + `order_engine_move_and_work_context_scenarios.dart`. Removed part files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 46: **32,810** (net −71 from post–slice 45; scenario tables add support modules but remove three part runners). Remaining: further imperative-suite compaction, lib DRY items 5–6, scenario-table migration toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 47: order_engine_naval_build_validation scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oenb-move-cross-own | move order accepted for own province across regions | `order_engine_naval_build_validation_test.dart` | `support/engine/order_engine_naval_build_validation_scenarios.dart` + thin runner | #3949 |
| oenb-move-cross-foreign | move order rejected when destination is foreign province across regions | same | same | #3949 |
| oenb-work-invalid | work order rejected for invalid target for unit type | same | same | #3949 |
| oenb-initial-copy | initial orders copy: getter returns equal but distinct lists | same | same | #3949 |
| oenb-naval-fleet | naval move order rejected when fleet not found | same | same | #3949 |
| oenb-blockade-peace | blockade order rejected when not at war with province owner | same | same | #3949 |
| oenb-blockade-war | blockade order accepted when at war with province owner | same | same | #3949 |

Migrated imperative `order_engine_naval_build_validation_test.dart` → table-driven scenarios with `order_engine_naval_build_validation_expectations.dart`. Added missing baseline pin for foreign-province cross-region move rejection. Removed file from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 47: **32,896** (net +86 from post–slice 46; scenario support modules add LOC while runner shrinks to ≤20 lines). Remaining: further imperative-suite compaction (`order_engine_naval_build_projection_and_workers_test.dart`, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 48: order_engine_naval_build_projection_and_workers scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oenb-pw-treasury | projectedEffects returns treasuryDelta when orders affect treasury | `order_engine_naval_build_projection_and_workers_test.dart` | `support/engine/order_engine_naval_build_projection_and_workers_scenarios.dart` + thin runner | #3949 |
| oenb-pw-peasants | rejects naval build when peasants are zero | same | same | #3949 |

Migrated imperative `order_engine_naval_build_projection_and_workers_test.dart` → table-driven scenarios with `order_engine_naval_build_projection_and_workers_expectations.dart`. Removed file from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 48: **32,959** (net +63 from post–slice 47; scenario support modules add LOC while runner shrinks to ≤20 lines). Remaining: further imperative-suite compaction (`order_engine_validation_phase_plan_test.dart`, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 49: order_engine_civilian_move_xor_work scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ocmxw-reject-work | rejects work when same civilian already has a move order | `order_engine_civilian_move_xor_work_test.dart` | `support/engine/order_engine_civilian_move_xor_work_scenarios.dart` + thin runner | #3949 |
| ocmxw-merged-draft | merged draft with move then work rejects work (move remains valid) | same | same | #3949 |

Migrated imperative `order_engine_civilian_move_xor_work_test.dart` → table-driven scenarios with `order_engine_civilian_move_xor_work_expectations.dart` + `order_engine_civilian_move_xor_work_fixtures.dart`. Removed file from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 49: **32,972** (net +13 from post–slice 48; scenario support modules add LOC while runner shrinks to ≤15 lines). Remaining: further imperative-suite compaction (`order_engine_validation_phase_plan_test.dart`, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 50: order_engine_validation_phase_plan + order_suggestion_work_feedstock_priority scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oevpp-phase-order | declares the canonical per-category phase order | `order_engine_validation_phase_plan_test.dart` | `support/engine/order_engine_validation_phase_plan_scenarios.dart` + thin runner | #3949 |
| oevpp-unique | phase names are unique (no category runs twice) | same | same | #3949 |
| oevpp-bundle-refresh | move + army-move share the initial bundle; resource/diplomatic/naval phases refresh; trade reuses the advanced bundle | same | same | #3949 |
| osfp-gate-active | supplier gate active: the emitted build_improvement suggestion targets the unimproved iron feedstock tile, not the lex-first grain tile | `order_suggestion_work_feedstock_priority_test.dart` | `support/suggestion/order_suggestion_work_feedstock_priority_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| osfp-gate-inactive | supplier gate inactive (peer at quota): ordinary lexicographic ordering emits the grain tile (negative control) | same | same | #3949 |
| osfp-castiron-waiver | supplier with lumber only: feedstock build_improvement is accepted under castIron waiver | same | same | #3949 |
| osfp-deterministic | suggestion ordering is deterministic across repeated passes | same | same | #3949 |
| osfp-co-timber-iron | supplier holds timber but no iron: the emitted build_improvement suggestion targets the least-held iron tile, not the lex-first timber tile | same | same | #3949 |
| osfp-co-tie-break | supplier holds equal feedstock (zero of each): lexicographic tie-break emits the timber tile (negative control) | same | same | #3949 |
| osfp-co-deterministic | co-availability ordering is deterministic across repeated passes | same | same | #3949 |

Migrated imperative `order_engine_validation_phase_plan_test.dart` and `order_suggestion_work_feedstock_priority_test.dart` → table-driven scenarios with dedicated expectations (+ fixtures for feedstock). Removed both files from `ordersPreferScenarioTablesAllowlist`. Fixed slice 49 multiline `label:` pin so preserved-description CI collects `merged draft with move then work rejects work (move remains valid)`.

test/ LOC after slice 50: **33,109** (net +137 from post–slice 49; scenario support modules add LOC while runners shrink). Remaining: further imperative-suite migration (suggestion families, validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400; optional opportunistic precheck/feedstock/army-move cleanup.

## Wave 3 — Slice 51: order_engine_validator_injection scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oevi-injected | OrderEngine validator factory allows injected validators | `order_engine_validator_injection_test.dart` | `support/engine/order_engine_validator_injection_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| oevi-six-bundles | validatePlayerOrdersWithContext builds six validator bundles (shared move+army, then fresh per later category; #2391 AC7, #2692 S4) | same | same | #2391 AC7 |

Migrated imperative `order_engine_validator_injection_test.dart` → table-driven scenarios with `order_engine_validator_injection_expectations.dart` + `order_engine_validator_injection_fixtures.dart`. Removed file from `ordersPreferScenarioTablesAllowlist`. Pinned multiline former `test(` description for six-bundle factory-call count in baseline + scenario `label:`.

test/ LOC after slice 51: **33,193** (net +84 from post–slice 50; scenario support modules add LOC while runner shrinks to 15 lines). Remaining: further imperative-suite migration (suggestion families, validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 52: work_suggestion_pipeline + validator_bundle scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| wsp-duplicate-pending | duplicate pending target short-circuits without adding suggestions | `work_suggestion_pipeline_test.dart` | `support/suggestion/work_suggestion_pipeline_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| wsp-first-accepted | first accepted candidate stops iteration when includeAllAccepted is false | same | same | #3949 |
| wsp-include-all | includeAllAccepted collects multiple rows and logs includedCount | same | same | #3949 |
| wsp-no-candidates | no candidates logs noCandidateReason | same | same | #3949 |
| wsp-resolve-no-candidate | resolveNoCandidateReason overrides noCandidateReason when nothing yielded | same | same | #3949 |
| wsp-max-probe | maxProbeAttempts override allows more than default cap of accepted rows | same | same | #3949 |
| wsp-default-cap | default cap of kMaxWorkProbeAttemptsPerUnitPerTarget caps accepted rows | same | same | #3949 |
| wsp-rejected | rejected candidates log engineRejectedReason | same | same | #3949 |
| vb-wired | createOrderValidators returns wired validators (Refs #2391 AC6) | `validator_bundle_test.dart` | `support/validators/validator_bundle_scenarios.dart` + fixtures/expectations + thin runner | #2391 AC6 |

Migrated imperative `work_suggestion_pipeline_test.dart` and `validator_bundle_test.dart` → table-driven scenarios with dedicated support modules. Logger capture moved into `withWspLogCapture` fixture helper. Removed both files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 52: **33,319** (net +126 from post–slice 51; scenario support modules add LOC while runners shrink). Remaining: further imperative-suite migration (suggestion families, validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 53: order_effects_projector_seam + work_order_duration_preview scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oeps-injected-output | uses the injected projector output | `order_effects_projector_seam_test.dart` | `support/engine/order_effects_projector_seam_scenarios.dart` + fixtures/expectations + thin runner | #3290 C2 |
| oeps-no-projector | throws StateError when no projector was injected | same | same | #3290 C2 |
| oeps-trade-no-projector | throws StateError when a trade order is validated without a projector | same | same | #3290 C2 |
| oeps-trade-valid-offer | uses the injected projector and accepts a valid offer | same | same | #3290 C2 |
| oeps-no-trade-skip | does not invoke the projector when no trade order is staged | same | same | #3290 C2 |
| wodp-explore-scaled | returns scaled explore turns from province size | `work_order_duration_preview_test.dart` | `support/application/work_order_duration_preview_scenarios.dart` + expectations + thin runner | #3949 |
| wodp-fort-scaled | returns fort-level scaled turns for build_fort | same | same | #3949 |
| wodp-counter-spy | returns one turn for counter_spy | same | same | #3949 |
| wodp-improvement-scaled | returns improvement-level scaled turns for build_improvement | same | same | #3949 |
| wodp-prospect-purchase | returns minimum one turn for prospect and purchase_land | same | same | #3949 |

Migrated imperative `order_effects_projector_seam_test.dart` and `work_order_duration_preview_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent multiline trade-order projector baseline description. Removed both files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 53: **33,471** (net +152 from post–slice 52; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — slice 54 (order resolution context + explorer consulate gate)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| orc-reuse-view | buildOrderResolutionContext reuses view and cached units (Refs #2836) | `order_resolution_context_test.dart` | `support/engine/order_resolution_context_scenarios.dart` + fixtures/expectations + thin runner | #2836 |
| orc-from-view | orderResolutionContextFromView aliases provincesById | same | same | #3949 |
| ecg-no-overture | blocks a Minor/Tribe province when no overture exists | `explorer_consulate_gate_predicate_test.dart` | `support/engine/explorer_consulate_gate_predicate_scenarios.dart` + fixtures/expectations + thin runner | #3753 R4 |
| ecg-below-consulate | blocks when the overture is below Consulate (none) | same | same | #3753 R4 |
| ecg-consulate-held | does not block when a Consulate is held | same | same | #3753 R4 |
| ecg-embassy-held | does not block when an Embassy (above Consulate) is held | same | same | #3753 R4b |
| ecg-gp-province | does not gate a Great Power-owned province | same | same | #3753 R4 |
| ecg-own-null | does not gate the player own province or a null owner | same | same | #3753 R4 |

Migrated imperative `order_resolution_context_test.dart` and `explorer_consulate_gate_predicate_test.dart` → table-driven scenarios with dedicated support modules. Removed both files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 54: **33,665** (net +194 from post–slice 53). Remaining: further imperative-suite migration (suggestion families, validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 55: civilian projected tile + propagate road + partial province reveal scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| cpt-prefers-pending | prefers pending work-order target tile key | `civilian_projected_tile_test.dart` | `support/application/civilian_projected_tile_scenarios.dart` + expectations + thin runner | #3949 |
| cpt-explore-exact | keeps exact pending tile key for explore projection | same | same | #3949 |
| prac-null-player | returns unchanged when player is null | `propagate_road_to_adjacent_capital_test.dart` | `support/application/propagate_road_to_adjacent_capital_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| prac-bad-key | returns unchanged when tile key is malformed | same | same | #3949 |
| prac-capital | propagates road level to adjacent capital tile when higher | same | same | #3949 |
| prac-port | propagates road level to adjacent port tile when higher | same | same | #3949 |
| ppr-includes-prefixed | includes prefixed province id when land tiles mix unknown and known | `partial_province_reveal_test.dart` | `support/engine/partial_province_reveal_scenarios.dart` + expectations + thin runner | #3949 |
| ppr-excludes-unprefixed | excludes unprefixed province keys and uniform visibility | same | same | #3949 |
| ppr-resolve-provinces | partial reveal ids resolve via provincesById to same set as allProvinces filter | same | same | #3949 |
| ppr-empty-scan | returns empty list without scanning when id set is empty | same | same | #3949 |
| ppr-sorted-match | returns matching provinces sorted by id | same | same | #3949 |

Migrated imperative `civilian_projected_tile_test.dart`, `propagate_road_to_adjacent_capital_test.dart`, and `partial_province_reveal_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent multiline partial-reveal baseline descriptions as single-line scenario labels. Removed all three files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 55: **33,844** (net +179 from post–slice 54; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 56: upgrade_town Minor/Tribe + build_rail work-rules scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| utmt-prefilter-minor | prefilter includes minor town tile when embassy and peace | `upgrade_town_minor_tribe_test.dart` | `support/validators/upgrade_town_minor_tribe_scenarios.dart` + fixtures/expectations + thin runner | #3872 |
| utmt-war-reject | precheck rejects upgrade_town when at war with tribe | same | same | #3872 |
| brwr-road-too-high | rejects when road level is neither 1 nor 2 (too high) | `build_rail_work_rules_test.dart` | `support/application/build_rail_work_rules_scenarios.dart` + expectations + thin runner | #3949 |
| brwr-road-intermediate | rejects when road level is 3 (intermediate, not 1 or 2) | same | same | #3949 |
| brwr-road-zero | rejects when road level is 0 | same | same | #3949 |
| brwr-terrain-null | rejects when terrain is null | same | same | #3949 |
| brwr-plains-no-tech | plains: rejects without rail tech | same | same | #3949 |
| brwr-plains-early | plains: allows with Early Steam | same | same | #3949 |
| brwr-hills-no-tech | hills: rejects without Later Steam or Dynamite | same | same | #3949 |
| brwr-hills-later | hills: allows with Later Steam | same | same | #3949 |
| brwr-mountain-no-dyn | mountain: rejects without Dynamite | same | same | #3949 |
| brwr-hills-dyn | hills: allows with Dynamite only | same | same | #3949 |
| brwr-plains-later | plains: allows with Later Steam only | same | same | #3949 |
| brwr-mountain-dyn | mountain: allows with Dynamite | same | same | #3949 |
| brwr-malformed-key | returns null for malformed tile key | same | same | #3949 |
| brwr-missing-region | returns null when region map is missing | same | same | #3949 |
| brwr-non-int-coords | returns null when x or y are not integers | same | same | #3949 |
| brwr-oob-coords | returns null when coordinates are out of bounds | same | same | #3949 |
| brwr-terrain-map | returns terrain from tile map | same | same | #3949 |

Migrated imperative `upgrade_town_minor_tribe_test.dart` and `build_rail_work_rules_test.dart` → table-driven scenarios with dedicated support modules. Removed `build_rail_work_rules_test.dart` from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 56: **34,073** (net +229 from post–slice 55; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 57: orders_logging + merchant purchase-land + append military regiment scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ol-ctlogger | ordersLog is a CtLogger with the distinct `orders` prefix | `orders_logging_test.dart` | `support/application/orders_logging_scenarios.dart` + expectations + thin runner | #3290 C2 |
| ol-shared | ordersLog is the single shared instance for the orders domain | same | same | #3290 C2 |
| ol-app-alias | ordersApplicationLog is an alias of the shared ordersLog | same | same | #3290 C2 |
| ol-suggestion-prefix | orderSuggestionLog is rooted under the `orders` domain prefix | same | same | #3290 C2 |
| ol-emits-prefix | ordersLog emits messages with the `orders:` prefix | same | same | #3290 C2 |
| ol-no-logic-log | no lib/src/orders source consumes the core logicLog | same | same | #3290 C2 |
| mpl-nw-first | lists NW tribe tiles before Old World minor tiles | `merchant_purchase_land_candidate_tile_keys_test.dart` | `support/suggestion/merchant_purchase_land_candidate_tile_keys_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| mpl-scan-membership | matches province scan membership (deterministic NW-first sort) | same | same | #3949 |
| mpl-projection-union | matches projection union over non-player owners (slice 14) | same | same | #3949 |
| mpl-dev-exclusive | excludes dev-exclusive reserved tiles like legacy path | same | same | #3949 |
| amr-create-equiv | create-new-army path matches with and without armiesById | `append_military_regiment_armies_by_id_test.dart` | `support/application/append_military_regiment_armies_by_id_scenarios.dart` + fixtures/expectations + thin runner | #2394 |
| amr-append-equiv | append-existing-army path matches with and without armiesById | same | same | #2394 |
| amr-mutate-append | mutates armiesById in place when appending to an existing army | same | same | #2394 |
| amr-mutate-create | mutates armiesById in place when creating a new army | same | same | #2394 |
| amr-multi-recruit | multiple recruits with shared map match repeated scan-path runs | same | same | #2394 |
| amr-partial-fallback | falls back to single-pass scan when armiesById lacks the entry | same | same | #2394 |

Migrated imperative `orders_logging_test.dart`, `merchant_purchase_land_candidate_tile_keys_test.dart`, and `append_military_regiment_armies_by_id_test.dart` → table-driven scenarios with dedicated support modules. Removed all three from `ordersPreferScenarioTablesAllowlist`; also removed stale `upgrade_town_minor_tribe_test.dart` allowlist entry (migrated slice 56).

test/ LOC after slice 57: **34,307** (net +234 from post–slice 56; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 slice 58 — draft_orders_mutations + order_visibility scenario migration (#3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| dom-remove-index | removes order at index | `draft_orders_mutations_test.dart` | `support/application/draft_orders_mutations_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| dom-invalid-index | returns orders unchanged when index invalid | same | same | #3949 |
| dom-trade-empty | tradeOrderForPlayerCommodity returns null on empty orders | same | same | #2993 E5b |
| dom-trade-match | tradeOrderForPlayerCommodity returns the matching staged order | same | same | #2993 E5b |
| dom-trade-add | applyTradeOrderForPlayer adds when no prior order exists | same | same | #2993 E5b |
| dom-trade-replace | applyTradeOrderForPlayer replaces a prior order for the same commodity (mutual exclusion: bid -> offer cannot coexist) | same | same | #2993 E5b |
| dom-trade-scope | applyTradeOrderForPlayer scopes per-player (other players' orders are not affected) | same | same | #2993 E5b |
| dom-trade-remove | removeTradeOrderForPlayer deletes the matching staged order | same | same | #2993 E5b |
| dom-trade-noop-empty | removeTradeOrderForPlayer is a no-op (returns same instance) when the player has no staged orders | same | same | #2993 E5b |
| dom-trade-noop-missing | removeTradeOrderForPlayer is a no-op (returns same instance) when the commodity is not present in the staged list | same | same | #2993 E5b |
| ov-prov-no-tile | false when no tile has 4-part key for region/province | `order_visibility_test.dart` | `support/application/order_visibility_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| ov-prov-min | true when a tile in province has at least min visibility | same | same | #3949 |
| ov-prov-bad-parts | ignores tile keys with wrong number of parts | same | same | #3949 |
| ov-prov-wrong-count | provinceHasAtLeastVisibility returns false when parts.length != 4 | same | same | #3949 |
| ov-tile-min | true when tile has at least min level | same | same | #3949 |
| ov-tile-unknown | false when tile unknown | same | same | #3949 |
| ov-move-src | true when province has at least fogged | same | same | #3949 |
| ov-move-dest | true when province has at least fogged | same | same | #3949 |
| ov-work-explore | explore requires partial reveal (known + unknown land tiles) | same | same | #3949 |
| ov-work-explore-reject | explore rejects province with no unknown land tile | same | same | #3949 |
| ov-work-explore-no-ws | explore rejects when worldState omitted | same | same | #3949 |
| ov-work-prospect | prospect requires at least fogged | same | same | #3949 |
| ov-work-build | build_improvement allows owned province | same | same | #3949 |
| ov-work-unknown | unknown workTarget returns false | same | same | #3949 |
| ov-work-counter-spy | counter_spy allows owned province without fogged | same | same | #3949 |
| ov-work-fort | build_fort with fogged visibility on owned province | same | same | #3949 |
| ov-work-road | build_road with targetTileKey uses tile key for region and province | same | same | #3949 |

Migrated imperative `draft_orders_mutations_test.dart` and `order_visibility_test.dart` → table-driven scenarios with dedicated support modules. Removed both from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 58: **34,538** (net +231 from post–slice 57; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 slice 59 — recruit_worker + build_order validator scenario migration (#3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| rwov-accept-peasant | accepts peasant recruit and deducts 2 fabric, adds peasant | `recruit_worker_order_validator_test.dart` | `support/validators/recruit_worker_order_validator_scenarios.dart` + fixtures/expectations + thin runner | #2692 S4 |
| rwov-reject-fabric | rejects peasant recruit when fabric is insufficient | same | same | #2692 S4 |
| rwov-accept-apprentice | accepts apprentice train when tech unlocked, deducts 200 ducats, 2 paper, 1 peasant; increments apprentices | same | same | #2692 S4 |
| rwov-reject-tech | rejects apprentice train when required tech is locked | same | same | #2692 S4 |
| rwov-reject-peasant | rejects apprentice train when no peasant is available | same | same | #2692 S4 |
| rwov-reject-treasury | rejects apprentice train when treasury is insufficient | same | same | #2692 S4 |
| rwov-accept-journeyman | accepts journeyman train and applies 500 ducat + 5 paper cost | same | same | #2692 S4 |
| rwov-accept-master | accepts master train and applies 1000 ducat + 10 paper cost | same | same | #2692 S4 |
| rwov-prev-rejected | short-circuits to "Previous invalid" when previousRejected is true | same | same | #2692 S4 |
| rwov-sequential | sequential apprentice trains drain peasants in submission order | same | same | #2692 S4 |
| bov-prev-rejected | validate returns rejected when previousRejected is true | `build_order_validator_test.dart` | `support/validators/build_order_validator_scenarios.dart` + expectations + thin runner | #3949 |
| bov-no-capital | civilian build is rejected when capital tile cannot be resolved | same | same | #3949 |

Migrated imperative `recruit_worker_order_validator_test.dart` and `build_order_validator_test.dart` → table-driven scenarios with dedicated support modules. Removed both from `ordersPreferScenarioTablesAllowlist`. Joined formerly multi-line apprentice description added to `DESCRIPTION_BASELINE.txt`.

test/ LOC after slice 59: **34,676** (net +138 from post–slice 58; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, validators, work handlers, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 slice 60 — work_order_target_prechecks + cost_calculator + treasury_no_bypass scenario migration (#3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| wotp-registers | registers expected work targets | `work_order_target_prechecks_test.dart` | `support/validators/work_order_target_prechecks_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| wotp-unregistered | runWorkOrderTargetPrecheck returns null for unregistered target | same | same | #3949 |
| wotp-upgrade-no-tech | precheckUpgradeTown rejects without National Bureaucracy | same | same | #3949 |
| wotp-upgrade-max | precheckUpgradeTown rejects when town development is already 4 | same | same | #3949 |
| wotp-skip-foreign | kWorkTargetsSkippingDefaultForeignProvinceCheck lists dedicated targets | same | same | #3949 |
| wotp-purchase-2394 | precheckPurchaseLand matches with or without DiplomacyFactionMembership (Refs #2394) | same | same | #2394 |
| wotp-improvement | precheckBuildImprovement rejects unprospected mineral tile | same | same | #3949 |
| wotp-foreign | precheckDefaultForeignProvince rejects builder in foreign province | same | same | #3949 |
| wotp-dev-exclusive | precheckDevExclusiveTileConflict rejects duplicate dev work tile | same | same | #3949 |
| wocc-null-cost | calculateCost returns null for counter_spy, purchase_land | `work_order_cost_calculator_test.dart` | `support/validators/work_order_cost_calculator_scenarios.dart` + expectations + thin runner | #3949 |
| wocc-improvement | calculateCost returns cost map for build_improvement | same | same | #3949 |
| wocc-fort | calculateCost for build_fort uses province fortLevel when not overridden | same | same | #3949 |
| botnb-pin | peasant_levies is the cheapest, tech-free regiment (fixture pin) | `build_order_treasury_no_bypass_test.dart` | `support/validators/build_order_treasury_no_bypass_scenarios.dart` + fixtures/expectations + thin runner | #2924 |
| botnb-ai-below | AI player below cheapest regiment treasury is rejected (no bypass) | same | same | #2924 |
| botnb-ai-at | AI player at exactly the cheapest treasury is accepted (treasury gate is the sole blocker) | same | same | #2924 |
| botnb-human-zero | human player at zero treasury is rejected (no human waiver) | same | same | #2924 |
| botnb-agnostic | affordability gate is player-agnostic at zero treasury (human and AI both rejected) | same | same | #2924 |

Migrated imperative `work_order_target_prechecks_test.dart`, `work_order_cost_calculator_test.dart`, and `build_order_treasury_no_bypass_test.dart` → table-driven scenarios with dedicated support modules. Removed all three from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 60: **34,850** (net +174 from post–slice 59; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, validators, work handlers, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 slice 61 — work handler scenario migration (#3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ewh-supports | supports only explore target | `explore_work_handler_test.dart` | `support/work_handlers/explore_work_handler_scenarios.dart` + expectations + thin runner | #3949 |
| ewh-assigns | assigns explore currentWork when province has discoverable tiles | same | same | #3949 |
| ewh-no-tiles | returns false when province has no tile keys in world state | same | same | #3949 |
| plwh-supports | supports only purchase_land target | `purchase_land_work_handler_test.dart` | `support/work_handlers/purchase_land_work_handler_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| plwh-try-apply | tryApply assigns currentWork without treasury deduction | same | same | #3949 |
| plwh-no-resource | returns unchanged treasury when tile has no resource entry | same | same | #3949 |
| rwh-counter-supports | supports only counter_spy | `remaining_work_handlers_test.dart` | `support/work_handlers/remaining_work_handlers_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| rwh-counter-apply | tryApply assigns counter_spy work for spy unit | same | same | #3949 |
| rwh-prospect-supports | supports only prospect | same | same | #3949 |
| rwh-prospect-reject | tryApply returns false for non-mineral tile | same | same | #3949 |
| rwh-already-working | returns false when unit already has currentWork | same | same | #3949 |
| rwh-fort-tech | skips fort level 2 when Mine Engineering not unlocked | same | same | #3949 |
| rwh-standard-supports | each standard build handler supports only its target | same | same | #3949 |
| rwh-registry | maps every standard and simple work target to a handler | same | same | #3949 |
| rwh-singleton | singleton handlers do not cross-support other simple targets | same | same | #3949 |

Migrated imperative `explore_work_handler_test.dart`, `purchase_land_work_handler_test.dart`, and `remaining_work_handlers_test.dart` → table-driven scenarios with dedicated support modules. Removed all three from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 61: **35,153** (net +303 from post–slice 60; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, validators, per_player_work_target_selection_cache, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 slice 62 — per_player_work_target_selection_cache scenario migration (#3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ppwtsc-default-refresh | default strategies refresh runs all population paths | `per_player_work_target_selection_cache_test.dart` | `support/per_player_work_target_selection_cache_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| ppwtsc-sorted | sorted returns deterministic ordering | same | same | #3949 |
| ppwtsc-contains | contains returns false for missing membership | same | same | #3949 |
| ppwtsc-turn-boundary | refresh replaces target membership on turn-boundary style update | same | same | #3949 |
| ppwtsc-isolated | refresh keeps cache isolated per player | same | same | #3949 |
| ppwtsc-prospect | refresh stores and reads prospect membership | same | same | #3949 |
| ppwtsc-shared-validator | refresh injects one shared incremental validator for all strategies | same | same | #3949 |
| ppwtsc-owned-ids | refresh reuses caller-supplied playerOwnedProvinceIds when set (Refs #2394) | same | same | #2394 |
| ppwtsc-validator-view | refresh built validator reuses snapshot playerView (Refs #2394) | same | same | #2394 |
| ppwtsc-external-validator | refresh reuses caller-supplied sharedCandidateValidator when set (Refs #2394) | same | same | #2394 |

Migrated imperative `per_player_work_target_selection_cache_test.dart` → table-driven scenarios with dedicated support modules. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 62: **35,250** (net +97 from post–slice 61; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 63 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osch-append-existing | appends order for existing player list | `order_suggestion_context_helpers_test.dart` | `support/suggestion/order_suggestion_context_helpers_scenarios.dart` + `order_suggestion_context_helpers_test.dart` | #3949 |
| osch-append-absent | creates new player list when absent | same | same | #3949 |
| osch-next-progression | follows expected progression | same | same | #3949 |
| osch-next-final | returns null when already at final stage | same | same | #3949 |
| osch-prev-inverse | next is left inverse of previous for every non-terminal stage | same | same | #3949 |
| osch-prev-then-next | previous then next restores stage for every stage past none | same | same | #3949 |
| osch-prev-reverse | reverses next for progression chain | same | same | #3949 |
| osch-prev-none | none maps to itself | same | same | #3949 |
| osch-prev-join | joinEmpire previous is nap | same | same | #3949 |
| osch-naval-move | isNavalMoveOrderAccepted returns a boolean result | same | same | #3949 |
| osch-naval-mission | isNavalMissionOrderAccepted returns a boolean result | same | same | #3949 |
| osch-diplomatic | isDiplomaticOrderAccepted returns a boolean result | same | same | #3949 |
| osch-diplomatic-default | isDiplomaticOrderAccepted matches default path when view/units shared | same | same | #3949 |
| osch-shared-validator | stateless accept helpers reuse sharedCandidateValidator without rebuild | same | same | #2394 |
| osch-with-validator | isDiplomaticOrderAcceptedWithValidator matches isDiplomaticOrderAccepted | same | same | #3949 |

Migrated imperative `order_suggestion_context_helpers_test.dart` → table-driven scenarios with dedicated support modules. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 63: **35,375** (net +125 from post–slice 62; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 64 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osh-drops-absent | drops move into minor-owned province when relation row is absent | `order_suggestion_helpers_test.dart` | `support/suggestion/order_suggestion_helpers_scenarios.dart` + `order_suggestion_helpers_test.dart` | #2394 |
| osh-keeps-war | keeps move into minor province when at war (relation row present) | same | same | #2394 |
| osh-drops-peace | drops move into minor province when explicitly at peace | same | same | #2394 |
| osh-keeps-own | keeps reordering-only move within own provinces | same | same | #2394 |
| osh-keeps-draft-war | keeps move into minor at peace when draft orders declare war | same | same | #2394 |

Migrated imperative `order_suggestion_helpers_test.dart` → table-driven scenarios with dedicated support modules. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 64: **35,482** (net +107 from post–slice 63; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 65 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ospc-index-skip-empty | indexExistingTargetsByEntityId skips empty targets when requested | `order_suggestion_pass_context_test.dart` | `support/suggestion/order_suggestion_pass_context_scenarios.dart` + `order_suggestion_pass_context_test.dart` | #3500 |
| ospc-emit-order | emitAcceptedCandidates collects accepted in iteration order | same | same | #3500 |
| ospc-emit-skip-targeted | emitAcceptedCandidates skips candidates already targeted | same | same | #3500 |
| ospc-emit-no-dedup | emitAcceptedCandidates probes every candidate without dedup args | same | same | #3500 |
| ospc-capped-probe | runCappedSuggestionProbeLoop respects acceptance and probe caps | same | same | #3500 |
| ospc-owned-provinces | ownedProvinceIdsFromView returns full province ids for owner | same | same | #3500 |

Migrated imperative `order_suggestion_pass_context_test.dart` → table-driven scenarios with dedicated support modules. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 65: **35,619** (net +137 from post–slice 64; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 66 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osua-pending-short-circuit | pending draft work short-circuits with zero engine probes | `order_suggestion_unit_availability_test.dart` | `support/suggestion/order_suggestion_unit_availability_scenarios.dart` + `order_suggestion_unit_availability_test.dart` | #2133 |
| osua-pending-scale | pending draft: zero probes even with high-reveal world (issue #2133 scale) | same | same | #2133 |
| osua-multi-target | multi-target availability matches shared-validator tile keys per target | same | same | #2133 |

Migrated imperative `order_suggestion_unit_availability_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent multiline baseline descriptions for scale and multi-target scenarios. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 66: **35,746** (net +127 from post–slice 65; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 67 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osbcs-includes-affordable | AC1: includes affordable civilian candidates when includeCivilianBuilds is true | `order_suggestion_build_civilian_suggestion_test.dart` | `support/suggestion/order_suggestion_build_civilian_suggestion_scenarios.dart` + `order_suggestion_build_civilian_suggestion_test.dart` | #3793 |
| osbcs-sorted | AC1: emitted civilian candidates are deterministically sorted by unitType | same | same | #3793 |
| osbcs-default-false | AC1b: default (flag omitted) emits no civilian candidates and equals the explicit false call | same | same | #3793 |
| osbcs-merchant-excluded | AC5: Merchant excluded when merchant_companies is not unlocked | same | same | #3793 |
| osbcs-merchant-included | AC5: Merchant included when merchant_companies is unlocked and affordable | same | same | #3793 |
| osbcs-identical | AC9: identical inputs produce identical civilian enumeration | same | same | #3793 |
| osbcs-zero-treasury | AC12: no civilian candidates when treasury is zero | same | same | #3793 |
| osbcs-low-paper | AC12: no civilian candidates when paper is below the minimum cost | same | same | #3793 |

Migrated imperative `order_suggestion_build_civilian_suggestion_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent multiline baseline descriptions for AC1/AC1b/AC5 merchant-included scenarios. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 67: **35,813** (net +67 from post–slice 66; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 68 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osbpr-accepts-peasant | accepts peasant_levies when treasury is zero but stockpile has spices | `order_suggestion_build_pending_riches_test.dart` | `support/suggestion/order_suggestion_build_pending_riches_scenarios.dart` + `order_suggestion_build_pending_riches_test.dart` | #2509 |
| osbpr-incremental-probe | incremental build probe matches full-pass when riches fund build | same | same | #2509 |

Migrated imperative `order_suggestion_build_pending_riches_test.dart` → table-driven scenarios with dedicated support modules. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 68: **35,854** (net +41 from post–slice 67; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 69 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ospopbp-co-located-feedstock | co-located feedstock Explorer still receives its iron prospect after earlier units drain the shared probe budget | `order_suggestion_prospect_own_province_budget_priority_test.dart` | `support/suggestion/order_suggestion_prospect_own_province_budget_priority_scenarios.dart` + `order_suggestion_prospect_own_province_budget_priority_test.dart` | #2847 |
| ospopbp-no-feedstock-prospected | no feedstock prospect when the co-located tile is already prospected (negative control) | same | same | #2847 |
| ospopbp-deterministic | own-province budget exemption is deterministic across runs | same | same | #2847 |

Migrated imperative `order_suggestion_prospect_own_province_budget_priority_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent multiline baseline descriptions for co-located feedstock and negative-control scenarios. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 69: **35,955** (net +101 from post–slice 68; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 70 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osplpp-co-located | co-located Explorer in late-sorted province still receives a prospect suggestion for its iron tile | `order_suggestion_prospect_location_province_priority_test.dart` | `support/suggestion/order_suggestion_prospect_location_province_priority_scenarios.dart` + thin runner | #2847 |
| osplpp-no-fogged | iron province without fogged visibility still yields no prospect (negative control) | same | same | #2847 |
| bv-accepts-peace | accepts when issuer holds a colony and target GP is at peace | `validators/diplomatic/boycott_validator_test.dart` | `support/validators/diplomatic/boycott_validator_scenarios.dart` + thin runner | #3753 R6 |
| bv-rejects-no-colony | rejects when the issuer holds no colony | same | same | #3753 R6 |
| bv-rejects-war | rejects when at war with the target GP | same | same | #3753 R6 |
| bv-rejects-duplicate | rejects a duplicate boycott for the same pair | same | same | #3753 R6 |
| bv-rejects-non-gp | rejects a non-Great-Power target | same | same | #3753 R6 |
| bv-revoke-accepts | accepts when an active boycott exists for the pair | same | same | #3753 R6 |
| bv-revoke-rejects | rejects when no active boycott exists for the pair | same | same | #3753 R6 |
| bv-parent-accepts | accepts a valid boycott order through the parent validator | same | same | #3753 R6 |

Migrated imperative `order_suggestion_prospect_location_province_priority_test.dart` and `validators/diplomatic/boycott_validator_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent multiline baseline descriptions for prospect location scenarios. Removed `boycott_validator_test.dart` from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 70: **36,155** (net +200 from post–slice 69; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite migration (suggestion families, remaining diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 71 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| bav-accepts-formal-alliance | accepts when a formal alliance exists with the GP target | `validators/diplomatic/break_alliance_validator_test.dart` | `support/validators/diplomatic/break_alliance_validator_scenarios.dart` + thin runner | #3753 R11 |
| bav-rejects-at-war | rejects while at war (war invariant cleared the alliance) | same | same | #3753 R11 |
| bav-rejects-no-alliance | rejects when no formal alliance exists with the target | same | same | #3753 R11 |
| bav-rejects-non-gp | rejects a non-Great-Power target | same | same | #3753 R11 |
| bav-parent-accepts | accepts a valid breakAlliance order through the parent validator | same | same | #3753 R11 |

Migrated imperative `validators/diplomatic/break_alliance_validator_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent multiline baseline description for parent-validator dispatch scenario. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 71: **36,240** (net +85 from post–slice 70; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite scenario migration (suggestion families, remaining diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 72 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| eosv-rejects-missing-stage | rejects when stage is missing | `validators/diplomatic/establish_overture_sub_validator_test.dart` | `support/validators/diplomatic/establish_overture_sub_validator_scenarios.dart` + thin runner | #2391 AC10 |
| eosv-consulate-debits | trade consulate debits treasury on accept | same | same | #2391 AC10 |
| eosv-consulate-no-expertise | trade consulate rejects without diplomatic_expertise | same | same | #2391 AC10 |
| eosv-consulate-low-treasury | trade consulate rejects when treasury too low (no debit) | same | same | #2391 AC10 |
| eosv-embassy-requires-consulate | embassy requires existing trade consulate | same | same | #2391 AC10 |
| eosv-embassy-debits | embassy accepts and debits treasury when consulate exists | same | same | #2391 AC10 |
| eosv-nap-no-debit | nap requires existing embassy and does not debit treasury | same | same | #2391 AC10 |
| eosv-join-empire-relations | joinEmpire rejects when relations below friendly threshold | same | same | #2391 AC10 |

Migrated imperative `validators/diplomatic/establish_overture_sub_validator_test.dart` → table-driven scenarios with dedicated support modules. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 72: **36,330** (net +90 from post–slice 71; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite scenario migration (suggestion families, remaining diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 73 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| dsva-grant-non-positive | rejects non-positive amount | `validators/diplomatic/diplomatic_sub_validators_aid_test.dart` | `support/validators/diplomatic/diplomatic_sub_validators_aid_scenarios.dart` + thin runner | #2391 AC10 |
| dsva-grant-below-step | rejects when amount is below the step | same | same | #2391 AC10 |
| dsva-grant-not-multiple | rejects amount that is not a multiple of the step | same | same | #2391 AC10 |
| dsva-grant-no-embassy | rejects without embassy | same | same | #2391 AC10 |
| dsva-grant-low-treasury | rejects when treasury below amount and preserves treasury | same | same | #2391 AC10 |
| dsva-grant-debits | accepts and debits treasury by the amount | same | same | #2391 AC10 |
| dsva-subsidy-zero | rejects a zero percent | same | same | #3753 R3 |
| dsva-subsidy-not-step | rejects a percent not a multiple of the step | same | same | #3753 R3 |
| dsva-subsidy-above-max | rejects a percent above the maximum | same | same | #3753 R3 |
| dsva-subsidy-no-overture | rejects without any overture | same | same | #3753 R3 |
| dsva-subsidy-consulate-only | rejects with a Trade Consulate only (Refs #3753 R2) | same | same | #3753 R2 |
| dsva-subsidy-accepts | accepts with an embassy and leaves treasury unchanged | same | same | #3753 R3 |
| dsva-subsidy-low-treasury | accepts with an embassy even when treasury is low (no upfront cost) | same | same | #3753 R3 |

Migrated imperative `validators/diplomatic/diplomatic_sub_validators_aid_test.dart` → table-driven scenarios with dedicated support modules. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 73: **36,459** (net +129 from post–slice 72; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite scenario migration (suggestion families, remaining diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 74 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| dsrel-declare-war-peace | accepts when at peace and leaves treasury unchanged | `validators/diplomatic/diplomatic_sub_validators_relations_test.dart` | `support/validators/diplomatic/diplomatic_sub_validators_relations_scenarios.dart` + thin runner | #2391 AC10 |
| dsrel-declare-war-reject | rejects when already at war and preserves treasury | same | same | #2391 AC10 |
| dsrel-offer-peace-war | accepts when at war and leaves treasury unchanged | same | same | #2391 AC10 |
| dsrel-offer-peace-reject | rejects when not at war | same | same | #2391 AC10 |
| dsrel-alliance-non-gp | rejects when target is not a Great Power | same | same | #2391 AC10 |
| dsrel-alliance-at-war | rejects when at war with the target Great Power | same | same | #2391 AC10 |
| dsrel-alliance-peace | accepts when target is a Great Power and at peace | same | same | #2391 AC10 |
| dsrel-alliance-duplicate | rejects a duplicate alliance when a formal alliance already exists | same | same | #2391 AC10 |
| dsrel-cooldown-alliance | blocks alliance toward the cooled-down GP | same | same | #3811 AC10 |
| dsrel-cooldown-overture | blocks establishOverture toward the cooled-down GP | same | same | #3811 AC10 |
| dsrel-cooldown-ftp | blocks establishFtp toward the cooled-down GP | same | same | #3811 AC10 |
| dsrel-cooldown-grant-aid | blocks grantAid toward the cooled-down GP | same | same | #3811 AC10 |
| dsrel-cooldown-subsidy | blocks setSubsidy toward the cooled-down GP | same | same | #3811 AC10 |
| dsrel-cooldown-declare-war | declareWar remains allowed during cooldown | same | same | #3811 AC10 |

Migrated imperative `validators/diplomatic/diplomatic_sub_validators_relations_test.dart` → table-driven scenarios with dedicated support modules. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 74: **36,604** (net +145 from post–slice 73; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite scenario migration (suggestion families, remaining diplomatic validators, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 75 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| dsfmem-alliance-equiv | accepts known GP target identically with and without snapshot | `validators/diplomatic/diplomatic_sub_validators_faction_membership_test.dart` | `support/validators/diplomatic/diplomatic_sub_validators_faction_membership_scenarios.dart` + thin runner | #2394 |
| dsfmem-alliance-non-gp | rejects non-GP target identically when snapshot has no GP membership | same | same | #2394 |
| dsfmem-alliance-snapshot | snapshot is consulted on active path: rejects target listed only in Game.players | same | same | #2394 |
| dsfmem-overture-equiv | accepts Trade Consulate toward Minor identically with snapshot | same | same | #2394 |
| dsfmem-overture-snapshot | snapshot is consulted: rejects overture toward target absent from snapshot | same | same | #2394 |
| dsfmem-parent-equiv | accepts equivalent classification with snapshot snapshot present | same | same | #2394 |
| dsfmem-parent-snapshot | snapshot is consulted on active path: rejects unknown target id | same | same | #2394 |

Migrated imperative `validators/diplomatic/diplomatic_sub_validators_faction_membership_test.dart` → table-driven scenarios with dedicated support modules. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 75: **36,673** (net +69 from post–slice 74; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite scenario migration (suggestion families, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 76 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| odf-owner-map | matches the projection-derived owner map across both regions | `order_suggestion_diplomacy_filter_test.dart` | `support/suggestion/order_suggestion_diplomacy_filter_scenarios.dart` + thin runner | #3949 |
| odf-unowned | excludes unowned (null-owner) provinces | same | same | #3949 |
| odf-empty-owner | excludes empty-string owner provinces (isNotEmpty parity) | same | same | #3949 |
| odf-full-id | getProvinceOwnerMap returns owner by full province id | same | same | #3949 |
| odf-nw | getProvinceOwnerMap includes newWorld provinces | same | same | #3949 |
| odf-peace | filterMoveOrdersByDiplomacy does not drop civilian moves at peace | same | same | #3949 |
| odf-war | filterMoveOrdersByDiplomacy keeps move to at-war faction | same | same | #3949 |

Migrated imperative `order_suggestion_diplomacy_filter_test.dart` → table-driven scenarios with dedicated support modules. Removed from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 76: **36,800** (net +127 from post–slice 75; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite scenario migration (suggestion families, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 77 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| odp-independent | isIndependentDiplomaticCandidate flags economic and boycott types | `order_suggestion_diplomatic_pass_test.dart` | `support/suggestion/order_suggestion_diplomatic_pass_scenarios.dart` + thin runner | #3949 |
| odp-overtures | playerOverturesByTargetIdForPlayer keeps first row per target | same | same | #3949 |
| odp-declare-war | acceptDeclareWarCandidatesForTargets skips self and at-war targets | same | same | #3949 |
| odb-emit | emits a boycott toward another GP at peace when the issuer holds a colony | `order_suggestion_diplomatic_boycott_test.dart` | `support/suggestion/order_suggestion_diplomatic_boycott_scenarios.dart` + thin runner | #3949, #3758 R8 |
| odb-coexist | boycott coexists with the single non-economic candidate for the same GP | same | same | #3949, #3758 R8 |
| odb-no-colony | does not emit a boycott when the issuer holds no colony | same | same | #3949, #3758 R8 |
| odb-no-dup | does not emit a duplicate boycott when one already exists | same | same | #3949, #3758 R8 |
| odb-no-minor | does not emit a boycott toward a Minor/Tribe target | same | same | #3949, #3758 R8 |
| odb-no-war | does not emit a boycott when at war with the target GP | same | same | #3949, #3758 R8 |

Migrated imperative `order_suggestion_diplomatic_pass_test.dart` and `order_suggestion_diplomatic_boycott_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent multiline baseline descriptions for boycott emit/coexist scenarios. Removed both files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 77: **36,943** (net +143 from post–slice 76; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite scenario migration (suggestion API impl suites, army-move families, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 78 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oswl-summaries | emits suggest_work summaries for Explorer/Builder/Spy/Merchant | `order_suggestion_work_logging_test.dart` | `support/suggestion/order_suggestion_work_logging_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| oswl-bounded | suggestWorkOrders logger lines never emit unbounded full list payload | same | same | #2133 |
| ocie-sea-reachable | colonialIntelExploreProvinceIdsSorted lists sea-reachable NW | `order_suggestion_colonial_intel_explore_test.dart` | `support/suggestion/order_suggestion_colonial_intel_explore_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| noefp-build | suggestBuildOrders does not invoke validatePlayerOrdersWithContext | `order_suggestion_no_order_engine_full_pass_test.dart` | `support/suggestion/order_suggestion_no_order_engine_full_pass_scenarios.dart` + fixtures/expectations + thin runner | #2237 AC2 |
| noefp-add-context | OrderEngine add-with-context still invokes full validation | same | same | #2237 |
| osrd-slot1 | slot 1 takes the highest-weight unrepresented bucket (AC9) | `order_suggestion_research_diversify_test.dart` | `support/suggestion/order_suggestion_research_diversify_scenarios.dart` + fixtures/expectations + thin runner | #3472 AC9 |
| osrd-weight-zero | weight 0 is identical to the greedy default (negative control) | same | same | #3472 |

Migrated imperative `order_suggestion_work_logging_test.dart`, `order_suggestion_colonial_intel_explore_test.dart`, `order_suggestion_no_order_engine_full_pass_test.dart`, and `order_suggestion_research_diversify_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent baseline description for bounded logger payload scenario. Removed all four files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 78: **37,242** (net −701 from post–slice 77; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite scenario migration (suggestion API impl suites, army-move families, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 79 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osrms-fills-slots | fills every empty slot with a distinct researchable tech | `order_suggestion_research_multi_slot_test.dart` | `support/suggestion/order_suggestion_research_multi_slot_scenarios.dart` + fixtures/expectations + thin runner | #3472 |
| osrms-in-progress | re-emits in-progress research so the resolver preserves progress | same | same | #3472 |
| osrms-zero-slots | returns no suggestions when there are zero research slots | same | same | #3472 |
| osrms-pending-order | does not re-suggest a tech already assigned by a pending order | same | same | #3472 |
| oswtpl-minor-gp | includes resource tiles in minor-owned provinces, excludes GP-owned | `order_suggestion_work_tile_prefilter_purchase_land_test.dart` | `support/suggestion/order_suggestion_work_tile_prefilter_purchase_land_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| oswtpl-tribe | includes resource tiles in tribe-owned provinces | same | same | #3949 |
| oswtpl-owned-province | playerOwnedProvinceIds yields same candidates as internal scan (build_road) | same | same | #3949 |

Migrated imperative `order_suggestion_research_multi_slot_test.dart` and `order_suggestion_work_tile_prefilter_purchase_land_test.dart` → table-driven scenarios with dedicated support modules. Removed both files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 79: **37,415** (net +173 from post–slice 78; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite scenario migration (suggestion API impl suites, army-move families, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — slice 80 (trade API impl + army-move heuristics scenarios)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osait-no-embassy | no embassy ⇒ bidTypeCap = 0; suggester emits offers only from current stockpile (riches excluded) and no bids | `order_suggestion_api_impl_trade_test.dart` | `support/suggestion/order_suggestion_api_impl_trade_scenarios.dart` + fixtures/expectations + thin runner | #2989 A6 |
| osait-override | contextOverride passes through to the pure suggester | same | same | #2989 A6 |
| osait-validator-clean | default impl returns validator-clean output for the wired context | same | same | #2989 A6 |
| osamh-one-per-army | keeps at most one army move per army id | `order_suggestion_army_move_heuristics_test.dart` | `support/suggestion/order_suggestion_army_move_heuristics_scenarios.dart` + fixtures/expectations + thin runner | #3949 |

Migrated imperative `order_suggestion_api_impl_trade_test.dart` and `order_suggestion_army_move_heuristics_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent baseline descriptions for no-embassy trade wiring and validator-clean output scenarios. Removed both files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 80: **37,530** (net +115 from post–slice 79; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite scenario migration (suggestion API impl diplomatic/core suites, army-move picker/test families, shared-validator equivalence, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — slice 81 (diplomatic API impl minor + GP scenarios)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| osaidm-unknown | does not suggest diplomatic orders for completely unknown factions | `order_suggestion_api_impl_diplomatic_minor_test.dart` | `support/suggestion/order_suggestion_api_impl_diplomatic_minor_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| osaidm-establish | returns establishOverture for minor when treasury suffices | same | same | #3949 |
| osaidm-no-expertise | does not suggest tradeConsulate/embassy/nap overture toward minor without diplomatic expertise | same | same | #3949 |
| osaidm-join-empire | toward minor at peace with join-empire overture suggests declareWar (primary before economic) | same | same | #3949 |
| osaid-alliance-single | returns alliance (single diplo per target) for other GP when at peace and not allied | `order_suggestion_api_impl_diplomatic_test.dart` | `support/suggestion/order_suggestion_api_impl_diplomatic_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| osaid-declare-war | returns declareWar toward GP when at peace and already allied | same | same | #3949 |
| osaid-break-alliance | returns breakAlliance toward GP when a formal alliance exists at peace | same | same | #3949 |
| osaid-no-alliance | does not return alliance toward a GP when a formal alliance exists | same | same | #3949 |
| osaid-no-break | does not return breakAlliance when relation level is allied but no formal alliance | same | same | #3949 |
| osaid-offer-peace | returns offerPeace when at war with another GP | same | same | #3949 |
| osaid-alliance-candidate | returns alliance candidate when at peace and not allied | same | same | #3949 |

Migrated imperative `order_suggestion_api_impl_diplomatic_minor_test.dart` and `order_suggestion_api_impl_diplomatic_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent baseline descriptions for unknown-faction, diplomatic-expertise, join-empire, single-diplo, break-alliance, and formal-alliance guard scenarios. Removed both files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 81: **37,615** (net +85 from post–slice 80; scenario support modules add LOC while runners shrink to thin loops). Remaining: further imperative-suite scenario migration (suggestion API impl core suite, army-move picker/test families, shared-validator equivalence, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 82 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| dpa-gp-row | GP row includes alliance, FTP, and four overture stages | `diplomatic_panel_actions_test.dart` | `support/diplomatic/diplomatic_panel_actions_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| dpa-formal-alliance | AC11/AC1: formal alliance (e.g. debug /set_diplomacy alliance) swaps alliance for breakAlliance only | same | same | #3949 |
| dpa-minor-row | Minor row omits alliance and FTP | same | same | #3949 |
| dpa-gp-boycott | GP row includes boycott + revoke boycott (Refs #3753 S14) | same | same | #3949 |
| dpa-minor-boycott | Minor/Tribe row omits boycott + revoke boycott (Refs #3753 S14) | same | same | #3949 |
| dpa-ac6 | AC-6: minor at none shows all overture stages; only consulate enabled | same | same | #3949 |
| dpa-s14-no-colony | S14: boycott disabled when human holds no colony | same | same | #3949 |
| dpa-s14-colony | S14: boycott enabled when human holds a colony at peace | same | same | #3949 |
| dpa-s14-revoke-on | S14: revoke enabled (and boycott disabled) with active boycott | same | same | #3949 |
| dpa-s14-revoke-off | S14: revoke disabled when no active boycott exists | same | same | #3949 |
| dpa-cooldown | post-break cooldown disables alliance with deterministic reason (#3811) | same | same | #3949 |
| dpa-ac10 | AC-10: invalid declare war / offer peace still enumerated | same | same | #3949 |
| dcs-commodity | sorted commodity ids match lexicographic sort of id set | `debug_console_supported_ids_test.dart` | `support/debug_console/debug_console_supported_ids_scenarios.dart` + expectations + thin runner | #3949 |
| dcs-regiment | sorted regiment type ids match lexicographic sort of id set | same | same | #3949 |
| dcs-ship | sorted ship type ids match lexicographic sort of id set | same | same | #3949 |
| dcs-nonempty | sorted lists are non-empty when catalogs have entries | same | same | #3949 |
| dcw-tiers | debug worker tier ids are canonical and lexicographically sorted | `debug_console_workers_test.dart` | `support/debug_console/debug_console_workers_scenarios.dart` + expectations + thin runner | #3949 |

Migrated imperative `diplomatic_panel_actions_test.dart`, `debug_console_supported_ids_test.dart`, and `debug_console_workers_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent baseline description for AC11/AC1 formal-alliance swap scenario. Removed all three files from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 82: **37,903** (net +288 from post–slice 81; support modules add LOC while runners shrink). Remaining: further imperative-suite scenario migration (suggestion API impl core suite, army-move picker/test families, shared-validator equivalence, etc.), lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 83 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| amp-cached-owned | cached player-owned set matches default destination picker path | `order_suggestion_army_move_picker_test.dart` | `support/suggestion/order_suggestion_army_move_picker_scenarios.dart` + expectations + fixtures + thin runner | #3949 |
| amp-shared-view | shared playerView and unitsById matches default armyMovePickerDestinations | same | same | #3949 |
| amp-shared-membership | shared factionMembership matches default armyMovePickerDestinations | same | same | #3949 |
| amp-shared-validator | sharedCandidateValidator matches default and skips forPlayer rebuild | same | same | #3949 |

Migrated imperative `order_suggestion_army_move_picker_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent baseline descriptions for shared playerView, shared factionMembership, and sharedCandidateValidator skip-rebuild scenarios. Removed file from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 83: **37,946** (net +43 from post–slice 82; support modules add LOC while runner shrinks). Remaining: `order_suggestion_api_impl_test.dart`, `order_suggestion_army_move_test.dart`, shared-validator equivalence families, lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 84 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| am-cross-region | includes cross-region player-owned province as destination | `order_suggestion_army_move_test.dart` | `support/suggestion/order_suggestion_army_move_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| am-pv-cache | armyMoveCandidateDestinationProvinceIds with PlayerView-owned cache matches legacy allProvinces scan | same | same | #3949 |
| am-fallback-cache | fallback owned-province scan derives its set from ProvinceOwnerCache (Phase 6b) | same | same | #3949 |
| am-fallback-empty | fallback yields no owned destinations when ProvinceOwnerCache has none for the player (Phase 6b negative) | same | same | #3949 |
| am-alternate-draft | still proposes alternate destination when draft has prior army move | same | same | #3949 |
| am-cached-scan | cached player-owned set matches default allProvinces scan | same | same | #3949 |

Migrated imperative `order_suggestion_army_move_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent baseline descriptions for PlayerView-owned cache parity, ProvinceOwnerCache fallback paths, alternate-draft suggestion, and dest-ids cached scan scenarios. Removed file from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 84: **38,054** (net +108 from post–slice 83; support modules add LOC while runner shrinks). Remaining: `order_suggestion_api_impl_test.dart`, shared-validator equivalence families, lib DRY items 5–6, scenario-table migration toward ≤26,400.

## Wave 3 — Slice 85 (Refs #3949)

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| api-move-list | suggestMoveOrders returns list | `order_suggestion_api_impl_test.dart` | `support/suggestion/order_suggestion_api_impl_scenarios.dart` + fixtures/expectations + thin runner | #3949 |
| api-work-list | suggestWorkOrders returns list | same | same | #3949 |
| api-build-list | suggestBuildOrders returns list | same | same | #3949 |
| api-build-ship | suggestBuildOrders includes ship types when player can afford a ship | same | same | #3949 |
| api-research-list | suggestResearchOrders returns list | same | same | #3949 |
| api-naval-move-list | suggestNavalMoveOrders returns list | same | same | #3949 |
| api-naval-mission-list | suggestNavalMissionOrders returns list | same | same | #3949 |
| api-naval-units-by-id | suggestNavalMoveOrders and suggestNavalMissionOrders match when caller supplies unitsById (Refs #2394) | same | same | #2394 |
| api-diplo-list | suggestDiplomaticOrders returns list | same | same | #3949 |
| api-recruit-list | suggestRecruitWorkerOrders returns list (#2692 S7) | same | same | #2692 S7 |
| api-recruit-peasant | suggestRecruitWorkerOrders includes peasant when fabric is affordable (#2692 S7) | same | same | #2692 S7 |

Migrated imperative `order_suggestion_api_impl_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent baseline descriptions for affordable-ship build, naval unitsById parity, and fabric-affordable peasant recruit scenarios. Removed file from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 85: **38,175** (net +121 from post–slice 84; support modules add LOC while runner shrinks). Remaining: shared-validator equivalence families, lib DRY items 5–6, scenario-table migration toward ≤26,400.

### Slice 86 — shared-validator equivalence scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| shared-equiv-move | suggestMoveOrders matches default path | `order_suggestion_shared_validator_equivalence_test.dart` | same + `support/suggestion/order_suggestion_shared_validator_equivalence_{scenarios,expectations}.dart` | #3949 |
| shared-equiv-army-move | suggestArmyMoveOrders matches default path | same | same | #3949 |
| shared-equiv-work | suggestWorkOrders matches default path | same | same | #3949 |
| shared-equiv-build | suggestBuildOrders matches default path | same | same | #3949 |
| shared-equiv-diplo-deterministic | suggestDiplomaticOrders is deterministic across repeated calls | same | same | #3949 |
| shared-equiv-external-view | shared validator built with externally provided view/unitsById produces identical suggestions to forPlayer default path (no internal rebuild) | same | same | #2394 |
| shared-equiv-for-base-prefix | forBasePrefix matches fresh forPlayer for same basePrefix | same | same | #3949 |

Migrated imperative `order_suggestion_shared_validator_equivalence_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent baseline description for external view/unitsById equivalence scenario. Removed file from `ordersPreferScenarioTablesAllowlist`.

test/ LOC after slice 86: **38,219** (net +44 from post–slice 85; support modules add LOC while runner shrinks). Remaining: `order_suggestion_work_tile_keys_shared_validator_test.dart`, lib DRY items 5–6, scenario-table migration toward ≤26,400.

### Slice 87 — work-tile-keys shared-validator scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| wtk-shared-validator | sharedCandidateValidator matches default path for same inputs | `order_suggestion_work_tile_keys_shared_validator_test.dart` | same + `support/suggestion/order_suggestion_work_tile_keys_shared_validator_{fixtures,scenarios,expectations}.dart` | #3949 |
| wtk-owned-ids | playerOwnedProvinceIds matches default path for same inputs | same | same | #3949 |
| wtk-units-by-id | optional unitsById matches default path | same | same | #3949 |
| wtk-builder-behavior | matches prior behavior for builder improvement tiles | same | same | #3949 |
| wtk-shared-view | shared view and validator matches default path | same | same | #3949 |

Migrated imperative `order_suggestion_work_tile_keys_shared_validator_test.dart` → table-driven scenarios with dedicated support modules. Removed file from `ordersPreferScenarioTablesAllowlist` (allowlist now empty — all documented-exception imperative suites migrated).

test/ LOC after slice 87: **38,210** (net −9 from post–slice 86; support modules add LOC while runner shrinks). Remaining: lib DRY items 5–6, scenario-table migration toward ≤26,400.

### Slice 88 — recruit-worker suggestion scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| rw-inclusion-peasant-apprentice | returns peasant and apprentice when fabric, treasury, paper, and apprentice tech support both rows | `order_suggestion_recruit_worker_test.dart`, `order_suggestion_recruit_worker_parity_test.dart` | `support/suggestion/order_suggestion_recruit_worker_{fixtures,scenarios,expectations}.dart` + thin runner | #2692 S7, #3949 |
| rw-inclusion-tech-locked | omits trained tiers when their required techs are locked | same | same | #2692 S7, #3949 |
| rw-inclusion-fabric | omits peasant recruit when fabric is insufficient | same | same | #2692 S7, #3949 |
| rw-inclusion-treasury | omits apprentice recruit when treasury is below 200 ducats | same | same | #2692 S7, #3949 |
| rw-inclusion-peasant-pool | omits apprentice recruit when peasant pool is empty | same | same | #2692 S7, #3949 |
| rw-parity-all-tiers | returns all four tiers when all techs unlocked and resources support every cost row | same | same | #2692 S7, #3949 |
| rw-parity-reservation | peasant reservation: pending apprentice recruit drains the only peasant so a candidate apprentice is excluded but candidate peasant remains | same | same | #2692 S7, #3949 |
| rw-parity-engine | engine round-trip parity: accept/reject decision matches addRecruitWorkerOrderWithContext for every WorkerTier in a partial tech / peasant / treasury fixture | same | same | #2692 S7, #3949 |
| rw-parity-empty | empty stockpile + zero treasury + zero peasants -> empty list | same | same | #2692 S7, #3949 |

Merged imperative `order_suggestion_recruit_worker_test.dart` + `order_suggestion_recruit_worker_parity_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent baseline descriptions for all nine recruit-worker inclusion/parity scenarios. Deleted parity shard file.

test/ LOC after slice 88: **38,257** (net +47 from post–slice 87; support modules add LOC while parity shard deleted). Remaining: further imperative-suite compaction (colonial acquisition, declare-war intervention, purchase-land colonial, etc.), lib DRY items 5–6 opportunistic cleanup, scenario-table migration toward ≤26,400.

### Slice 89 — colonial acquisition suggestion scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| ca-join-empire | embassy-stage tribe: suggestDiplomaticOrders surfaces Join Empire | `order_suggestion_colonial_acquisition_join_empire_or_war_test.dart` | `support/suggestion/order_suggestion_colonial_acquisition_{fixtures,scenarios,expectations}.dart` + thin runner | #2509, #3949 |
| ca-declare-war | embassy-stage tribe: suggestDeclareWarOrders surfaces declareWar | same | same | #2509, #3949 |
| ca-deterministic | candidate set is deterministic across repeated suggestion calls | same | same | #2509, #3949 |

Migrated imperative `order_suggestion_colonial_acquisition_join_empire_or_war_test.dart` → table-driven scenarios with dedicated support modules. Pinned previously absent baseline descriptions for all three colonial-acquisition candidate-emission scenarios.

test/ LOC after slice 89: **38,273** (net +16 from post–slice 88; support modules add LOC while runner shrinks). Remaining: further imperative-suite compaction (declare-war intervention, purchase-land colonial, etc.), lib DRY items 5–6 opportunistic cleanup, scenario-table migration toward ≤26,400.

### Slice 90 — declare-war intervention + purchase-land colonial scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| dwir-tribe-candidate | tribe stays in candidates when other GPs hold embassies on it | `order_suggestion_declare_war_intervention_risk_test.dart` | `support/suggestion/order_suggestion_declare_war_intervention_risk_{fixtures,scenarios,expectations}.dart` + thin runner | #2509, #3949 |
| dwir-deterministic | tribe candidate is deterministic across repeated suggestDeclareWarOrders calls | same | same | #2509, #3949 |
| plc-embassy-purchase | embassy-stage NW tribe: suggestWorkOrders surfaces purchase_land for Merchant | `order_suggestion_work_purchase_land_colonial_test.dart` | `support/suggestion/order_suggestion_work_purchase_land_colonial_{fixtures,scenarios,expectations}.dart` + thin runner | #2509, #3949 |
| plc-deterministic | embassy-stage NW tribe: suggestWorkOrders is deterministic for repeated calls | same | same | #2509, #3949 |
| plc-no-embassy | no embassy with NW tribe: suggestWorkOrders omits purchase_land for Merchant | same | same | #2509, #3949 |

Migrated imperative `order_suggestion_declare_war_intervention_risk_test.dart` and `order_suggestion_work_purchase_land_colonial_test.dart` → table-driven scenarios with dedicated support modules. Reused `colonialAcquisitionTopology` from colonial-acquisition fixtures for the shared four-node NW spine. Pinned previously absent baseline descriptions for all five scenarios.

test/ LOC after slice 90: **38,247** (net −26 from post–slice 89; support modules add LOC while runners shrink). Remaining: lib DRY items 5–6 opportunistic cleanup, further imperative-suite compaction toward ≤26,400.

### Slice 91 — colonial discovery, API declare-war, naval validator-reuse scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| dwc-first-contact | suggestDeclareWarOrders excludes sea-reachable tribe without NW tile visibility (#3620 first-contact gate) | `order_suggestion_declare_war_colonial_discovery_test.dart` | `support/suggestion/order_suggestion_declare_war_colonial_discovery_{fixtures,scenarios,expectations}.dart` + thin runner | #3620, #3949 |
| dw-api-minor | returns declareWar toward minor when establishOverture would win in suggestDiplomaticOrders | `order_suggestion_api_impl_declare_war_test.dart` | `support/suggestion/order_suggestion_api_impl_declare_war_{fixtures,scenarios,expectations}.dart` + thin runner | #3949 |
| nvr-shared | suggestNavalMoveOrders and suggestNavalMissionOrders reuse one validator | `order_suggestion_naval_validator_reuse_test.dart` | `support/suggestion/order_suggestion_naval_validator_reuse_{fixtures,scenarios,expectations}.dart` + thin runner | #2394, #3949 |

Migrated imperative `order_suggestion_declare_war_colonial_discovery_test.dart`, `order_suggestion_api_impl_declare_war_test.dart`, and `order_suggestion_naval_validator_reuse_test.dart` → table-driven scenarios with dedicated support modules. Reused `colonialAcquisitionTopology` for colonial-discovery fixtures. Pinned previously absent baseline descriptions for all three scenarios.

test/ LOC after slice 91: **38,438** (net +191 from post–slice 90; support modules add LOC while runners shrink). Remaining: lib DRY items 5–6 opportunistic cleanup, further imperative-suite compaction toward ≤26,400.

### Slice 92 — work-logging prospect merge + diplomatic validator-reuse scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| oswl-prospect-included-count | explorer multiple prospect tiles emit one suggest_work with includedCount | `order_suggestion_work_logging_prospect_test.dart` | `support/suggestion/order_suggestion_work_logging_{fixtures,scenarios,expectations}.dart` + `order_suggestion_work_logging_test.dart` | #3949 |
| oswl-pending-duplicate | explorer pending targets preserve duplicate check and log ordering | same | same | #3949 |
| dvr-one-pass | builds one pass-level validator across multiple diplomatic targets | `order_suggestion_diplomatic_validator_reuse_test.dart` | `support/suggestion/order_suggestion_diplomatic_validator_reuse_{fixtures,scenarios,expectations}.dart` + thin runner | #2394, #3949 |
| dvr-shared-supplied | skips pass-level build when sharedCandidateValidator is supplied | same | same | #2394, #3949 |
| dvr-rebind | rebinds pass validator to workingOrders after each target | same | same | #2394, #3949 |

Merged imperative `order_suggestion_work_logging_prospect_test.dart` into the existing work-logging scenario family. Migrated imperative `order_suggestion_diplomatic_validator_reuse_test.dart` → table-driven scenarios with dedicated support modules. Pinned five previously absent baseline descriptions. Deleted prospect shard file.

test/ LOC after slice 92: **38,494** (net +56 from post–slice 91; support modules add LOC while prospect shard deleted). Remaining: lib DRY items 5–6 opportunistic cleanup, further imperative-suite compaction toward ≤26,400.

### Slice 93 — army-move armiesById + simple-AI validator-reuse scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| amv-accepted-parity | accepted result is identical with and without supplied armiesById | `army_move_validator_armies_by_id_test.dart` | `support/validators/army_move_validator_armies_by_id_{fixtures,scenarios,expectations}.dart` + thin runner | #2394, #3949 |
| amv-rejected-parity | rejected result is identical with and without supplied armiesById | same | same | #2394, #3949 |
| amv-missing-id | armiesById missing the target army id is rejected as Invalid army move | same | same | #2394, #3949 |
| amv-incremental-parity | IncrementalCandidateValidator.isArmyMoveAccepted matches ArmyMoveValidator.validate (Refs #2394 incremental hot path) | same | same | #2394, #3949 |
| amv-faction-membership | factionMembership path matches legacy GP declare-war guard (Refs #2394) | same | same | #2394, #3949 |
| savr-heuristic | builds one incremental validator per player heuristic pass | `simple_ai_validator_reuse_test.dart` | `support/suggestion/simple_ai_validator_reuse_{fixtures,scenarios,expectations}.dart` + thin runner | #2394, #3949 |
| savr-batch | builds one incremental validator per AI player in batch path | same | same | #2394, #3949 |

Migrated imperative `army_move_validator_armies_by_id_test.dart` and `simple_ai_validator_reuse_test.dart` → table-driven scenarios with dedicated support modules. Pinned seven previously absent baseline descriptions.

test/ LOC after slice 93: **38,623** (net +129 from post–slice 92; support modules add LOC while runners shrink). Remaining: lib DRY items 5–6 opportunistic cleanup, further imperative-suite compaction toward ≤26,400.

### Slice 94 — shared-validator negative + diplomatic appendability scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| svn-move-wrong-player | suggestMoveOrders trips assertion when validator is for a different player | `order_suggestion_shared_validator_negative_test.dart` | `support/suggestion/order_suggestion_shared_validator_negative_{scenarios,expectations}.dart` + thin runner | #2394, #3949 |
| svn-army-wrong-player | suggestArmyMoveOrders trips assertion when validator is for a different player | same | same | #2394, #3949 |
| svn-work-wrong-player | suggestWorkOrders trips assertion when validator is for a different player | same | same | #2394, #3949 |
| svn-build-wrong-player | suggestBuildOrders trips assertion when validator is for a different player | same | same | #2394, #3949 |
| svn-for-player-foreign-view | IncrementalCandidateValidator.forPlayer trips assertion when supplied view is for a different player | same | same | #2394, #3949 |
| svn-heuristics-smoke | orders generated under the new shared-validator code path are unchanged against a known fixture | same | same | #2394, #3949 |
| daa-excludes-draft | does not suggest toward target already in draft diplomatic orders | `order_suggestion_api_impl_diplomatic_appendability_test.dart` | `support/suggestion/order_suggestion_api_impl_diplomatic_appendability_{fixtures,scenarios,expectations}.dart` + thin runner | #3949 |
| daa-cumulative-validates | suggestDiplomaticOrders: cumulative list appendable and validates | same | same | #3949 |
| daa-pending-restore | removing pending diplomatic order restores suggestions for that target | same | same | #3949 |

Migrated imperative `order_suggestion_shared_validator_negative_test.dart` and `order_suggestion_api_impl_diplomatic_appendability_test.dart` → table-driven scenarios with dedicated support modules. Pinned nine previously absent baseline descriptions.

test/ LOC after slice 94: **38,695** (net +72 from post–slice 93; support modules add LOC while runners shrink). Remaining: lib DRY items 5–6 opportunistic cleanup, further imperative-suite compaction toward ≤26,400.

### Slice 95 — feedstock bootstrap, town-work prefilter, lock-recovery guard, build-phase index maps scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| wocfb-castiron-lumber | omits castIron for unimproved feedstock tile when gate active and stockpile has lumber only | `work_order_cost_calculator_feedstock_bootstrap_test.dart` | `support/validators/work_order_cost_calculator_feedstock_bootstrap_{fixtures,scenarios,expectations}.dart` + thin runner | #2847, #3949 |
| wocfb-castiron-affordable | keeps full cost when castIron is already affordable (negative control) | same | same | #3949 |
| wocfb-non-feedstock | keeps full cost on non-feedstock tile while gate active (negative control) | same | same | #3949 |
| wocfb-lumber-bootstrap | omits lumber and castIron for unimproved feedstock tile when gate active and stockpile has neither input (Refs #2847 lumber bootstrap) | same | same | #2847, #3949 |
| wocfb-no-lumber-waiver | does not waive lumber when castIron is already affordable (negative control) | same | same | #3949 |
| vwt-town-owned | upgrade_town includes town tiles only in owned provinces with a town | `order_suggestion_work_tile_prefilter_town_work_test.dart` | `support/suggestion/order_suggestion_work_tile_prefilter_town_work_{fixtures,scenarios,expectations}.dart` + thin runner | #3949 |
| vwt-fort-match | build_fort matches upgrade_town town-tile prefilter for shared owned set | same | same | #3949 |
| vwt-cache-path | default path derives owned provinces from ProvinceOwnerCache (Phase 6b) | same | same | #3949 |
| blr-positive | positive control: a broke GP with riches CAN train the cheapest regiment (proves the negative guard is non-vacuous) | `order_suggestion_build_lock_recovery_affordability_guard_test.dart` | `support/suggestion/order_suggestion_build_lock_recovery_affordability_guard_{fixtures,scenarios,expectations}.dart` + thin runner | #2924, #3949 |
| blr-ai-no-bypass | affordability regression guard: AI GP at treasury 0 with no riches gets zero regiment build candidates (no AI bypass) | same | same | #2924, #3949 |
| blr-human-suggestions | human-player guard: human at treasury 0 with no riches gets zero regiment suggestions (no human waiver) | same | same | #2924, #3949 |
| blr-human-validation | human-player guard: the build-validation path rejects a human regiment build at treasury 0 (UI submission path, no waiver) | same | same | #2924, #3949 |
| rbpi-military | consecutive military recruits build one home army with all regiments | `run_build_phase_index_maps_test.dart` | `support/application/run_build_phase_index_maps_{fixtures,scenarios,expectations}.dart` + thin runner | #2394, #3949 |
| rbpi-naval | consecutive ship recruits add ships to a single home fleet (cache reuse) | same | same | #2394, #3949 |

Migrated four remaining imperative suites to table-driven scenarios with dedicated support modules. All fourteen baseline descriptions preserved.

test/ LOC after slice 95: **38,981** (net +286 from post–slice 94; support modules add LOC while runners shrink). Remaining: lib DRY items 5–6 opportunistic cleanup, further imperative-suite compaction toward ≤26,400.

### Slice 96 — final imperative-suite scenario migration

| scenario_id | test description | source file(s) | target file | refs |
|-------------|------------------|----------------|-------------|------|
| mew-draft-work | suggestMoveOrders emits no MoveOrder for a unit that already has a draft WorkOrder | `order_suggestion_move_excludes_unit_with_draft_work_test.dart` | `support/suggestion/order_suggestion_move_excludes_unit_with_draft_work_{fixtures,scenarios,expectations}.dart` + thin runner | #2082, #3949 |
| pop-tile-cap | co-located Explorer still prospects feedstock iron when it sorts after four other accepted mineral tiles in the same province | `order_suggestion_prospect_own_province_tile_cap_test.dart` | `support/suggestion/order_suggestion_prospect_own_province_tile_cap_{fixtures,scenarios,expectations}.dart` + thin runner | #2847, #3949 |
| fnw-projection | seller owning a New World province deactivates the feedstock gate (projection-backed new-world count, Refs #3393) | `order_suggestion_feedstock_new_world_projection_test.dart` | `support/suggestion/order_suggestion_feedstock_new_world_projection_{fixtures,scenarios,expectations}.dart` + thin runner | #3393, #3949 |
| fcs-stable | suggestWorkOrders full-candidate snapshot remains stable (Refs #2133 AC8) | `order_suggestion_full_candidate_snapshot_test.dart` | `support/suggestion/order_suggestion_full_candidate_snapshot_{fixtures,scenarios,expectations}.dart` + thin runner | #2133, #3949 |
| owc-ownership | work-target / mineral / prospect constants ownership (4 scenarios) | `order_work_constants_test.dart` | `support/order_work_constants_{scenarios,expectations}.dart` + thin runner | #3290, #3949 |
| jeo-validator | validateJoinEmpireOverture direct contract (4 scenarios) | `join_empire_overture_validator_test.dart` | `support/validators/diplomatic/join_empire_overture_validator_{scenarios,expectations}.dart` + thin runner | #2560, #3949 |
| ec-precheck | precheckExplorerConsulateInMinorTribe rejects explore without Consulate | `work_order_target_prechecks_explorer_consulate_test.dart` | `support/validators/work_order_target_prechecks_explorer_consulate_{fixtures,scenarios,expectations}.dart` + thin runner | #3949 |

Migrated the last seven imperative `*_test.dart` suites without `runLabeledScenario` to table-driven scenarios. All thirteen baseline descriptions preserved; thirteen previously absent descriptions pinned. **Zero** remaining long-form imperative bodies outside scenario loops (`repo.orders_test_prefer_scenario_tables` clean with empty allowlist).

test/ LOC after slice 96: **39,395** (net +414 from post–slice 95; support modules add LOC while runners shrink). Remaining: lib DRY items 5–6 opportunistic cleanup, support-table compaction toward ≤26,400.

## Wave 3 — documented exceptions (kickoff)

| file | retained test description(s) | rationale | refs |
|------|------------------------------|-----------|------|
| (none after slice 96) | — | All former imperative suites migrated; `ordersPreferScenarioTablesAllowlist` empty | #3949 |
