# Game Events → UI Bridge — SPEC/program/game-event-bridge.md

**SPEC/program** — Bridge that forwards `GameEvent` subtypes from `colonizethis_logic` to `AppEventBus` as `GameToUIEvent` subtypes during turn resolution. Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Context

`GameEventBus` (colonizethis_logic) publishes game-layer events during turn resolution. `AppEventBus` (colonizethis_models/app) carries UI-bound events. Currently only `TurnResolutionCompleteEvent` and `NewGameCreatedEvent` are bridged — individual game events (combat, diplomacy, research, victory) are not forwarded to the UI.

This spec closes that gap: a `GameEventBridge` subscribes to `GameEventBus` and emits corresponding `GameToUIEvent` subtypes on `AppEventBus`, allowing UI components to react to individual game occurrences without polling.

---

## Architecture

```
TurnResolver (colonizethis_logic)
    │
    └── GameEventBus.publish(GameEvent)
              │
              │  (only events that need UI notification)
              ▼
    ┌─────────────────────────────────┐
    │   GameEventBridge               │
    │   - Subscribes to GameEventBus  │
    │   - Maps GameEvent → GameToUIEvent │
    │   - Emits on AppEventBus         │
    └─────────────────────────────────┘
              │
              ▼
    AppEventBus (colonizethis_models/app)
              │
              │  GameToUIEvent stream
              ▼
    ┌──────────────────────────────────────────────────────┐
    │  UI Listeners                                        │
    │  - GameToUIBusListener (screen-level reload)         │
    │  - NotifyEvent handlers (combat/diplomacy/research)   │
    │  - OvertureRequiredEvent → overture dialog           │
    └──────────────────────────────────────────────────────┘
```

### Bridge Location

`GameEventBridge` lives in `app/lib/core/services/game_event_bridge.dart`. It is not in `colonizethis_logic` (cannot depend on `AppEventBus`/`colonizethis_models`) and not in `colonizethis_models` (cannot depend on Flutter). It is constructed in the app DI layer.

---

## Event Mapping

Logic-layer `GameEvent` subtypes are forwarded as `App`-prefixed `GameToUIEvent` subtypes on `AppEventBus`. No payload transformation; fields are copied directly.

| `GameEvent` (logic) | `GameToUIEvent` (app) | UI response |
|--------------------|-----------------------|--------------|
| `CombatResultEvent` | `AppCombatResultEvent` | `NotifyEvent` snackbar |
| `ProvinceCapturedEvent` | `AppProvinceCapturedEvent` | `NotifyEvent` snackbar |
| `DiplomacyChangeEvent` | `AppDiplomacyChangeEvent` | `NotifyEvent` snackbar |
| `ResearchCompleteEvent` | `AppResearchCompleteEvent` | `NotifyEvent` snackbar |
| `VictorySetEvent` | `AppVictorySetEvent` | navigates to victory screen |
| `OrderRejectedEvent` | `AppOrderRejectedEvent` | `NotifyEvent` warning |
| — (pending overtures) | `OvertureRequiredEvent` | opens overture dialog |

### New GameToUIEvent subtypes

Each `App*` event mirrors the corresponding logic event's fields exactly:

```dart
class AppCombatResultEvent extends GameToUIEvent {
  const AppCombatResultEvent({
    required this.provinceId,
    required this.attackerId,
    required this.defenderId,
    required this.winnerId,
    required this.turnNumber,
    this.casualties = const {},
  });
  final String provinceId;
  final String attackerId;
  final String defenderId;
  final String winnerId;
  final int turnNumber;
  final Map<String, int> casualties;
}

class AppProvinceCapturedEvent extends GameToUIEvent {
  const AppProvinceCapturedEvent({
    required this.provinceId,
    required this.previousOwnerId,
    required this.newOwnerId,
    required this.turnNumber,
  });
  final String provinceId;
  final String? previousOwnerId;
  final String newOwnerId;
  final int turnNumber;
}

class AppDiplomacyChangeEvent extends GameToUIEvent {
  const AppDiplomacyChangeEvent({
    required this.actorId,
    required this.targetId,
    required this.changeType,
    required this.turnNumber,
  });
  final String actorId;
  final String targetId;
  final String changeType;
  final int turnNumber;
}

class AppResearchCompleteEvent extends GameToUIEvent {
  const AppResearchCompleteEvent({
    required this.playerId,
    required this.techId,
    required this.turnNumber,
  });
  final String playerId;
  final String techId;
  final int turnNumber;
}

class AppVictorySetEvent extends GameToUIEvent {
  const AppVictorySetEvent({
    required this.winnerPlayerId,
    required this.victoryType,
    required this.turnNumber,
  });
  final String winnerPlayerId;
  final String victoryType;
  final int turnNumber;
}

class AppOrderRejectedEvent extends GameToUIEvent {
  const AppOrderRejectedEvent({
    required this.playerId,
    required this.orderSummary,
    required this.reasonCode,
  });
  final String playerId;
  final String orderSummary;
  final String reasonCode;
}
```

---

## GameEventBridge API

```dart
class GameEventBridge {
  /// Creates a bridge that forwards events from [logicBus] to [appBus].
  /// Both bus references are stored; caller manages lifecycle.
  GameEventBridge({
    required GameEventBus logicBus,
    required AppEventBus appBus,
  });

  /// Starts forwarding events. Call after construction, before turn resolution.
  void start();

  /// Stops forwarding events. Call when the game session ends or UI unmounts.
  void stop();

  void dispose();
}
```

### Wire-in to GameService

`GameService` accepts an optional `GameEventBus? logicEventBus`. When set (by the Riverpod provider), `GameService.runTurnResolution` passes it to `resolveTurnForGame`, which emits events. The bridge subscribes to that bus and forwards to `AppEventBus`.

Riverpod wiring:

```dart
final gameEventBridgeProvider = Provider<GameEventBridge?>((ref) {
  // Only created when a game is active; null when no game is loaded.
  final logicBus = DefaultGameEventBus();
  final appBus = ref.watch(appEventBusProvider);

  final bridge = GameEventBridge(
    logicBus: logicBus,
    appBus: appBus,
  );
  bridge.start();

  ref.onDispose(() {
    bridge.dispose();
  });

  return bridge;
});

final gameServiceProvider = Provider<GameService>((ref) {
  final box = ref.watch(gamesBoxProvider);
  final adapter = ref.watch(gameSaveAdapterProvider);
  final bus = ref.watch(appEventBusProvider);
  final bridge = ref.watch(gameEventBridgeProvider);

  final service = GameService(box, adapter);
  service.eventBus = bus;
  // Pass the logic bus to turn resolver via GameEventBridge's internal bus.
  // GameService.runTurnResolution calls resolveTurnForGame(eventBus: bridge.logicBus, ...)
  // The bridge subscribes to bridge.logicBus and forwards to appBus.
  service.logicEventBus = bridge.logicBus;
  return service;
});
```

**Alternative (simpler):** `GameService` holds `GameEventBus?` directly; Riverpod creates `DefaultGameEventBus()` and wires it in. The bridge subscribes to the same bus. This avoids double-forwarding.

---

## Overture Flow

`OvertureRequiredEvent` is emitted by `GameService` when `resolveTurnForGame` returns `TurnResolutionPendingOvertures`, before the result is returned to the caller. The UI shows the overture dialog (via `pendingOverturesProvider` today); this remains unchanged, but the bridge also emits `OvertureRequiredEvent` on `AppEventBus` so screens can subscribe reactively.

```dart
TurnResolutionResult runTurnResolution(...) {
  final result = resolveTurnForGame(
    ...
    eventBus: logicEventBus,
  );

  if (result is TurnResolutionPendingOvertures) {
    eventBus?.emit(OvertureRequiredEvent(overtures: result.pendingOvertures));
  }

  return result;
}
```

---

## File Locations

| File | Purpose |
|------|---------|
| `app/lib/core/services/game_event_bridge.dart` | `GameEventBridge` implementation |
| `app/lib/core/services/game_service.dart` | Add `logicEventBus` field; pass to `resolveTurnForGame` |
| `packages/colonizethis_models/lib/src/app_events.dart` | Add `AppCombatResultEvent`, `AppProvinceCapturedEvent`, `AppDiplomacyChangeEvent`, `AppResearchCompleteEvent`, `AppVictorySetEvent`, `AppOrderRejectedEvent` |
| `app/test/game_event_bridge_test.dart` | Unit tests for bridge forwarding |
| `app/test/game_service_test.dart` | Integration test: turn resolution → AppEventBus events |
| `app/test/app_event_bus_test.dart` | Add equality tests for new `GameToUIEvent` subtypes |

---

## Acceptance Criteria (Given–When–Then)

### Bridge forwarding

- Given a `GameEventBridge` with `DefaultGameEventBus` as logicBus and `AppEventBus` as appBus, when the logic bus publishes a `CombatResultEvent` and the bridge is started, then `AppEventBus` receives exactly one `AppCombatResultEvent` with matching provinceId, attackerId, defenderId, winnerId, and turnNumber.
- Given a `GameEventBridge` started and the logic bus publishes `ProvinceCapturedEvent`, when the event is emitted, then `AppEventBus` receives exactly one `AppProvinceCapturedEvent` with matching provinceId, previousOwnerId, newOwnerId, and turnNumber.
- Given a bridge started, when the logic bus publishes `DiplomacyChangeEvent`, `ResearchCompleteEvent`, `VictorySetEvent`, or `OrderRejectedEvent`, then `AppEventBus` receives the corresponding `AppDiplomacyChangeEvent`, `AppResearchCompleteEvent`, `AppVictorySetEvent`, or `AppOrderRejectedEvent`.
- Given a bridge started, when `stop()` is called, then subsequent events on the logic bus are not forwarded to the app bus.
- Given a bridge with null logicBus (not started), when the bridge is disposed, then no error is thrown.

### GameService integration

- Given `GameService` with `logicEventBus` set to a `DefaultGameEventBus`, when `runTurnResolution` completes a turn, then the logic bus has published all game events for phases that completed.
- Given `GameService` with `logicEventBus` null, when `runTurnResolution` runs, then no exception is thrown.

### OvertureRequiredEvent

- Given `GameService` with `eventBus` set, when `runTurnResolution` returns `TurnResolutionPendingOvertures`, then `AppEventBus` has emitted `OvertureRequiredEvent` with matching overtures list before the result is returned.

### Null safety

- Given a bridge with a null appBus, when the bridge is started, then no exception is thrown and events are silently dropped (appBus is null-checked on each emit).
- Given a bridge with a null logicBus at construction, when `start()` is called, then it returns early without subscribing.

---

## Constraints

- Province ids in forwarded events remain **prefixed** (`regionId|localId`) per [world-model-identity.md](../game/world-model-identity.md).
- No Flutter imports in `colonizethis_models` — new event classes are pure Dart.
- `GameEventBridge` is constructed and managed in the app layer; logic layer is unaware of it.
- `GameEvent` (logic) and `GameToUIEvent` (app) types are **not** shared; the bridge performs the mapping explicitly.
- Event ordering: events are forwarded in the same order they are published on the logic bus.
- Backward compat: existing `TurnResolutionCompleteEvent` emission from `GameService` remains unchanged; the bridge is additive.

---

## Migration Steps

1. ✅ **Add new `GameToUIEvent` subtypes** to `colonizethis_models/lib/src/app_events.dart`.
2. ✅ **Create `GameEventBridge`** in `app/lib/core/services/game_event_bridge.dart`.
3. ✅ **Update `GameService`** to accept `GameEventBus? logicEventBus` and pass it to `resolveTurnForGame`.
4. ✅ **Wire bridge** in `game_service_provider.dart` (create bus, create bridge, pass bus to service).
5. ✅ **Add equality tests** for new `GameToUIEvent` subtypes in `app_event_bus_test.dart`.
6. ✅ **Add bridge unit tests** in `app/test/game_event_bridge_test.dart`.
7. ✅ **Add integration test** in `app/test/game_service_test.dart` covering `TurnResolutionPendingOvertures` → `OvertureRequiredEvent` emission.
8. ✅ **Update `SPEC/program/app-event-bus.md`** to document the new `GameToUIEvent` subtypes and the bridge architecture.
9. ✅ **`OvertureRequiredEvent`** is now emitted from `GameService.runTurnResolution` when result is `TurnResolutionPendingOvertures`.
