# Debug console package internals (TDD)

Authorizes shared parse/execute abstractions inside `packages/colonizethis_debug_console`. User-facing command semantics remain in [debug-console-panel.md](../ui/debug-console-panel.md).

## Parse pipeline

1. Tokenize slash input (`DebugConsoleCommandParser.parse`).
2. Dispatch on command verb.
3. Validate args via shared helpers in `lib/src/debug_console_parser_helpers.dart`.
4. Canonicalize IDs via `_canonicalIdForInput`.
5. Emit typed `DebugConsoleParsedInvocation`.

## Shared parser helpers (`debug_console_parser_helpers.dart`)

| Helper | Signature | Contract |
|--------|-----------|----------|
| Count | `(int count, String? error)? parseOptionalCount(List<String> tokens, int position)` | When `tokens.length < position`, returns `(1, null)`. Otherwise parses `tokens[position - 1]` as int in `1..kDebugConsoleMaxSpawnCount`; on failure returns `(0, errorMessage)`. |
| Amount | `(int requested, int credited, String? error)? parseAmountWithClamp(String token)` | Parses int ≥ 1; clamps credited to `kDebugConsoleMaxTreasuryCreditAmount`; returns error when token is not a positive integer. |
| ID | `String? canonicalIdForInput(String input, Iterable<String> candidates)` | Case-insensitive match against `candidates`; returns canonical casing from the iterable. |

Spawn parsers (`_parseSpawnCivilian`, `_parseSpawnRegiment`, `_parseSpawnShip`) MUST call `parseOptionalCount`. Credit parsers (`_parseAddMoney`, `_parseAddWorker`, `_parseAddResource`) MUST call `parseAmountWithClamp` for the amount token.

## Executor helpers (`debug_console_executor_helpers.dart`)

| Helper | Role |
|--------|------|
| `dispatchDebugConsoleSessionEvents` | Maps spawn/credit/flip/reveal/set-diplomacy invocations + `humanPlayerId` to `(events, message)`. The `DebugConsoleSetDiplomacy` branch emits one `SetDebugDiplomacyRelationEvent` (raw faction inputs + `DebugDiplomacyAction`; `factionA` null for the one-faction form). |
| `creditExecutorMessage` | Single formatter for treasury, worker-pool, and stockpile credit success messages (requested vs credited clamp text). |

`_executeInvocation` in `debug_console_command_executor.dart` MUST delegate spawn, credit, flip, and reveal branches to `dispatchDebugConsoleSessionEvents` rather than inlining per-command `DebugConsoleExecutionResult.success` event construction.

## App apply handler (`/set_diplomacy`)

`SetDebugDiplomacyRelationEvent` is applied in the app shell, not in this package, mirroring the other mutating debug commands (`/add_money`, `/flip_province`).

- **Location:** `app/lib/core/services/app_event_handler_debug_set_diplomacy.dart` — `applyDebugSetDiplomacyRelation({required Game? currentGame, required SetDebugDiplomacyRelationEvent event})` returns a `DebugCommandResult` (`(Game?, message)`); a null `game` signals rejection.
- **Subscription:** registered in `app_event_handler_scope_session_subscriptions.dart` via `bus.on<SetDebugDiplomacyRelationEvent>()`, guarded by `_unlessTurnResolutionBlocksSession`, and applied with `_applyDebugCommand` (persist + snackbar).
- **Responsibilities, in order:** (1) `TurnPhase.orders` gate; (2) faction resolution of `factionA` (defaulting to `humanPlayerId` when null) and `factionB` — exact canonical id wins, else case-insensitive display-name match across `players`, `minorNations`, and `tribes`, with ambiguous/unknown inputs rejected; (3) self-target rejection (`factionA == factionB`); (4) per-pair-per-turn quota check against `Game.debugDiplomacyUsedPairKeys` (sorted `pairKey`); (5) per-action hard-incompatibility validation; (6) direct `Game` mutation (relation state/`formalAlliance`, overture upsert/clear, FTP set/remove); (7) `war` side effects (clear overtures both directions, remove FTP); (8) `DiplomaticEvent` history append with sequential `intraTurnIndex`; (9) record the pair key in `debugDiplomacyUsedPairKeys`.
- **Quota reset:** `runEndOfTurnPhase` (`packages/colonizethis_turn`) clears `Game.debugDiplomacyUsedPairKeys` when the turn advances.

## File organization

- `debug_console_command_parser.dart` — verb dispatch and spawn/credit arg extraction (≤ 270 lines).
- `debug_console_parser_helpers.dart` — shared parse helpers and credit/spawn caps (package-private top-level).
- `debug_console_parser_province_commands.dart` — flip, reveal, and observe parse functions.
- `debug_console_parser_diplomacy_commands.dart` — `/set_diplomacy` parse function (`parseSetDiplomacyCommand`) with quote-aware tokenization for multi-word faction display names.
- `debug_console_parse_result.dart` — `DebugConsoleParseResult` type.
- `debug_console_command_executor.dart` — parse → execute orchestration and read-only commands (≤ 220 lines).
- `debug_console_executor_helpers.dart` — event dispatch and credit message formatting.

## Acceptance criteria

- Given `debug_console_parser_helpers.dart` defines `parseOptionalCount`, when repo lint runs `repo.debug_console_shared_helpers`, then each of `_parseSpawnCivilian`, `_parseSpawnRegiment`, and `_parseSpawnShip` invokes `parseOptionalCount`.
- Given `debug_console_parser_helpers.dart` defines `parseAmountWithClamp`, when repo lint runs `repo.debug_console_shared_helpers`, then each of `_parseAddMoney`, `_parseAddWorker`, and `_parseAddResource` invokes `parseAmountWithClamp`.
- Given `debug_console_executor_helpers.dart` defines `creditExecutorMessage`, when repo lint runs `repo.debug_console_shared_helpers`, then `debug_console_command_executor.dart` contains no `_treasuryCreditExecutorMessage`, `_workerPoolCreditExecutorMessage`, or `_stockpileCreditExecutorMessage` functions.
- Given a spawn or credit `DebugConsoleParsedInvocation`, when `dispatchDebugConsoleSessionEvents` runs, then it returns the same `SessionCommandEvent` list and success message semantics as before extraction (behavior-preserving).
