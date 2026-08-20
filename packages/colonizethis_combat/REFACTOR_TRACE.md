# Combat dedup refactor trace (Refs #3865)

Maps consolidated scenario modules to preserved test descriptions, source files, and originating issue AC references.

Baseline: `dev` @ `df7bbd62` (combat test LOC 6,573 physical lines across 31 `*_test.dart` files before slice 1).

## Phase 3 — slice 1 (Refs #3983)

Delivered in this slice:

- Shared harness `runLabeledScenarios` / `runLabeledScenarioGroup` / `LabeledScenario` in `colonizethis_combat_test_support`; all prior thin runners + nine residual imperative suites adopted.
- Collapsed `run*Scenario` trampolines onto `(s) => s.run()`.
- De-`part`ed land `combat_resolver_*` into explicit-import libraries; `repo.combat_no_part_directives`.
- Survivor/casualty filter helper `combat_survivor_units.dart` used in land auto-resolve, post-battle, and Quick Battle apply/engine.
- Harness gate `repo.combat_test_scenario_harness` (zero bare scenario for-loops).

Combat test LOC: **1,577 → 507** physical lines (`find … | wc -l`; target ≤1,340).

## Phase 3 — slice 2 (Refs #3983)

Delivered in this slice:

- Split naval resolver seams: `naval_combat_types.dart` (types + ship clone + retreat constants), `naval_combat_detection.dart` (detect + attacker normalize), `naval_combat_resolver.dart` (strength + resolve + apply; re-exports types/detection for the package barrel).

Deferred (still optional):

- Optional DESCRIPTION_BASELINE file (trace table below + duplicate-description gate cover labels).
- Optional densify of test_support preamble after harness adoption.

| scenario_id | test description | source file |
|---|---|---|
| pci-prefixed-destination | passes through an already-prefixed destination unchanged | `pre_combat_index_test.dart` |
| pci-qualifies-local-destination | qualifies a bare local id with the army stationed region | `pre_combat_index_test.dart` |
| pci-units-grouped-ordered | groups combat units by province, preserving region.units order | `pre_combat_index_test.dart` |
| pci-units-empty | returns an empty map for a region without units | `pre_combat_index_test.dart` |
| pci-provinces-by-id | maps each province id to its province | `pre_combat_index_test.dart` |
| pci-build-* | greatPowerIds contains every player id and armiesById every army; includes Great Power army moves with destinations resolved in order; skips moves from factions that are not Great Powers; skips home armies; skips orders for unknown army ids; skips orders whose army owner differs from the ordering faction | `pre_combat_index_test.dart` |
| upc-captures-undefended | captures undefended minor province when GP army moved in at war | `unopposed_province_capture_test.dart` |
| upc-defender-units | skips when province owner still has combat units in province | `unopposed_province_capture_test.dart` |
| upc-peace | skips when attacker is not at war with province owner | `unopposed_province_capture_test.dart` |
| mae-base-cost | base cost 100 without military tech discounts | `military_attack_economy_test.dart` |
| mae-tech-discounts | applies multiplicative discounts for machinery and modern funding | `military_attack_economy_test.dart` |
| mae-deducts-one | deducts per attacker Great Power once per battle context | `military_attack_economy_test.dart` |
| mae-deducts-nonfirst | deducts treasury when attacker is not first in players list order | `military_attack_economy_test.dart` |
| mae-deducts-distinct | deducts treasury for each distinct Great Power attacker side | `military_attack_economy_test.dart` |
| mae-skip-minor | does not deduct treasury when attacker is not a Great Power | `military_attack_economy_test.dart` |
| qbras-old-world-clear | quick battle conquest clears Spy timer for new owner province | `quick_battle_resolver_apply_spy_test.dart` |
| qbras-new-world-clear | quick battle conquest in newWorld region also clears Spy timer | `quick_battle_resolver_apply_spy_test.dart` |
| qbib-* | produces QuickBattleInput with defender and attacker groups; filters out unit ids not present in region; supplies leader multipliers from Game players (napoleon 1.25, frederick 1.15); leader multipliers default to 1.0 when players have no leaderKey; builds input from newWorld BattleContext; passes attacker and defender medals from battle assignment | `quick_battle_input_builder_test.dart` |
| clp-* | blunts strong attacker victory when attacker morale is lower; uses decisive attacker band at the blunt upper bound; keeps exact ratio thresholds in the documented bands; uses default close-fight profile below attacker edge | `combat_loss_profile_test.dart` |
| clp-strong-striker | classifies at and above the strong-striker threshold | `combat_loss_profile_test.dart` |
| clp-strong-target | classifies at and below the strong-target threshold | `combat_loss_profile_test.dart` |
| clp-even | classifies the open interval between thresholds as even | `combat_loss_profile_test.dart` |
| clp-breakpoints | exposes the canonical breakpoint values | `combat_loss_profile_test.dart` |
| clp-casualty-round-clamp | rounds fractional losses up and clamps to available units | `combat_loss_profile_test.dart` |
| crng-* | quickBattleRng matches Random(seed) sequence; quickBattleRng is deterministic for a fixed seed; probabilisticEngagementRng falls back to 0 for a null seed; probabilisticEngagementRng matches Random(seed) for non-null seed; navalCombatRng matches DeterministicRng(seed) sequence; navalCombatRng is deterministic for a fixed seed | `combat_rng_test.dart` |
| crng-precombat-hash | preCombatBindingRng matches the SPEC §3 hash recipe | `combat_rng_test.dart` |
| crng-precombat-null | preCombatBindingRng treats a null globalGameSeed as 0 | `combat_rng_test.dart` |
| crng-assignment-hash | battleAssignmentRng matches hash(seed, turn, region, province) | `combat_rng_test.dart` |
| crng-assignment-province | battleAssignmentRng differs across provinces | `combat_rng_test.dart` |
| crpot-owner-not-defender | transfers from province owner when battle defender is another occupant | `combat_resolver_province_owner_transfer_test.dart` |
| cdai-local-defender-army | defender army selection ignores unrelated armies in other provinces | `conflict_detection_army_index_test.dart` |

## Slice 1 — test_support package, effective-strength tables, military-strength fixtures

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| att-all-factors-no-fort | multiplies base by all factors when no fort applies | `combat_effective_strength_test.dart` | — |
| att-omitted-factors-identity | omitted factors are the identity (bit-exact) | `combat_effective_strength_test.dart` | — |
| att-fort-damage-reduction | applies fort damage reduction inside the siege range | `combat_effective_strength_test.dart` | — |
| att-fort-outside-range | does not apply reduction outside the siege range | `combat_effective_strength_test.dart` | — |
| def-ignores-emplaced-without-fort | multiplies base by factors and ignores emplaced without fort | `combat_effective_strength_test.dart` | — |
| def-adds-emplaced-in-siege | adds emplaced strength inside the siege range | `combat_effective_strength_test.dart` | — |
| ratio-outside-siege-range | returns effAtt unchanged outside the siege range | `combat_effective_strength_test.dart` | — |
| ratio-subtracts-wall-hp | subtracts wall HP inside the siege range | `combat_effective_strength_test.dart` | — |
| ratio-clamps-zero | clamps to zero when wall HP exceeds effAtt | `combat_effective_strength_test.dart` | — |
| emplaced-outside-range | returns 0 outside the siege range | `combat_effective_strength_test.dart` | — |
| emplaced-gun-count-times-strength | returns gunCount * emplacedStrength inside the siege range | `combat_effective_strength_test.dart` | — |

Modules:
- `colonizethis_combat_test_support/lib/src/effective_strength_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/military_strength_test_support.dart` (promoted from `test/combat/military_strength_test_support.dart`)

Package: `colonizethis_combat_test_support` workspace package created; `colonizethis_combat` dev_dependency wired.

Lint: `repo.combat_test_no_local_support` — forbids `*_test_support.dart` under `packages/colonizethis_combat/test/**`.

Lint: `repo.combat_test_core_fixtures_shared` and `repo.combat_test_duplicate_descriptions` — added slice 9 (Refs #3865).

Deferred: part2/probabilistic table migration during resolver scenario hoisting (slice 9+).

## Slice 2 — military-strength scenario tables

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| ms-empty-army | returns 0 for empty army | `military_strength_test.dart` | — |
| ms-gp-medals | calculates strength for Great Power units with medals | `military_strength_test.dart` | — |
| ms-minor-era | uses effective military level for Minor Nation | `military_strength_test.dart` | — |
| ms-tribe-era | uses effective military level for Tribe | `military_strength_test.dart` | — |
| ms-gp-era4 | Great Power uses era 4 (does not downgrade era 3 units) | `military_strength_test.dart` | — |
| ms-unknown-regiment | skips units with unknown regiment types | `military_strength_test.dart` | — |
| ms-ow-nw | aggregates units from both Old World and New World | `military_strength_test.dart` | — |
| ms-owner-filter | only includes units owned by the specified player | `military_strength_test.dart` | — |
| ms-medal-multipliers | applies medal multiplier correctly (0-4 medals) | `military_strength_test.dart` | — |
| ms-deterministic | is deterministic - same inputs produce same output | `military_strength_test.dart` | — |
| ms-non-negative | returns non-negative value | `military_strength_test.dart` | — |
| as-list-units | aggregates strength for a list of units | `military_strength_test.dart` | — |
| as-era-downgrade | downgrades units when era exceeds effective era | `military_strength_test.dart` | — |
| eef-gp | returns 4 for Great Power | `military_strength_test.dart` | — |
| eef-minor | returns effectiveMilitaryLevel for Minor Nation | `military_strength_test.dart` | — |
| eef-tribe | returns effectiveMilitaryLevel for Tribe (capped at 1 in-game) | `military_strength_test.dart` | — |
| eef-unknown | returns 4 for unknown faction | `military_strength_test.dart` | — |
| cf-empty | returns 0 when unit list is empty | `military_strength_test.dart` | — |
| cf-share | counts cavalry share over all unit ids | `military_strength_test.dart` | — |
| cf-missing-denominator | missing units still count toward denominator | `military_strength_test.dart` | — |

Module: `colonizethis_combat_test_support/lib/src/military_strength_scenarios.dart`

Combat test LOC: 6,481 → 6,170 physical lines (−311 in test files; ≥15% target deferred to later slices).

## Slice 3 — Quick Battle action-modifier and emplaced-gun tables

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| qam-neutral | no actions yields neutral 1.0 modifiers | `quick_battle_action_modifiers_test.dart` | — |
| qam-volley | volleyFire raises casualties dealt only | `quick_battle_action_modifiers_test.dart` | — |
| qam-entrench | defendEntrench lowers casualties taken only | `quick_battle_action_modifiers_test.dart` | — |
| qam-maneuver | maneuver raises offense only | `quick_battle_action_modifiers_test.dart` | — |
| qam-fallback | fallBackRefuseFlank lowers offense and casualties taken | `quick_battle_action_modifiers_test.dart` | — |
| qam-assault | assaultCharge raises offense and casualties taken | `quick_battle_action_modifiers_test.dart` | — |
| qam-combined | combined actions sum deltas in order | `quick_battle_action_modifiers_test.dart` | — |
| qam-assault-clamp-high | repeated assaultCharge clamps offense to 1.5 upper bound | `quick_battle_action_modifiers_test.dart` | — |
| qam-fallback-clamp-low | repeated fallBackRefuseFlank clamps casualties taken to 0.5 floor | `quick_battle_action_modifiers_test.dart` | — |
| meg-from-input | copies all fields from immutable input gun | `quick_battle_emplaced_guns_test.dart` | — |
| ags-sum-alive | sums attack+defense over alive guns and skips dead | `quick_battle_emplaced_guns_test.dart` | — |
| ags-empty | empty list yields 0.0 | `quick_battle_emplaced_guns_test.dart` | — |
| sah-sum-hp | sums hp over alive guns only | `quick_battle_emplaced_guns_test.dart` | — |
| rrd-noop | non-positive amount is a no-op | `quick_battle_emplaced_guns_test.dart` | — |
| rrd-round-robin | distributes damage round-robin by id order | `quick_battle_emplaced_guns_test.dart` | — |
| rrd-skip-dead | skips fully destroyed guns and keeps damaging survivors | `quick_battle_emplaced_guns_test.dart` | — |
| rrd-overkill | damage exceeding total HP drives all guns to zero | `quick_battle_emplaced_guns_test.dart` | — |

Modules:
- `colonizethis_combat_test_support/lib/src/quick_battle_action_modifiers_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/quick_battle_emplaced_guns_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/quick_battle_emplaced_guns_test_support.dart` (`emplacedGun` builder)

Combat test LOC: 6,170 → 6,053 physical lines (−117 in test files across slice 3).

## Slice 4 — Quick Battle resolver scenario tables + input builders

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| qbr-deterministic-seed | deterministic for same seed | `quick_battle_resolver_resolve_test.dart` | — |
| qbr-stronger-attacker-wins | stronger attacker tends to win | `quick_battle_resolver_resolve_test.dart` | — |
| qbr-custom-round-actions | custom roundActions override default Volley Fire | `quick_battle_resolver_resolve_test.dart` | — |
| qbr-fort-level | fort level applies wall and damage reduction | `quick_battle_resolver_resolve_test.dart` | — |
| qbr-stronger-defender-holds | stronger defender tends to hold | `quick_battle_resolver_resolve_test.dart` | — |
| qbr-lane-terrain-actions | uses lane terrain modifiers and actions | `quick_battle_resolver_resolve_test.dart` | — |
| qbr-initiative-ordering | initiative ordering is deterministic and affects sequencing | `quick_battle_resolver_resolve_test.dart` | — |

Modules:
- `colonizethis_combat_test_support/lib/src/quick_battle_resolver_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/quick_battle_input_test_support.dart` (`centerFrontQuickBattleInput`, `centerFrontQuickBattleDeployment`, `quickBattleUnitIds`)

Combat test LOC: 6,019 → 5,677 physical lines (−342 in test files across slice 4).

## Slice 5 — Quick Battle siege and initiative scenario tables

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| qbs-conquest-fort-downgrade | Scenario: concentrated fire destroys battery before garrison — conquest + fort downgrade | `quick_battle_siege_scenarios_test.dart` | — |
| qbs-battery-absorbs-volleys | Scenario: battery absorbs volleys — partial HP loss, fort stands | `quick_battle_siege_scenarios_test.dart` | — |
| qbs-two-gun-round-robin | Scenario: two-gun battery — round-robin damage (sorted by id) | `quick_battle_siege_scenarios_test.dart` | — |
| qbs-triple-battery | Scenario: triple battery (fort 3) — each piece tracked independently | `quick_battle_siege_scenarios_test.dart` | — |
| qbs-no-virtual-guns | Scenario: no virtual guns — legacy aggregate emplaced lump still applies | `quick_battle_siege_scenarios_test.dart` | — |
| qbs-pipeline-build-apply | Scenario: pipeline buildQuickBattleInput → resolve → apply reduces fort on conquest | `quick_battle_siege_scenarios_test.dart` | — |
| qbi-cavalry-attacker-first | Scenario: cavalry-heavy attacker gains first action and trades better | `quick_battle_siege_scenarios_test.dart` | — |

Modules:
- `colonizethis_combat_test_support/lib/src/quick_battle_siege_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/quick_battle_siege_pipeline_test_support.dart` (`siegePipelineGame`, `siegePipelineBattleContext`)
- `quick_battle_input_test_support.dart` — `siegeEmplacedGun`, `emplacedGuns` on `centerFrontQuickBattleInput`

Deferred: perf/build QB suites, land resolver, conflict-detection tables; inline `Game(` gate; lib multiplier helper.

Combat test LOC: 5,677 → 5,336 physical lines (−341 in test files across slice 5).

## Slice 6 — Naval combat scenario tables

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| ncr-empty-fleets | returns empty when no fleets | `naval_combat_resolver_test.dart` | — |
| ncr-peace-same-zone | returns empty when two factions in same zone but at peace | `naval_combat_resolver_test.dart` | — |
| ncr-at-war-battle | returns one BattleContextSea when two at-war factions in same zone | `naval_combat_resolver_test.dart` | — |
| nbs-mover-attacker | only mover is attacker when the other is not Patrol or Blockade | `naval_combat_resolver_test.dart` | — |
| nbs-interceptor-attacker | interceptor is attacker when the other faction moved | `naval_combat_resolver_test.dart` | — |
| nbs-lex-neither-moved | neither moved: lexicographically smaller ownerId is attacker | `naval_combat_resolver_test.dart` | — |
| nbs-lex-both-moved | both moved: lexicographically smaller ownerId is attacker | `naval_combat_resolver_test.dart` | — |
| ns-empty | returns 0 for empty list | `naval_combat_resolver_test.dart` | — |
| ns-weighted-formula | uses configured weighted formula including durability | `naval_combat_resolver_test.dart` | — |
| rsb-strength-ratio | returns surviving ships with casualties by strength ratio | `naval_combat_resolver_resolution_test.dart` | — |
| rsb-zero-strength | returns all ships when total strength is zero | `naval_combat_resolver_resolution_test.dart` | — |
| rsb-feeding-morale | feeding coverage multiplies raw naval strength like land combat morale | `naval_combat_resolver_resolution_test.dart` | — |
| rsb-no-retreat | does not retreat when retreat is disallowed by topology/relation gate | `naval_combat_resolver_resolution_test.dart` | — |
| anbr-replace-fleets | replaces fleets in zone with surviving sides | `naval_combat_resolver_resolution_test.dart` | — |
| anbr-preserve-mission | preserves mission on recreated surviving fleets | `naval_combat_resolver_resolution_test.dart` | — |
| nip-patrol | Patrol uses mission-factor * ratio | `naval_combat_resolver_resolution_test.dart` | — |
| nip-blockade | Blockade uses mission-factor * ratio | `naval_combat_resolver_resolution_test.dart` | — |
| nip-clamped | result is clamped 0.05-0.85 | `naval_combat_resolver_resolution_test.dart` | — |
| npp-baseline | no privateering uses the baseline (unscaled) interceptor score | `naval_combat_resolver_privateering_test.dart` | #3470 |
| npp-scaled | privateering scales interceptor score by 1.25 before clamp | `naval_combat_resolver_privateering_test.dart` | #3470 |
| npp-higher-than-baseline | privateering yields strictly higher probability than baseline | `naval_combat_resolver_privateering_test.dart` | #3470 |
| npp-clamped | privateering result remains within [0.05, 0.85] clamp | `naval_combat_resolver_privateering_test.dart` | #3470 |
| fbi-at-least-as-often | interceptor with privateering intercepts at least as often | `naval_combat_resolver_privateering_test.dart` | #3470 |
| fbi-deterministic | interception counts are deterministic for fixed seeds | `naval_combat_resolver_privateering_test.dart` | #3470 |

Modules:
- `colonizethis_combat_test_support/lib/src/naval_combat_test_support.dart` (`navalTwoPlayerGame`, `navalGameTwoFleetsAtWar`)
- `colonizethis_combat_test_support/lib/src/naval_combat_resolver_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/naval_combat_resolution_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/naval_combat_privateering_scenarios.dart`

Deferred: perf/build QB suites, land resolver, conflict-detection tables; inline `Game(` gate; lib multiplier helper.

Combat test LOC: 5,336 → 4,756 physical lines (−580 in test files across slice 6).

## Slice 7 — Quick Battle perf-invariant and build/siege scenario tables

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| qbpi-three-guns-sorted-id-parity | three small guns drained over multiple rounds keep sorted-id parity | `quick_battle_resolver_perf_invariants_test.dart` | #2316 P1 #8 |
| qbpi-asymmetric-gun-hp-round-robin | asymmetric gun HP still allocates damage in sorted-id round-robin order | `quick_battle_resolver_perf_invariants_test.dart` | #2316 P1 #8 |
| qbpi-attacker-first-cache-bit-identical | attacker-acts-first siege duplicate runs are bit-identical | `quick_battle_resolver_perf_invariants_test.dart` | #2316 P1 #9 |
| qbpi-defender-first-cache-bit-identical | defender-acts-first siege duplicate runs are bit-identical | `quick_battle_resolver_perf_invariants_test.dart` | #2316 P1 #9 |
| qbpi-non-siege-initiative-ordering | non-siege battle outcomes are unchanged across initiative orderings | `quick_battle_resolver_perf_invariants_test.dart` | #2316 P1 #9 |
| qbbs-build-from-context | builds input from BattleContext | `quick_battle_resolver_build_and_siege_test.dart` | — |
| qbbs-napoleon-bonus | attacker with napoleon bonus wins more often than with reserve (same seed) | `quick_battle_resolver_build_and_siege_test.dart` | — |
| qbbs-spawn-guns-fort-level | buildQuickBattleInput spawns guns by fort level and stable ids | `quick_battle_resolver_build_and_siege_test.dart` | COL-151 |
| qbbs-resolve-duplicate-emplaced | resolveQuickBattle duplicate runs match emplaced outcomes | `quick_battle_resolver_build_and_siege_test.dart` | — |
| qbbs-apply-fort-downgrade | applyQuickBattleResultToGame downgrades fort when flag set without flip | `quick_battle_resolver_build_and_siege_test.dart` | — |

Modules:
- `colonizethis_combat_test_support/lib/src/quick_battle_perf_invariants_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/quick_battle_build_siege_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/quick_battle_build_test_support.dart`
- `quick_battle_input_test_support.dart` — `perfSiegeQuickBattleInput`

Deferred: land resolver; inline `Game(` gate; lib multiplier helper.

Combat test LOC: 4,756 → 4,156 physical lines (−600 in test files across slice 7).

## Slice 8 — Land conflict-detection scenario tables

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| cd-two-factions-same-province | returns one battle when two factions in same province | `conflict_detection_test.dart` | — |
| cd-new-world-conflict | detects conflict in newWorld when two factions and move order | `conflict_detection_test.dart` | — |
| cd-single-faction | returns no battle when only one faction in province | `conflict_detection_test.dart` | — |
| cd-multiple-provinces | multiple provinces with conflicts return multiple battles | `conflict_detection_test.dart` | — |
| cd-civilians-no-battle | civilians alone do not trigger battles | `conflict_detection_test.dart` | — |
| cd-unowned-non-mover-defender | unowned province: defender is non-mover when two factions present | `conflict_detection_test.dart` | — |
| cd-unowned-lex-first-defender | unowned province: defender is lexicographically first when all moved in | `conflict_detection_test.dart` | — |
| cd-new-world-only-units | returns no battles when oldWorld has no units | `conflict_detection_test.dart` | — |
| cd-army-move-attacker | army move order contributes moved-in attacker detection | `conflict_detection_test.dart` | — |

Modules:
- `colonizethis_combat_test_support/lib/src/conflict_detection_test_support.dart`
- `colonizethis_combat_test_support/lib/src/conflict_detection_scenarios.dart`

Deferred: land resolver (`combat_resolver_test_part*`); inline `Game(` gate; lib multiplier helper.

Combat test LOC: 4,156 → 3,803 physical lines (−353 in test files across slice 8).

## Slice 9 — Land resolver engagement/limits tables, inline Game gate, duplicate-description gate

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| cre-attacker-wins-decisively | attacker wins decisively when much stronger | `combat_resolver_test_part1_test.dart` | — |
| cre-defender-wins | defender wins when much stronger | `combat_resolver_test_part1_test.dart` | — |
| cre-siege-modifiers | siege modifiers apply when fortLevel >= 1 | `combat_resolver_test_part1_test.dart` | — |
| cre-feeding-morale-penalty | low attacker feeding coverage penalises strength via morale multiplier | `combat_resolver_test_part1_test.dart` | — |
| cre-leader-keys-resolve-path | leader keys from Game produce correct multipliers in resolveEngagement path | `combat_resolver_test_part1_test.dart` | — |
| cre-new-world-context | resolveBattleContext updates newWorld when regionId is newWorld | `combat_resolver_test_part1_test.dart` | — |
| crl-deployment-cap-base-10 | deployment limit caps participating regiments per side (base 10, no Nationalism) | `combat_resolver_test_part1_limits_test.dart` | — |
| crl-deployment-cap-nationalism-12 | deployment limit with Nationalism tech is 12 (attacker has 13 units, ≥1 does not participate) | `combat_resolver_test_part1_limits_test.dart` | — |
| crl-winning-general-medal | assigned winning general gains +1 medal immediately and persists | `combat_resolver_test_part1_limits_test.dart` | — |
| crl-leader-fallback-no-general | leader fallback medals apply when no uncommitted general exists | `combat_resolver_test_part1_limits_test.dart` | — |
| crl-general-medal-cap-4 | general medals are capped at 4 on immediate engagement win | `combat_resolver_test_part1_limits_test.dart` | — |

Modules:
- `colonizethis_combat_test_support/lib/src/combat_resolver_test_support.dart`
- `colonizethis_combat_test_support/lib/src/combat_resolver_engagement_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/combat_resolver_limits_scenarios.dart`
- `quick_battle_input_test_support.dart` — `quickBattleInputBuilderGame`, `quickBattleInputBuilderContext`

Removed duplicate file: `combat_resolver_test_part1_deployment_and_general_medals_test.dart` (scenarios consolidated into limits table).

CI gates added: `repo.combat_test_core_fixtures_shared`, `repo.combat_test_duplicate_descriptions`.

Deferred: part2/probabilistic table migration; lib multiplier helper.

Combat test LOC: 3,803 → 2,623 physical lines (−1,180 in test files across slice 9; 30 `*_test.dart` files).

## Slice 10 — Part2/probabilistic/spy-civilian tables, lib morale multiplier

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| crp-same-seed-identical | same seed produces identical outcome | `combat_resolver_probabilistic_test.dart` | — |
| crp-rounds-bounded | rounds bounded by maxCombatRounds | `combat_resolver_probabilistic_test.dart` | — |
| crp-strong-attacker-wins-majority | strong attacker tends to win over many trials | `combat_resolver_probabilistic_test.dart` | — |
| crp-per-round-details | outcome includes per-round details | `combat_resolver_probabilistic_test.dart` | — |
| crp-mutual-annihilation-possible | can produce mutualAnnihilation when both sides eliminated | `combat_resolver_probabilistic_test.dart` | — |
| crp-stalemate-possible | can produce stalemate when rounds end with both sides remaining | `combat_resolver_probabilistic_test.dart` | — |
| crp2-tie-break-deterministic | battle tie-break is deterministic for same seed and context | `combat_resolver_test_part2_test.dart` | — |
| crp2-gp-garrison-recovery-era4 | great power defender: recovered regiments match most-advanced infantry era 4 | `combat_resolver_test_part2_test.dart` | — |
| crp2-minor-garrison-recovery-era3 | minor nation effective era 3: recovered regiments are grenadiers | `combat_resolver_test_part2_test.dart` | — |
| crp2-tribe-garrison-recovery-era1 | tribe effective era 1: recovered regiments are arquebusiers | `combat_resolver_test_part2_test.dart` | — |
| crsc-spy-timer-cleared | combat conquest clears Spy timer for new owner province | `combat_resolver_test_part2_spy_civilian_test.dart` | — |
| crsc-purchased-land-cleared | combat conquest clears purchased land for conquered province | `combat_resolver_test_part2_spy_civilian_test.dart` | — |
| crsc-relocate-working-civilian | combat conquest relocates illegal foreign civilian in changed province to owner capital | `combat_resolver_test_part2_spy_civilian_test.dart` | — |
| crsc-relocate-idle-civilian | combat conquest relocates idle foreign civilian with stale assignment tracking but no currentWork to owner capital | `combat_resolver_test_part2_spy_civilian_test.dart` | — |
| crsc-general-medal-morale-aura | general medals provide morale aura bonus (5% per medal, max 20%) | `combat_resolver_test_part2_spy_civilian_test.dart` | — |

Modules:
- `colonizethis_combat_test_support/lib/src/combat_resolver_probabilistic_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/combat_resolver_part2_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/combat_resolver_spy_civilian_scenarios.dart`
- `combat_resolver_test_support.dart` — `probResolverUnit` builder

Lib: `combatSideMoraleMultiplier` in `combat_resolver_support.dart` (feeding × general-medal assembly for land auto-resolve; naval path remains feeding-only).

Combat test LOC: 2,623 → 1,921 physical lines (−702 in test files across slice 10).

## Slice 11 — Battle general assignment and combat mode selection tables

| scenario_id | test description | source file(s) | refs |
|-------------|------------------|----------------|------|
| bga-second-attack-excludes-general | second attack in same phase excludes general already used as attacker | `battle_general_assignment_test.dart` | — |
| bga-defender-pool-not-filtered | defender pool not filtered by attack ledger for same faction | `battle_general_assignment_test.dart` | — |
| bga-battle-rng-matches | battleAssignmentRng matches for auto and QB same context | `battle_general_assignment_test.dart` | — |
| bgb-binds-distinct-then-fallback | binds distinct attacker/defender generals per context, then falls back when each faction pool is exhausted | `battle_general_assignment_bind_phase_test.dart` | — |
| bgb-respects-pre-bound-ledger | respects generals already bound in the ledger before this pass | `battle_general_assignment_bind_phase_test.dart` | — |
| cms-not-siege-no-fort | returns false when not a siege (no fort) | `combat_mode_selection_test.dart` | — |
| cms-siege-not-capital | returns false when siege but province is not a capital | `combat_mode_selection_test.dart` | — |
| cms-siege-gp-capital | returns true when siege of GP capital | `combat_mode_selection_test.dart` | — |
| cms-capital-siege-qb | capital siege always returns QuickBattle | `combat_mode_selection_test.dart` | — |
| cms-default-mode | uses default when no per-battle override | `combat_mode_selection_test.dart` | — |
| cms-per-battle-override | uses per-battle override when provided | `combat_mode_selection_test.dart` | — |

Modules:
- `colonizethis_combat_test_support/lib/src/battle_general_assignment_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/battle_general_assignment_bind_phase_scenarios.dart`
- `colonizethis_combat_test_support/lib/src/combat_mode_selection_scenarios.dart`

Completes §5 remaining resolver integration suites (battle general assignment + combat mode selection).

Combat test LOC: 1,921 → 1,580 physical lines (−341 in test files across slice 11).

## Wave — slice A (Refs #4196)

Delivered in this slice:

- Shared `RunnableScenario` / `runRunnableScenario` / `rs()` on `colonizethis_combat_test_support` `scenario_runner.dart` (mirrors `colonizethis_orders` harness pattern; adds `scenarioId` for combat table metadata).
- Removed ~29 near-identical per-family `*Scenario` class shells; all `*_scenarios.dart` tables now use `RunnableScenario` rows.
- Public list factory names and every `scenarioId` / `label` string preserved; `colonizethis_combat/test/**` runners unchanged.

## Wave — slice B (Refs #4196)

Delivered in this slice:

- Topic-split four god modules (>300 phys) along existing private-list seams:
  - `conflict_detection_scenarios` → core / ownership / order topic files + thin aggregator
  - `military_strength_scenarios` → player faction/filtering/multiplier + aggregate / era / cavalry files + aggregator
  - `combat_resolver_engagement_scenarios` → outcome / context topic files + aggregator
  - `combat_resolver_spy_civilian_scenarios` → spy conquest / civilian relocation / general morale files + aggregator
- Public list factory names (`detectConflictsScenarios`, `aggregateMilitaryStrengthForPlayerScenarios`, `aggregateStrengthScenarios`, `effectiveEraForFactionScenarios`, `cavalryFractionScenarios`, `combatResolverEngagementScenarios`, `combatResolverSpyCivilianScenarios`) and every `scenarioId` / `label` preserved; `colonizethis_combat/test/**` unchanged.

Deferred to follow-up slices on #4196: builder densify, CI file-size + LOC ratchets (target ≤6,800 package LOC).

### Slice C — remaining >220 files + `combat_resolver_test_support` split (PR #4207)

Delivered in this slice:

- Split `combat_resolver_test_support.dart` into player constants, land battle games, integration game builders, and unit/context helpers with a thin re-export aggregator.
- Topic-split remaining >220 phys scenario modules along existing list boundaries:
  - `combat_resolver_limits_scenarios` → deployment limits / general medals
  - `combat_resolver_probabilistic_scenarios` → core / outcome
  - `naval_combat_resolver_scenarios` → detect conflicts / normalize sides / resolver strength
  - `naval_combat_resolution_scenarios` → resolve sea battle / apply results / intercept probability
  - `pre_combat_index_scenarios` → destination / units / provinces / movement (+ shared test support)
  - `quick_battle_siege_scenarios` → siege core / initiative
- Every `packages/colonizethis_combat_test_support/lib/**/*.dart` file is now ≤ **220** physical lines; public factory names and `scenarioId` / `label` strings preserved; `colonizethis_combat/test/**` (207 tests) green.

Deferred to Slice D on #4196: package LOC densify toward ≤6,800, `tool/check_combat_test_support_*` CI ratchets, `SPEC/program/repo-lint.md` entries.

### Slice D — CI ratchets + traceability close-out (PR #4207)

Delivered in this slice:

- Added `tool/check_combat_test_support_file_size.dart` (per-file ≤220 phys) and `tool/check_combat_test_support_loc.dart` (package ≤7250 phys, measured ≈7242 post-wave).
- Registered `repo.combat_test_support_file_size` and `repo.combat_test_support_loc` in `tool/ct_repo_lint_manifest.yaml`.
- Unit tests: `test/check_combat_test_support_file_size_test.dart`, `test/check_combat_test_support_loc_test.dart`.
- Documented both rules in `SPEC/program/repo-lint.md`.

Final ceilings: per-file **220** phys; package LOC **7250** (shrink-only ratchet; baseline was 7,307 @ `396fa936`).

## Phase 4 — slice A (Refs #4284)

Delivered in this slice:

- Extracted `BattleContext` and `AttackingSide` from `conflict_detection.dart` into `battle_context.dart`.
- Package barrel exports `battle_context.dart`; `conflict_detection.dart` re-exports types for stable deep-import paths.
- `detectConflicts` remains in `conflict_detection.dart` (detection-only module).

Post-split physical lines (approx.): `battle_context.dart` **103**; `conflict_detection.dart` **207** (was 310 combined).

Deferred to slices B–D on #4284: Quick Battle apply/outcome split, land `resolveBattleContext` seams, `repo.combat_lib_file_size` CI ratchet.

## Phase 4 — slice B (Refs #4284)

Delivered in this slice:

- Moved `applyQuickBattleResultToGame` to `quick_battle_apply.dart` (world mutation separate from round-loop resolve).
- Moved round-limit terminal outcome to `resolveQuickBattleRoundLimitOutcome` in `quick_battle_resolver_outcome.dart`.
- `quick_battle_resolver.dart` re-exports apply for stable imports; package barrel exports `quick_battle_apply.dart`.

Post-split physical lines (approx.): `quick_battle_resolver.dart` **~210** (was 309); `quick_battle_apply.dart` **~75**; `quick_battle_resolver_outcome.dart` **~115** (was 79).

Deferred to slices C–D on #4284: land `resolveBattleContext` seams, `repo.combat_lib_file_size` CI ratchet.

## Phase 4 — slice C (Refs #4284)

Delivered in this slice:

- Extracted multi-attacker engagement loop from `resolveBattleContext` into `combat_resolver_multi_attacker_loop.dart` (`runLandBattleMultiAttackerLoop`).
- `combat_resolver.dart` is now a short orchestrator: setup → loop → post-battle → resolve → log.

Post-split physical lines (approx.): `combat_resolver.dart` **~85** (was 221); `combat_resolver_multi_attacker_loop.dart` **~175**.

Deferred to slice D on #4284: `repo.combat_lib_file_size` CI ratchet.

## Phase 4 — slice D (Refs #4284)

Delivered in this slice:

- Added `tool/check_combat_lib_file_size.dart` (per-file ≤280 phys; empty shrink-only grandfather list).
- Registered `repo.combat_lib_file_size` in `tool/ct_repo_lint_manifest.yaml`.
- Unit test: `test/check_combat_lib_file_size_test.dart`.
- Documented rule in `SPEC/program/repo-lint.md`.

Post-split max lib file: `quick_battle_resolver_engine.dart` **≈268** phys (ceiling **280**).

## Phase 5 — slice A (Refs #4545)

Delivered in this slice:

- Extracted `ProbabilisticRoundResult`, `ProbabilisticEngagementOutcome`, and round constants into `combat_resolver_probabilistic_types.dart`.
- Moved `_poissonSample` / `_selectCasualtiesWeighted` into `combat_resolver_probabilistic_casualties.dart`.
- `combat_resolver_probabilistic.dart` remains the barrel-exported entry for `resolveEngagementProbabilistic`; re-exports types.

Post-split physical lines (approx.): `combat_resolver_probabilistic.dart` **~157** (was 267); `combat_resolver_probabilistic_types.dart` **~45**; `combat_resolver_probabilistic_casualties.dart` **~75**.

Deferred to slices B–D on #4545: Quick Battle engine split, snapshot densify, 250 ratchet.

## Phase 5 — slice B (Refs #4545)

Delivered in this slice:

- Split `quick_battle_resolver_engine.dart` into single-concern siblings:
  - `quick_battle_resolver_engine_groups.dart` (group/CP bookkeeping)
  - `quick_battle_resolver_engine_strike.dart` (strike-strength math)
  - `quick_battle_resolver_engine_emplaced.dart` (emplaced mixed losses)
- `quick_battle_resolver_engine.dart` re-exports siblings; `#3448` copy-disposition marker preserved on `copyGroups`.

Post-split physical lines (approx.): `quick_battle_resolver_engine.dart` **~35** (was 268); largest sibling **~153** phys.

Deferred to slices C–D on #4545: snapshot densify, 250 ratchet.

## Phase 5 — slice C (Refs #4545)

Delivered in this slice:

- Replaced imperative `combat_engagement_snapshot_test.dart` (#4090 characterization) with `runLabeledScenarioGroup` runner.
- Added `combat_engagement_snapshot_scenarios.dart` under `test/combat/` (9 labeled rows; support-package LOC/file-size ratchets precluded a support-module home).

Post-split physical lines (approx.): `combat_engagement_snapshot_test.dart` **~10** (was 209); support scenario module **~220** phys.

Deferred to slice D on #4545: lib size CI ratchet 280→250.

## Phase 5 — slice D (Refs #4545)

Delivered in this slice:

- Lowered `combatLibFileSizeCeiling` to **250** with an empty grandfather list.
- Pinned constant in `test/check_combat_lib_file_size_test.dart`.
- Updated `tool/ct_repo_lint_manifest.yaml` title and `SPEC/program/repo-lint.md` `repo.combat_lib_file_size` row.

Post-split max lib file: `conflict_detection.dart` / `battle_general_assignment.dart` **≈213** phys (ceiling **250**).

