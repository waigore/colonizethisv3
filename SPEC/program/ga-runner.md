# GA Runner Tool

## Purpose

Orchestrate genetic-algorithm optimization of `AiProfile` parameters (#3436) by
running `run_observer_game` sessions with `--profiles`, scoring outcomes via
`computeFitness` (#3438), and applying selection/crossover/mutation. Refs #3439.

## CLI

```
melos run ga_runner -- --config <path>     Start a new GA run
melos run ga_runner -- --resume <dir>      Resume from saved state
melos run ga_runner -- --help              Usage
```

Exit codes: **0** success or already-complete resume; **1** config/resume/seed
error; **130** SIGINT (last completed generation persisted).

## Configuration (`ga-config.json`)

| Field | Default | Meaning |
|---|---|---|
| `population_size` | 20 | Profiles per generation |
| `games_per_profile` | 5 | Observer games (`k`) scored per profile per generation |
| `max_generations` | 100 | Generation count |
| `game_player_count` | 2 | Must match `selectedGreatPowerIds.length` in setup |
| `max_turns` | 200 | Observer `--max-turns` |
| `seed_profiles_dir` | required | Directory of seed `AiProfile` JSON (`*.json`) |
| `game_setup_config` | required | `GameSetupConfig` JSON (`init_game`-compatible) |
| `output_dir` | `output/` | Parent directory for run folders |
| `seed` | optional | Master RNG seed for pairing/mutation. Omit to generate one from entropy (see **Master seed resolution**) |
| `seven_gp_games_per_profile` | 1 | Observer games per profile in the 7-GP stage (`0` disables the stage) |
| `stage_fitness_weights.two_player` | 0.5 | Weight for 2-player stage fitness |
| `stage_fitness_weights.seven_gp` | 0.5 | Weight for 7-GP stage fitness |
| `seven_gp_opponent_selection` | `top_fitness` | Prior-winner ordering policy: `top_fitness` (fitness desc, generation asc tiebreak) or `random` (deterministic seeded shuffle). Other values fail config parse (exit `1`) |
| `seven_gp_fallback_default_ai_seats` | 3 | Default-AI seats when prior-winner pool is insufficient |
| `seven_gp_fallback_randomized_ai_seats` | 3 | Randomized-AI seats when prior-winner pool is insufficient |
| `seven_gp_use_blessed_profiles` | false | Include blessed manifest profiles in opponent pool |

The 2-player stage keeps `game_player_count = 2` in `game_setup_config`. The
7-GP stage uses a derived 7-GP setup (`allGreatPowerIds`) built with the same
minor/tribe constraints. Refs #3488.

## Multi-stage evaluation (Refs #3488)

Per profile, per generation:

1. **2-player stage:** `games_per_profile` observer games with the 2-GP setup;
   subject is always `gp1`; stage fitness = mean of successfully scored `gp1`
   totals; all games fail → stage fitness `0.0`.
2. **7-GP stage:** unless skipped (zero successfully scored 2-player games),
   `seven_gp_games_per_profile` observer games with the derived 7-GP setup;
   subject is always `gp1` (same `AiProfile` as the 2-player stage); six
   opponent seats (`gp2`–`gp7`) from prior generation winners, optional blessed
   profiles, then default seed leaders and randomized-AI fallback (`3`+`3` by
   default when no prior winners).

**Per-generation fitness:**

- When the 7-GP stage runs:  
  `(w2p × fitness_2p + w7gp × fitness_7gp) / (w2p + w7gp)` using
  `stage_fitness_weights` (each weight finite and > 0).
- When the 7-GP stage is skipped (all 2-player games failed): `fitness_2p`
  only (typically `0.0`).

Stages run for every profile before selection/evolution. Round artifacts:
`gen-NNN/<slot>-gXX` (2-player) and `gen-NNN/<slot>-7gp-gXX` (7-GP).

**Opponent selection modes (`seven_gp_opponent_selection`):** Selects the order
in which eligible prior-generation winners are seated into the six opponent
seats before blessed/default/randomized fallback fill. Selection never reorders
the downstream blessed → default-leader → randomized fallback stages and never
seats the subject profile.

- `top_fitness` (default): rank prior winners by fitness descending, breaking
  ties by generation ascending, then seat in that order.
- `random`: seat prior winners in a deterministic seeded shuffle. The shuffle
  RNG is seeded by `deriveSevenGpSelectionSeed(master_seed, generation,
  subjectIndex)` so the seating order is identical for fixed master seed,
  generation, subject index, and prior-winner pool, and is independent of the
  randomized-AI fallback RNG stream.

### Mid-generation resume (Refs #3488)

When SIGINT arrives during the **7-GP stage** after all 2-player games for the
in-progress generation have completed, the runner persists an
`evaluation_checkpoint` in `run-state.json` with `evaluation_stage: seven_gp`,
per-slot stage score arrays, and the next `profile_index` / `game_index`. The
`current_generation` field remains at the last **fully completed** generation.

`ga_runner --resume` continues the interrupted generation from the checkpoint:
completed 2-player artifacts are not replayed; only unfinished 7-GP games run.
SIGINT during the 2-player stage still abandons the in-progress generation with
no checkpoint (unchanged).

## Master seed resolution (Refs #3486)

The master `seed` drives pairing/mutation (`Random(config.seed)`) and per-game
seed derivation (`deriveGameSeed`). It is **optional**: when the key is absent
(or `null`), the runner generates one via `Random.secure()` as a non-negative
32-bit integer (`[0, 2^32)`), assigns it into the resolved `GaConfig`, persists
it in `run-state.json` (`config.seed`), and emits `ga:master_seed seed=<n>
source=entropy` at run start. A present-but-non-integer `seed` is a config error
(`FormatException`, exit **1**). An explicit integer is preserved unchanged
(emitted `source=config`) and yields identical evolution/derivation as before.
`--resume` reuses the persisted integer seed and never regenerates. No other seed
semantics change.

## GA setup profile (Refs #3447)

GA observer games must produce **realistic** worlds matching the player-app
province-assignment invariants (full non-empty ownership, app-default per-GP Old
World share, mandatory minors/tribes ≥ 3 each), not the sparse zero-minor maps
used previously. `GaConfig.fromJson` rejects (`FormatException`, exit **1**) any
`game_setup_config` with `minorNationCount < 3` or `tribeCount < 3`. Per-faction
targets, budget scaling, and the orphan-continent rule are normative in
**[ga-setup-profile.md](ga-setup-profile.md)**.

## Observer contract

The runner invokes (from repo root):

```
melos run run_observer_game -- \
  --config <round>/setup.json \
  --profiles <round>/profiles/ \
  --max-turns <max_turns> \
  --seed <per-game-seed> \
  --output <round>/
```

Final snapshot: highest `turn-NNNNNN.snapshot.json` under
`<round>/observer-traces/<gameId>/`. `run-summary.json` in the same directory.
Capital provinces for fitness are resolved once per game via `runInitGame` with
the same setup/seed and written to `<round>/capitals.json`.

## Genetic operators

- **Initialization:** load all `*.json` seeds from `seed_profiles_dir`; the first
  seven (sorted by basename) seed the population; remaining slots are mutated
  clones of random seeds.
- **Selection:** sort by fitness descending; elite top 2 unchanged; fill remaining
  slots with tournament(size 3) parents + uniform crossover + 5% per-parameter
  Gaussian mutation (`σ = 0.05 × (max − min)`, clamped to registry bounds;
  integers rounded).
- **Generation fitness:** when the 7-GP stage runs, weighted mean of 2-player and
  7-GP stage means (see **Multi-stage evaluation**); otherwise the 2-player
  stage mean only. Failed games discarded per stage; all-failed stage → `0.0`;
  non-finite treated as failure.

## Persistence

Atomic writes at **completed-generation** boundaries only (`run-state.json` temp +
rename). SIGINT abandons the in-progress generation; resume continues at
`current_generation + 1`. Schema version **1**; unknown version exits **1**.

Directory layout under `<output_dir>/<run-id>/`:

```
run-state.json
profiles/profile-NNN.json
gen-NNN/fitness.json
gen-NNN/best-profile.json
best-overall-profile.json
history.json
```

On run completion (all generations finished) the runner writes
`best-overall-profile.json` at the run root: the `AiProfile` JSON of the
best-overall member (the `gen-NNN/best-profile.json` from `best_overall.generation`).
The export is idempotent: resuming an already-complete run re-writes it without
re-running games.

## Acceptance criteria

- Given a valid `ga-config.json`, when the operator runs `ga_runner --config`,
  then the system creates a run directory, seeds the population from
  `seed_profiles_dir`, and completes generation 0 scheduling.
- Given a completed generation, when state is persisted, then `run-state.json`
  records `current_generation` and the full population metadata and
  `profiles/profile-NNN.json` round-trip through resume.
- Given tournament selection with a fixed RNG seed, when parents are chosen twice
  with identical inputs, then the same parents are selected (deterministic).
- Given uniform crossover with fixed RNG, when two parents are crossed, then each
  child parameter is within registry bounds and equals one parent's value.
- Given mutation with fixed RNG, when a parameter is marked for mutation, then the
  new value is clamped to `[minValue, maxValue]` and integer params are integral.
- Given a failed observer game for one profile round, when generation fitness is
  computed, then that game is omitted from the average and the run continues.
- Given all `k` games fail for a profile, when generation fitness is computed,
  then the profile receives fitness `0.0` for that generation.
- Given SIGINT during a generation, when the handler runs, then the last
  completed generation remains on disk and the process exits **130**.
- Given `ga_runner --resume` on a completed run (`current_generation ==
  max_generations`), then the system logs completion and exits **0** without
  re-running games.
- Given a GA run completes all generations, when the final generation is
  persisted, then the system writes `best-overall-profile.json` at the run root
  whose `AiProfile` JSON equals the `gen-NNN/best-profile.json` of the
  `best_overall.generation`.
- Given `ga_runner --resume` on an already-complete run with
  `best-overall-profile.json` absent, when resume runs, then the system
  re-writes `best-overall-profile.json` from the best-overall generation and
  exits **0** without re-running games.
- Given a `ga-config.json` whose `game_setup_config.minorNationCount` is `0`,
  `1`, or `2`, when `GaConfig.fromJson` parses it, then the system throws a
  `FormatException` (CLI exit **1**) naming the minimum of 3 minors.
- Given a `ga-config.json` whose `game_setup_config.tribeCount` is `0`, `1`, or
  `2`, when `GaConfig.fromJson` parses it, then the system throws a
  `FormatException` (CLI exit **1**) naming the minimum of 3 tribes.
- Given a profile whose 2-player stage has at least one successfully scored game,
  when generation evaluation runs with `seven_gp_games_per_profile > 0`, then the
  runner schedules a 7-GP stage for that profile before finalizing generation
  fitness.
- Given a profile whose 2-player stage has zero successfully scored games, when
  generation fitness is computed, then the 7-GP stage is skipped and generation
  fitness equals the 2-player stage fitness (`0.0`).
- Given both stages run for a profile, when per-generation fitness is computed,
  then the system applies the weighted formula from **Multi-stage evaluation**
  using configured `stage_fitness_weights`.
- Given generation 0 with zero prior GA winners, when building a 7-GP roster,
  then all six opponent seats use the configured default-AI and randomized-AI
  fallback counts (defaults `3` + `3`).
- Given interruption during the 7-GP stage after all 2-player games completed,
  when `ga_runner --resume` continues, then completed 2-player artifacts are
  not replayed and only unfinished 7-GP games resume from `evaluation_checkpoint`.
- Given interruption during the 2-player stage, when `ga_runner --resume`
  continues, then the runner resumes at the last fully completed generation
  (no partial 2-player checkpoint).
- Given a `ga-config.json` whose `seven_gp_opponent_selection` is `random`, when
  `GaConfig.fromJson` parses it, then the system does not throw and
  `config.sevenGpOpponentSelection == 'random'`.
- Given a `ga-config.json` whose `seven_gp_opponent_selection` is any value
  other than `top_fitness` or `random` (for example `most_wins`), when
  `GaConfig.fromJson` parses it, then the system throws a `FormatException`
  (CLI exit **1**) naming the allowed values.
- Given `seven_gp_opponent_selection = random` and a fixed master seed,
  generation, subject index, and prior-winner pool of at least two distinct
  winners, when `buildSevenGpOpponentRoster` runs twice, then both invocations
  seat the prior winners in the identical order (deterministic seeded shuffle).
- Given `seven_gp_opponent_selection = random`, when the roster is built, then
  the subject profile is never seated as an opponent and every eligible prior
  winner (up to the six seats) is seated before blessed/default/randomized
  fallback fill.

### Master seed resolution ACs (Refs #3486)

- Given a valid `ga-config.json` with no top-level `seed` key, when the operator
  runs `ga_runner --config`, then `GaConfig.fromJson` does not throw and the
  resolved `config.seed` is a non-negative integer in `[0, 2^32)`.
- Given a config parsed with no `seed` key, when the resolved config is
  serialized (`toJson`, as persisted in `run-state.json`), then `seed` is present
  as the resolved integer value.
- Given a run started from a config with no `seed` key, when generation starts,
  then the runner emits an operator-visible line containing
  `ga:master_seed seed=<n> source=entropy` before observer scheduling.
- Given a config whose `seed` is an integer `7`, when `GaConfig.fromJson` parses
  it, then `config.seed == 7` and re-parsing `config.toJson()` yields the same
  seed (explicit-seed determinism preserved on resume).
- Given a config whose `seed` is present but not an integer (for example `"abc"`
  or `1.5`), when `GaConfig.fromJson` parses it, then the system throws a
  `FormatException` (CLI exit **1**) naming `seed must be an integer`.
- Given a persisted `run-state.json` whose `config.seed` is `12345`, when the run
  is resumed, then `loadRunState` reuses `config.seed == 12345` and no new master
  seed is generated.

GA setup profile builder ACs are normative in
[ga-setup-profile.md](ga-setup-profile.md).

## Blessing / graduation (Refs #3444)

```
melos run ga_runner -- bless --run <dir> --name <profile-name> [--profile <slot-id>] [--force]
melos run ga_runner -- compare --baseline <dir> --candidate <dir>
melos run ga_runner -- compare --baseline-name <name> --candidate <dir>
melos run ga_runner -- list --run <dir>
```

- **`bless`** copies a completed-run profile JSON to
  `app/assets/profiles/<name>.json` and updates `manifest.json` (schema below).
  Default source is `best_overall.profile_id`; `--profile` selects a slot id.
  Duplicate names exit **2** unless `--force` (in-place manifest replace).
- **`compare`** prints side-by-side `best_fitness_per_generation` curves and a
  parameter diff of best-overall profiles. `--baseline` and `--baseline-name`
  are mutually exclusive; `--baseline-name` resolves `source_run_id` from the
  manifest and locates the run directory as a sibling of `--candidate`.
- **`list`** prints final-generation population rows: slot id, last fitness,
  `generations_survived`, display name.

### Blessed profile manifest (`app/assets/profiles/manifest.json`)

```json
{
  "profiles": [
    {
      "name": "aggressive_v2",
      "source_run_id": "ga-run-20260601-120000",
      "source_profile_id": "profile-007",
      "source_fitness": 156.2,
      "blessed_at": "2026-06-02T10:00:00Z"
    }
  ]
}
```

At most one manifest entry per profile name.
