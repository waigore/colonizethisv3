# Game Events → UI Bridge — SPEC/program/game-event-bridge.md

**SPEC/program** — `GameEventBridge` forwards `GameEvent` from `colonizethis_logic` `GameEventBus` to `AppEventBus` as `GameToUIEvent` during turn resolution. Province ids: [world-model-identity.md](../game/world-model-identity.md).

---

## Context

`TurnResolver` publishes on `GameEventBus`. `AppEventBus` carries UI-facing events. The bridge subscribes to the logic bus and maps each listed `GameEvent` subtype to an App-prefixed `GameToUIEvent` so Flutter can react without polling.

---

## Architecture

`TurnResolver` → `GameEventBus.publish(GameEvent)` → `GameEventBridge` → `AppEventBus` → UI (`GameToUIBusListener`, `NotifyEvent`, overture dialog).

**Location:** `app/lib/core/services/game_event_bridge.dart`. Not in `colonizethis_logic` (must not depend on app/models UI types) or `colonizethis_models` (no Flutter). Constructed in app DI (`game_service_provider.dart`).

---

## Event mapping

Forward by copying fields; no payload transforms. Province ids remain **prefixed** (`regionId|localId`).

| Logic `GameEvent` | App `GameToUIEvent` | Typical UI |
|-------------------|---------------------|------------|
| `CombatResultEvent` | `AppCombatResultEvent` | `NotifyEvent` |
| `NavalCombatResultEvent` | `AppNavalCombatResultEvent` | `NotifyEvent` |
| `ProvinceCapturedEvent` | `AppProvinceCapturedEvent` | `NotifyEvent` |
| `DiplomacyChangeEvent` | `AppDiplomacyChangeEvent` | `NotifyEvent` |
| `ResearchCompleteEvent` | `AppResearchCompleteEvent` | `NotifyEvent` |
| `VictorySetEvent` | `AppVictorySetEvent` | victory screen |
| `OrderRejectedEvent` | `AppOrderRejectedEvent` | `NotifyEvent` (warning) |
| `WorkOrderCompletedEvent` | `AppWorkOrderCompletedEvent` | player turn feed |
| `PlayerProvinceDiscoveredEvent` | `AppPlayerProvinceDiscoveredEvent` | player turn feed |
| `PlayerSeaZoneDiscoveredEvent` | `AppPlayerSeaZoneDiscoveredEvent` | player turn feed |
| `OvertureAdvancedEvent` | `AppOvertureAdvancedEvent` | player turn feed |
| `SpyCaughtEvent` | `AppSpyCaughtEvent` | player turn feed |
| `SpyDefectedEvent` | `AppSpyDefectedEvent` | player turn feed |
| (pending overtures; not a `GameEvent`) | `OvertureRequiredEvent` from `GameService` | overture dialog |

`App*` field shapes mirror the logic events; source of truth: `packages/colonizethis_models/lib/src/app_events.dart`.

**Bridge API:** `GameEventBridge({required GameEventBus logicBus, required AppEventBus appBus})`, `start()`, `stop()`, `dispose()`, read-only `logicBus`.

**Wiring:** `GameService.logicEventBus` is passed into `resolveTurnForGame` as its `eventBus`. `gameEventBridgeProvider` creates `DefaultGameEventBus`, constructs `GameEventBridge`, calls `start()`, and disposes on `ref.onDispose`. `gameServiceProvider` assigns `service.logicEventBus` to that bus.

---

## Overture flow

When `resolveTurnForGame` returns `TurnResolutionPendingOvertures`, `GameService` emits `OvertureRequiredEvent` on `eventBus` **before** returning, so listeners see it synchronously with the pending result.

## Player turn event feed integration (v1)

The bridge remains a per-event forwarder. The app-side map shell may aggregate these forwarded `App*` events into one human-player-scoped batch per resolved turn and commit that batch only when `TurnResolutionCompleteEvent` for the same game is received.

- No extra singleton bus is introduced; this uses the existing `GameEventBus -> GameEventBridge -> AppEventBus` path.
- Aggregation preserves incoming event order.
- Batch commit uses `TurnResolutionCompleteEvent` as the replace boundary.

### Acceptance criteria (Given-When-Then)

- Given a started bridge and an app subscriber that accumulates forwarded `App*` events, when the logic bus publishes A then B and the service emits `TurnResolutionCompleteEvent`, then the subscriber can commit one batch ordered A then B.
- Given two consecutive resolved turns for the same game, when each turn publishes events and then `TurnResolutionCompleteEvent`, then the subscriber replaces the previous committed batch on the second completion event.

---

## Files

| Path | Role |
|------|------|
| `app/lib/core/services/game_event_bridge.dart` | Bridge implementation |
| `app/lib/core/services/game_service.dart` | `logicEventBus`; overture emit |
| `app/lib/providers/game_service_provider.dart` | Riverpod wiring |
| `packages/colonizethis_models/lib/src/app_events.dart` | `App*` event types |
| `app/test/game_event_bridge_test.dart` | Bridge forwarding tests |
| `app/test/game_service_test.dart` | Service / overture tests |
| `app/test/app_event_bus_test.dart` | Equality for new `GameToUIEvent` types |

---

## Acceptance criteria (Given–When–Then)

- **Bridge mapping:** Given a started `GameEventBridge` wired to `DefaultGameEventBus` and `AppEventBus`, when The System publishes each mapped `GameEvent` on the logic bus, then `AppEventBus` receives exactly one corresponding `App*` event with matching field values.
- **Stop:** Given a started bridge, when The System calls `stop()` and publishes another `GameEvent` on the logic bus, then `AppEventBus` receives no additional forwarded events from that publication.
- **Order:** Given a started bridge, when The System publishes event A then B on the logic bus, then forwarded app events appear in the same order (A then B).
- **Overture:** Given `GameService` with non-null `eventBus`, when `runTurnResolution` returns `TurnResolutionPendingOvertures`, then `AppEventBus` has received `OvertureRequiredEvent` whose `overtures` equal `pendingOvertures` before the method returns to the caller.
- **Null logic bus:** Given `GameService` with `logicEventBus == null`, when The System runs `runTurnResolution`, then no exception is thrown.

---

## Constraints

- Prefixed province ids in all payloads.
- Pure Dart `App*` types in `colonizethis_models`; logic `GameEvent` and app `GameToUIEvent` hierarchies are not shared across packages—the bridge maps explicitly.
- Logic layer does not reference `GameEventBridge`.
- Existing `TurnResolutionCompleteEvent` emission from `GameService` stays as today; the bridge is additive.
