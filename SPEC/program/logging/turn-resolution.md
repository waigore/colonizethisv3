# Logging — turn resolution

**SPEC/program/logging** — Annex to [logging.md](logging.md). Applies to **logic** package turn resolution, phase resolvers, order application, movement, naval resolution, economy phases, research, diplomacy, and combat orchestration.

---

## Info (phases and player-anchored results)

- **Turn frame:** **Info** `turn` (and `year` if available) at **start** and **end** of full turn resolution when exposed by the API.
- **Each phase:** **Info** **phase start** and **phase end** with `phase=<name>` and `turn=<n>`. Phase names must be stable grep tokens (e.g. `phase=production`, `phase=extraction`, `phase=consumption`, `phase=research`, `phase=diplomacy`, `phase=movement`, `phase=combat`, `phase=naval`, … per actual resolver order in code).

### App isolate runner (`TurnResolutionRunner`, #2160)

The app emits **info** / **debug** / **error** lines (under the app `logic` logger sub-prefix) for **session lifecycle** only (not a duplicate of per-phase logic logs):

- **Info** `logic: turn_resolution_runner session_start` with `sessionId=` and `gameId=`.
- **Debug** `logic: turn_resolution_runner isolate_spawned` with `sessionId=` after the worker isolate is created.
- **Info** `logic: turn_resolution_runner session_complete` with `sessionId=` and `outcome=success` when the isolate returns a terminal success payload.
- **Error** `logic: turn_resolution_runner session_complete` with `sessionId=` and `outcome=error` when the isolate reports a terminal error; **error** `logic: turn_resolution_runner isolate_spawn_failed` when isolate spawn fails; **error** `logic: turn_resolution_runner session_start_failed` when pre-spawn preparation fails (e.g. serialization before isolate spawn).
- **Next-turn UI (two shells, #2277):** The Flame-canvas path logs **`logic: next_turn_ui …`** from `game_screen.dart` (`_runFlameCanvasNextTurn`). The **map** path logs the same lifecycle with token **`logic: next_turn_ui_map …`** from `GameMapArea` (`game_map_area_part1.dart`): **`started`**, **`processing_dialog_painted`** (ms after confirm), **`session_started`**, optional **`phase`** at **debug**, **`session_done`**, **`external_result_handled`**, optional **`worker_trace_export_path`**, **`result_applied`**, **`terminal_error`** on failure, and **`cleanup_complete`**. Use these lines to attribute main-isolate time to modal paint vs spawn serialization vs decode/apply per surface.
- **Per-player work:** Where a phase processes **each player** (or GP), emit **info** **summary** lines: `playerId=` or `nationId=`, counts changed (orders applied, resources delta summary, research completion flag), and **high-level** diplomacy/combat outcomes. Avoid duplicating full state dumps at info.
- **Order engine:** **Info** for **batch** accept/reject summaries; **debug** for each validation branch (see [logging.md](logging.md) level split).
- **Movement / naval:** **Info** apply summaries per spec’d flows; **debug** for rejected move reasons already partially covered by tests — keep consistent tokens.

---

## Land combat (`logic` + stable tokens)

During the Combat phase, **land** resolution emits grep-oriented lines containing **`combat`** after the `logic` prefix (e.g. message body `combat conflict_detection start`). **Naval** combat: **info** battle outcome summaries; **debug** for fine-grained steps unless another spec overrides.

- **Conflict detection (info):** Start and end for the phase with `turn` and `battleContexts` count from turn combat orchestration (not isolated unit tests only).
- **Per battle (info):** `combat battle_start` with `turn`, `battleIndex`, prefixed `regionId` and `provinceId`, `defenderFactionId`, `attackerSides`, `attackerUnitsTotal`, `mode=autoResolve|quickBattle`.
- **Per engagement (debug, auto-resolve):** `combat engagement` with `attackerFactionId`, `result` (enum name), `attCasualties`, `defCasualties` (counts only).
- **World application (info):** `combat battle_apply` with `mode`, `provinceFlipped`, casualty counts as applicable, `ownerAfter`; Quick Battle includes `winner`.

Use **`key=value`** segments separated by spaces where practical (e.g. `rg 'combat battle_apply'` on the full message).

---

## Land combat — acceptance criteria

- **Given** a game state after Movement where at least one land `BattleContext` exists for the turn, **when** the system runs the Combat phase (`_runCombatPhase`), **then** the logger emits at **info** a message containing `combat conflict_detection start` with `turn=<integer>` and a message containing `combat conflict_detection end` with the same `turn` and `battleContexts=<non-negative integer>`.

- **Given** a land `BattleContext` processed in that phase, **when** the system begins resolving that battle, **then** the logger emits at **info** a message containing `combat battle_start` with `regionId=`, `provinceId=`, `defenderFactionId=`, `attackerSides=<integer>`, `attackerUnitsTotal=<integer>`, and `mode=autoResolve` or `mode=quickBattle`.

- **Given** auto-resolve for a `BattleContext` with at least one executed engagement, **when** each engagement completes, **then** the logger emits at **debug** a message containing `combat engagement` with `attackerFactionId=<string>`, `result=<EngagementResult enum name>`, `attCasualties=<integer>`, and `defCasualties=<integer>`.

- **Given** auto-resolve completes for a `BattleContext`, **when** the system applies the result to world state, **then** the logger emits at **info** a message containing `combat battle_apply` with `mode=autoResolve`, `provinceFlipped=true` or `provinceFlipped=false`, `casualtiesApplied=<integer>`, `ownerAfter=<faction id string or empty if unknown>`.

- **Given** Quick Battle completes for a `BattleContext`, **when** the system applies the result to world state, **then** the logger emits at **info** a message containing `combat battle_apply` with `mode=quickBattle`, `winner=<QuickBattleWinner enum name>`, `provinceFlipped=true` or `provinceFlipped=false`, and per-side casualty counts (`attCasualties`, `defCasualties`).
