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
| **`UIActionEvent`** with **`void Function(...)?`** filled by emitter for map/shell integration (e.g. `onLocateUnit` on `OpenCivilianUnitsPanelEvent`) | **Allowed** — not another panel widget’s API. |

---

## Typed panel events (preferred)

| Event | Opened by | Handler builds |
|-------|-----------|----------------|
| `OpenPauseMenuPanelEvent` | `GameScreen` (pause) | `PauseMenuPanel` |
| `OpenCivilianUnitsPanelEvent` | `GameSideMenu` | `CivilianUnitsPanel` (+ Riverpod game/orders) |
| `OpenMilitaryUnitsPanelEvent` | `GameSideMenu` | `MilitaryUnitsPanel` |
| `OpenNavalUnitsPanelEvent` | `GameSideMenu` | `NavalUnitsPanel` |

`onPanelDismissed` runs when the sheet route completes (e.g. map highlight cleanup).

---

## Dialog IDs (`OpenDialogEvent`)

Register builders in **`app/lib/core/services/app_event_handler_scope.dart`**.

| ID | Widget | Constant |
|----|--------|----------|
| `train_civilians` | `TrainCiviliansDialog` | `trainCiviliansDialogId` |
| `train_military` | `TrainMilitaryDialog` | `trainMilitaryDialogId` |
| `grant_or_subsidy` | `GrantOrSubsidyDialog` | `grantOrSubsidyDialogId` |
| `new_game_leader_selection` | `NewGameLeaderSelectionDialog` (six slots: **nation** + **leader** per slot; nation picker shows default GP map colour swatch beside each nation name; fair GP Old World assignment checkbox; initial nations = `GameSetupConfig.defaultConfig.selectedGreatPowerIds`) | `newGameLeaderSelectionDialogId` |

| ID | Widget | Status |
|----|--------|--------|
| `quick_battle_result` | `QuickBattleResultDialog` | planned (or local if combat UI stays internal) |
| `combat_mode_choice` | `CombatModeChoiceDialog` | same |

**Local by design (no `OpenDialogEvent`):** map display options (`GameMapArea`), tech detail (`TechTreeWidget`), split fleet (`NavalUnitsPanel`), civilian work-target sheet (`CivilianUnitsPanel`), next-turn confirmation (`GameMapArea`), in-game Android back exit confirmation (`GameScreen`), research tech picker (`TechnologyPanel`), **`CtDropdown`** internal picker, **new-game setup progress and error dialogs** after leader confirmation (see **SPEC/ui/game-initializing.md**).

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

---

## Migration checklist

### Done
- `grant_or_subsidy`, diplomacy detail nav/back, shell new-game leader + load-game nav, macOS debug log via bus (see [app-event-bus.md](app-event-bus.md) for service emissions).

### Optional
- Combat dialogs: bus vs local per **When to use the bus vs local**.
- New shared panels: prefer **typed** `UIActionEvent` subclasses over **`OpenPanelEvent(panelId)`**.

---

## Constraints (wiring)

- **Cross-cutting UI** must not use **`Ref` / `BuildContext` / `Navigator` chains** between unrelated widgets; use **`AppEventBus`** and **`AppEventHandler`**. **Panel-to-panel `onXxx` orchestration is disallowed.**
- **Dialog builders** and route handling: one place at shell init — see [app-event-bus.md](app-event-bus.md) constraints for package boundaries and event payload rules.

---

## Acceptance Criteria (Given–When–Then)

### Typed panels and decoupling

- Given `GameSideMenu` is mounted with a valid `currentGameProvider`, When the user chooses Civilian Units, Then the system emits `OpenCivilianUnitsPanelEvent` (not `showModalBottomSheet` from `GameSideMenu`).
- Given `CivilianUnitsPanel` is mounted with a bus, When the user taps Train, Then the system emits `OpenDialogEvent(trainCiviliansDialogId)` (panel does not call `showDialog` directly for that action).
- Given `MilitaryUnitsPanel` is mounted with a bus, When the user taps Train, Then the system emits `OpenDialogEvent(trainMilitaryDialogId)` (panel does not call `showDialog` directly for that action).
- Given `DiplomacyPanel` is mounted with a bus, When the user taps Grant Aid or Set Subsidy, Then the system emits `OpenDialogEvent('grant_or_subsidy')` (panel does not call `showDialog` directly).
- Given `DiplomacyPanel` is mounted with a bus, When the user taps a faction row, Then the system emits `NavigateToRouteEvent(Routes.diplomacyDetail)` (panel does not call `Navigator.push` directly).

### Coupling rules

- Given an empire panel specified to use the bus for a navigation or shared-dialog action (e.g. `DiplomacyPanel`), When that action runs, Then the panel emits the corresponding `UIActionEvent` via `AppEventBus` and does not use `Navigator.of(context).push`, `pushNamed`, or `showDialog` for that action (dismissing a **local** route remains allowed per **Local by design**).
- Given two distinct panels under `features/game/widgets/`, When one must show another **feature’s** UI, Then the first emits a typed `AppEvent` and does not call an `onXxx` callback supplied from the other panel’s widget API.
- Given `AppEventHandler` is bound at the shell, When it handles `NavigateToRouteEvent` or `OpenDialogEvent` for cross-cutting cases, Then it uses `navigatorKey` (or dialog context from that handler), not `BuildContext` from an unrelated feature subtree.
- Given a `ConsumerWidget` owns a screen or panel, When it passes dependencies to a **child in a different feature directory**, Then the child receives `AppEventBus`, data, or narrow listenables — not `WidgetRef` solely for cross-feature navigation or another panel’s behavior (**potential smell** if violated).

### Automated tests (widget / integration)

- Widget tests for `GameScreen`, `GameSideMenu`, and `TrainCiviliansDialog` / `CivilianUnitsPanel` cover pause menu, empire panels, and Train-via-bus behavior.
