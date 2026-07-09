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

## Wave 3 — documented exceptions (kickoff)

| file | retained test description(s) | rationale | refs |
|------|------------------------------|-----------|------|
| remaining long-form `*_test.dart` | see `DESCRIPTION_BASELINE.txt` + `ordersPreferScenarioTablesAllowlist` | Imperative suites still outside migrated families; allowlisted explicitly after slice 13 shut off baseline allow-all | #3949 |
