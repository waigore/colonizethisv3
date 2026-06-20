# Turn package — defensive collection-copy audit (#3416)

**SPEC/program** — documents which `Map.from` / `List.from` copies remain in
`packages/colonizethis_turn/lib/` after the #3416 hot-path audit and why.

## Motivation

Several turn-phase handlers previously shallow-copied collections on every
invocation even when the copy was not required for mutation safety or
immutability contracts. Unnecessary copies add allocator pressure on the
15-second next-turn budget path (`colonizethis-turn-resolution-budget.mdc`).

## Removals (this audit)

| Location | Change | Rationale |
|----------|--------|-----------|
| `turn_order_acceptance.dart` | Pass through `researchOrdersByPlayerId`, `navalMoveOrdersByPlayerId`, and `navalMissionOrdersByPlayerId` without `Map.from` | These order families are not filtered in this function; outer-map copies did not isolate inner lists |
| `world_market_phase_carry_forward.dart` | Assign carry-forward `orders` lists directly when stockpile/capacity is absent | Lists are read-only in the pass-through branch |
| `turn_resolution_events.dart` | Sort player ids instead of cloning `Player` lists | Deterministic iteration without duplicating player records |
| `production_phase.dart` | Store `result.productionByRecipe` directly | `resolveProduction` returns a fresh map per player invocation |

## Retained copies (required)

| Location | Copy | Rationale |
|----------|------|-----------|
| `movement_phase.dart` | Lazy `Map<String, int>.from` for spy timers | Mutates nested province timers only when a spy leaves a province |
| `movement_phase.dart` | `Map<String, Unit>.from(allUnitsById)` | Updates `unitById` as bundled work moves units within the phase |
| `naval_resolution.dart` | `List<Fleet>.from`, nested visibility maps | Fleets and visibility are mutated during naval move application |
| `consumption_phase.dart` | Feeding and idle-labour maps | Phase writes per-player coverage into local maps before `copyWith` |
| `turn_pipeline_state.dart` | Constructor `Map.from` for carry-over fields | Value-type immutability for pipeline state between phases |
| `research_resolver.dart` | Tech-unlock and progress maps | Mutable working state while applying research orders |
| `turn_resolution_events.dart` | `List<DiplomaticOrder>.from(diplo)` in order acceptance | Preserves list identity when assembling filtered diplomatic orders per player |

## Acceptance criteria

- Given `filterAcceptedOrdersForAllPlayers` runs with research, naval, and mission orders present, when the function returns, then the returned `Orders` object references the same outer maps for those three families as the source `OrderEngine.orders` (no redundant `Map.from` on the outer map).
- Given carry-forward offers exist for a faction with no stockpile entry at validation time, when `validateCarryForwards` runs, then the surviving offers list is the same list instance as the input carry-forward list (no `List.from` in the pass-through branch).
- Given `emitPlayerDiscoveryEvents` runs for a game with N players, when events are emitted, then player iteration order is deterministic by sorted player id and no `List<Player>.from` clone of `stateAfter.players` is constructed.
- Given `runProductionPipelinePhase` records non-empty production for a player, when the production callback map is populated, then each player's entry references the `productionByRecipe` map returned by `resolveProduction` for that player (no redundant `Map.from`).
- Given naval move orders are applied, when `applyNavalMovesAndShipReveal` mutates fleet or visibility state, then the implementation still clones `game.worldState.fleets` and `playerVisibilityByTile` before mutation (retained defensive copies).
