# Capital and Connectivity

**SPEC/game** — Capital definition, setup, and connectivity rules for extraction. Reference: Imperialism II 02-economy. Flow: [stockpiles-and-production.md](stockpiles-and-production.md), [auto-transport.md](../program/auto-transport.md).

Connectivity in this document applies **only to extraction**: it determines which tiles contribute to resource extraction and flow to the player's stockpile. It is a **tile-level** concept — each tile is either connected or not for a given player. Connectivity output is consumed by the extraction pipeline; see [extraction-pipeline.md](../program/extraction-pipeline.md).

---

## Capital

The **capital** is a designated home province plus a **specific tile** within that province (e.g. `(regionId, provinceId, x, y)`). It is chosen in a **capital-choice phase** before the game starts. The sea-bound requirement applies to **Great Power** capitals only: the topology must have at least one P<->S edge for that province. Minor Nations and Tribes may have inland capitals; they do not participate in extraction or transport. See [capital-choice-phase.md](capital-choice-phase.md).

---

## Capital Setup

When the player chooses the capital tile:

- If that tile is **adjacent to sea**, a **capital port** is auto-built on it.
- Otherwise, a **port** is built on the tile in that province that is **closest to the capital tile** and adjacent to sea; then a **road** is auto-built along the **shortest path** (on province tiles only) from that port tile to the capital tile.

**Init order:** Capital placement (province + tile) and port placement happen first; **then** for each such port that is land-connected to the capital, roads are placed along the shortest path to the capital (so the path is computed and applied after all capitals/ports are fixed). **Then** (step 7d) province town assignment: each province gets one **town** tile — see § Town per province.

---

## Town per province

At **game init**, every province has exactly one **town** tile assigned (the province's "town" for extraction). The town is: (1) the **capital tile** if the province is that faction's capital province, or (2) otherwise the tile in that province with the **shortest path** to the capital (same region) or to a **port** in that province (overseas). Town is stored as province's `townTileKey` or in a region-level map. Linking a tile to a town (via road/rail/port path) means the faction can extract that tile's resources; town development level and transport level along the path limit extraction (see [extraction-and-improvements.md](extraction-and-improvements.md) § Town and extraction).

---

## Port connection to capital

A **port** is connected to the player's capital iff: **(1)** the capital is on the seaboard (capital tile adjacent to sea), or **(2)** the capital is not on the seaboard but there exists a path of road/railroad tiles from the capital to that port (same rules as tile connectivity). This applies in both the capital region and overseas: for overseas, a tile is connected if it has a road path to a port in that province that is itself connected to the capital (by (1) or (2)).

---

## Connectivity (Game Rule)

A tile T is **connected** to the capital for a player iff there is a path of road/rail/port from T to the **province's town** and from that town to the capital (existing rules). So: **(a)** T is adjacent to the capital tile, or **(b)** T is on or adjacent to a road/railroad tile that has a path to the **province's town**, and that town has a path to the capital tile. The graph is: tiles connected by shared edge; edges are road/railroad tiles or adjacency to the capital tile or the province town.

**Town development level** (from Builder `upgrade_town` work) and **transport level** along the path limit extraction: effective yield = min(production, tech cap, **town development level**, **min transport level along path to town**, then to capital). If multiple paths exist (e.g. tile connected to two towns), the **maximum** transport level path determines the cap.

**Road level** on a tile is the same as **transport level** used for extraction (effective yield = min(production, transport level)); railroads are a higher road/transport level gated by tech (see [extraction-and-improvements.md](extraction-and-improvements.md), [tech-tree-transport.md](tech-tree-transport.md)).

**Overseas provinces:** A tile in an overseas province is connected if it has a road/rail path to **a port in that province that is connected to the capital** (per the port-connection rule above). Blockade can intercept cargo; blockade is currently stubbed (no effect).

---

## Sea paths

Overseas (and same-region) port connectivity uses **sea zone topology**: the capital's seaboard belongs to one or more sea zones; another port (same or overseas) is connected to the capital by sea if its sea zone is the same as the capital's or reachable from it by a **path of sea–sea edges** in the topology. Reference [map-topology.md](map-topology.md). For overseas provinces, a tile is connected if it has a road path to a port in that province and that port's sea zone is reachable from the capital's sea (as above).

---

## Dynamic Recompute

Connectivity is **recomputed every turn** during the extraction phase. Ownership and roads/ports can change (provinces gained or lost), so each tile's connection status must be derived from current state.

---

## Overseas

A province is **overseas** for a player if it is in a **different region** from that player's capital province. Sea transport is required **only** for overseas-extracted commodities. Same-region provinces (e.g. all Old World when the capital is in the Old World) flow by land only once connectivity is satisfied.

**Connectivity edge cases (per Imp2):**

- **Severed road:** Losing a province along a road path to the capital breaks all connections through it. Resources from disconnected tiles no longer flow to stockpile.
- **Port connection:** Ports are connected to the capital only by (1) capital on seaboard or (2) road/rail path from capital to port (see § Port connection to capital). They do not automatically stay connected "via sea" regardless of land path. Blockade may intercept cargo but does not sever the port's network membership for connectivity (stub).
- **Retaking a province:** Re-establishes connections through it immediately.

---

## Capital loss and reassignment

If a player no longer owns their capital province (e.g. after conquest), a new capital is chosen during turn resolution (see [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § Combat). New capital is in the player's **original region** (region of the previous capital) from the player's **owned provinces** in that region. Prefer **seaboard** provinces; place capital along the seaboard when possible. If the player has no seaboard provinces in that region, choose any remaining owned province (inland capital). Apply port/road setup per § Capital Setup. Reference capital-choice heuristics (e.g. border-avoidance) for tile choice where applicable. If the player has no owned provinces in the original region, leave capital (and capital tile) null; no port/road setup is applied.
