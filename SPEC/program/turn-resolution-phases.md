# Turn Resolution Phases

**SPEC/program** — Phase sequence and ordering rules. Overview: [turn-resolution.md](turn-resolution.md). Factions: [factions.md](../game/factions.md). Per-phase details: [turn-resolution-phase-details.md](turn-resolution-phase-details.md).

---

## Phase Sequence

TurnResolver runs phases in **fixed order**:

1. **Orders** — Gather/validate; Great Powers only submit. Merge human + AI; resolve cross-player effects before application.
2. **Extraction** — Tile yields to stockpile.
3. **Riches to treasury** — Riches convert to treasury at base price; removed from stockpile.
4. **Consumption** — Military food upkeep first, then workers/navy (food + luxury); strike rules per [workers-and-population.md](../game/workers-and-population.md).
5. **Production** — Recipes and idle labour; outputs to stockpile (uses post-Consumption stockpile and labour).
6. **Diplomacy** — Before Research and Movement so same-turn ownership and relation changes are visible to downstream phases. Overtures, Join Empire/Colony, alliances, Declare War, Peace, **intervention** (when a GP declares war on a Minor/Tribe and another GP has Embassy or purchased land there), relation updates. [diplomacy-resolution.md](diplomacy-resolution.md)
6a. **Spy resolution** — Immediately after Diplomacy and before Research: spy kill rolls (base 5% + garrison + empire-wide counter-esp), diplomacy penalties on kill, defection rolls, event emission. Research then applies passive spy RP boost from surviving spies in rival GP provinces. Refs #3834.
7. **Research** — Read orders; validate treasury; deduct spending; add progress (including passive spy RP boost); complete techs. [research-resolution.md](research-resolution.md)
8. **Movement** — Apply land/naval MoveOrders and mission assignments; update unit/fleet locations.
9. **Minor Regiment Upgrade** — Compute `maxGreatPowerMilitaryLevel` from post-Research Great Power buildable regiment tiers; set Old World Minor Nations `effectiveMilitaryLevel`; upgrade eligible minor land regiments in place; set Tribe `effectiveMilitaryLevel` to 1 (no parity).
10. **Naval Interception & Naval Combat** — Patrol/blockade/beachhead interceptions; sea battles; fleet updates. [naval-movement-resolution.md](naval-movement-resolution.md), [naval-combat-resolution.md](naval-combat-resolution.md)
11. **Combat** — Land battles; casualties; province flips.
12. **Build / work** — BuildUnitOrder; WorkOrder (explore, prospect, `purchase_land`, improvements, roads, ports, forts, rails, spy targets, etc.). `prospect` and `purchase_land` use `currentWork` with assign-time duration from `totalTurnsForWork` but **no** instant primary effects at accept: see [orders.md](orders.md) (Civilian deferred primary effects) and [development-resolution.md](development-resolution.md). Exploration and visibility: [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).
13. **World Market** — Gather submitted `TradeOrder` bids/offers, run per-commodity priority-queue deal matching (FTP tiebreakers, cross-commodity buyer-cargo caps), apply commodity/treasury/cargo transfers, compute next-turn prices, and roll unfilled quantities forward as carry-forwards. Riches commodities (gold, silver, gems, diamonds, spices) are excluded and continue to flow through phase 3 Riches-to-treasury. Player-facing game rules: [world-market.md](../game/world-market.md); detailed resolution algorithm and edge cases: [world-market-resolution.md](world-market-resolution.md). Inserting this phase renumbers End-of-turn from 13 → 14.
14. **End-of-turn** — Victory check; era-change dialogue; immediate Explorer/Spy fog decay (no spy grace timer); coastal sea zone full visibility; advance turn number. See [turn-resolution-phase-details.md](turn-resolution-phase-details.md) § End-of-turn.

---

## Dependency Rules

Extraction → riches to treasury → **consumption → production** **must** run before diplomacy, research, movement, and build, in that order. Diplomacy runs before Research so same-turn ownership transfers from diplomacy are visible to Research and all following phases. **Movement (phase 8) completes before Build / work (phase 12) begins** for the same turn: any **implicit civilian move leg** bundled into a `WorkOrder` is applied during Movement; the **work leg** (including `tileKey` / `currentWork` updates per [orders.md](orders.md)) runs only in Build / work. There is no interleaving of Movement and Build / work for that bundle. **World Market (phase 13) runs after Build / work (phase 12) and before End-of-turn (phase 14)**: the market consumes post-Build/work cargo capacity (extraction-first, trade-second per [auto-transport.md](auto-transport.md)) and produces commodity/treasury transfers that are observable at End-of-turn for victory and event checks.

---

## Blocking human input

Some phases may require input from a **human player** before resolution can continue. When that happens, turn resolution **suspends** and returns a result indicating **pending human input**: overture accept/reject when the target is a human-controlled Great Power; **intervention** (intervene / do nothing / protest) when another GP has declared war on a Minor/Tribe and the human’s GP has an embassy or purchased land there; or **call to arms** join/refuse when the human’s GP is allied to a Great Power that was just declared upon in the same Diplomacy phase. The **app** presents the decision, collects the response, and calls the matching **resume** API (`resumeTurnResolutionWithOvertureDecisions`, `resumeTurnResolutionWithInterventionDecisions`, or `resumeTurnResolutionWithCallToArmsDecisions`). The resolver then continues the Diplomacy phase and the rest of the turn. See [diplomacy-resolution.md](diplomacy-resolution.md); [diplomacy.md](../game/diplomacy.md) § Intervention and § Alliances.

---

## Determinism

Same TurnResolver and phase order used in main game and ctdev sim_game; identical development and exploration rules for reproducible simulations. When resolution suspends for human input, the eventual outcome depends on that input; given the same input (including human decisions on resume), the result is deterministic.

---

## Acceptance criteria

- **Phase sequence:** Given any run of TurnResolver, the system executes exactly the phases 1–14 above in that order (Orders → Extraction → Riches to treasury → Consumption → Production → Diplomacy → Spy resolution → Research → Movement → Minor Regiment Upgrade → Naval Interception & Naval Combat → Combat → Build / work → World Market → End-of-turn). No phase is skipped or reordered; no additional phases mutate game state between these steps.
- **Dependency order:** Extraction runs before Riches to treasury; Riches to treasury before Consumption; Consumption before Production. Extraction through Production complete before Diplomacy, Research, Movement, and Build / work. Research runs after Diplomacy and after Production so treasury is current and diplomacy state changes are visible. **Movement always runs before Build / work** in the same turn (phases 8 then 12); bundled civilian `WorkOrder` implicit move legs are not applied during Build / work. **Build / work (phase 12) runs before World Market (phase 13)** so port/road/harbour additions and any newly-built cargo hulls from this turn are visible to market cargo accounting. **World Market (phase 13) runs before End-of-turn (phase 14)** so market commodity/treasury transfers are observable to victory checks, era-change dialogue, and turn advance. Given a resolver run, the system does not apply extraction/riches/consumption/production effects after diplomacy, movement, build, or world-market has started.
- **Determinism:** Given the same starting WorldState, merged orders, ruleset, and random seeds, TurnResolver produces the same resulting WorldState (and victory state) in main game and in ctdev sim_game; phase order is identical in both.
- **Implementation contract:** Per-phase behaviour is specified in [turn-resolution-phase-details.md](turn-resolution-phase-details.md); this document is the single source of truth for phase sequence and ordering. Tests may assert phase order and dependency rules by inspecting resolver behaviour or by comparing outcomes across runs.
- **Phase dispatch architecture:** Given `runTurnResolutionPipeline`, when the resolver applies a phase, then it dispatches through a `Map<TurnPhase, TurnPhaseHandler>` registry and fails fast with `StateError` if any phase in `turnResolutionSequence` has no registered handler.
- **Phase handler overrides (testing / narrow customization):** Given `TurnResolverConfig` with `phaseHandlerOverrides` set to a map of `[TurnPhase]` → handler functions, when `runTurnResolutionPipeline` runs, then the system merges those entries over the default registry (same phase key replaces the default handler) and otherwise keeps default phase order and semantics unchanged. When `phaseHandlerOverrides` is null or omitted, then the system uses only the default registry.
- **Progress callback:** Given `resolveTurnForGame` (or equivalent pipeline entry) with `onPhaseProgress` set, when each phase handler begins and ends, then the system invokes the callback with the current `TurnPhase` and a `start` / `end` marker aligned with the same ordering as logic phase **info** logs in [logging/turn-resolution.md](logging/turn-resolution.md). The app uses this for live turn-resolution UI without parsing logs.
- **Blocking:** When the Diplomacy phase encounters an overture whose target is a human-controlled Great Power, turn resolution returns **TurnResolutionPendingOvertures**. When intervention requires a human GP’s choice, turn resolution returns **TurnResolutionPendingIntervention**. When call to arms requires a human ally’s choice, turn resolution returns **TurnResolutionPendingCallToArms**. The app must not advance the turn until it has collected the human’s response and called the matching resume API. When no human input is pending, resolution runs to completion and returns the final game state.
