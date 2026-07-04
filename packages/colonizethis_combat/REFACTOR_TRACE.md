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

Deferred: `repo.combat_test_duplicate_descriptions` — blocked until `combat_resolver_test_part1_*` duplicate descriptions are resolved during resolver scenario migration (slice 2+).
