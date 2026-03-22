# Event Bus — Centralized Game Event Distribution

**SPEC/program** — EventBus pattern replacing callback pyramid in turn resolution. Consolidates `GameEvent` and `DialogueEvent` dispatch. Implements SPEC/program/game-events.md contract.

---

## Context

Current event handling uses **constructor-injected callbacks** passed through every function in the turn resolution chain:

```dart
void Function(DialogueEvent)? onDialogue,
void Function(GameEvent)? onGameEvent,
void Function(Map<String, Map<String, int>>)? onProductionComplete,
```

This creates:
- **Callback pyramid**: 8+ callback parameters in `resolveTurnForGame`
- **Tight coupling**: Adding event types requires modifying every function signature
- **Scattered consumption**: No central place to see all event flows

---

## Design

### EventBus Interface

```dart
/// Centralized event distribution. SPEC/program/game-events.md.
abstract class GameEventBus {
  /// Publish [event] to all subscribers.
  void publish(GameEvent event);

  /// Stream of all published events, in emission order.
  Stream<GameEvent> get events;

  /// Subscribe to [T] events. [handler] is called for each matching event.
  /// Returns unsubscriber.
  void Function() subscribe<T extends GameEvent>(void Function(T) handler);
}
```

### Concrete Implementation

```dart
/// Default GameEventBus using [StreamController].
class DefaultGameEventBus implements GameEventBus {
  final _controller = StreamController<GameEvent>.broadcast();

  @override
  void publish(GameEvent event) {
    _controller.add(event);
  }

  @override
  Stream<GameEvent> get events => _controller.stream;

  @override
  void Function() subscribe<T extends GameEvent>(
    void Function(T) handler,
  ) {
    late final StreamSubscription<GameEvent> sub;
    sub = _controller.stream
        .where((e) => e is T)
        .cast<T>()
        .listen(handler);
    return () => sub.cancel();
  }
}
```

### Integration with Turn Resolver

Turn resolver accepts `GameEventBus?` instead of callbacks:

```dart
// Before
TurnResolutionResult resolveTurnForGame({
  ...
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
  ...
});

// After
TurnResolutionResult resolveTurnForGame({
  ...
  GameEventBus? eventBus,
  ...
});
```

Internal emission calls `eventBus?.publish(event)` instead of `onGameEvent?.call(event)`.

**Downstream bridge:** `SPEC/program/game-event-bridge.md` describes how app-layer wires `GameEventBus` to `AppEventBus` so Flutter UI can subscribe to game events.

### Backward Compatibility

For existing callers that use callbacks, provide a **wrapper**:

```dart
/// Adapts callback-based API to EventBus.
GameEventBus callbacksToEventBus({
  void Function(GameEvent)? onGameEvent,
  void Function(DialogueEvent)? onDialogue,
}) {
  final bus = DefaultGameEventBus();
  onGameEvent?.let((f) => bus.subscribe<GameEvent>(f));
  onDialogue?.let((f) => bus.subscribe<DialogueEvent>((e) => f(e as DialogueEvent)));
  return bus;
}
```

---

## Event Types

### GameEvent (existing, sealed)

From `colonizethis_logic/lib/src/game_events.dart`:
- `CombatResultEvent`
- `ProvinceCapturedEvent`
- `DiplomacyChangeEvent`
- `ResearchCompleteEvent`
- `VictorySetEvent`
- `OrderRejectedEvent`

### DialogueEvent (migrate to sealed)

Current: plain class in `colonizethis_models/lib/src/ai_events.dart`.

**Decision**: Keep `DialogueEvent` and `PortraitMoodEvent` in `colonizethis_models` but introduce `DialogueEventBus` for AI dialogue events. This separates game state events (logic package) from AI dialogue events (models package).

```dart
/// Separate bus for dialogue/mood events (AI-driven).
abstract class DialogueEventBus {
  void publish(DialogueEvent event);
  Stream<DialogueEvent> get events;
  void Function() subscribe<T extends DialogueEvent>(void Function(T) handler);
}
```

Rationale: `DialogueEvent` is defined in `colonizethis_models` (shared), not `colonizethis_logic`. AI packages produce dialogue; UI consumes. Clean separation.

---

## Responsibilities

| Layer | Responsibility |
|-------|----------------|
| `colonizethis_logic` | Defines `GameEventBus`, emits game events via bus |
| `colonizethis_models` | Defines `DialogueEventBus`, AI events |
| `colonizethis_ai` | Emits dialogue events via `DialogueEventBus` |
| App/ctterm | Creates bus, passes to resolver, subscribes to events |

---

## File Locations

| File | Purpose |
|------|---------|
| `packages/colonizethis_logic/lib/src/event_bus/game_event_bus.dart` | `GameEventBus` interface + `DefaultGameEventBus` |
| `packages/colonizethis_models/lib/src/events/dialogue_event_bus.dart` | `DialogueEventBus` interface |
| `packages/colonizethis_logic/lib/src/turn/turn_resolver.dart` | Uses `GameEventBus?` instead of callbacks |
| `packages/colonizethis_logic/test/event_bus/game_event_bus_test.dart` | Unit tests for bus |

---

## Acceptance Criteria (Given–When–Then)

### EventBus subscription

- **Subscribe — single type.** Given a `DefaultGameEventBus` with no subscribers, when a handler subscribes to `CombatResultEvent` and the bus publishes a `CombatResultEvent`, then the handler is called exactly once with that event.
- **Subscribe — filtered.** Given a `DefaultGameEventBus` with a subscriber to `CombatResultEvent`, when the bus publishes a `DiplomacyChangeEvent`, then the handler is not called.
- **Subscribe — unsubscribe.** Given a `DefaultGameEventBus` with an active subscription, when the unsubscriber is called, then subsequent events do not trigger the handler.
- **Subscribe — multiple handlers.** Given a `DefaultGameEventBus`, when multiple handlers subscribe to the same event type and the bus publishes that event, then all handlers are called.

### EventBus integration

- **Turn resolver emits via bus.** Given `resolveTurnForGame` is called with a `GameEventBus` and a combat occurs, when combat phase completes, then the bus has published a `CombatResultEvent`.
- **Null bus is safe.** Given `resolveTurnForGame` is called with `eventBus: null`, when turn resolution runs, then no exception is thrown and events are silently dropped.
- **Backward compat — callbacks.** Given a caller passes `onGameEvent` callback, when turn resolution runs, then events are delivered to that callback.

### Event ordering

- **Order preserved.** Given `resolveTurnForGame` with a bus, when multiple events are emitted in sequence (research, then diplomacy, then combat), then subscribers receive them in the same order.

---

## Migration Plan

1. **Phase 1**: Create `GameEventBus` in `colonizethis_logic`, add tests
2. **Phase 2**: Update `resolveTurnForGame` to accept `GameEventBus?` alongside existing callbacks (backward compat)
3. **Phase 3**: Migrate all internal emission sites to use bus
4. **Phase 4**: Remove callback parameters from `resolveTurnForGame` signature
5. **Phase 5**: Update all callers (app, ctterm, tests) to use bus

---

## Constraints

- No UI strings in events (per game-events.md)
- Province ids in payloads are always prefixed
- Same event stream determinism as callbacks (events in phase order)
- Thread-safe: `DefaultGameEventBus` uses `StreamController.broadcast`
