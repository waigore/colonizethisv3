# Military Strength Aggregation

**SPEC/program** — API for computing a faction's total military strength for display (e.g. Game Overview tab in ctdev). Uses the same formula as the auto-resolve combat simulator. Reference: [combat-resolution.md](combat-resolution.md), [military-units.md](../game/military-units.md), [combat_resolver.dart](../../packages/colonizethis_logic/lib/src/combat_resolver.dart).

---

## Responsibility

colonizethis_logic provides a public function that aggregates military strength for a faction. Used by the Running Game Screen's Game Overview tab and any UI that needs a single-number summary of a player's military power.

---

## Formula

Military strength = sum of army strengths = sum of unit strengths. Uses the same logic as `_aggregateStrength` in the combat resolver:

- **Unit strength:** (FPN + FPM) × medal multiplier. Medal multiplier: 1.0 (0 medals), 1.1 (1), 1.2 (2), 1.3 (3), 1.4 (4). Stats and multiplier from colonizethis_data.
- **Army strength:** Sum of unit strengths in that army.
- **Player/faction military strength:** Sum of all unit strengths owned by that faction (equivalently, sum of army strengths).

Effective era: Great Powers use era 4; Minor Nations and Tribes use `effectiveMilitaryLevel`. Units with stats above the effective era are downgraded to the era-equivalent regiment in the same category.

---

## API

`aggregateMilitaryStrengthForPlayer(Game game, String playerId) → double`

- **Input:** Current `Game`, faction id (player, minor, or tribe).
- **Output:** Total military strength (non-negative double).
- **Units considered:** All military units in `RegionData.units` (OW + NW) where `ownerId == playerId`.
- **Determinism:** Same inputs → same output. No RNG.

---

## Location

colonizethis_logic. May live in a dedicated module (e.g. `military_strength.dart`) or as an exported function that reuses or calls the combat resolver's internal aggregation logic.
