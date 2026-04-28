# Debug console panel

**SPEC/ui** — Debug-only in-map console overlay for immediate civilian spawn commands.

---

## Entry point

- The panel is available only in active game map view and only when compile-time flag `CT_DEBUG_CONSOLE=true`.
- Trigger is the `debug_console` icon in `GameMapEmpireLeftRail`.
- The panel is non-modal and rendered inside `GameMapArea` overlay stack.

---

## Command surface

- Supported command: `/spawn_civilian <type> [count]`.
- `<type>` aliases: `explorer`, `builder`, `engineer`, `spy`, `merchant`, `rail_builder`.
- `[count]` default: `1`; allowed range: `1..25`.

---

## Interaction rules

- Input keeps command history for this panel session.
- `ArrowUp` navigates older commands; `ArrowDown` navigates newer commands.
- `Escape` closes panel.
- Successful command emits typed session event and shows feedback via snackbar.
- Invalid command shows deterministic error feedback and does not emit spawn event.

---

## Acceptance Criteria (Given–When–Then)

- Given `CT_DEBUG_CONSOLE=false`, when `GameMapEmpireLeftRail` is rendered, then the UI layer does not render a debug-console icon.
- Given `CT_DEBUG_CONSOLE=true` and an active game map, when the player taps the debug-console icon, then the UI layer toggles the in-map debug-console overlay and does not open a modal bottom sheet.
- Given panel input `/spawn_civilian explorer`, when the player submits, then the system emits one `SpawnDebugCivilianAtCapitalEvent` with `unitType=Explorer` and `count=1`.
- Given panel input `/spawn_civilian rail_builder 3`, when the player submits, then the system emits one `SpawnDebugCivilianAtCapitalEvent` with `unitType=Rail Builder` and `count=3`.
- Given panel input with invalid command text, when the player submits, then the system emits no spawn event and shows a deterministic error message.
- Given panel input is focused and command history contains at least one command, when the player presses `ArrowUp` then `ArrowDown`, then the UI layer updates the input text to older/newer history entries in order.
