# App Event Bus — SPEC/program/app-event-bus.md

**SPEC/program** — Typed event bus for decoupling UI↔UI, UI↔game logic, and game logic→UI communication. Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Background / Motivation

Direct `showDialog()` and `Navigator.of(context).push()/pop()` calls couple UI widgets to each other, making testing harder and preventing service-layer access to UI actions. A typed event bus lets any component emit actions (open dialog, navigate) without knowing who handles them, and lets handlers be composed, swapped, or tested in isolation.

---

## Principles

- **Stable handlers, not ephemeral refs:** Panels, side menus, and routes that close before an async action completes must not capture `WidgetRef` or other context that becomes invalid on dispose. Emit a typed **command event** (e.g. `SessionCommandEvent`); a **long-lived** shell listener (e.g. `AppEventHandlerScope`) applies mutations using a stable ref.
- **No coupling on sibling mount state:** Do not assume another widget is still mounted when handling user actions. The emitter publishes intent; the subscriber owns session state and may outlive any single panel.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AppEventBus (singleton)                   │
│   emit(AppEvent)  ─────────────────────►  stream                │
└─────────────────────────────────────────────────────────────────┘
         ▲                                        │
         │ emit                                  │ listen
         │                                        ▼
  ┌──────────────┐                    ┌─────────────────────┐
  │ Emitters     │                    │ AppEventHandler     │
  │ - UI widgets │                    │ (shell level)       │
  │ - Services   │                    │                     │
  │ - Game logic │                    │ typed panel events  │
  └──────────────┘                    │ → bottom sheets     │
         │                            │ on<UIActionEvent>   │
         │                            │ on<UISystemEvent>   │
         │                            └─────────────────────┘
         │
         ▼
  ┌──────────────────────────────────────────────────────┐
  │ Screens (GameScreen, Production, Diplomacy, Tech…)   │
  │ subscribe via bus.on<TurnResolutionCompleteEvent>()  │
  │ (e.g. GameToUIBusListener) — no central GameToUI hub │
  └──────────────────────────────────────────────────────┘
```

---

## Event Hierarchy

```
AppEvent (sealed)
├── UIActionEvent        — UI requests other UI actions
│   ├── OpenDialogEvent(dialogId, params?)
│   ├── ConfirmDialogEvent(title, message, confirmLabel, cancelLabel) → bool
│   ├── NavigateToRouteEvent(route, arguments?)
│   ├── PopNavigationEvent()
│   ├── OpenPanelEvent(panelId, params?)   // legacy string id
│   ├── OpenPauseMenuPanelEvent(onDebugLog?, onResume?)
│   ├── OpenCivilianUnitsPanelEvent(onLocateUnit, onStartWorkTargetSelection, onPanelDismissed?)
│   ├── OpenMilitaryUnitsPanelEvent(onLocateTile, onPanelDismissed?)
│   ├── OpenNavalUnitsPanelEvent(onLocateFleet, onPanelDismissed?)
│   ├── ClosePanelEvent()
│   ├── StartTargetSelectionEvent(unitId, action, onComplete?, onCancel?)
│   ├── CancelTargetSelectionEvent()
│   └── GrantOrSubsidySubmittedEvent(targetFactionId, amount, isSubsidy)
│
├── SessionCommandEvent  — session mutations; shell listeners only (not AppEventHandler)
│   ├── RemovePendingWorkOrderRequestedEvent(playerId, index)
│   ├── CancelInProgressCivilianWorkRequestedEvent(unitId)
│   └── NavalFleetsUpdatedEvent(game)
│
├── UISystemEvent        — transient system feedback
│   ├── ShowSnackBarEvent(message, actionLabel?, action?)
│   ├── ShowOverlayEvent(overlayId, params?)
│   ├── DismissOverlayEvent(overlayId)
│   └── NotifyEvent(title, body, priority?)
│
└── GameToUIEvent       — game layer → UI triggers
    ├── TurnResolutionCompleteEvent(gameId, turnNumber)
    ├── OvertureRequiredEvent(overtures)
    ├── SaveGameCompleteEvent(gameId)
    └── NewGameCreatedEvent(gameId)
```

---

## Event Bus API

```dart
class AppEventBus {
  factory AppEventBus() => _instance ??= AppEventBus._();
  static AppEventBus? _instance;

  void emit(AppEvent event);          // broadcast to all listeners
  Stream<AppEvent> get stream;        // raw stream
  Stream<T> on<T extends AppEvent>(); // typed filter

  // Convenience streams
  Stream<UIActionEvent>  get uiActionEvents;
  Stream<UISystemEvent>  get uiSystemEvents;
  Stream<GameToUIEvent>  get gameToUIEvents;
  Stream<SessionCommandEvent> get sessionCommandEvents;
  Stream<DialogueEvent>  get dialogueEvents;
  Stream<PortraitMoodEvent> get portraitMoodEvents;

  void dispose();
}
```

---

## AppEventHandler

`AppEventHandler` lives at the shell level and translates events into Flutter calls.

```dart
class AppEventHandler {
  AppEventHandler({
    required AppEventBus bus,
    required GlobalKey<NavigatorState> navigatorKey,
    Map<String, DialogBuilder>? dialogBuilders,    // dialogId → builder
    Map<String, PanelBuilder>? panelBuilders,      // panelId → builder
    void Function(ShowSnackBarEvent)? onShowSnackBar,
    void Function(ShowOverlayEvent)? onShowOverlay,
    void Function(DismissOverlayEvent)? onDismissOverlay,
    void Function(NotifyEvent)? onNotify,
  });

  void bind();   // start listening (call in initState)
  void unbind(); // stop listening (call in dispose)
}
```

**DialogBuilder**: `Widget Function(BuildContext, Map<String, Object?>? params?)`

**PanelBuilder**: `Widget Function(BuildContext, Map<String, Object?>? params?)`

---

## Typed panel events (preferred)

| Event | Opened by | Handler builds |
|-------|-----------|----------------|
| `OpenPauseMenuPanelEvent` | `GameScreen` (pause) | `PauseMenuPanel` |
| `OpenCivilianUnitsPanelEvent` | `GameSideMenu` | `CivilianUnitsPanel` (+ Riverpod game/orders, `AppEventBus`) |
| `OpenMilitaryUnitsPanelEvent` | `GameSideMenu` | `MilitaryUnitsPanel` |
| `OpenNavalUnitsPanelEvent` | `GameSideMenu` | `NavalUnitsPanel` (+ `AppEventBus`) |

`onPanelDismissed` on unit panel events runs when the sheet route completes (e.g. map highlight cleanup).

**Civilian / naval work and fleets:** `CivilianUnitsPanel` emits `RemovePendingWorkOrderRequestedEvent` and `CancelInProgressCivilianWorkRequestedEvent`; `NavalUnitsPanel` emits `NavalFleetsUpdatedEvent` after split/combine. `AppEventHandlerScope` subscribes and updates `currentOrdersProvider` / `currentGameProvider` using `colonizethis_logic` (`removePendingWorkOrderAt`, `clearUnitCurrentWork`). Panels do not receive Riverpod `ref` for those mutations.

## Dialog IDs (`OpenDialogEvent`)

| ID | Widget | Registered in |
|----|--------|----------------|
| `train_civilians` | `TrainCiviliansDialog` | `app_event_handler_scope.dart` (`trainCiviliansDialogId`) |
| `grant_or_subsidy` | `GrantOrSubsidyDialog` | `app_event_handler_scope.dart` (`grantOrSubsidyDialogId`) |

| ID | Widget | Status |
|----|--------|--------|
| `quick_battle_result` | `QuickBattleResultDialog` | planned |
| `combat_mode_choice` | `CombatModeChoiceDialog` | planned |
| `map_display_options` | inline `AlertDialog` | planned |
| `tech_detail` | tech detail dialog | planned |
| `split_fleet` | `SplitFleetDialog` | planned |

---

## Routes

Routes are named strings passed via `NavigateToRouteEvent`. Handled by `AppEventHandler` via `nav.pushNamed()`.

| Route name | Screen |
|------------|--------|
| `Routes.debugLog` | `DebugLogViewerScreen` |
| `Routes.production` | `ProductionScreen` (in-game, full screen) |
| `Routes.diplomacy` | `DiplomacyScreen` (in-game, full screen) |
| `Routes.diplomacyDetail` | `DiplomacyDetailScreen` (in-game, full screen) |
| `Routes.technology` | `TechnologyScreen` (in-game, full screen) |

---

## Game Logic → UI Bridge

`GameService` holds an optional `AppEventBus? eventBus` (wired from Riverpod in the app). When set, it emits:

- `TurnResolutionCompleteEvent` after `runTurnResolution` or `resumeOvertureDecisions` completes with `TurnResolutionComplete`
- `NewGameCreatedEvent` after `createNewGame()` saves

**Consumption:** There is no single shell subscriber for `GameToUIEvent`. Each screen that must react mounts its own subscription (e.g. `GameToUIBusListener` wraps `GameScreen`, `ProductionScreen`, `DiplomacyScreen`, `TechnologyScreen` for `TurnResolutionCompleteEvent` and reloads `currentGameProvider` via `GameService.loadGame` when the event’s `gameId` matches the mounted screen’s game and `currentGameProvider` already holds that game).

The raw `GameEvent` stream from `TurnResolver` remains available via `void Function(GameEvent)? onGameEvent` for logic-layer consumers.

---

## Remaining migration

### Completed
- `grant_or_subsidy` dialog → `OpenDialogEvent('grant_or_subsidy')` via `GrantOrSubsidyDialog` widget + `GrantOrSubsidySubmittedEvent`
- `DiplomacyDetailScreen` push → `NavigateToRouteEvent(Routes.diplomacyDetail)`
- `DiplomacyDetailScreen` back button → `PopNavigationEvent` via `DiplomacyDetailScreen` as `ConsumerWidget`

### Planned
- Replace remaining inline dialogs with `OpenDialogEvent` + builders:
  - `quick_battle_result` (`QuickBattleResultDialog`)
  - `combat_mode_choice` (`CombatModeChoiceDialog`)
  - `map_display_options` (inline `AlertDialog` in `GameMapArea`)
  - `tech_detail` (inline dialog in `TechTreeWidget`)
  - `split_fleet` (`SplitFleetDialog` in `NavalUnitsPanel`)
- Prefer new typed panel events over `OpenPanelEvent(panelId)` for any new panels.

---

## Acceptance Criteria (Given–When–Then)

### Event bus core

- Given a fresh `AppEventBus` from `AppEventBus.create()` and a listener on `on<OpenDialogEvent>()`, When the system emits any `OpenDialogEvent`, Then the listener receives exactly that event and no other `UIActionEvent` types on that stream.
- Given two subscribers on `bus.stream`, When the system emits one `PopNavigationEvent`, Then both subscribers each receive one event.
- Given a bus on which `dispose()` has been called, When a test calls `emit` again, Then the call throws or fails as defined by the stream contract (no silent delivery).

### AppEventHandler

- Given `AppEventHandler` is bound with a registered `trainCiviliansDialogId` builder, When the system emits `OpenDialogEvent('train_civilians')`, Then `showDialog` runs and the dialog widget tree is present.
- Given `AppEventHandler` is bound, When the system emits `OpenPauseMenuPanelEvent`, Then a modal bottom sheet appears listing Debug log and Resume.
- Given `AppEventHandler` is bound, When the system emits `OpenDialogEvent` with an unknown `dialogId`, Then the handler logs a debug warning and does not throw.
- Given `ConfirmDialogEvent` with `onResult`, When the user taps confirm, Then `onResult(true)` runs; When the user taps cancel, Then `onResult(false)` runs.

### Typed panels and decoupling

- Given `GameSideMenu` is mounted with a valid `currentGameProvider`, When the user chooses Civilian Units, Then the system emits `OpenCivilianUnitsPanelEvent` (not `showModalBottomSheet` from `GameSideMenu`).
- Given `CivilianUnitsPanel` is mounted with a bus, When the user taps Train, Then the system emits `OpenDialogEvent(trainCiviliansDialogId)` (panel does not call `showDialog` directly).
- Given `DiplomacyPanel` is mounted with a bus, When the user taps a Grant Aid or Set Subsidy action, Then the system emits `OpenDialogEvent('grant_or_subsidy')` (panel does not call `showDialog` directly).
- Given `DiplomacyPanel` is mounted with a bus, When the user taps a faction row, Then the system emits `NavigateToRouteEvent(Routes.diplomacyDetail)` (panel does not call `Navigator.push` directly).

### GameToUI and screens

- Given `GameToUIBusListener` wraps a widget for `gameId` G and `currentGameProvider` is G, When the bus emits `TurnResolutionCompleteEvent` for G with a newer turn saved in `GameService`, Then `currentGameProvider` updates to the loaded game from storage.
- Given `GameToUIBusListener` for `gameId` G, When the bus emits `TurnResolutionCompleteEvent` for a different game id, Then `currentGameProvider` is unchanged.

### GameService bridge

- Given `GameService.eventBus` is non-null, When `runTurnResolution` completes with `TurnResolutionComplete`, Then the service emits `TurnResolutionCompleteEvent` with matching `gameId` and `turnNumber`.
- Given `GameService.eventBus` is null, When `runTurnResolution` completes with `TurnResolutionComplete`, Then no `TurnResolutionCompleteEvent` is emitted.

### Automated tests (must pass in CI)

- `app/test/app_event_bus_test.dart` covers bus delivery, filtering, dispose, and equality for `UIActionEvent` / `UISystemEvent` / `GameToUIEvent` (including `OpenPauseMenuPanelEvent` where const).
- `app/test/app_event_handler_test.dart` covers `OpenDialogEvent`, `NavigateToRouteEvent`, `ConfirmDialogEvent`, `OpenPanelEvent`, `OpenPauseMenuPanelEvent`, `PopNavigationEvent`, and snackbar/overlay callbacks.
- `app/test/game_to_ui_bus_listener_test.dart` covers `TurnResolutionCompleteEvent` → provider reload.
- Widget tests for `GameScreen`, `GameSideMenu`, and `TrainCiviliansDialog` / `CivilianUnitsPanel` cover pause menu, empire panels, and Train-via-bus behavior.

---

## Constraints

- `GameEvent` lives in `colonizethis_logic` (avoids circular dep with `colonizethis_models`); `DialogueEvent`/`PortraitMoodEvent` live in `colonizethis_models`.
- No Flutter imports in `colonizethis_models` package — event bus and handlers live in `app/`.
- Dialog builders are registered at shell init time; unknown IDs log a warning.
- Event emission is fire-and-forget; `ConfirmDialogEvent` carries `onResult` / `result()` for the bool outcome (user choice A: callback on the event).
- Province ids in any game events are always **prefixed** (`regionId|localId`).
