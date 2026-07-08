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

test/ LOC after slice 7: see `find … wc -l` in PR. Remaining: diplomatic / recruit / trade validate suites, other `orders_application_*`, incremental equivalence, lib DRY. ≥20% target ≤26,400 still deferred.

## Wave 3 — documented exceptions (kickoff)

| file | retained test description(s) | rationale | refs |
|------|------------------------------|-----------|------|
| (all pre-wave `*_test.dart`) | see `DESCRIPTION_BASELINE.txt` | Imperative suites allowlisted via `ordersPreferScenarioTablesBaselineAllowAll` until table migration; tighten allowlist as families migrate | #3949 |
