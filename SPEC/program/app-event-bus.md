# App Event Bus (architecture) — SPEC/program/app-event-bus.md

**SPEC/program** — **`AppEventBus`** types, stream API, **`AppEventHandler`** contract, **`GameService` → UI** bridge, and **core** acceptance criteria. **How to wire panels, dialogs, routes, and coupling rules:** **[app-ui-wiring.md](app-ui-wiring.md)**. Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Background

A typed event bus lets emitters publish **`AppEvent`** subclasses without depending on who handles them. **`AppEventHandler`** (shell) turns **`UIActionEvent`** / **`UISystemEvent`** into Flutter **`Navigator`** / **`showDialog`** / snackbars. **UI authors:** follow **[app-ui-wiring.md](app-ui-wiring.md)** for when to emit vs local APIs and for **`Ref` / `BuildContext` bans**.

---

## Principles

- **Stable handlers, not ephemeral refs:** Panels, side menus, and routes that close before an async action completes must not capture `WidgetRef` or other context that becomes invalid on dispose. Emit a typed **command event** (e.g. `SessionCommandEvent`); a **long-lived** shell listener (e.g. `AppEventHandlerScope`) applies mutations using a stable ref.
- **No coupling on sibling mount state:** Do not assume another widget is still mounted when handling user actions. The emitter publishes intent; the subscriber owns session state and may outlive any single panel.

### Navigator, `maybePop`, and dialog/panel presentation

**Heavily discouraged** outside **`AppEventHandler`** (and the small set of flows explicitly marked **local by design** in **[app-ui-wiring.md](app-ui-wiring.md)**):

- Calling **`Navigator.of(context).push` / `pushNamed` / `popUntil` / `maybePop`** or **`showDialog` / `showModalBottomSheet`** from empire panels, the map, side menus, or shell to drive **cross-panel, cross-screen, or shell-level** behavior.
- Using **`maybePop`** to dismiss bottom sheets or routes that **`AppEventHandler`** opened with **`navigatorKey`**, except from **`AppEventHandler`** itself (e.g. handling **`ClosePanelEvent`**) or from documented local-only flows.

**Preferred:** Emit **`UIActionEvent`** subclasses (`NavigateToRouteEvent`, `NavigateToShellEvent`, `ClosePanelEvent`, `OpenDialogEvent`, typed panel opens, `LocateMapTileEvent`, etc.). **`AppEventHandler`** is the choke point that turns those into **`Navigator`** / **`showDialog`** using **`GlobalKey<NavigatorState>`**.

**Local-by-design exception:** **`Navigator.pop`** / **`showDialog`** entirely **inside one widget’s local UX** (same panel subtree, confirm steps, internal pickers; see **Local by design** in app-ui-wiring) remain allowed; they must not replace the bus for cross-cutting actions.

### Turn-resolution active guards (#2160)

While background **turn resolution** is active from the map, **`turnResolutionBlockingProvider`** is `true`. In that window:

- **`AppEventHandler`** suppresses **`UIActionEvent`** types that drive navigation/panels/dialogs (**not** **`OpenPauseMenuPanelEvent`** nor **`ClosePanelEvent`**) and logs **`logic:`** rejects for blocked actions.
- **`AppEventHandlerScope`** session-command listeners suppress mutations (orders/game/debug session commands); **`LandArmiesUpdatedEvent`** ingestion is also guarded so routed updates cannot slip past map **`IgnorePointer`**.

Locate intents (**`LocateMapTileEvent`**) remain map-local listeners; the handler ignores them regardless (unchanged routing).

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

Defined in **`colonizethis_models`** (`app_events.dart`, exports).

- **`UIActionEvent`** — dialogs, navigation, panels, map locate/selection intents, grants/subsidy submit; concrete types in source and **[app-ui-wiring.md](app-ui-wiring.md)**. Map minimap camera intents: **`RequestRegionMapCameraCenterWorldEvent`**, **`RequestRegionMapCameraPanWorldDeltaEvent`**, **`RequestRegionMapSetZoomMultiplierEvent`** ([empire-overview.md](../ui/empire-overview.md) § Region minimap). For `RequestRegionMapSetZoomMultiplierEvent`, the map host clamps `m` to **`[0.5, 8.0]`** (fit-relative zoom multiplier band).
- **`SessionCommandEvent`** — session mutations applied by long-lived shell listeners (e.g. **`AppEventHandlerScope`**), not by **`AppEventHandler`**. Includes **`RemovePendingWorkOrderRequestedEvent`**, **`CancelInProgressCivilianWorkRequestedEvent`**, **`NavalFleetsUpdatedEvent`**, **`NavalSplitFleetRequestedEvent`**, **`NavalMoveFleetRequestedEvent`** (naval panel → current‑turn orders draft), **`ArmyMoveRequestedEvent`** (optional **`declareWarTargetFactionId`** when the move dialog committed an invasion that requires a same-turn **declare war**), **`ArmySplitRequestedEvent`**, **`ArmyCombineRequestedEvent`**, **`LandArmiesUpdatedEvent`** (military panel → orders draft / game state per TDD), **`TrainCivilianBuildOrdersCommittedEvent`**, **`TrainMilitaryBuildOrdersCommittedEvent`**.
- **`UISystemEvent`** — snackbar, overlay, notify.
- **`GameToUIEvent`** — e.g. **`TurnResolutionCompleteEvent`**, **`OvertureRequiredEvent`**, **`InterventionRequiredEvent`**, **`CallToArmsRequiredEvent`**, **`NewGameCreatedEvent`**, **`SaveGameCompleteEvent`**, plus bridge types **`AppCombatResultEvent`**, **`AppProvinceCapturedEvent`**, **`AppDiplomacyChangeEvent`**, **`AppResearchCompleteEvent`**, **`AppVictorySetEvent`**, **`AppOrderRejectedEvent`** (**SPEC/program/game-event-bridge.md**).

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
  Stream<SessionCommandEvent> get sessionCommandEvents;
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

- **DialogBuilder:** `Widget Function(BuildContext, Map<String, Object?>? params?)`
- **PanelBuilder:** `Widget Function(BuildContext, Map<String, Object?>? params?)`

**Registration:** `app/lib/core/services/app_event_handler_scope.dart` — dialog IDs and panel wiring per **[app-ui-wiring.md](app-ui-wiring.md)**.

---

## Game logic → UI bridge

**`GameService`** (`app/lib/core/services/game_service.dart`) holds optional **`AppEventBus? eventBus`** and optional **`GameEventBus? logicEventBus`**. When **`eventBus`** is set, it emits:

- **`TurnResolutionCompleteEvent`** after `runTurnResolution` or any resume method completes with **`TurnResolutionComplete`**
- **`NewGameCreatedEvent`** after a new game is created and saved (sync **`createNewGame()`** or async phased **`createNewGameAsync()`** used by the shell)
- **`OvertureRequiredEvent`** when `runTurnResolution` or a resume method returns **`TurnResolutionPendingOvertures`**
- **`InterventionRequiredEvent`** when `runTurnResolution` or a resume method returns **`TurnResolutionPendingIntervention`**
- **`CallToArmsRequiredEvent`** when `runTurnResolution` or a resume method returns **`TurnResolutionPendingCallToArms`**

When **`logicEventBus`** is set, turn resolution passes it into **`resolveTurnForGame`** and the **`resumeTurnResolutionWith*`** entry points so **`GameEventBridge`** can subscribe and map logic **`GameEvent`** instances to **`GameToUIEvent`** on the app bus. **Full bridge:** **SPEC/program/game-event-bridge.md**.

**Typed panels** (shell **`AppEventHandler`**): full **`Ref` / callback rules** in **[app-ui-wiring.md](app-ui-wiring.md)**.

| Event | Opened by | Handler builds |
|-------|-----------|----------------|
| `OpenPauseMenuPanelEvent` | `GameScreen` (pause) | `PauseMenuPanel` |
| `OpenCivilianUnitsPanelEvent` | `GameSideMenu`, province Tile inline shortcuts | `CivilianUnitsPanel` (+ Riverpod game/orders, `AppEventBus`). Optional shortcut fields (at most one non-null): `exploreShortcutTargetTileKey`, `prospectShortcutTargetTileKey`, `buildImprovementShortcutTargetTileKey` — each opens the panel in the matching filtered shortcut mode for direct assign on that tile key. |
| `OpenMilitaryUnitsPanelEvent` | `GameSideMenu` | `MilitaryUnitsPanel` |
| `OpenNavalUnitsPanelEvent` | `GameSideMenu`, map fleet marker tap | `NavalUnitsPanel` (+ `AppEventBus`); optional `locationScopeKey`, `initialSelectedFleetId`, `tileScopeTileKey` for tile-scoped list and header |

**Civilian / naval work and fleets:** `CivilianUnitsPanel` emits `StartCivilianWorkTargetSelectionEvent`, `LocateMapTileEvent`, `RemovePendingWorkOrderRequestedEvent`, and `CancelInProgressCivilianWorkRequestedEvent`; `MilitaryUnitsPanel` / `NavalUnitsPanel` emit `LocateMapTileEvent`; `MilitaryUnitsPanel` emits **`ArmyMoveRequestedEvent`**, **`ArmySplitRequestedEvent`**, **`ArmyCombineRequestedEvent`**, and **`LandArmiesUpdatedEvent`** when army state changes; `NavalUnitsPanel` emits `NavalFleetsUpdatedEvent` after combine; split uses `SplitFleetDialog` → **`NavalSplitFleetRequestedEvent`** → scope applies and emits **`NavalFleetsUpdatedEvent`**. Train dialogs emit **`TrainCivilianBuildOrdersCommittedEvent`** / **`TrainMilitaryBuildOrdersCommittedEvent`** on close; scope merges orders. `AppEventHandlerScope` subscribes and updates `currentOrdersProvider` / `currentGameProvider` using `colonizethis_logic` where applicable (`removePendingWorkOrderAt`, `clearUnitCurrentWork`). Panels do not receive Riverpod `ref` for those mutations.

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
- Given **`AppEventHandler`** is bound with routes **`shell`** and **`game`** on the stack, When the system emits **`NavigateToShellEvent`**, Then the navigator returns to the **`shell`** route.
- Given **`AppEventHandler`** is bound, When the system emits **`OpenDialogEvent`** with an unknown **`dialogId`**, Then the handler logs a debug warning and does not throw.
- Given **`ConfirmDialogEvent`** with **`onResult`**, When the user taps confirm, Then **`onResult(true)`** runs; When the user taps cancel, Then **`onResult(false)`** runs.

### GameToUI and screens

- Given **`GameToUIBusListener`** wraps a widget for **`gameId` G** and **`currentGameProvider`** is G, When the bus emits **`TurnResolutionCompleteEvent`** for G with a newer turn saved in **`GameService`**, Then **`currentGameProvider`** updates to the loaded game from storage.
- Given **`GameToUIBusListener`** for **`gameId` G**, When the bus emits **`TurnResolutionCompleteEvent`** for a different game id, Then **`currentGameProvider`** is unchanged.

### GameService bridge

- Given **`GameService.eventBus`** is non-null, When **`runTurnResolution`** completes with **`TurnResolutionComplete`**, Then the service emits **`TurnResolutionCompleteEvent`** with matching **`gameId`** and **`turnNumber`**.
- Given **`GameService.eventBus`** is null, When **`runTurnResolution`** completes with **`TurnResolutionComplete`**, Then no **`TurnResolutionCompleteEvent`** is emitted.

### GameEventBridge (SPEC/program/game-event-bridge.md)

- Given a `GameEventBridge` started with a `DefaultGameEventBus` as logicBus and `AppEventBus` as appBus, When the logic bus publishes `CombatResultEvent`, Then `AppEventBus` receives exactly one `AppCombatResultEvent` with matching fields.
- Given a `GameEventBridge` started, When the logic bus publishes `ProvinceCapturedEvent`, `DiplomacyChangeEvent`, `ResearchCompleteEvent`, `VictorySetEvent`, or `OrderRejectedEvent`, Then `AppEventBus` receives the corresponding `AppProvinceCapturedEvent`, `AppDiplomacyChangeEvent`, `AppResearchCompleteEvent`, `AppVictorySetEvent`, or `AppOrderRejectedEvent`.
- Given a `GameEventBridge` started, When `stop()` is called, Then subsequent events on the logic bus are not forwarded.
- Given `GameService` with `eventBus` set, When `runTurnResolution` returns `TurnResolutionPendingOvertures`, Then `AppEventBus` has emitted `OvertureRequiredEvent` before the result is returned.
- Given `GameService` with `eventBus` set, When `runTurnResolution` returns `TurnResolutionPendingIntervention`, Then `AppEventBus` has emitted `InterventionRequiredEvent` before the result is returned.
- Given `GameService` with `eventBus` set, When `runTurnResolution` returns `TurnResolutionPendingCallToArms`, Then `AppEventBus` has emitted `CallToArmsRequiredEvent` before the result is returned.

### Automated tests (must pass in CI)

- **`app/test/app_event_bus_test.dart`** — delivery, filtering, **`dispose`**, equality for **`UIActionEvent`** / **`UISystemEvent`** / **`GameToUIEvent`** (including new **`GameToUIEvent`** subtypes where applicable).
- **`app/test/app_event_handler_test.dart`** — **`OpenDialogEvent`**, **`NavigateToRouteEvent`**, **`NavigateToShellEvent`**, **`ClosePanelEvent`** sequencing, **`ConfirmDialogEvent`**, **`OpenPanelEvent`**, **`OpenPauseMenuPanelEvent`**, **`PopNavigationEvent`**, combat choice (**`CombatModeChosenEvent`**), snackbar/overlay callbacks.
- **`app/test/game_to_ui_bus_listener_test.dart`** — **`TurnResolutionCompleteEvent`** → provider reload.
- **`app/test/game_event_bridge_test.dart`** — bridge forwarding of **`GameEvent`** → **`GameToUIEvent`** mappings.

Panel/widget coupling ACs: **[app-ui-wiring.md](app-ui-wiring.md)**.

---

## Constraints

- **`GameEvent`** lives in **`colonizethis_logic`**; **`DialogueEvent`** / **`PortraitMoodEvent`** in **`colonizethis_models`**.
- No Flutter imports in **`colonizethis_models`** for the bus — handler lives in **`app/`**.
- Dialog/panel builders registered at shell init; unknown dialog/panel IDs log a warning.
- Emission is fire-and-forget; **`ConfirmDialogEvent`** uses **`onResult`** / **`result()`** for the bool outcome.
- Province ids in game events: **prefixed** (`regionId|localId`).
- **`GameEventBridge`** (app layer) maps logic-layer **`GameEvent`** → app-layer **`GameToUIEvent`**; the two hierarchies stay separate to avoid circular deps.
- **Cross-cutting UI coupling** (**`Ref` / context / `Navigator` chains**, panel **`onXxx` orchestration**): **[app-ui-wiring.md](app-ui-wiring.md)**.
