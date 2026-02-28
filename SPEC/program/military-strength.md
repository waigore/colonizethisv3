# Military Strength Aggregation

**SPEC/program** — API for computing a faction's total military strength for display (e.g. Game Overview tab in ctdev). Uses the same formula as the auto-resolve combat simulator. Reference: [combat-resolution.md](combat-resolution.md), [military-units.md](../game/military-units.md), [combat_resolver.dart](../../packages/colonizethis_logic/lib/src/combat_resolver.dart). This API uses **faction id** for ownership only and does **not** use province id (no province lookup); for identity rules see [world-model-identity.md](../game/world-model-identity.md).

---

## Responsibility

colonizethis_logic provides a public function that aggregates military strength for a faction. Used by the Running Game Screen's Game Overview tab and any UI that needs a single-number summary of a player's military power.

---

## Formula

Military strength = sum of army strengths = sum of unit strengths. Uses the same logic as `_aggregateStrength` in the combat resolver:

- **Unit strength:** (FPN + FPM) × medal multiplier. Medal multiplier: 1.0 (0 medals), 1.1 (1), 1.2 (2), 1.3 (3), 1.4 (4). Stats and multiplier from colonizethis_data.
- **Army strength:** Sum of unit strengths in that army.
- **Player/faction military strength:** Sum of all unit strengths owned by that faction (equivalently, sum of army strengths).

Effective era: Great Powers use era 4; Minor Nations use their `effectiveMilitaryLevel` (parity with max GP); Tribes use their `effectiveMilitaryLevel` (always 1, no parity). Units with stats above the effective era are downgraded to the era-equivalent regiment in the same category.

---

## API

`aggregateMilitaryStrengthForPlayer(Game game, String playerId) → double`

- **Input:** Current `Game`, faction id (player, minor, or tribe).
- **Output:** Total military strength (non-negative double).
- **Units considered:** All military units in `RegionData.units` (OW + NW) where `ownerId == playerId`.
- **Determinism:** Same inputs → same output. No RNG.

---

## Acceptance criteria

- Given a `Game` and a faction id (player, minor, or tribe), when the system calls the aggregation API, then the output equals the sum of unit strengths for all military units owned by that faction, with effective-era downgrade and medal multiplier (0–4 medals; multiplier 1.0–1.4 per Formula).
- Given the same `Game` and faction id, when the system calls the aggregation API multiple times, then the output is identical each time (deterministic; no RNG).
- Given a `Game`, when the system aggregates military strength for a faction, then only units in Old World and New World `RegionData.units` with `ownerId ==` that faction id are included; only units that have regiment stats (FPN, FPM, medal multiplier) count—civilians and ships are skipped.
- Given a Great Power faction, when the system applies effective era for strength calculation, then the effective era is 4. Given a Minor Nation, then the effective era is that faction's `effectiveMilitaryLevel` (parity). Given a Tribe, then the effective era is 1 per [factions.md](../game/factions.md).
- Given any caller, when the system aggregates military strength, then the API uses faction id for ownership only and does not perform province id lookups; see [world-model-identity.md](../game/world-model-identity.md) for identity rules.

---

## Location

colonizethis_logic. May live in a dedicated module (e.g. `military_strength.dart`) or as an exported function that reuses or calls the combat resolver's internal aggregation logic.
