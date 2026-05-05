# Debug console panel

**SPEC/ui** — Debug-only in-map console overlay for immediate debug session commands (spawn, treasury credit, debug province transfer).

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
- **`/spawn_regiment <regiment_type_id> [count]`** — `<regiment_type_id>` must be one canonical regiment id from `RegimentEconomyCatalog.byId` (no display-name aliases). `[count]` default: `1`; allowed range: `1..25`.
- **`/spawn_ship <ship_type_id> [count]`** — `<ship_type_id>` must be one canonical ship id from `ShipEconomyCatalog.byId` (no aliases/display-name tokens). `[count]` default: `1`; allowed range: `1..25`. Parsing and `/help` output use the same catalog-derived id source.
- **`/add_money <amount>`** — `<amount>` must parse as an integer. Valid range for execution: `1..9999` inclusive. Values `>9999` are **clamped to 9999 in the parser** (single source of clamp); the parsed invocation carries both `requestedAmount` and `creditedAmount`. Values `<1` or non-integer input are rejected with deterministic errors. No ruleset or economy-phase modifiers apply.
- **`/add_resource <commodity_id> <amount>`** — `<commodity_id>` must be one canonical id from `CommodityCatalog.byId` (no aliases/display-name parsing). Input lookup is case-insensitive at parser boundaries (`GRAIN` resolves to canonical `grain`) while emitted/stored ids remain canonical catalog ids. `<amount>` must parse as integer. Valid range for execution: `1..9999` inclusive. Values `>9999` are **clamped to 9999 in the parser** (single source of clamp); parsed invocation carries both `requestedAmount` and `creditedAmount`. Values `<1` or non-integer input are rejected with deterministic errors. Credits apply immediately to the active human player's central `Player.stockpile`.
- **`/flip_province <regionId> <province_display_name>`** — requests one canonical province ownership transfer to the human player for the uniquely matched province display name inside the specified region id. Parser accepts region ids as user input tokens without hard-coded literals; app/session validation resolves against active world region data.
- **`/help`** — Lists supported commands and bounds. `/spawn_regiment` and `/spawn_ship` help text must include every canonical catalog id exactly once in stable sorted order, generated from the same catalog-derived source used for parser validation.
- **Orders-phase gate policy** — `/add_money`, `/add_resource`, and `/flip_province` are allowed only during human Orders phase. Outside Orders phase, the app listener rejects command apply with deterministic feedback and leaves game state unchanged.
- **`/help`** — Lists supported commands and bounds. `/spawn_regiment`, `/spawn_ship`, and `/add_resource` help text must include every canonical catalog id exactly once in stable sorted order, generated from the same catalog-derived source used for parser validation.

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
- Given panel input `/spawn_regiment peasant_levies 3`, when the player submits, then the system emits one `SpawnDebugRegimentAtCapitalEvent` with `regimentTypeId=peasant_levies` and `count=3`.
- Given panel input `/spawn_regiment siege_guns`, when the player submits, then the system emits one `SpawnDebugRegimentAtCapitalEvent` with `count=1` by default.
- Given panel input `/spawn_regiment not_a_regiment`, when the player submits, then the system emits no `SpawnDebugRegimentAtCapitalEvent` and shows a deterministic error message.
- Given panel input `/spawn_ship carrack`, when the player submits, then the system emits one `SpawnDebugShipAtCapitalHomeFleetEvent` with `shipTypeId=carrack` and `count=1`.
- Given panel input `/spawn_ship ship_of_the_line 3`, when the player submits, then the system emits one `SpawnDebugShipAtCapitalHomeFleetEvent` with `shipTypeId=ship_of_the_line` and `count=3`.
- Given panel input `/spawn_ship not_a_ship`, when the player submits, then the system emits no `SpawnDebugShipAtCapitalHomeFleetEvent` and shows a deterministic error message.
- Given panel input `/spawn_ship carrack 26`, when the player submits, then the system emits no `SpawnDebugShipAtCapitalHomeFleetEvent` and shows deterministic count-bounds feedback.
- Given panel input `/add_money 500` with the active human player’s treasury at `100`, when the player submits, then the system emits one `CreditDebugTreasuryEvent` with `requestedAmount=500`, `creditedAmount=500`, and after apply the human player’s treasury is `600`.
- Given panel input `/add_money 12000`, when the player submits, then the system emits one `CreditDebugTreasuryEvent` with `requestedAmount=12000` and `creditedAmount=9999`, and success feedback states both the requested amount (`12000`) and the credited amount (`9999`) plus the resulting treasury balance.
- Given panel input `/add_money 0` or `/add_money abc`, when the player submits, then the system emits no `CreditDebugTreasuryEvent` and shows a deterministic error message.
- Given panel input `/add_resource grain 500` during human Orders phase, when the player submits, then the system emits one `CreditDebugStockpileCommodityEvent` with `commodityId=grain`, `requestedAmount=500`, and `creditedAmount=500`.
- Given panel input `/add_resource castIron 12000` during human Orders phase, when the player submits, then the system emits one `CreditDebugStockpileCommodityEvent` with `commodityId=castIron`, `requestedAmount=12000`, and `creditedAmount=9999`.
- Given panel input `/add_resource GRAIN 10` during human Orders phase, when the player submits, then the parser accepts case-insensitive canonical-id input and emits canonical `commodityId=grain`.
- Given panel input `/add_resource nope 10` or `/add_resource grain abc`, when the player submits, then the system emits no `CreditDebugStockpileCommodityEvent` and shows deterministic validation feedback.
- Given a valid stockpile-credit event for `commodityId=grain` with `creditedAmount=50` and active human stockpile `grain=100`, when the app listener applies the event during Orders phase, then the system updates the human player's central stockpile `grain` to `150`, persists updated game state, and shows success feedback including resulting commodity balance.
- Given a valid `/add_resource grain 50` command outside human Orders phase, when the app listener attempts apply, then the system keeps game state unchanged and shows deterministic phase-gate rejection feedback.
- Given a valid `/add_money 50` command outside human Orders phase, when the app listener attempts apply, then the system keeps game state unchanged and shows deterministic phase-gate rejection feedback.
- Given panel input with invalid command text, when the player submits, then the system emits no spawn or treasury session event and shows a deterministic error message.
- Given panel input `/flip_province oldWorld New Bordeaux`, when the player submits and parser validation succeeds, then the system emits one `FlipDebugProvinceOwnershipEvent` with `regionId=oldWorld` and `provinceDisplayName=New Bordeaux`.
- Given panel input `/flip_province oldWorld` or `/flip_province` with missing arguments, when the player submits, then the UI layer emits no `FlipDebugProvinceOwnershipEvent` and shows deterministic usage feedback.
- Given panel input is focused and command history contains at least one command, when the player presses `ArrowUp` then `ArrowDown`, then the UI layer updates the input text to older/newer history entries in order.
- Given panel input `/help`, when displayed, then `/spawn_regiment` documentation includes every `RegimentEconomyCatalog.byId` id exactly once in stable sorted order.
- Given panel input `/help`, when displayed, then `/spawn_ship` documentation includes every `ShipEconomyCatalog.byId` id exactly once in stable sorted order.
- Given panel input `/help`, when displayed, then `/add_resource` documentation includes every `CommodityCatalog.byId` id exactly once in stable sorted order.

---

## Automated verification (`/flip_province`)

- **App handler and JSON persistence parity:** `app/test/app_event_handler_scope_test.dart` (`applyDebugFlipProvinceOwnership` — success, Orders-phase gate, unknown-to-human, already-owned, ambiguous name, not found, null owner, `Game.fromJson` / `toJson` round-trip).
- **Logic downstream after canonical transfer:** `packages/colonizethis_logic/test/debug_flip_province_turn_downstream_test.dart` (`emitProvinceCapturedEvents`, `resolveConnectivity` via `runExtractionPhase`, `findMilitaryVictoryWinner`, `runEndOfTurnPhase`).
