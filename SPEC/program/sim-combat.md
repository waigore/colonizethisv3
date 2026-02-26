# sim_combat — Combat Simulation Tool

**SPEC/program** — Standalone CLI tool to simulate probabilistic combat resolution on scripted scenarios. References: [combat.md](../game/combat.md), [combat-resolution.md](combat-resolution.md), [military-units.md](../game/military-units.md), [siege-mechanics.md](../game/siege-mechanics.md).

---

## Purpose and Scope

- **Purpose:** Run the probabilistic engagement resolver on scripted scenarios: attacker vs defender unit compositions, province (terrain, fort level). Output winner, casualties, and detailed per-round formula and probability stats.
- **Owner:** Program layer (Dart CLI, e.g. `melos run sim_combat`), implemented in a tools package that depends on `colonizethis_models`, `colonizethis_data`, and `colonizethis_logic`.
- **Scope:** No map or full game state. Constructs minimal battle input from script; delegates to the probabilistic resolver (see [combat-resolution.md](combat-resolution.md) *Probabilistic engagement*).

---

## CLI Interface

- Command: `melos run sim_combat`.
- Arguments:
  - `--script <path>`: JSON script describing one or more battle scenarios. Required.
  - `--output <path>` (optional): path for Markdown report. Default: `sim_combat.md` in cwd.
  - `--json-output <path>` (optional): machine-readable log. If omitted, no JSON file.
  - `--seed <int>` (optional): RNG seed. When omitted, uses `DateTime.now().millisecondsSinceEpoch` so each run produces different results. When provided, same script and seed produce identical output.

Validation errors (unknown unit type, invalid fort level, malformed script) abort the run.

---

## Script Format (JSON)

Top-level keys:

- `metadata`: scenario name.
- `battles`: array of battle objects.

Each battle object (required keys: `id`, `attacker`, `defender`, `province`; missing or wrong type = validation error):

- `id`: string identifier.
- `attacker`: `{ "units": [ { "type": string, "medals": int } ], "generalMedals": int (optional) }`.
- `defender`: same structure. `type` must match regiment ids from [military-units.md](../game/military-units.md).
- `province`: `{ "fortLevel": 0|1|2|3, "terrain": string }` (terrain from config: e.g. plains, mountain, forest).
- `defenderFaction`: optional; `"greatPower" | "minorNation" | "tribe"` for parity rules.

---

## Output

Per battle: attacker/defender strength, winner, casualties, province flip, and per-round details.

### Markdown Report

- Header with metadata (scenario, script, seed, model description).
- Per battle: initial strengths (raw, terrain modifiers, fort, effective E_a/E_d).
- Per round: E_a, E_d; P(attacker hits), P(defender hits) with clamp; λ_defender, λ_attacker; sampled casualties; unit ids lost; remaining counts.
- Outcome: winner, province flip, total casualties.
- Summary table: id, attacker strength, defender strength, winner, province flip, casualties (A/D).

### JSON Log

Array of `{ "id": string, "attackerStrength": number, "defenderStrength": number, "winner": string, "casualties": { "attacker": [...], "defender": [...] }, "provinceFlip": boolean }`.

---

## Determinism

When `--seed` is provided, same script and seed produce identical output. When omitted, the seed is derived from the current time, so each run yields different results. The probabilistic resolver is deterministic given its inputs per [combat-resolution.md](combat-resolution.md).
