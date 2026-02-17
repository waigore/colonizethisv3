# sim_combat_montecarlo — Monte Carlo Combat Simulation

**SPEC/program** — CLI tool to run many probabilistic combat trials and aggregate results. References: [sim-combat.md](sim-combat.md), [combat-resolution.md](combat-resolution.md).

---

## Purpose and Scope

- **Purpose:** Run Monte Carlo simulations on scripted battle scenarios. For each battle, run N trials with the probabilistic resolver, then aggregate win rates and mean casualties.
- **Scope:** Same script format as [sim-combat.md](sim-combat.md). Uses `resolveEngagementProbabilistic` with distinct seeds per trial.

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

## Output

### Markdown Report

- Metadata: scenario, script, trials, base seed.
- Per-battle aggregate table: Battle Id, Attacker Str, Defender Str, Attacker Win %, Defender Win %, Stalemate %, Mutual Ann %, Mean Cas (A/D).

### JSON Log

Array of per-battle aggregates: id, attackerStrength, defenderStrength, trials, attackerWins, defenderWins, stalemates, mutualAnnihilation, attackerWinPct, defenderWinPct, stalematePct, mutualAnnPct, meanAttackerCasualties, meanDefenderCasualties.
