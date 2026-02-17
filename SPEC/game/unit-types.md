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

Current implementation includes the **full Imperialism II military roster**: 28 regiment types across 8 categories and 4 eras. See [military-units.md](military-units.md) for the complete table, tactical stats (FPN, FPM, RNG, DEF, MVR), and tech unlocks. Cost and upkeep per regiment type from program-level config (colonizethis_data). Construction consumes a worker from the player's WorkerPool (per [workers-and-population.md](workers-and-population.md)). No navy.

---

## Relations

Units are map units (owner, location province id). Movement: land only, adjacent provinces per topology. Orders: move, build unit, work (explore, build improvement, prospect) per [orders](../program/orders.md).
