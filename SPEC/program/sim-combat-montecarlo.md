# sim_combat_montecarlo — Monte Carlo Combat Simulation

**SPEC/program** — CLI tool to run many probabilistic combat trials and aggregate results. References: [sim-combat.md](sim-combat.md), [combat-resolution.md](combat-resolution.md).

---

## Purpose and Scope

- **Purpose:** Run Monte Carlo simulations on scripted battle scenarios. For each battle, run N trials with the probabilistic resolver, then aggregate win rates and mean casualties.
- **Scope:** Same script format as [sim-combat.md](sim-combat.md). Uses `resolveEngagementProbabilistic` with distinct seeds per trial.

---

## Script Format and Validation

- Script format is the same as [sim-combat.md](sim-combat.md): `metadata`, `battles` array; each battle has `id`, `attacker`, `defender`, `province`, and optional `defenderFaction`. Attacker and defender each have `units` and optional `generalMedals`.
- **Validation:** As in sim-combat, validation errors abort the run with non-zero exit and a clear error message. Invalid inputs: unknown unit type (not in regiment catalog), fortLevel outside 0–3, malformed script (e.g. missing required keys or wrong types).

---

## CLI Interface

- Command: `melos run sim_combat_montecarlo`.
- Arguments:
  - `--script <path>`: JSON script (same format as sim_combat). Required.
  - `--trials <N>`: number of trials per battle. Default: 1000.
  - `--seed <int>`: base seed; trial i uses seed + i. Optional; if omitted, random base.
  - `--output <path>`: Markdown report path. Default: `sim_combat_montecarlo.md`.
  - `--json-output <path>`: JSON log path. Optional.

---

## Determinism

- When `--seed` is provided, the same script and seed produce identical Markdown and JSON output. Trial index `i` uses RNG seed `baseSeed + i`.
- When `--seed` is omitted, base seed is derived from the current time, so each run yields different results.

---

## Defender Effective Level

- The sim uses a **fixed defender effective military level** (4) for all trials. The script field `defenderFaction` is accepted for script format parity with sim-combat but does not change the level in this tool; in-game rules for minor/tribe level are defined in [factions.md](../game/factions.md) and are not applied here.

---

## Output

### Markdown Report

- Metadata: scenario, script, trials, base seed.
- Per-battle aggregate table: Battle Id, Attacker Str, Defender Str, Attacker Win %, Defender Win %, Stalemate %, Mutual Ann %, Mean Cas (A/D).

### JSON Log

Array of per-battle aggregates: id, attackerStrength, defenderStrength, trials, attackerWins, defenderWins, stalemates, mutualAnnihilation, attackerWinPct, defenderWinPct, stalematePct, mutualAnnPct, meanAttackerCasualties, meanDefenderCasualties.

---

## Acceptance Criteria

- Given a valid script and `--seed N`, two runs produce identical Markdown and JSON output.
- Invalid script (unknown unit type, fortLevel ∉ {0,1,2,3}, or malformed JSON/structure) aborts with non-zero exit and a clear error message.
- Per-battle aggregate table includes: Battle Id, Attacker Str, Defender Str, Attacker Win %, Defender Win %, Stalemate %, Mutual Ann %, Mean Cas (A/D).
- Trial index `i` uses seed `baseSeed + i` when a base seed is provided.
