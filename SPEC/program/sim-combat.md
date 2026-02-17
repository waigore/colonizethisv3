# sim_combat — Combat Simulation Tool

**SPEC/program** — Standalone CLI tool to simulate combat resolution. Reuses Phase 3 combat rules. References: [combat.md](../game/combat.md), [combat-resolution.md](combat-resolution.md), [military-units.md](../game/military-units.md), [siege-mechanics.md](../game/siege-mechanics.md).

---

## Purpose and Scope

- **Purpose:** Deterministically run the combat resolver on scripted scenarios: attacker vs defender unit compositions, province (terrain, fort level), optional general/initiative inputs. Output winner, casualties, optional step log.
- **Owner:** Program layer (Dart CLI, e.g. `melo sim_combat`), implemented in a tools package that depends on `colonizethis_models`, `colonizethis_data`, and `colonizethis_logic`.
- **Scope:** No map or full game state. Constructs minimal battle input from script; delegates to the same combat resolver used in TurnResolver.

---

## CLI Interface

- Command: `melo sim_combat`.
- Arguments:
  - `--script <path>`: JSON script describing one or more battle scenarios. Required.
  - `--output <path>` (optional): path for Markdown report. Default: `sim_combat.md` in cwd.
  - `--json-output <path>` (optional): machine-readable log. If omitted, no JSON file.
  - `--seed <int>` (optional): RNG seed when formula uses variance. Same seed → identical results.

Validation errors (unknown unit type, invalid fort level, malformed script) abort the run.

---

## Script Format (JSON)

Top-level keys:

- `metadata`: scenario name.
- `battles`: array of battle objects.

Each battle object:

- `id`: string identifier.
- `attacker`: `{ "units": [ { "type": string, "medals": int } ], "generalMedals": int (optional) }`.
- `defender`: same structure. `type` must match regiment ids from [military-units.md](../game/military-units.md).
- `province`: `{ "fortLevel": 0|1|2|3, "terrain": string }` (terrain from config: e.g. plains, mountain, forest).
- `defenderFaction`: `"greatPower" | "minorNation" | "tribe"` for parity rules.

---

## Output

Per battle:

- Attacker/defender strength (after tactical stats, medals, modifiers).
- Winner (attacker | defender).
- Casualties per side (unit ids or counts).
- Province flip (if defender eliminated).

### Markdown Report

- Header with metadata.
- Per-battle table: id, attacker strength, defender strength, winner, casualties, province flip.

### JSON Log

Array of `{ "id": string, "attackerStrength": number, "defenderStrength": number, "winner": string, "casualties": { "attacker": [...], "defender": [...] }, "provinceFlip": boolean }`.

---

## Determinism

Same script and seed produce identical output. The combat resolver is deterministic per [combat-resolution.md](combat-resolution.md).
