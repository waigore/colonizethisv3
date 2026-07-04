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
