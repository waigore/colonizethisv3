# Debug console panel

**SPEC/ui** — Debug-only in-map console overlay for immediate debug session commands (spawn, treasury credit).

---

## Glossary

- **`DebugConsoleParsedInvocation`** (`colonizethis_debug_console`): parser output for one accepted slash line — validated verb and per-command payload only. The executor maps each variant to a typed `SessionCommandEvent`; the app chooses `humanPlayerId` and persists.

---

## Entry point

- The panel is available only in active game map view and only when compile-time flag `CT_DEBUG_CONSOLE=true`.
- Trigger is the `debug_console` icon in `GameMapEmpireLeftRail`.
- The panel is non-modal and rendered inside `GameMapArea` overlay stack.

---

## Command surface

- **`/spawn_civilian <type> [count]`** — `<type>` aliases: `explorer`, `builder`, `engineer`, `spy`, `merchant`, `rail_builder`. `[count]` default: `1`; allowed range: `1..25`.
- **`/add_money <amount>`** — `<amount>` must parse as an integer. Valid range for execution: `1..9999` inclusive. Values `>9999` are **clamped to 9999 in the parser** (single source of clamp); the parsed invocation carries both `requestedAmount` and `creditedAmount`. Values `<1` or non-integer input are rejected with deterministic errors. No ruleset or economy-phase modifiers apply.
- **`/help`** — Lists supported commands and bounds (including `/add_money` clamp behavior).

---

## Interaction rules

- Input keeps command history for this panel session.
- `ArrowUp` navigates older commands; `ArrowDown` navigates newer commands.
- `Escape` closes panel.
- Successful command emits typed session event and shows feedback via snackbar (same dual path as spawn: executor-queued message plus listener-applied message; dedupe out of scope).
- Invalid command shows deterministic error feedback and does not emit session command events.

---

## Acceptance Criteria (Given–When–Then)

- Given `CT_DEBUG_CONSOLE=false`, when `GameMapEmpireLeftRail` is rendered, then the UI layer does not render a debug-console icon.
- Given `CT_DEBUG_CONSOLE=true` and an active game map, when the player taps the debug-console icon, then the UI layer toggles the in-map debug-console overlay and does not open a modal bottom sheet.
- Given panel input `/spawn_civilian explorer`, when the player submits, then the system emits one `SpawnDebugCivilianAtCapitalEvent` with `unitType=Explorer` and `count=1`.
- Given panel input `/spawn_civilian rail_builder 3`, when the player submits, then the system emits one `SpawnDebugCivilianAtCapitalEvent` with `unitType=Rail Builder` and `count=3`.
- Given panel input `/add_money 500` with the active human player’s treasury at `100`, when the player submits, then the system emits one `CreditDebugTreasuryEvent` with `requestedAmount=500`, `creditedAmount=500`, and after apply the human player’s treasury is `600`.
- Given panel input `/add_money 12000`, when the player submits, then the system emits one `CreditDebugTreasuryEvent` with `requestedAmount=12000` and `creditedAmount=9999`, and success feedback states both the requested amount (`12000`) and the credited amount (`9999`) plus the resulting treasury balance.
- Given panel input `/add_money 0` or `/add_money abc`, when the player submits, then the system emits no `CreditDebugTreasuryEvent` and shows a deterministic error message.
- Given panel input with invalid command text, when the player submits, then the system emits no spawn or treasury session event and shows a deterministic error message.
- Given panel input is focused and command history contains at least one command, when the player presses `ArrowUp` then `ArrowDown`, then the UI layer updates the input text to older/newer history entries in order.
