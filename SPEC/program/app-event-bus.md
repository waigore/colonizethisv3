# App Event Bus — SPEC/program/app-event-bus.md

**SPEC/program** — Typed event bus for decoupling UI↔UI, UI↔game logic, and game logic→UI communication. Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Background / Motivation

Direct `showDialog()` and `Navigator.of(context).push()/pop()` calls couple UI widgets to each other, making testing harder and preventing service-layer access to UI actions. A typed event bus lets any component emit actions (open dialog, navigate) without knowing who handles them, and lets handlers be composed, swapped, or tested in isolation.

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
  │ - UI widgets │                    │ (shell level)      │
  │ - Services   │                    │                    │
  │ - Game logic │                    │ on<UIActionEvent>  │
  └──────────────┘                    │   → showDialog     │
                                     │   → Navigator.push │
                                     │ on<UISystemEvent>  │
                                     │   → SnackBar      │
                                     └─────────────────────┘
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
│   ├── OpenPanelEvent(panelId, params?)
│   ├── ClosePanelEvent()
│   ├── StartTargetSelectionEvent(unitId, action, onComplete?, onCancel?)
│   └── CancelTargetSelectionEvent()
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

## Dialog/Panel IDs

| ID | Widget | Builder location |
|----|--------|-----------------|
| `train_civilians` | `TrainCiviliansDialog` | `game_side_menu.dart` |
| `quick_battle_result` | `QuickBattleResultDialog` | `game_screen.dart` or `GameMapArea` |
| `combat_mode_choice` | `CombatModeChoiceDialog` | combat trigger site |
| `map_display_options` | inline `AlertDialog` | `GameMapArea` |
| `tech_detail` | inline tech dialog | `TechTreeWidget` |
| `grant_or_subsidy` | `GrantOrSubsidyDialog` | `DiplomacyDialogs` |
| `pause_menu` | pause bottom sheet | `GameScreen` |
| `civilian_units` | `CivilianUnitsPanel` bottom sheet | `GameSideMenu` |
| `military_units` | `MilitaryUnitsPanel` bottom sheet | `GameSideMenu` |
| `naval_units` | `NavalUnitsPanel` bottom sheet | `GameSideMenu` |

---

## Routes

Routes are named strings passed via `NavigateToRouteEvent`. Handled by `AppEventHandler` via `nav.pushNamed()`.

| Route name | Screen |
|------------|--------|
| `Routes.debugLog` | `DebugLogViewerScreen` |
| `Routes.production` | `ProductionScreen` (in-game, full screen) |
| `Routes.diplomacy` | `DiplomacyScreen` (in-game, full screen) |
| `Routes.technology` | `TechnologyScreen` (in-game, full screen) |

---

## Game Logic → UI Bridge

`GameService` holds an optional `AppEventBus? eventBus`. When set, it emits `GameToUIEvent` variants after game state changes:

- `TurnResolutionCompleteEvent` after `runTurnResolution` returns `TurnResolutionComplete`
- `SaveGameCompleteEvent` after `saveGame()`
- `NewGameCreatedEvent` after `createNewGame()`

The raw `GameEvent` stream from `TurnResolver` is forwarded by passing `void Function(GameEvent)? onGameEvent` — callers are responsible for bridging to `AppEventBus` if needed.

---

## Migration Plan

### Phase 1: Confirm dialogs (UI→UI, no return coupling)
- `diplomacy_panel.dart` `_showConfirmDialog` → `ConfirmDialogEvent`
- `civilian_units_panel.dart` `_confirmCancel` → `ConfirmDialogEvent`

### Phase 2: Route navigation (UI→UI via Navigator.pushNamed)
- `game_screen.dart` `_showPauseMenu` → `NavigateToRouteEvent` + `PopNavigationEvent`
- `game_side_menu.dart` Production/Diplomacy/Technology pushes → `NavigateToRouteEvent`

### Phase 3: Bottom sheets and panels (UI→UI via showModalBottomSheet)
- `game_side_menu.dart` Civilian/Military/Naval units bottom sheets → `OpenPanelEvent`
- `game_screen.dart` pause menu bottom sheet → `OpenPanelEvent`

### Phase 4: Named dialogs (fire-and-forget)
- `QuickBattleResultDialog` → `OpenDialogEvent` + registered builder
- `CombatModeChoiceDialog` → refactored to use event + Future result pattern
- `TrainCiviliansDialog` → `OpenDialogEvent` + registered builder
- `GrantOrSubsidyDialog` → `OpenDialogEvent` + registered builder
- `Tech detail dialog` → `OpenDialogEvent` + registered builder
- `Map display options` → `OpenDialogEvent` + registered builder

---

## Acceptance Criteria

### Event Bus Core
- [ ] `AppEventBus` is a singleton with `emit()` and `on<T>()` methods
- [ ] `on<T>()` returns a `Stream<T>` that only emits events of type `T`
- [ ] Multiple listeners can coexist (broadcast stream)
- [ ] `dispose()` closes the controller without error

### AppEventHandler
- [ ] `bind()` starts subscriptions; `unbind()` cancels them
- [ ] `OpenDialogEvent(dialogId)` calls `showDialog` with registered builder
- [ ] `OpenDialogEvent(unknownId)` prints debug warning, does not throw
- [ ] `ConfirmDialogEvent` returns `true` when confirm pressed, `false` when cancel pressed
- [ ] `NavigateToRouteEvent(route)` calls `nav.pushNamed(route, arguments)`
- [ ] `PopNavigationEvent` calls `nav.pop()`
- [ ] `OpenPanelEvent(panelId)` calls `showModalBottomSheet` with registered builder
- [ ] `ClosePanelEvent` calls `nav.maybePop()`
- [ ] `ShowSnackBarEvent` calls `onShowSnackBar` callback when registered
- [ ] `ShowOverlayEvent` calls `onShowOverlay` callback when registered
- [ ] `DismissOverlayEvent` calls `onDismissOverlay` callback when registered

### Migration
- [ ] `game_screen.dart` `_showPauseMenu` uses event bus only (no direct Navigator)
- [ ] `game_side_menu.dart` unit panels (civilian/military/naval) use `OpenPanelEvent`
- [ ] `game_side_menu.dart` full-screen routes use `NavigateToRouteEvent`
- [ ] `diplomacy_panel.dart` `_showConfirmDialog` uses `ConfirmDialogEvent`
- [ ] `civilian_units_panel.dart` `_confirmCancel` uses `ConfirmDialogEvent`
- [ ] `TrainCiviliansDialog` is registered as `train_civilians` dialog builder
- [ ] `QuickBattleResultDialog` is registered and opened via `OpenDialogEvent`
- [ ] `CombatModeChoiceDialog` is registered and opened via event with Future return

### GameService Bridge
- [ ] `GameService` has `AppEventBus? eventBus` field
- [ ] After `runTurnResolution` returns `TurnResolutionComplete`, emits `TurnResolutionCompleteEvent`
- [ ] No event emitted when `eventBus` is `null`

### Tests
- [ ] `AppEventBus` unit test: emit → on<T> delivers event
- [ ] `AppEventBus` unit test: multiple listeners all receive events
- [ ] `AppEventBus` unit test: on<T> only receives matching events
- [ ] `AppEventBus` unit test: dispose prevents further events
- [ ] `UIActionEvent` subclasses are equality-comparable (same params → equal)
- [ ] `UISystemEvent` subclasses are equality-comparable
- [ ] `GameToUIEvent` subclasses are equality-comparable
- [ ] `AppEventHandler` test: `OpenDialogEvent` calls registered builder with params
- [ ] `AppEventHandler` test: `NavigateToRouteEvent` calls `pushNamed`
- [ ] `AppEventHandler` test: `ConfirmDialogEvent` returns bool from dialog result
- [ ] `AppEventHandler` test: `OpenPanelEvent` calls `showModalBottomSheet`
- [ ] `AppEventHandler` test: `PopNavigationEvent` calls `nav.pop()`
- [ ] Widget test: emitting `OpenDialogEvent` from a widget triggers dialog display
- [ ] Widget test: `ConfirmDialogEvent` result flows back to emitter

---

## Constraints

- `GameEvent` lives in `colonizethis_logic` (avoids circular dep with `colonizethis_models`); `DialogueEvent`/`PortraitMoodEvent` live in `colonizethis_models`.
- No Flutter imports in `colonizethis_models` package — event bus and handlers live in `app/`.
- Dialog builders are registered at shell init time; unknown IDs log a warning.
- Event emission is fire-and-forget; `ConfirmDialogEvent` is the exception (returns `Future<bool>`).
- Province ids in any game events are always **prefixed** (`regionId|localId`).
