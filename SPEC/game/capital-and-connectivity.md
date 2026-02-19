# Capital and Connectivity

**SPEC/game** — Capital definition, setup, and connectivity rules for extraction. Reference: Imperialism II 02-economy. Flow: [stockpiles-and-production.md](stockpiles-and-production.md), [auto-transport.md](../program/auto-transport.md).

---

## Capital

The **capital** is a designated home province plus a **specific tile** within that province (e.g. `(regionId, provinceId, x, y)`). It is chosen in a **capital-choice phase** before the game starts. The sea-bound requirement applies to **Great Power** capitals only: the topology must have at least one P<->S edge for that province. Minor Nations and Tribes may have inland capitals; they do not participate in extraction or transport. See [capital-choice-phase.md](capital-choice-phase.md).

---

## Capital Setup

When the player chooses the capital tile:

- If that tile is **adjacent to sea**, a **capital port** is auto-built on it.
- Otherwise, a **port** is built on a tile in that province that is **closest to the capital tile** and adjacent to sea, and a **road** is auto-built from that port tile to the capital tile (pathfinding: shortest path on province tiles).

---

## Connectivity (Game Rule)

A tile T is **connected** to the capital for a player iff:

- **(a)** T is adjacent to the capital tile, or  
- **(b)** T is on or adjacent to a road/railroad tile that has a **path of road/railroad tiles** to the capital tile. The graph is: tiles connected by shared edge; edges are road/railroad tiles or adjacency to the capital tile.

**Overseas provinces:** A tile in an overseas province is connected if it has a road path to a **port** in that province. The port tile counts as connected to the capital via sea. Blockade can break this; Phase 2: blockade is stubbed (no effect).

---

## Dynamic Recompute

Connectivity is **recomputed every turn** during the extraction phase. Ownership and roads/ports can change (provinces gained or lost), so each tile’s connection status must be derived from current state.

---

## Overseas

A province is **overseas** for a player if it is in a **different region** from that player’s capital province. Sea transport is required **only** for overseas-extracted commodities. Same-region provinces (e.g. all Old World when the capital is in the Old World) flow by land only once connectivity is satisfied.

**Connectivity edge cases (per Imp2):**

- **Severed road:** Losing a province along a road path to the capital breaks all connections through it. Resources from disconnected tiles no longer flow to stockpile.
- **Ports never lose connection:** Sea ports remain connected regardless of land path status (they connect via sea). Blockade may intercept cargo but does not sever the port's network membership.
- **Retaking a province:** Re-establishes connections through it immediately.
