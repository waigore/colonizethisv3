# Combat dedup refactor trace (Refs #3865)

Maps consolidated scenario modules to preserved test descriptions, source files, and originating issue AC references.

Baseline: `dev` @ `df7bbd62` (combat test LOC 6,573 physical lines across 31 `*_test.dart` files before slice 1).

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

Deferred: `repo.combat_test_duplicate_descriptions` — blocked until `combat_resolver_test_part1_*` duplicate descriptions are resolved during resolver scenario migration (slice 3+).

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
