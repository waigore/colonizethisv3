# Game Events — Shared Event Stream

**SPEC/program** — Contract for game events emitted during or after turn resolution and on order validation. Consumed by the Flutter app so users are clearly notified what is happening. Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Responsibility

Define the **contract** of the game event stream: event types, payload shapes, emission points, and determinism. No UI-specific fields in events; consumers (the app) map events to notifications and UI. Implementation lives in colonizethis_logic (or a shared layer); TurnResolver and OrderEngine (or their caller) emit events.

---

## Purpose

A single event stream for "what happened in the game" consumable by the Flutter app. Enables status lines, logs, overlays, and notification feeds without the UI parsing raw resolution output.

---

## Event types (contract)

Events are a union or sealed type (e.g. `GameEvent`) with variants. Payloads use keys/ids only; no UI strings. Province ids in any payload are **prefixed** (`regionId|localId`) per [world-model-identity.md](../game/world-model-identity.md).

| Event type           | When emitted                    | Payload (minimal) |
|----------------------|----------------------------------|-------------------|
| `combat_result`      | After Combat phase              | provinceId (prefixed), attackerId, defenderId, winnerId, casualties (or summary). |
| `naval_combat_result` | After each resolved sea battle in Naval interception phase | seaZoneId (local, e.g. s3), side1OwnerId, side2OwnerId, outcomeName (`NavalBattleOutcome.name`), turnNumber, optional winnerOwnerId, retreat flags. |
| `province_captured`  | When province ownership transfers **from one non-empty faction to another** (combat capture or other supported handover) | provinceId (prefixed), previousOwnerId, newOwnerId (both non-empty faction ids), turnNumber. Not emitted when the new `ownerId` would be null/empty—uncolonized frontier is not a capture outcome; see [world-model.md](../game/world-model.md) § Invariants. |
| `diplomacy_change`   | After Diplomacy phase           | actorId, targetId, changeType (e.g. war, peace, alliance), turnNumber. |
| `research_complete`   | When a tech is researched      | playerId, techId, turnNumber. |
| `victory_set`        | End-of-turn when victory set    | winnerPlayerId, victoryType, turnNumber. See [victory.md](../game/victory.md). |
| `order_rejected`     | On validation failure          | playerId, orderSummaryOrId, reasonCode (e.g. insufficient_treasury, invalid_destination). |
| `work_order_completed` | When a civilian work target resolves during Build/Work phase | playerId, unitId, workTarget, targetTileKey, provinceId (prefixed), turnNumber. |
| `player_province_discovered` | When a specific player transitions from unknown to known visibility in a province this turn | playerId, provinceId (prefixed), turnNumber. |
| `player_sea_zone_discovered` | When a specific player first charts/enters a sea zone this turn | playerId, seaZoneId (prefixed), turnNumber. |
| `overture_advanced` | When overture stage increases vs start of turn | offererGpId, targetFactionId, newStage, turnNumber. |
| `spy_caught` | After spy-resolution kill roll eliminates a foreign spy | unitId, spyOwnerId, territoryOwnerId, provinceId (prefixed), turnNumber. |
| `spy_defected` | After spy-resolution defection roll succeeds | unitId, previousOwnerId, newOwnerId, provinceId (prefixed), turnNumber. |

Additional event types (e.g. extraction_summary) may be added in the same format. Dialogue and mood ([ai-events-and-dossier.md](ai-events-and-dossier.md)) may be a separate channel or folded into this stream; the emitter guarantees a single, ordered stream per game/turn so consumers can present a chronological feed.

---

## Emission points

- **Turn resolution:** During or immediately after each phase in [turn-resolution-phase-details.md](turn-resolution-phase-details.md) (Combat → combat_result, province_captured; Diplomacy → diplomacy_change; Spy resolution → spy_caught, spy_defected; Research → research_complete; End-of-turn → victory_set when applicable). Caller or TurnResolver pushes events in phase order.
- **Order validation:** When [order-engine.md](order-engine.md) validates and rejects an order, an `order_rejected` event is emitted (or the validation layer emits it so that the UI can show the reason).

The **caller** that owns the order list or invokes TurnResolver is responsible for wiring the event stream to the resolver/engine so that events are emitted in a deterministic order. Same game state and seeds produce the same event sequence (replay and save/load compatibility).

---

## Determinism

- Same initial WorldState, orders, ruleset, and random seeds → same sequence of GameEvents for that turn.
- Events are emitted in a fixed order (e.g. phase order, then within phase by a defined ordering). No nondeterministic batching or reordering.
- Replay and save/load must reproduce or recompute the same events from persisted state when the turn is re-resolved.

---

## Acceptance criteria (Given–When–Then)

- **Emission — combat_result.** Given a turn resolution run in which the Combat phase resolves a battle in province P with a winner, when the Combat phase completes, then the system emits exactly one `combat_result` event with provinceId in prefixed form, and the payload includes winnerId and at least one of attackerId or defenderId consistent with the resolved battle.
- **Emission — naval_combat_result.** Given the Naval interception phase resolves a sea battle in zone Z, when that battle’s resolution completes, then the system emits exactly one `naval_combat_result` event with seaZoneId, both side owner ids, outcomeName, turnNumber, and winnerOwnerId when the outcome is a decisive victory for one side.
- **Emission — victory_set.** Given a turn resolution run in which the End-of-turn phase sets `Game.victory` (winner, type military, turn number), when the End-of-turn phase completes, then the system emits exactly one `victory_set` event with winnerPlayerId, victoryType, and turnNumber equal to the game’s victory state.
- **Emission — order_rejected.** Given the order engine validates a player’s order list and the first rejection occurs at order N with reason R, when validation returns, then the system has emitted an `order_rejected` event for that order with a reasonCode consistent with R (or the validation layer exposes the same so that a consumer can emit the event).
- **Determinism.** Given the same Game (and WorldState), same per-player order lists, same ruleset, and same seeds, when the system runs turn resolution and order validation, then the sequence of GameEvents emitted for that run is identical to any other run with the same inputs.
- **Province identity.** Given any GameEvent that carries a province id, when the event is emitted, then that id is in prefixed form (`regionId|localId`) per [world-model-identity.md](../game/world-model-identity.md).

- **Emission — province_captured.** Given combat or another resolver step would change a province from owner **A** to owner **B**, when **A** and **B** are each a non-empty faction id and **A ≠ B**, then the system may emit a `province_captured` event with `previousOwnerId == A`, `newOwnerId == B`, and prefixed `provinceId`. Given the post-resolution `ownerId` for that province is null or empty while the previous snapshot had a non-empty owner, when the emitter runs, then the system does **not** emit `province_captured` for that province (invalid capture state; see [world-model.md](../game/world-model.md) § Invariants).

---

## Integration

- **Upstream:** [turn-resolution-phase-details.md](turn-resolution-phase-details.md), [order-engine.md](order-engine.md), [victory.md](../game/victory.md). Emission is implemented in or alongside colonizethis_logic.
- **Downstream:** Flutter app subscribes to the stream and presents events (e.g. status line, scrollable log, overlay).
- **Dialogue/mood:** [ai-events-and-dossier.md](ai-events-and-dossier.md) defines DialogueEvent and PortraitMoodEvent. Whether they are part of this stream or a separate channel is an implementation choice; if separate, the app may subscribe to both for a unified feed.

---

## Constraints

- No asset paths or UI-only strings in event payloads.
- Province ids in payloads are always prefixed; never bare local id.
- Event order is part of the contract; consumers may rely on chronological order for display.

---

## Player turn event feed batch (v1)

The app builds a **human-player-scoped turn feed batch** from the deterministic `GameEvent` stream (forwarded as `App*` events) and commits the batch when `TurnResolutionCompleteEvent` is emitted for the same game.

- Source events for v1.2: `combat_result`, `naval_combat_result`, `province_captured`, `diplomacy_change`, `research_complete`, `order_rejected`, `work_order_completed`, `player_province_discovered`, `player_sea_zone_discovered`, `overture_advanced`.
- Scope filter:
  - combat/naval: include when the human player id is one of the participating side ids.
  - province capture: include when human player id is `previousOwnerId` or `newOwnerId`.
  - diplomacy: include when human player id is `actorId` or `targetId`.
  - research/order rejected: include when `playerId` equals the human player id.
  - work-order/province/sea discovery: include when `playerId` equals the human player id.
  - overture advanced: include when human id is `offererGpId` or `targetFactionId`.
- Payloads remain id-oriented; formatting to exclamatory English copy is app-layer only.
- Batch lifecycle: accumulate during one resolution run, then **replace** previous UI lines atomically on `TurnResolutionCompleteEvent` (no cross-turn accumulation).

### Acceptance criteria (Given-When-Then)

- Given one turn resolution run emits zero or more mapped game events in deterministic order for game `G` and human player `P`, when the app receives `TurnResolutionCompleteEvent(gameId: G)`, then the app commits exactly one ordered batch containing only lines relevant to `P`.
- Given the app has a committed batch for turn `T`, when the next `TurnResolutionCompleteEvent` for the same game commits turn `T+1`, then the app replaces all prior lines with turn `T+1` lines.
- Given a mapped game event payload includes a province id, when it is included in the player turn event feed batch, then the province id remains prefixed (`regionId|localId`).
