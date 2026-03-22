# App Event Bus (architecture) — SPEC/program/app-event-bus.md

**SPEC/program** — **`AppEventBus`** types, stream API, **`AppEventHandler`** contract, **`GameService` → UI** bridge, and **core** acceptance criteria. **How to wire panels, dialogs, routes, and coupling rules:** **[app-ui-wiring.md](app-ui-wiring.md)**. Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Background

A typed event bus lets emitters publish **`AppEvent`** subclasses without depending on who handles them. **`AppEventHandler`** (shell) turns **`UIActionEvent`** / **`UISystemEvent`** into Flutter **`Navigator`** / **`showDialog`** / snackbars. **UI authors:** follow **[app-ui-wiring.md](app-ui-wiring.md)** for when to emit vs local APIs and for **`Ref` / `BuildContext` bans**.

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

## Event hierarchy

Defined in **`colonizethis_models`** (`app_events.dart`, exports). Summary:

```
AppEvent (sealed)
├── UIActionEvent        — UI requests (dialogs, nav, panels, target selection, …)
├── UISystemEvent        — Snackbar, overlay, notify
└── GameToUIEvent        — TurnResolutionCompleteEvent, OvertureRequiredEvent, …
```

Full list of subclasses: source and **[app-ui-wiring.md](app-ui-wiring.md)** (dialog IDs / typed panels).

---

## Event bus API

```dart
class AppEventBus {
  factory AppEventBus() => _instance ??= AppEventBus._();
  static AppEventBus? _instance;

  void emit(AppEvent event);
  Stream<AppEvent> get stream;
  Stream<T> on<T extends AppEvent>();

  Stream<UIActionEvent>  get uiActionEvents;
  Stream<UISystemEvent>  get uiSystemEvents;
  Stream<GameToUIEvent>  get gameToUIEvents;
  Stream<DialogueEvent>  get dialogueEvents;
  Stream<PortraitMoodEvent> get portraitMoodEvents;

  void dispose();
}
```

**Implementation:** `packages/colonizethis_models/lib/src/app_event_bus.dart`. **App provider:** `app/lib/providers/app_event_bus_provider.dart`.

---

## AppEventHandler

Lives in **`app/`**. Translates **`UIActionEvent`** / **`UISystemEvent`** into Flutter APIs using **`GlobalKey<NavigatorState>`**.

```dart
class AppEventHandler {
  AppEventHandler({
    required AppEventBus bus,
    required GlobalKey<NavigatorState> navigatorKey,
    Map<String, DialogBuilder>? dialogBuilders,
    Map<String, PanelBuilder>? panelBuilders,
    void Function(ShowSnackBarEvent)? onShowSnackBar,
    void Function(ShowOverlayEvent)? onShowOverlay,
    void Function(DismissOverlayEvent)? onDismissOverlay,
    void Function(NotifyEvent)? onNotify,
  });

  void bind();
  void unbind();
}
```

**DialogBuilder:** `Widget Function(BuildContext, Map<String, Object?>? params?)`  
**PanelBuilder:** `Widget Function(BuildContext, Map<String, Object?>? params?)`

**Registration:** `app/lib/core/services/app_event_handler_scope.dart` — dialog IDs and panel wiring per **[app-ui-wiring.md](app-ui-wiring.md)**.

---

## Game logic → UI bridge

**`GameService`** (`app/lib/core/services/game_service.dart`) holds optional **`AppEventBus? eventBus`**. When set, it emits:

- **`TurnResolutionCompleteEvent`** after `runTurnResolution` / `resumeOvertureDecisions` completes with **`TurnResolutionComplete`**
- **`NewGameCreatedEvent`** after **`createNewGame()`** saves

**Consumption:** No single shell subscriber. Each screen that must react listens (e.g. **`GameToUIBusListener`**) and reloads **`currentGameProvider`** when **`gameId`** matches.

**`GameEvent`** from **`TurnResolver`** remains on **`void Function(GameEvent)? onGameEvent`** for logic-layer use.

---

## Acceptance Criteria (Given–When–Then)

### Event bus core

- Given a fresh **`AppEventBus`** from **`AppEventBus.create()`** and a listener on **`on<OpenDialogEvent>()`**, When the system emits any **`OpenDialogEvent`**, Then that listener receives exactly that event and no other **`UIActionEvent`** on that typed stream.
- Given two subscribers on **`bus.stream`**, When the system emits one **`PopNavigationEvent`**, Then both subscribers each receive one event.
- Given a bus on which **`dispose()`** has been called, When a test calls **`emit`** again, Then the call throws or fails per the stream contract (no silent delivery).

### AppEventHandler

- Given **`AppEventHandler`** is bound with a registered **`train_civilians`** dialog builder, When the system emits **`OpenDialogEvent('train_civilians')`**, Then **`showDialog`** runs and the dialog widget tree is present.
- Given **`AppEventHandler`** is bound, When the system emits **`OpenPauseMenuPanelEvent`**, Then a modal bottom sheet appears listing Debug log and Resume.
- Given **`AppEventHandler`** is bound, When the system emits **`OpenDialogEvent`** with an unknown **`dialogId`**, Then the handler logs a debug warning and does not throw.
- Given **`ConfirmDialogEvent`** with **`onResult`**, When the user taps confirm, Then **`onResult(true)`** runs; When the user taps cancel, Then **`onResult(false)`** runs.

### GameToUI and screens

- Given **`GameToUIBusListener`** wraps a widget for **`gameId` G** and **`currentGameProvider`** is G, When the bus emits **`TurnResolutionCompleteEvent`** for G with a newer turn saved in **`GameService`**, Then **`currentGameProvider`** updates to the loaded game from storage.
- Given **`GameToUIBusListener`** for **`gameId` G**, When the bus emits **`TurnResolutionCompleteEvent`** for a different game id, Then **`currentGameProvider`** is unchanged.

### GameService bridge

- Given **`GameService.eventBus`** is non-null, When **`runTurnResolution`** completes with **`TurnResolutionComplete`**, Then the service emits **`TurnResolutionCompleteEvent`** with matching **`gameId`** and **`turnNumber`**.
- Given **`GameService.eventBus`** is null, When **`runTurnResolution`** completes with **`TurnResolutionComplete`**, Then no **`TurnResolutionCompleteEvent`** is emitted.

### Automated tests (must pass in CI)

- **`app/test/app_event_bus_test.dart`** — delivery, filtering, **`dispose`**, equality for **`UIActionEvent`** / **`UISystemEvent`** / **`GameToUIEvent`**.
- **`app/test/app_event_handler_test.dart`** — **`OpenDialogEvent`**, **`NavigateToRouteEvent`**, **`ConfirmDialogEvent`**, **`OpenPanelEvent`**, **`OpenPauseMenuPanelEvent`**, **`PopNavigationEvent`**, snackbar/overlay callbacks.
- **`app/test/game_to_ui_bus_listener_test.dart`** — **`TurnResolutionCompleteEvent`** → provider reload.

Panel/widget coupling ACs: **[app-ui-wiring.md](app-ui-wiring.md)**.

---

## Constraints

- **`GameEvent`** lives in **`colonizethis_logic`**; **`DialogueEvent`** / **`PortraitMoodEvent`** in **`colonizethis_models`**.
- No Flutter imports in **`colonizethis_models`** for the bus — handler lives in **`app/`**.
- Dialog/panel builders registered at shell init; unknown dialog/panel IDs log a warning.
- Emission is fire-and-forget; **`ConfirmDialogEvent`** uses **`onResult`** / **`result()`** for the bool outcome.
- Province ids in game events: **prefixed** (`regionId|localId`).
- **Cross-cutting UI coupling** ( **`Ref` / context / `Navigator` chains**, panel **`onXxx` orchestration**): **[app-ui-wiring.md](app-ui-wiring.md)**.
