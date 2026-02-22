# ctdev — Running Game Screen

**SPEC/program** — Sim Game screen: controls, tabs, AI diagnostics. Overview: [ctdev-app.md](ctdev-app.md).

---

## Entry and Control Bar

Reached via Start Game (Sim) from Init Game Map Debug. User may navigate back to Init Map Debug.

**Control bar:** Session ID and log path (`logs/ctdev-sim-<sessionId>.log`). Next Player | Resolve Turn | Next Turn | Fast-forward 10. Disabled while resolving.

---

## Tabs

| Tab | Content |
|-----|---------|
| **Map** | OW + NW. Sub-views: **Default** (ownership/geographic, capitals, ports); **Improvements** (per-tile improvement and transport level); **Units** (army markers per province per player). Fleet/navy state (locations, mission icons). |
| **Game Overview** | Turn, year; owned province list per GP; military strength ([military-strength.md](military-strength.md)); diplomatic states. **Turn seed** `turnSeed[P, T]` per GP for reproducibility. |
| **Orders (AI history)** | Per-turn, per-GP scrollable view: movement, build, work, diplomatic, naval orders; validation status (accepted/rejected + reason) per [order-engine.md](order-engine.md). Naval combat outcomes when applicable. |
| **Player (GP) tabs** | One tab per GP. Per-player map via [player-view.md](player-view.md): Unknown (black), Revealed (grey), Fogged (ownership + grey stripes), Fully visible. Only viewing player's units. Below map: stockpiles, `techUnlocked` (stubs: `currentResearchTechId`, `researchableTechIds`); expected extraction/production ([order-projections.md](order-projections.md)); pending orders; available orders ([order-engine.md](order-engine.md)). |

All tabs read from `SimGameController.game` and `pendingOrdersByPlayerId`; refresh on Next Player / Next Turn.

---

## Sim Game Controls

AI choice made on Init Map Debug before Start Game. **Player-by-player:** Next Player (generates orders for next GP); Resolve Turn (enabled when all GPs have orders). **Turn-by-turn:** Next Turn (AI for all GPs → resolveTurnForGame). **Fast-forward 10:** 10 iterations with progress indicator and aggregated summary.

---

## Display and Logging

After each resolved turn: map updates from `Game.worldState`; panel shows turn/year, land combat events (province, sides, winner, casualties, flips), naval combat events. Fast-forward 10 may compress to summary.

**In-memory Sim Log:** Last 10 lines at info+; cleared at start of each turn. Full detail in session log file ([ctdev-logging.md](ctdev-logging.md)).

**AI order history:** Each order validated via `OrderEngine.validatePlayerOrdersWithContext(...)`; Orders tab shows cumulative history (unit ids, origins/destinations, accepted/rejected + reason).

**Work orders:** Display unit `tileKey` and province; order `targetTileKey` and province. Provinces from tileKey format `regionId|provinceId|x|y`.
