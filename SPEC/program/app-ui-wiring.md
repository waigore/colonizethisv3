# App UI wiring (event bus) — SPEC/program/app-ui-wiring.md

**SPEC/program** — Rules for **adding and wiring** Flutter UI to the **`AppEventBus`**: when to emit vs use local APIs, coupling bans, dialog/route registries, migration notes, and acceptance criteria for panel behavior. Event types, handler API, and `GameToUI` bridge: **[app-event-bus.md](app-event-bus.md)**. Province identity: [world-model-identity.md](../game/world-model-identity.md).

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
| `OpenNavalUnitsPanelEvent` | `GameSideMenu` | `NavalUnitsPanel` |

Sheet close cleanup should be emitted as a typed bus event (`UnitsPanelClosedEvent`) from the handler.

---

## Dialog IDs (`OpenDialogEvent`)

Register builders in **`app/lib/core/services/app_event_handler_scope.dart`**.

| ID | Widget | Constant |
|----|--------|----------|
| `train_civilians` | `TrainCiviliansDialog` | `trainCiviliansDialogId` |
| `train_military` | `TrainMilitaryDialog` | `trainMilitaryDialogId` |
| `grant_or_subsidy` | `GrantOrSubsidyDialog` | `grantOrSubsidyDialogId` |
| `new_game_leader_selection` | `NewGameLeaderSelectionDialog` (six slots: **nation** + **leader** per slot; nation picker shows default GP map colour swatch beside each nation name; fair GP Old World assignment checkbox; initial nations = `GameSetupConfig.defaultConfig.selectedGreatPowerIds`) | `newGameLeaderSelectionDialogId` |

For `train_civilians` and `train_military`, shared order/count orchestration must be implemented in `app/lib/features/game/widgets/train_unit_dialog_helper.dart`; keep dialog-specific economics and lock rules inside each dialog widget.

| ID | Widget | Status |
|----|--------|--------|
| `quick_battle_result` | `QuickBattleResultDialog` | `quickBattleResultDialogId` |
| `combat_mode_choice` | `CombatModeChoiceDialog` (`CombatModeChosenEvent` on choice) | `combatModeChoiceDialogId` |

**Local by design (no `OpenDialogEvent`):** map display options (`GameMapArea`), tech detail (`TechTreeWidget`), civilian work-target sheet (`CivilianUnitsPanel`), next-turn confirmation (`GameMapArea`), in-game Android back exit confirmation (`GameScreen`), research tech picker (`TechnologyPanel`), **`CtDropdown`** internal picker, **new-game setup progress and error dialogs** after leader confirmation (see **SPEC/ui/game-initializing.md**).

**Split fleet:** `NavalUnitsPanel` uses local `showDialog` for `SplitFleetDialog`, but the dialog commits via **`NavalSplitFleetRequestedEvent`** → `AppEventHandlerScope` (applies `applyNavalSplitFleet`, then emits **`NavalFleetsUpdatedEvent`**) so the dialog does not receive panel merge callbacks. Widgetbook / tests without the shell wire the same request event or listen for `NavalFleetsUpdatedEvent` only.

**Train at-capital dialogs:** `TrainCiviliansDialog` / `TrainMilitaryDialog` emit **`TrainCivilianBuildOrdersCommittedEvent`** / **`TrainMilitaryBuildOrdersCommittedEvent`** on close; `AppEventHandlerScope` merges into orders. No `onOrdersChanged` callback from the shell into the dialog.

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

## Migration checklist

### Done
- `grant_or_subsidy`, diplomacy detail nav/back, shell new-game leader + load-game nav, macOS debug log via bus (see [app-event-bus.md](app-event-bus.md) for service emissions).

### Optional
- New shared panels: prefer **typed** `UIActionEvent` subclasses over **`OpenPanelEvent(panelId)`**.

---

## Constraints (wiring)

- **Cross-cutting UI** must not use **`Ref` / `BuildContext` / `Navigator` chains** between unrelated widgets; use **`AppEventBus`** and **`AppEventHandler`**. **Panel-to-panel `onXxx` orchestration is disallowed.**
- **Dialog builders** and route handling: one place at shell init — see [app-event-bus.md](app-event-bus.md) constraints for package boundaries and event payload rules.

---

## Acceptance Criteria (Given–When–Then)

### Typed panels and decoupling

- Given `GameSideMenu` is mounted with a valid `currentGameProvider`, When the user chooses Civilian Units, Then the system emits `OpenCivilianUnitsPanelEvent` (not `showModalBottomSheet` from `GameSideMenu`).
- Given `CivilianUnitsPanel` is mounted with a bus, When the user taps Train, Then the system emits `ClosePanelEvent` and then `OpenDialogEvent(trainCiviliansDialogId)` (panel does not call `showDialog` or `Navigator.maybePop` on the handler-owned sheet for that action).
- Given `MilitaryUnitsPanel` is mounted with a bus, When the user taps Train, Then the system emits `ClosePanelEvent` and then `OpenDialogEvent(trainMilitaryDialogId)` under the same rules.
- Given a units sheet should close before the map reacts, When the player triggers locate or work-target selection from that sheet, Then the system emits `ClosePanelEvent` before `LocateMapTileEvent` or `StartCivilianWorkTargetSelectionEvent`; the map widget does not call `Navigator.maybePop` for that teardown.
- Given `DiplomacyPanel` is mounted with a bus, When the user taps Grant Aid or Set Subsidy, Then the system emits `OpenDialogEvent('grant_or_subsidy')` (panel does not call `showDialog` directly).
- Given `DiplomacyPanel` is mounted with a bus, When the user taps a faction row, Then the system emits `NavigateToRouteEvent(Routes.diplomacyDetail)` (panel does not call `Navigator.push` directly).

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
