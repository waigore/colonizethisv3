# Debug console panel

**Screen ID:** `SYS20001` — stable; do not reassign.
**SPEC/ui** — Debug-only in-map console overlay for immediate debug session commands (spawn, treasury credit, worker pool credit, debug province transfer).

**Mockup:** [mockups/SYS20001-debug-console-panel.html](mockups/SYS20001-debug-console-panel.html)
---

## Glossary

- **`DebugConsoleParsedInvocation`** (`colonizethis_debug_console`): parser output for one accepted slash line — validated verb and per-command payload only. The executor maps each variant either to typed `SessionCommandEvent` values (mutating commands) or to a read-only message result with zero events (info commands). The app chooses `humanPlayerId` and persists only when events are emitted.

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
- **`/add_worker <worker_tier> <amount>`** — `<worker_tier>` must be one canonical `WorkerPool` field name: `peasants`, `apprentices`, `journeymen`, or `masters` (parser accepts case-insensitive input and emits the canonical lowercase id on the bus). `<amount>` follows the same integer range, clamp, and `requestedAmount` / `creditedAmount` semantics as `/add_money`. Credits apply immediately to the active human player's industrial `WorkerPool` for the selected tier only. No ruleset or economy-phase modifiers apply.
- **`/add_resource <commodity_id> <amount>`** — `<commodity_id>` must be one canonical id from `CommodityCatalog.byId` (no aliases/display-name parsing). Input lookup is case-insensitive at parser boundaries (`GRAIN` resolves to canonical `grain`) while emitted/stored ids remain canonical catalog ids. `<amount>` must parse as integer. Valid range for execution: `1..9999` inclusive. Values `>9999` are **clamped to 9999 in the parser** (single source of clamp); parsed invocation carries both `requestedAmount` and `creditedAmount`. Values `<1` or non-integer input are rejected with deterministic errors. Credits apply immediately to the active human player's central `Player.stockpile`.
- **`/flip_province <regionId> <province_display_name>`** and **`/flip_province <regionId|localId>`** — requests one canonical province ownership transfer to the human player by region-scoped display-name match or direct full-id targeting. Ambiguous display-name matches return deterministic candidate ids and require id-form retry.
- **`/reveal_province <regionId|localId | province_display_name>`** — reveals one province for the human player by full province id or global display-name exact match (trim + case-insensitive). Unprefixed local ids (e.g. `P12`) are rejected deterministically; ambiguous display-name matches return deterministic candidate ids and require id-form retry.
- **`/get_tile_basic_info`** — read-only command that reports ids from the current orange tile selection (`mapProvincePanelProvider.selectedTileKey`). Success output is multiline and includes `tile_id: <regionId|localProvinceId|x|y>` and `province_id: <regionId|localProvinceId>`. Missing selection returns deterministic error `No tile is selected.`; malformed selection returns deterministic error `Selected tile key is invalid.`.
- **`/observe`** — enter **global** in-app observe mode (session-only; see [observe-mode.md](observe-mode.md)). Emits `SetObserveModeGlobalEvent`.
- **`/observe off`** — exit observe mode. Emits `SetObserveModeOffEvent`.
- **`/observe <target>`** — enter **player** observe for one Great Power; `<target>` is exact `player_id` or `display_name` (trim, case-insensitive; ambiguous names → candidate list + id retry, same as `/list_players`). Rejects unknown, non-GP, and eliminated GPs (`capitalProvinceId == null`). Emits `SetObserveModePlayerEvent`.
- **`/list_players`** — read-only command that enumerates all `Game.players` in ascending `player.id` order. Success output starts with `players_count: <N>` and one blank-line-separated block per player with `player_id`, `display_name` (empty/blank `displayName` falls back to `player_id`), `type` (`human` or `ai`), and `eliminated` (`true` when `capitalProvinceId == null`, else `false`). Extra arguments return `Usage: /list_players`. When the submit-time read-only context does not supply a `players` projection, the executor returns deterministic error `Player list is unavailable.` with no events.
- **`/help`** — Lists supported commands and bounds. `/spawn_regiment`, `/spawn_ship`, `/add_resource`, and `/add_worker` help text must include every canonical id (regiment, ship, commodity, or worker tier) exactly once in stable sorted order, generated from the same source used for parser validation.
- **Orders-phase gate policy** — `/add_money`, `/add_resource`, `/flip_province`, and `/reveal_province` apply paths are allowed only during human Orders phase. Outside Orders phase, the app listener rejects those applies with deterministic feedback and leaves game state unchanged. **`/add_worker`** is **not** `TurnPhase`-gated in its apply handler (parity with the “no economy-phase modifiers” credit surface for `/add_money` / `/add_worker` above); a valid `CreditDebugWorkerPoolEvent` still mutates `WorkerPool` outside Orders phase.

---

## Interaction rules

- Input keeps command history for this panel session.
- `ArrowUp` navigates older commands; `ArrowDown` navigates newer commands.
- `Escape` closes panel.
- Successful command emits typed session event and shows feedback via snackbar (same dual path as spawn: executor-queued message plus listener-applied message; dedupe out of scope).
- Read-only info commands (for example `/get_tile_basic_info`, `/list_players`) append deterministic output and show snackbar feedback without emitting `SessionCommandEvent`.
- Invalid command shows deterministic error feedback and does not emit session command events.

---

## Visual chrome

The panel renders against the canonical dark editorial-monocle palette
(`SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette). No raw
Material color literals appear in feature code; every surface, glyph,
and text colour resolves through an `EditorialMonoclePalette` token.

| Region | Token / catalog primitive |
|--------|---------------------------|
| Outer panel surface | `EditorialMonoclePalette.bgDeep` at `0.85` alpha |
| Header title text | `EditorialMonoclePalette.fg` (weight `w700`) |
| Header close affordance | `CtIconAction` (`Refs #2914` S8 — replaces banned `IconButton`) with `iconColor = EditorialMonoclePalette.fg` |
| Log readout background | `EditorialMonoclePalette.dialogScrim` |
| Log readout text | `EditorialMonoclePalette.fg` |
| Input field text | `EditorialMonoclePalette.fg` |
| Input field hint | `EditorialMonoclePalette.muted` at `0.6` alpha |
| Input field fill | `EditorialMonoclePalette.dialogScrim` |

### Acceptance criteria — Visual chrome

- Given the debug console overlay is mounted, when the panel builds, then The UI layer renders the header close affordance as a `CtIconAction` (catalog primitive) and renders **no** Material `IconButton` widgets inside the panel subtree.
- Given the debug console overlay is mounted, when the panel builds, then The UI layer resolves the header title text colour to `EditorialMonoclePalette.fg`, the input style colour to `EditorialMonoclePalette.fg`, and the input hint colour to `EditorialMonoclePalette.muted` at `0.6` alpha.
- Given the debug console overlay is mounted, when the panel builds, then The UI layer resolves the outer `Material` surface colour to `EditorialMonoclePalette.bgDeep` at `0.85` alpha and the input fill colour to `EditorialMonoclePalette.dialogScrim`.
- Given the user taps the header close affordance, when the tap is committed, then the system invokes the panel `onClose` callback exactly once.

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
- Given panel input `/add_worker peasants 500` with the active human player’s `WorkerPool.peasants` at `10`, when the player submits, then the system emits one `CreditDebugWorkerPoolEvent` with `workerTierId=peasants`, `requestedAmount=500`, `creditedAmount=500`, and after apply the human player’s `WorkerPool.peasants` is `510`.
- Given panel input `/add_worker MASTERS 12000`, when the player submits, then the parser accepts case-insensitive tier input and emits one `CreditDebugWorkerPoolEvent` with `workerTierId=masters`, `requestedAmount=12000`, and `creditedAmount=9999`, and success feedback states both the requested amount (`12000`) and the credited amount (`9999`) plus the resulting `masters` tier count.
- Given panel input `/add_worker peasants 0`, `/add_worker peasants abc`, or `/add_worker invalid_tier 5`, when the player submits, then the system emits no `CreditDebugWorkerPoolEvent` and shows deterministic validation feedback.
- Given a valid `/add_worker apprentices 50` command while the active game’s `TurnState.phase` is **not** `TurnPhase.orders`, when the app listener applies `CreditDebugWorkerPoolEvent`, then the system increases the human player’s `WorkerPool.apprentices` by `50` and persists the mutation (no phase-gate rejection path).
- Given panel input `/add_resource grain 500` during human Orders phase, when the player submits, then the system emits one `CreditDebugStockpileCommodityEvent` with `commodityId=grain`, `requestedAmount=500`, and `creditedAmount=500`.
- Given panel input `/add_resource castIron 12000` during human Orders phase, when the player submits, then the system emits one `CreditDebugStockpileCommodityEvent` with `commodityId=castIron`, `requestedAmount=12000`, and `creditedAmount=9999`.
- Given panel input `/add_resource GRAIN 10` during human Orders phase, when the player submits, then the parser accepts case-insensitive canonical-id input and emits canonical `commodityId=grain`.
- Given panel input `/add_resource nope 10` or `/add_resource grain abc`, when the player submits, then the system emits no `CreditDebugStockpileCommodityEvent` and shows deterministic validation feedback.
- Given a valid stockpile-credit event for `commodityId=grain` with `creditedAmount=50` and active human stockpile `grain=100`, when the app listener applies the event during Orders phase, then the system updates the human player's central stockpile `grain` to `150`, persists updated game state, and shows success feedback including resulting commodity balance.
- Given a valid `/add_resource grain 50` command outside human Orders phase, when the app listener attempts apply, then the system keeps game state unchanged and shows deterministic phase-gate rejection feedback.
- Given a valid `/add_money 50` command outside human Orders phase, when the app listener attempts apply, then the system keeps game state unchanged and shows deterministic phase-gate rejection feedback.
- Given panel input with invalid command text, when the player submits, then the system emits no spawn or treasury session event and shows a deterministic error message.
- Given panel input `/flip_province oldWorld New Bordeaux`, when the player submits and parser validation succeeds, then the system emits one `FlipDebugProvinceOwnershipEvent` with `regionId=oldWorld` and `provinceDisplayName=New Bordeaux`.
- Given panel input `/flip_province oldWorld|P1`, when the player submits and parser validation succeeds, then the system emits one `FlipDebugProvinceOwnershipEvent` with `fullProvinceId=oldWorld|P1`.
- Given panel input `/flip_province oldWorld` or `/flip_province` with missing arguments, when the player submits, then the UI layer emits no `FlipDebugProvinceOwnershipEvent` and shows deterministic usage feedback.
- Given `/flip_province` targets a province owned by the active human player, when the app listener applies the event, then the system keeps game state unchanged and returns deterministic feedback `Debug flip_province rejected: target province is already human-owned.`.
- Given `/flip_province` targets a non-human capital province and the owning faction has no eligible reassignment capital in that same region under existing capital-loss rules, when the app listener applies the event, then the system applies canonical ownership transfer, immediately resolves terminal fall using the same semantics as existing Great Power fall, and returns deterministic success feedback that terminal outcome was resolved in the same transaction.
- Given `/flip_province` targets a non-human capital province and the owning faction has at least one deterministic eligible reassignment capital, when the app listener applies the event during human Orders phase, then the system applies canonical ownership transfer, immediately runs capital reassignment using the same deterministic eligibility mechanism used by combat capital-loss handling, and then applies Great Power fall and Minor Nation / Tribe terminal fall evaluation in the same command transaction.
- Given `/flip_province` targets the capital province of a Minor Nation that still owns at least one other province in the same original capital region with a valid `townTileKey`, when the app listener applies the event during human Orders phase, then the system applies canonical ownership transfer, sets that Minor Nation's `capitalProvinceId` to the deterministic eligible new capital per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Capital loss and reassignment, sets `capitalTile` from the new province's `townTileKey`, and does not modify `WorldState.portsByProvinceSeaboard`, `WorldState.tileState`, or `townDevelopmentLevel` for any province.
- Given `/flip_province` targets the capital province of a Tribe that still owns at least one other province in the same original capital region with a valid `townTileKey`, when the app listener applies the event during human Orders phase, then the system applies canonical ownership transfer and sets that Tribe's `capitalProvinceId` and `capitalTile` from the new province's `townTileKey` only, with no port/road/town-development changes.
- Given `/flip_province` targets the capital province of a Minor Nation or Tribe whose only owned province in the original capital region is that capital, when the app listener applies the event during human Orders phase, then the system applies canonical ownership transfer, resolves terminal fall in the same transaction per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Minor Nation and Tribe terminal fall (provinces transferred to the conqueror, faction removed from `Game.minorNations` / `Game.tribes`, units and fleets removed), and returns deterministic success feedback that notes terminal outcome resolved.
- Given panel input `/reveal_province oldWorld|P1`, when the player submits and parser validation succeeds, then the system emits one `RevealDebugProvinceEvent` with `target=oldWorld|P1` and `targetIsFullProvinceId=true`.
- Given panel input `/reveal_province New Bordeaux` and more than one province matches globally by normalized display name, when the app listener resolves the target, then the system keeps game state unchanged and returns deterministic disambiguation feedback listing candidate full ids and id-form retry guidance.
- Given a valid `/reveal_province oldWorld|P1` command during human Orders phase, when the app listener applies the event, then the system sets all land tiles in `oldWorld|P1` to `fullyVisible` for the human player, sets directly adjacent sea-zone water tiles to `fullyVisible`, persists updated game state, and returns deterministic success feedback.
- Given a valid `/reveal_province oldWorld|P1` command outside human Orders phase, when the app listener attempts apply, then the system keeps game state unchanged and returns deterministic phase-gate rejection feedback.
- Given panel input is focused and command history contains at least one command, when the player presses `ArrowUp` then `ArrowDown`, then the UI layer updates the input text to older/newer history entries in order.
- Given panel input `/help`, when displayed, then `/spawn_regiment` documentation includes every `RegimentEconomyCatalog.byId` id exactly once in stable sorted order.
- Given panel input `/help`, when displayed, then `/spawn_ship` documentation includes every `ShipEconomyCatalog.byId` id exactly once in stable sorted order.
- Given panel input `/help`, when displayed, then `/add_resource` documentation includes every `CommodityCatalog.byId` id exactly once in stable sorted order.
- Given panel input `/help`, when displayed, then `/add_worker` documentation includes the four worker tier ids (`apprentices`, `journeymen`, `masters`, `peasants`) exactly once each in stable sorted order.
- Given `mapProvincePanelProvider.selectedTileKey = oldWorld|P12|34|21`, when the player submits `/get_tile_basic_info`, then the system appends multiline success output with `tile_id: oldWorld|P12|34|21` and `province_id: oldWorld|P12` and emits no session command events.
- Given `mapProvincePanelProvider.selectedTileKey = null`, when the player submits `/get_tile_basic_info`, then the system appends deterministic error `No tile is selected.` and emits no session command events.
- Given the active game has three players with ids `a`, `b`, and `c` and the debug console submit-time context supplies their snapshots, when the player submits `/list_players`, then the system appends multiline output whose first line is `players_count: 3` and whose `player_id:` lines appear in ascending id order `a`, then `b`, then `c`.
- Given a player snapshot has `isHuman=true`, when `/list_players` runs, then that player block contains `type: human`; given `isHuman=false`, then that block contains `type: ai`.
- Given a player snapshot has empty or whitespace-only `displayName`, when `/list_players` runs, then that player block contains `display_name: <player_id>` matching that snapshot id.
- Given a player snapshot has `capitalProvinceId == null`, when `/list_players` runs, then that player block contains `eliminated: true`; given a non-null `capitalProvinceId`, then that block contains `eliminated: false`.
- Given panel input `/list_players extra`, when the player submits, then the system shows deterministic usage feedback `Usage: /list_players` and emits no session command events.
- Given panel input `/help`, when displayed, then the help text includes `/list_players` exactly once.
- Given the submit-time read-only context omits `players` (null projection), when the player submits `/list_players`, then the system appends deterministic error `Player list is unavailable.` and emits no session command events.

---

## Automated verification (`/flip_province`)

- **App handler and JSON persistence parity:** `app/test/app_event_handler_scope_test.dart` (`applyDebugFlipProvinceOwnership` — success, Orders-phase gate, unknown-to-human, already-owned, ambiguous name, not found, null owner, `Game.fromJson` / `toJson` round-trip).
- **Logic downstream after canonical transfer:** `packages/colonizethis_logic/test/debug_flip_province_turn_downstream_test.dart` (`emitProvinceCapturedEvents`, `resolveConnectivity` via `runExtractionPhase`, `findMilitaryVictoryWinner`, `runEndOfTurnPhase`).
- **Minor Nation and Tribe capital-loss parity:** `app/test/app_event_handler_debug_flip_province_minor_tribe_capital_test.dart` (capital reassignment for Minor Nation and Tribe owners; terminal fall when no eligible reassignment exists in the original capital region; `Game.fromJson` / `toJson` round-trip preserves post-reassignment minor/tribe capital fields).
