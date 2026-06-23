# App UI wiring (event bus) — SPEC/program/app-ui-wiring.md

**SPEC/program** — Rules for **adding and wiring** Flutter UI to the **`AppEventBus`**: when to emit vs use local APIs, coupling bans, dialog/route registries, migration notes, and acceptance criteria for panel behavior. Event types, handler API, and `GameToUI` bridge: **[app-event-bus.md](app-event-bus.md)**. Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Overlay construction and simulation cost (normative)

When building or rebuilding game overlays (widget `build`, scroll/pan, selection changes), the UI layer **must not** invoke expensive simulation paths—tile pickers such as `getValidWorkOrderTileKeysWithVisibility`, full **order-engine** validation or application, or other heavy rule evaluation—**unless** there is an explicit, narrow justification (for example validating a user commit when assigning an order).

Authoritative world and player-view updates happen primarily at **turn resolution** and other explicit commit boundaries. Overlays read **stable** models (`Game`, `PlayerView`, map view data, draft orders) and **cheap** pure predicates shared with the engine (for example `isMineralEligibleTile` with visibility and prospected-tile state), not re-run the engine solely to paint affordances. Province detail prospect shortcut behavior is specified in [province-sea-zone-detail-overlay.md](../ui/province-sea-zone-detail-overlay.md).

### Turn resolution in progress (#2160)

While **`turnResolutionBlockingProvider`** is true (background turn resolution from the map), **bus-driven** navigation, dialogs, and unit panels must not open except **`OpenPauseMenuPanelEvent`** and **`ClosePanelEvent`** as documented in [app-event-bus.md](app-event-bus.md). The map uses local **`IgnorePointer`** for gameplay taps; the **pause / hamburger** path stays available. Do not bypass this with direct **`Navigator`** calls for cross-cutting UI.

---

## When to use the bus vs local Flutter APIs

Use **`AppEventBus`** for **cross-cutting** actions: shell ↔ game, empire panels opening **shared** dialogs or **full-screen** empire routes, side menu opening unit sheets, platform menus, and anything that must not depend on a long **`BuildContext`** chain.

Keep **`showDialog` / `showModalBottomSheet` / `Navigator.pop`** **inside one feature** for **internal** steps: confirm/cancel in a flow, multi-step order assignment, pickers owned by a single panel, **`CtDropdown`’s** built-in dialog. See **Local by design** below.

---

## Banned: `Ref` / `BuildContext` / `Navigator` chains (cross-cutting)

**Do not** use these as the primary mechanism for **cross-panel, cross-screen, or shell-level** behavior:

- Threading **`WidgetRef`** (or `Ref`) through constructors into widgets in a **different feature** or **another panel** so a distant child reads providers or triggers another area’s side effects.
- Depending on **`BuildContext`** chains to open dialogs, push routes, or show sheets **outside** the widget’s **local** subtree.
- Calling **`Navigator.of(context).push` / `pushNamed` / `showDialog`** from empire panels, side menus, or shell for actions that **leave** that panel’s local UX. Use **`AppEventBus` → `AppEventHandler`** (see [app-event-bus.md](app-event-bus.md)); the handler is the choke point for **`navigatorKey`** + those Flutter APIs for cross-cutting cases.

**Allowed:** **`Navigator.pop`** / local **`showDialog`** for the same local flow. **`WidgetRef` in `build`** on **`ConsumerWidget` / `ConsumerStatefulWidget`** for **that** screen or panel only; pass **`AppEventBus`** or **data** across feature boundaries, not **`ref`**. **`AppEventHandler`** and shell dialog builders using **`navigatorKey`** / **`ProviderScope.containerOf`**.

---

## Code smells

| Signal | Severity |
|--------|----------|
| **`WidgetRef` passed into widgets** across panels or `features/...` subtrees to trigger another area | **Potential smell** — prefer bus events, notifiers, or data. |
| **Panel A** calls **panel B’s `onXxx`** to open B’s UI or mutate B | **Definite smell — disallowed.** Emit a typed **`AppEvent`**. |
| Typed bus event payload (`LocateMapTileEvent`, `StartCivilianWorkTargetSelectionEvent`) | **Preferred** — avoid callback threading for cross-panel intent. |

---

## Typed panel events (preferred)

| Event | Opened by | Handler builds |
|-------|-----------|----------------|
| `OpenPauseMenuPanelEvent` | `GameScreen` (pause) | `PauseMenuPanel` |
| `OpenCivilianUnitsPanelEvent` | `GameSideMenu` | `CivilianUnitsPanel` (+ Riverpod game/orders) |
| `OpenMilitaryUnitsPanelEvent` | `GameSideMenu` | `MilitaryUnitsPanel` |
| `OpenNavalUnitsPanelEvent` | `GameSideMenu`, map fleet marker | `NavalUnitsPanel` (optional tile/location scope fields on event) |
| `ToggleDebugConsolePanelEvent` | `GameMapEmpireLeftRail` (debug-gated) | `GameMapArea` in-map non-modal overlay (`DebugConsoleOverlayPanel`) |
| `SetObserveModeOffEvent` / `SetObserveModeGlobalEvent` / `SetObserveModePlayerEvent` | `/observe` debug console | `AppEventHandlerScope` updates `observeSessionProvider` + in-memory `Game` control handoff |

Sheet close cleanup should be emitted as a typed bus event (`UnitsPanelClosedEvent`) from the handler.

**Observe mode:** While `observeSessionProvider.mode != off`, UI mutation via bus `SessionCommandEvent`s (work, naval, army, diplomacy draft) is rejected when `shellPlayerContextProvider.canMutateViaUi` is false. Debug spawn/credit commands use `debugCommandTargetPlayerId` (see [observe-mode.md](../ui/observe-mode.md)).

---

## Dialog IDs (`OpenDialogEvent`)

Register core (game-feature) builders in **`app/lib/core/services/app_event_handler_scope.dart`**. **Feature-layer dialog builders that would otherwise force `core/services/` to import `features/`** (for example the shell `new_game_leader_selection` dialog) live in their owning feature and are injected into the scope at the **composition root** (`app/lib/main.dart`) via **`AppEventHandlerScope.extraDialogBuilders`** — a `Map<String, NavigatorKeyDialogBuilder>` (each value a `DialogBuilder Function(GlobalKey<NavigatorState>)`) merged over the core builders by `OpenDialogEvent` id. The scope resolves each factory with `appNavigatorKey` so the feature threads the navigator key **explicitly** rather than reading the global; `appNavigatorKey` access stays confined to `core/services/` + `app.dart` (enforced by `repo.app_event_bus_decoupling`). This keeps `core/services/` free of `features/shell/` imports while preserving the single choke point for `navigatorKey` / `ProviderScope.containerOf` (Refs #3546).

| ID | Widget | Constant |
|----|--------|----------|
| `train_civilians` | `TrainCiviliansDialog` | `trainCiviliansDialogId` |
| `train_military` | `TrainMilitaryDialog` | `trainMilitaryDialogId` |
| `train_naval` | `TrainNavalDialog` | `trainNavalDialogId` |
| `grant_or_subsidy` | `GrantOrSubsidyDialog` (see [grant-or-subsidy-dialog.md](../ui/grant-or-subsidy-dialog.md)) | `grantOrSubsidyDialogId` |
| `new_game_leader_selection` | `NewGameLeaderSelectionDialog` (six slots: **nation** + **leader** per slot; nation picker shows default GP map colour swatch beside each nation name; fair GP Old World assignment checkbox; **game / world seed** field + helper below checkbox; initial nations = `GameSetupConfig.defaultConfig.selectedGreatPowerIds`; see [new-game-leader-selection-dialog.md](../ui/new-game-leader-selection-dialog.md)) | `newGameLeaderSelectionDialogId` |

For `train_civilians`, `train_military`, and `train_naval`, shared order/count orchestration must be implemented in `app/lib/features/game/widgets/train_unit_dialog_helper.dart`; keep dialog-specific economics and lock rules inside each dialog widget.

| ID | Widget | Status |
|----|--------|--------|
| `quick_battle_result` | [`QuickBattleResultDialog`](../ui/quick-battle-result-dialog.md) | `quickBattleResultDialogId` |
| `combat_mode_choice` | [`CombatModeChoiceDialog`](../ui/combat-mode-choice-dialog.md) (`CombatModeChosenEvent` on choice) | `combatModeChoiceDialogId` |

Combat-flow non-dialog screens (constructed directly by the orchestrator, not via `OpenDialogEvent`) are documented in [`quick-battle-screen.md`](../ui/quick-battle-screen.md), with sub-views [`quick-battle-deployment-view.md`](../ui/quick-battle-deployment-view.md) and [`quick-battle-action-selector.md`](../ui/quick-battle-action-selector.md).

**Local by design (no `OpenDialogEvent`):** map display options (`GameMapArea`), tech detail (`TechTreeWidget`), civilian work-target sheet (`CivilianUnitsPanel`), next-turn confirmation (`GameMapArea`), in-game Android back exit confirmation (`GameScreen`), research tech picker (`TechnologyPanel`), **`CtDropdown`** internal picker, **new-game setup progress and error dialogs** after leader confirmation (see **SPEC/ui/game-initializing.md**), **`TransferToHomeFleetDialog`** (opened from `NavalUnitsPanel` via local `showDialog` for the regular-fleet → Home Fleet ship merge flow, commits via **`NavalTransferShipsRequestedEvent`**; see [SPEC/ui/transfer-to-home-fleet-dialog.md](../ui/transfer-to-home-fleet-dialog.md)), **`ProductionCommodityBreakdownDialog`** (opened from `ProductionScreen` via local `showDialog` as a read-only commodity preview; see [SPEC/ui/production-commodity-breakdown-dialog.md](../ui/production-commodity-breakdown-dialog.md)), **`ResearchFundingBreakdownDialog`** (opened from the `TechnologyPanel` slot turn-preview view via local `showDialog` as a read-only RP/treasury funding breakdown, split out of `technology_panel.dart` to keep that file under the widget file-size cap; see [SPEC/ui/technology-panel.md](../ui/technology-panel.md) § Slot turn preview).

**Split fleet:** `NavalUnitsPanel` uses local `showDialog` for `SplitFleetDialog`, but the dialog commits via **`NavalSplitFleetRequestedEvent`** → `AppEventHandlerScope` (applies `applyNavalSplitFleet`, then emits **`NavalFleetsUpdatedEvent`**) so the dialog does not receive panel merge callbacks. Widgetbook / tests without the shell wire the same request event or listen for `NavalFleetsUpdatedEvent` only.

**Move fleet:** `NavalUnitsPanel` uses local `showDialog` for `MoveFleetDialog` (see [SPEC/ui/move-fleet-dialog.md](../ui/move-fleet-dialog.md)). On confirm, emit **`NavalMoveFleetRequestedEvent`** → `AppEventHandlerScope` updates **`currentOrdersProvider`** via **`applyNavalMoveOrderForPlayer`** (replaces any prior naval move for that fleet and removes naval mission orders for that fleet from the draft). No merge callback into the dialog.

**Land armies (`MilitaryUnitsPanel`):** **Move army** uses local `showDialog` like naval move (see [SPEC/ui/move-army-dialog.md](../ui/move-army-dialog.md)) and confirms via **`ArmyMoveRequestedEvent`**. The dialog lists **only** destinations returned by **`colonizethis_logic`** as **order-engine-valid** for the current draft (visibility, adjacency, ownership, war/declare-war rules). The dropdown is **grouped by owning faction** with **player-owned** provinces first; **invasion** into another GP / Minor / Tribe without war uses a **second confirm** and sets optional **`declareWarTargetFactionId`** on the event so the shell merges **`declareWar`** and **`ArmyMoveOrder`** atomically. **`AppEventHandler`** opens the panel with **`ref.watch(currentOrdersProvider)`** and passes **`draftOrders`** into **`MilitaryUnitsPanel`** (naval parity for pending move lines). The scope handler applies the move (and declare war when present), runs **full draft validation** for that player; on failure it **does not** update `currentOrders`, logs **`error`**, emits **`ShowSnackBarEvent`**, and **asserts** in debug (per [orders.md](orders.md) shell contract). **Split** / **combine** use **`ArmySplitRequestedEvent`** / **`ArmyCombineRequestedEvent`** → handler mutates `Game`; panel refreshes from updated state. Same decoupling pattern as naval split (`NavalSplitFleetRequestedEvent`).

**Train at-capital dialogs:** `TrainCiviliansDialog` / `TrainMilitaryDialog` / `TrainNavalDialog` emit **`TrainCivilianBuildOrdersCommittedEvent`** / **`TrainMilitaryBuildOrdersCommittedEvent`** / **`TrainNavalBuildOrdersCommittedEvent`** on close; `AppEventHandlerScope` merges into orders. The naval merge replaces only dialog-managed naval orders (`isMilitary == false`, ship `unitType` in `ShipEconomyCatalog.byId`, spawned at capital), leaving civilian build orders intact. No `onOrdersChanged` callback from the shell into the dialog.

---

## Routes (`NavigateToRouteEvent`)

Handled by **`AppEventHandler`** via **`pushNamed`**. Common names:

| Route | Screen |
|-------|--------|
| `Routes.debugLog` | `DebugLogViewerScreen` |
| `Routes.production` | `ProductionScreen` |
| `Routes.diplomacy` | `DiplomacyScreen` |
| `Routes.diplomacyDetail` | `DiplomacyDetailScreen` |
| `Routes.technology` | `TechnologyScreen` |

Shell/game entry: **`Routes.shell`**, **`Routes.game`** (see `config/routes.dart`).

**Return to main menu from in-game / victory:** emit **`NavigateToShellEvent`**; **`AppEventHandler`** pops until **`Routes.shell`** or **`pushNamedAndRemoveUntil`** as needed. Do not call **`Navigator.popUntil`** from **`GameScreen`** / victory UI for that flow.

**Pause-menu exit flow (`RequestExitToMainMenuFlowEvent`):** the pause menu's **Exit to Main Menu** action emits **`ClosePanelEvent`** first (to dismiss the pause modal), then **`RequestExitToMainMenuFlowEvent`** on the bus. **`AppEventHandler`** reacts by scheduling a post-frame `showExitToMainMenuConfirmDialog`; on confirm it emits **`NavigateToShellEvent`** (which then runs the standard pop-until-shell flow); on cancel no further event fires. See [`SPEC/ui/pause-menu-panel.md`](../ui/pause-menu-panel.md) and [`SPEC/ui/in-game-shell-narrow.md`](../ui/in-game-shell-narrow.md) § Android back confirm for the shared confirm-dialog contract.

---

## Game feature screen wrapper

Game-bound feature screens under `app/lib/features/game/widgets/` should use a shared wrapper for repeated shell/listener/live-game orchestration.

- Shared wrapper scope: full-screen feature routes (for example `TechnologyScreen`, `ProductionScreen`, `DiplomacyScreen`).
- Shared wrapper responsibilities:
  - resolve display game from route game vs `currentGameProvider` when ids match;
  - wrap feature content with `CtScreenShell`;
  - optionally attach `GameToUIBusListener` for the route game id (default attached; test-only override allowed).
- `GameScreen` is excluded from this wrapper requirement because it owns Flame/map overlays and custom lifecycle concerns.

Feature-specific behavior (tabs, panel listeners, orders callbacks, local dialogs) remains in each feature screen.

---

## Stream subscriptions (`SubscriptionTracker`)

In **`colonizethis_app`**, widgets and services that hold **one or more** `StreamSubscription` values for the same lifecycle should register them with **`app/lib/core/services/subscription_tracker.dart`** and call **`cancelAll()`** in **`dispose()`** / teardown (same pattern as **`AppEventHandler.unbind`** and **`CtRegionMap`** bus listeners). This keeps multi-subscription cleanup in one place and avoids scattered **`?.cancel()`** calls.

**Documented exceptions:**

- Packages that do not depend on **`colonizethis_app`** must not import app-only types such as **`SubscriptionTracker`**; they keep local teardown for their own subscriptions and non-stream async handles (for example **`Timer`**).

---

## Migration checklist

### Done
- `grant_or_subsidy`, diplomacy detail nav/back, shell new-game leader + load-game nav, macOS debug log via bus (see [app-event-bus.md](app-event-bus.md) for service emissions).

### Optional
- New shared panels: prefer **typed** `UIActionEvent` subclasses over **`OpenPanelEvent(panelId)`**.

---

## Constraints (wiring)

- **Cross-cutting UI** must not use **`Ref` / `BuildContext` / `Navigator` chains** between unrelated widgets; use **`AppEventBus`** and **`AppEventHandler`**. **Panel-to-panel `onXxx` orchestration is disallowed.**
- **Dialog builders** and route handling: one place at shell init — see [app-event-bus.md](app-event-bus.md) constraints for package boundaries and event payload rules.

### CI gate — `repo.app_event_bus_decoupling` (Refs #2626)

`tool/check_app_event_bus_decoupling.dart` (wired through `tool/ct_repo_lint_manifest.yaml`) enforces four invariants against `app/lib/**`:

- **No `AppEventBus()` singleton** in production code (under `app/lib/**`, excluding `app/lib/widgetbook/**`). Use `appEventBusProvider` (or an `AppEventBus.create()` instance held by the owning widget/service).
- **`appNavigatorKey.currentContext` / `.currentState` / equivalent property access** is restricted to `app/lib/core/services/**` and `app/lib/app.dart`. Other layers must thread an explicit `GlobalKey<NavigatorState>` parameter or use the bus.
- **`showDialog` / `showModalBottomSheet` calls under `app/lib/features/**`** are restricted to the documented "Local by design" allow-list above (plus the per-panel carve-outs for split/move fleet, move army, train at-capital). New call sites outside the allow-list must use a typed `AppEvent` instead. Adding a new local-by-design dialog requires extending **both** this SPEC section **and** the lint allow-list.
- **No raw `addPostFrameCallback` + bus-`emit` sequencing under `app/lib/features/**`.** A `addPostFrameCallback` closure must not emit a **non-`ClosePanelEvent`** bus event (`bus.emit(...)` / `widget.bus.emit(...)`). The "close the active panel, then emit a follow-up event next frame" idiom must route through the shared **`AppEventBus.closePanelThenEmit`** helper (`app/lib/core/services/app_event_bus_panel_nav.dart`), which emits `ClosePanelEvent` synchronously and defers the single follow-up by exactly one frame so the SPEC-normative ordering (Train → `ClosePanelEvent` then `OpenDialogEvent`; locate / work-target → `ClosePanelEvent` then the follow-up) and the post-frame rationale live in one place. A bare deferred `ClosePanelEvent` emit (for example a scoped auto-close once a panel becomes empty) remains allowed.

---

## Acceptance Criteria (Given–When–Then)

### Typed panels and decoupling

- Given `GameSideMenu` is mounted with a valid `currentGameProvider`, When the user chooses Civilian Units, Then the system emits `OpenCivilianUnitsPanelEvent` (not `showModalBottomSheet` from `GameSideMenu`).
- Given `CivilianUnitsPanel` is mounted with a bus, When the user taps Train, Then the system emits `ClosePanelEvent` and then `OpenDialogEvent(trainCiviliansDialogId)` (panel does not call `showDialog` or `Navigator.maybePop` on the handler-owned sheet for that action).
- Given `MilitaryUnitsPanel` is mounted with a bus, When the user taps Train, Then the system emits `ClosePanelEvent` and then `OpenDialogEvent(trainMilitaryDialogId)` under the same rules.
- Given `NavalUnitsPanel` is mounted with a bus and not in observe mode, When the user taps Train, Then the system emits `ClosePanelEvent` and then `OpenDialogEvent(trainNavalDialogId)` under the same rules.
- Given `CT_DEBUG_CONSOLE=true` and an active game map, When the user taps Debug Console in `GameMapEmpireLeftRail`, Then the system emits `ToggleDebugConsolePanelEvent` and `GameMapArea` toggles a non-modal in-map overlay without using `OpenPanelEvent` or `showModalBottomSheet`.
- Given debug console input submits `/spawn_civilian <type> [count]`, When command parsing succeeds, Then the panel emits `SpawnDebugCivilianAtCapitalEvent` and the shell listener applies immediate civilian spawn to the active game and persists via `GameService.saveGame`.
- Given debug console input submits `/spawn_regiment <regiment_type_id> [count]`, When command parsing succeeds, Then the panel emits `SpawnDebugRegimentAtCapitalEvent` and the shell listener applies immediate capital regiment spawn for the active human player and persists via `GameService.saveGame`.
- Given debug console input submits `/spawn_ship <ship_type_id> [count]`, When command parsing succeeds, Then the panel emits `SpawnDebugShipAtCapitalHomeFleetEvent` and the shell listener applies immediate home-fleet ship spawn for the active human player and persists via `GameService.saveGame`.
- Given debug console input submits `/add_money <amount>` with a valid integer amount, When command parsing succeeds, Then the panel emits `CreditDebugTreasuryEvent` and the shell listener applies immediate treasury credit to the active human player and persists via `GameService.saveGame`.
- Given debug console input submits `/add_worker <worker_tier> <amount>` with a valid tier id and integer amount, When command parsing succeeds, Then the panel emits `CreditDebugWorkerPoolEvent` and the shell listener applies immediate worker-pool tier credit to the active human player and persists via `GameService.saveGame`.
- Given debug console input submits `/flip_province <regionId> <province_display_name>`, When command parsing succeeds, Then the panel emits `FlipDebugProvinceOwnershipEvent` and the shell listener validates human-turn + target eligibility, applies canonical province transfer semantics, and persists via `GameService.saveGame` on success.
- Given debug console input submits `/get_tile_basic_info`, When command parsing succeeds, Then the panel reads `mapProvincePanelProvider.selectedTileKey` at submit-time, appends read-only info output, emits no `SessionCommandEvent`, and does not trigger `GameService.saveGame`.
- Given debug console input submits `/list_players`, When command parsing succeeds, Then the panel builds a submit-time `DebugConsoleReadOnlyContext` from current `Game.players`, appends read-only player-list output, emits no `SessionCommandEvent`, and does not trigger `GameService.saveGame`.
- Given a units sheet should close before the map reacts, When the player triggers locate or work-target selection from that sheet, Then the system emits `ClosePanelEvent` before `LocateMapTileEvent` or `StartCivilianWorkTargetSelectionEvent`; the map widget does not call `Navigator.maybePop` for that teardown.
- Given `DiplomacyPanel` is mounted with a bus, When the user taps Grant Aid or Set Subsidy, Then the system emits `OpenDialogEvent('grant_or_subsidy')` (panel does not call `showDialog` directly).
- Given `DiplomacyPanel` is mounted with a bus, When the user taps a faction row, Then the system emits `NavigateToRouteEvent(Routes.diplomacyDetail)` (panel does not call `Navigator.push` directly).
- Given `CT_DEBUG_CONSOLE=true`, When the app shell computes a localized app title for desktop or web title surfaces, Then the shell appends the exact terminal suffix ` (debug)` using the shared debug-aware title formatter.
- Given `CT_DEBUG_CONSOLE=false` or undefined, When the app shell computes a localized app title for desktop or web title surfaces, Then the shell keeps the title unchanged and does not alter debug-console commands, routing, persistence, or game behavior.

### Coupling rules

- Given an empire panel specified to use the bus for a navigation or shared-dialog action (e.g. `DiplomacyPanel`), When that action runs, Then the panel emits the corresponding `UIActionEvent` via `AppEventBus` and does not use `Navigator.of(context).push`, `pushNamed`, or `showDialog` for that action (dismissing a **local** route remains allowed per **Local by design**).
- Given two distinct panels under `features/game/widgets/`, When one must show another **feature’s** UI or request map/session behavior, Then the first emits a typed `AppEvent` (`Open*PanelEvent`, `LocateMapTileEvent`, `StartCivilianWorkTargetSelectionEvent`, etc.) and does not call an `onXxx` callback supplied from the other panel’s widget API.
- Given `AppEventHandler` is bound at the shell, When it handles `NavigateToRouteEvent` or `OpenDialogEvent` for cross-cutting cases, Then it uses `navigatorKey` (or dialog context from that handler), not `BuildContext` from an unrelated feature subtree.
- Given a `ConsumerWidget` owns a screen or panel, When it passes dependencies to a **child in a different feature directory**, Then the child receives `AppEventBus`, data, or narrow listenables — not `WidgetRef` solely for cross-feature navigation or another panel’s behavior (**potential smell** if violated).

### Game feature screen wrapper

- Given a game-bound feature screen uses the shared wrapper with route game `G`, When `currentGameProvider` is null or has a different id, Then the wrapper builds feature content with route game `G`.
- Given a game-bound feature screen uses the shared wrapper with route game `G`, When `currentGameProvider` has id `G`, Then the wrapper builds feature content with the provider game value.
- Given a game-bound feature screen uses the shared wrapper with `attachGameToUiListener = true`, When it builds, Then the wrapper mounts `GameToUIBusListener(gameId: G.id)` around `CtScreenShell`.
- Given a game-bound feature screen uses the shared wrapper with `attachGameToUiListener = false`, When it builds, Then the wrapper renders `CtScreenShell` without `GameToUIBusListener`.

### Automated tests (widget / integration)

- Widget tests for `GameScreen`, `GameSideMenu`, and `TrainCiviliansDialog` / `CivilianUnitsPanel` cover pause menu, empire panels, and Train-via-bus behavior.
- Train dialog helper tests in `app/test/train_unit_dialog_helper_test.dart` cover shared count initialization, order materialization, and shared stepper count mutation helpers used by both train dialogs.
