# ctdev — Running Game Screen

**SPEC/program** — Sim Game screen: controls, tabs, AI diagnostics. Overview: [ctdev-app.md](ctdev-app.md).

---

## Entry and Control Bar

Reached via Start Game (Sim) from Init Game Map Debug. User may navigate back to Init Map Debug.

**Control bar:** Session ID and log path (current day file per [ctdev-logging.md](ctdev-logging.md): `logs/YYYY-MM-DD.log`). Next Player | Resolve Turn | Next Turn | Fast-forward 10. Disabled while resolving.

---

## Tabs

| Tab | Content |
|-----|---------|
| **Map** | OW + NW. Sub-views: **Default** (ownership/geographic, capitals, ports); **Improvements** (per-tile improvement and transport level); **Units** (army markers per province per player **and** fleet markers: triangle + mission letter per [ships-and-naval.md](../game/ships-and-naval.md), same toggle as armies). |
| **Game Overview** | Turn, year; owned province list per GP; military strength ([military-strength.md](military-strength.md)); **Diplomacy:** every row in `Game.diplomacyRelations` (faction display names, `RelationState`, `RelationLevel`, score). Undiscovered cross-region pairs are not stored as relations and do not appear. **Last turn combat:** land + naval summary lines from the most recent resolve (see Display and Logging). **Turn seed** `turnSeed[P, T]` per GP for reproducibility. |
| **Orders (AI history)** | Per-turn, per-GP scrollable view: movement, build, work, diplomatic, research, naval move/mission orders; validation status (accepted/rejected + reason) per [order-engine.md](order-engine.md). Combat narratives: **Overview** and **Sim Log**, not this tab. |
| **Player (GP) tabs** | One tab per GP. Per-player map via [player-view.md](player-view.md): Unknown (black), Revealed (grey), Fogged (ownership + grey stripes), Fully visible. Only viewing player's units **and** that player's fleets when **Units** is on. Below map: **Projected end of turn** via [order-projections.md](order-projections.md) (`projectOrderEffects`) when any GP has pending orders (empty `Orders` for GPs not yet filled this turn); stockpiles; `techUnlocked`; pending orders; available orders ([order-engine.md](order-engine.md)). |

All tabs read from `SimGameController.game` and `pendingOrdersByPlayerId`; refresh on Next Player / Next Turn.

---

## Sim Game Controls

AI choice made on Init Map Debug before Start Game. **Player-by-player:** Next Player (generates orders for next GP); Resolve Turn (enabled when all GPs have orders). **Turn-by-turn:** Next Turn (AI for all GPs → resolveTurnForGame). **Fast-forward 10:** 10 iterations with progress indicator and aggregated summary.

---

## Display and Logging

After each resolved turn: map updates from `Game.worldState`. **Land combat:** `CombatResultEvent` from the Combat phase → one human-readable line per battle (province, attacker, defender, winner, optional casualties). **Naval combat:** `NavalCombatResultEvent` from the naval interception phase → one line per battle (sea zone, sides, outcome, optional winner, retreats). **Game Overview** repeats the same lines under **Last turn combat** for the turn just resolved. **In-memory Sim Log** receives these lines via `Logger().i('ctdev: …')` (info+), so they appear in the rolling UI log alongside other ctdev messages. Province ownership flips continue to be logged as today. Fast-forward 10 does not change event shape (one line per battle per turn).

**In-memory Sim Log:** Last 10 lines at info+; cleared at start of each turn. Full detail in session log file ([ctdev-logging.md](ctdev-logging.md)).

**AI order history:** Each order validated via `OrderEngine.validatePlayerOrdersWithContext(...)`; Orders tab shows cumulative history (unit ids, origins/destinations, accepted/rejected + reason).

**Work orders:** Display unit `tileKey` and province; order `targetTileKey` and province. Provinces from tileKey format `regionId|provinceId|x|y`.
