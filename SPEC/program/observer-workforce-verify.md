# Observer workforce sustain verifier

**SPEC/program** — Verifier for the **15-regiment workforce sustain** metric from issue **#2692** Requirement §21. Lives in `tool/run_observer_game/lib/observer_workforce_verify.dart`. Consumes the `workerPool` block added to player rollups in `ObserverSnapshot` v3 (see [run_observer_game-tool.md](run_observer_game-tool.md)). Stakeholder decisions: GitHub **#2692**.

## Scope (this slice, S10a)

In scope:

- Schema reader: `WorkerPoolCounts workerPoolCountsForPlayer(Map snapshotJson, String playerId)` returns the player's pool counts or `WorkerPoolCounts.zero` for missing / malformed / v2 rollups.
- Per-GP verifier: `List<String> verifyPerGpWorkforceSustain({...})` checks each canonical Great Power (`gp1`–`gp6`) against the provisional thresholds and returns one human-readable failure line per failing threshold per GP.
- Disk reader: `List<String> verifyObserverWorkforceFromTraceDir(String tracesGameDir, {int endTurn = 100, ...})` loads `turn-<endTurn>.snapshot.json` and delegates to the per-GP verifier; reports a single `missing end snapshot: <path>` line when the file is absent.

Out of scope for this slice (tracked under #2692 S10 follow-up):

- `--verify-workforce` CLI flag wiring in `run_observer_game_cli.dart`.
- Nightly workflow integration in `.github/workflows/nightly.yml`.
- Food production (`grain + meat`) and luxury production (`refinedSugar` / `cigars` / `furHats`) checks from Requirement §21 bullets 3–4. These require new snapshot fields (production / stockpile rollups) and are gated by `kObserverWorkforceFoodLuxuryDeferred` in the verifier so future work can grep the marker.

## Provisional thresholds (v1; tunable in S10a)

Per Requirement §21 of issue **#2692**, recorded here as the source of truth for the verifier constants:

| Constant | Default | Meaning |
|----------|---------|---------|
| `kObserverWorkforceCanonicalTurn` | `100` | Turn whose snapshot is read by `verifyObserverWorkforceFromTraceDir`. |
| `kObserverWorkforceMinPeasants` | `15` | Lower bound on `peasants` per Great Power; covers one full 15-regiment build cycle plus a reservation buffer per `SPEC/game/workers-and-population.md` § Peasant reservation. |
| `kObserverWorkforceMinTrained` | `8` | Lower bound on `apprentices + journeymen + masters` per Great Power; effective-labour buffer for production chains. |
| `kObserverWorkforceFoodLuxuryDeferred` | `true` | Documents that food / luxury sustain checks are not enforced yet. |

S10a observer-trace analysis on **seed 42** (issue #2692 AC #7a) may revise these constants before the nightly gate (S10) is wired; the defaults above are the starting point.

## Acceptance

- Given an `ObserverSnapshot` v3 player rollup with `workerPool = {peasants: P, apprentices: A, journeymen: J, masters: M}`  
  When the System invokes `workerPoolCountsForPlayer(snapshot, playerId)` with that rollup's `playerId`  
  Then the System returns `WorkerPoolCounts(peasants: P, apprentices: A, journeymen: J, masters: M)` and `WorkerPoolCounts.trained == A + J + M`.

- Given a snapshot whose `players` list is missing, is not a list, or contains no entry for `playerId`  
  When the System invokes `workerPoolCountsForPlayer(snapshot, playerId)`  
  Then the System returns `WorkerPoolCounts.zero`.

- Given a snapshot where every `gp1`–`gp6` player rollup contains `peasants >= 15` and `apprentices + journeymen + masters >= 8`  
  When the System invokes `verifyPerGpWorkforceSustain(turnEndSnapshot: snapshot)` with default thresholds  
  Then the System returns an empty `List<String>`.

- Given a snapshot where exactly one Great Power (`gpX`) has `peasants < 15` AND `apprentices + journeymen + masters < 8` and all other Great Powers meet both thresholds  
  When the System invokes `verifyPerGpWorkforceSustain(turnEndSnapshot: snapshot)` with default thresholds  
  Then the System returns exactly **two** failure lines: one starting with `gpX peasants=` and one starting with `gpX trained=`, and no failure lines for any other Great Power.

- Given a trace directory containing no `turn-000100.snapshot.json`  
  When the System invokes `verifyObserverWorkforceFromTraceDir(tracesGameDir: dir)` with the default `endTurn`  
  Then the System returns a single failure line containing `missing end snapshot:` followed by the expected snapshot path.

- Given a trace directory containing a `turn-000050.snapshot.json` where every `gp1`–`gp6` has `peasants == 8` and `apprentices == 1`  
  When the System invokes `verifyObserverWorkforceFromTraceDir(tracesGameDir: dir, endTurn: 50)`  
  Then the System returns at least one failure line containing `peasants=8` and at least one containing `trained=1`.
