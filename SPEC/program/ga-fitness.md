# GA Fitness Function

## Purpose

Score AI profile performance from `run_observer_game` output so the GA runner
(#3439) can select, recombine, and mutate `AiProfile`s (#3436). This module is a
**pure computation**: it reads one game's final `ObserverSnapshot` and the
`run-summary.json`, and returns a per-player `FitnessScore`. It does **not** run
games, mutate parameters, or aggregate across the GA's `k` games (that belongs to
#3439).

## Source Of Truth

- Game behavior remains defined by `SPEC/game/**`.
- Snapshot/run-summary shapes are produced by `SPEC/program/run_observer_game-tool.md`
  (`observerSnapshotSchemaVersion = 4`, `runSummarySchemaVersion = 2`). Only fields
  present there are consumed; components needing unavailable data are dropped.

## Inputs

- `snapshot`: decoded final `ObserverSnapshot` JSON map (last turn before
  termination).
- `runSummary`: decoded `run-summary.json` map (for `declared_winner_player_id`).
- `capitalProvinceByPlayerId`: `Map<String, String>` mapping each playerId to its
  capital province id. Supplied by the caller (#3439) from game setup; capital ids
  are not in the snapshot.

## Output

`computeFitness(snapshot, runSummary, {required capitalProvinceByPlayerId})`
returns `Map<String, FitnessScore>` keyed by `playerId` for every player in
`snapshot.players`. `FitnessScore` exposes `economic`, `military`, `diplomatic`
(each normalized to `[0, 1]`), and `total` (the final fitness).

## Formula

```
base   = 0.4 × economic + 0.4 × military + 0.2 × diplomatic   // base ∈ [0, 1]
scored = base × winMultiplier                                  // ×2.0 winner else ×1.0
total  = scored + shapingPenalties                             // penalties additive, ≤ 0
```

### Category scores (each normalized to `[0, 1]`)

Each category is the **equal-weight mean** of its per-component normalized values.
Per component: take the player's raw value, floor it at `0`, then divide by the
game-wide max of that component. If a component's game-max is `0`, every player
scores `0` for that component. **Exception:** province share is already a
`[0, 1]` fraction of all `provinceOwnershipSorted` rows and is used **directly**
(not re-normalized among GPs) so minor/tribe-owned provinces lower GP scores
(#3447).

| Category (weight) | Components (equal weight) | Raw source |
|---|---|---|
| Economic (0.4) | treasury; worker count; province share | `treasuryPounds`; sum of `workerPool` tiers; `ownedProvinces / totalProvinces` where `totalProvinces` is the count of all `provinceOwnershipSorted` rows (GP, minor, and tribe ownership included) |
| Military (0.4) | regiment count; province share; strength proxy | sum of `regiments=` over `militaryArmySummariesSorted` for `owner=playerId`; province share (same as economic); `regimentLikeUnitCountHint` (fallback `greatPowerPowerScore` when the hint is absent) |
| Diplomatic (0.2) | alliance count; non-war relations | `diplomacyRelationSummariesSorted` rows involving the player with `lvl=allied`; rows involving the player that are `peace` |

### Win multiplier

`winMultiplier = 2.0` when `playerId == runSummary['declared_winner_player_id']`,
else `1.0`. Applied before shaping penalties.

### Shaping penalties (additive, applied after the win multiplier)

A winner is **not** exempt. Each penalty uses only snapshot-derivable data.

| Penalty | Condition | Value |
|---|---|---|
| Bankruptcy | `treasuryPounds <= 0` | -50 |
| Capital loss | capital province (from `capitalProvinceByPlayerId`) not owned by the player | -100 |
| Zero regiments | summed regiment count == 0 | -80 |
| Military-heavy + broke | `regiments / (regiments + workerTotal) > 0.9` AND `treasuryPounds <= 0` | -30 |

Capital loss is evaluated only when `capitalProvinceByPlayerId` contains the
player; an absent capital id skips that penalty. A capital id present in the map
but not owned by the player (including an unowned or other-owned province row)
triggers the penalty. The military-heavy ratio is `0` when the denominator is `0`.

### NPC / minor / tribe world pressure (#3447)

Province share replaces raw province count in economic and military categories so
fitness reflects **political map density**, not a two-GP vacuum. When minors and
tribes own provinces in `provinceOwnershipSorted`, the same absolute GP province
holdings yield a **lower** share than in a sparse world, penalizing head-to-head
normalization that ignored NPC territory. Diplomatic components already count any
relation row involving the scored GP (including minor/tribe factions when present
in `diplomacyRelationSummariesSorted`).

## Non-Scope

- Game execution, parameter mutation, multi-game (`k`) aggregation, snapshot
  schema extensions. Grain/cargo/firepower/tribute/per-player improvement data are
  dropped (not in snapshot v4).

## Acceptance Criteria

- Given a snapshot with `players` and ownership/army/diplomacy summaries and a
  `capitalProvinceByPlayerId` for each player, when `computeFitness` runs, then it
  returns one `FitnessScore` per player keyed by `playerId`, each with
  `economic`, `military`, `diplomatic`, and `total` fields.
- Given two players where one has strictly greater treasury, workers, and
  provinces and all else equal, when scored, then the stronger player's `economic`
  is `1.0` and is greater than the weaker player's `economic`.
- Given a component whose game-wide max raw value is `0` across all players, when
  scored, then every player's normalized value for that component is `0` and does
  not produce a division-by-zero error.
- Given a player with negative `treasuryPounds`, when the economic treasury
  component is normalized, then that player's floored treasury raw is `0` (no
  negative normalized contribution).
- Given `runSummary['declared_winner_player_id'] == P`, when scored, then `P`'s
  `total` equals `base(P) × 2.0` plus `P`'s shaping penalties, and a non-winner's
  multiplier is `1.0`.
- Given a player with `treasuryPounds <= 0`, when scored, then `-50` is included
  in that player's `total` after the win multiplier.
- Given a player whose `capitalProvinceByPlayerId` capital province has an
  `ownerId` other than that player (or is unowned), when scored, then `-100` is
  included in that player's `total`.
- Given a player with a summed regiment count of `0`, when scored, then `-80` is
  included in that player's `total`.
- Given a player with `regiments / (regiments + workerTotal) > 0.9` and
  `treasuryPounds <= 0`, when scored, then `-30` is additionally included.
- Given the same snapshot and run-summary inputs, when `computeFitness` is called
  twice, then both results are identical (deterministic).
- Given two snapshots identical except that player `P` owns more provinces and has
  more regiments and treasury in the second, when both are scored, then `P`'s
  `total` in the second is strictly greater than in the first.
- Given two snapshots where GP `P` owns the same absolute province count but the
  second includes additional minor/tribe-owned provinces in
  `provinceOwnershipSorted`, when both are scored, then `P`'s province-share
  components in economic and military are strictly lower in the second than in
  the first.
