# Unit Types in Scope

**SPEC/game** — Which unit types are implemented in current scope. Full civilian roster: [civilian-units.md](civilian-units.md). GDD 05, TDD 05.

---

## Civilian Units in Scope

Current implementation includes a **subset** of civilian types:

- **Explorer** — Explore fog; prospect for minerals. Free; starting. Minerals must be prospected before extraction.
- **Builder** — Improve terrain production (mines, farms, etc.). Lumber + cast iron; starting. Output levels 1→2→3→4; tech caps max.
- **Engineer** — Build roads, ports, fortifications. Lumber + metal; starting. Roads gather resources.

**Deferred** (not in current scope): Spy, Merchant, Rail Builder. Full roster and caps defined in [civilian-units.md](civilian-units.md).

---

## Military: Full Roster

Current implementation includes the **full Imperialism II military roster**: 28 regiment types across 8 categories and 4 eras. See [military-units.md](military-units.md) for the complete table, tactical stats (FPN, FPM, RNG, DEF, MVR), and tech unlocks. **Training cost and upkeep per regiment type** come from program-level config in `colonizethis_data`:

- **Training cost:** `treasuryCost` (cash) **+ material inputs** (commodities such as fabric, castIron, lumber, steel, bronze) defined in the regiment economy catalog, **plus one worker** consumed from the player's `WorkerPool` at construction time (per [workers-and-population.md](workers-and-population.md)).
- **Upkeep:** per‑turn food demand per regiment (food units/turn) defined in the same catalog; food is consumed during the Consumption phase per [turn-resolution-phases.md](../program/turn-resolution-phases.md).

No navy.

---

## Relations

Units are map units (owner, location province id). Movement: land only, adjacent provinces per topology. Orders: move, build unit, work (explore, build improvement, prospect) per [orders](../program/orders.md).
