# Capital and Connectivity

**SPEC/game** — Capital definition, setup, and connectivity rules for extraction. Reference: Imperialism II 02-economy. Flow: [stockpiles-and-production.md](stockpiles-and-production.md), [auto-transport.md](../program/auto-transport.md). Province and tile identity (capital province, town keys, connectivity state) use prefixed province ids and tile keys per [world-model-identity.md](world-model-identity.md).

Connectivity in this document applies **only to extraction**: it determines which tiles contribute to resource extraction and flow to the player's stockpile. It is a **tile-level** concept — each tile is either connected or not for a given player. Connectivity output is consumed by the extraction pipeline; see [extraction-pipeline.md](../program/extraction-pipeline.md).

**Province and tile identity:** All province ids in game state and in capital/town/connectivity logic use **prefixed** form (`regionId|localId`). Tile keys use the 4-part format `regionId|localId|x|y`. See [world-model-identity.md](world-model-identity.md).

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

Overseas (and same-region) port connectivity uses **sea zone topology**. Each region has its **own** topology graph; regions connect **only** via **warp zones** (see [map-topology.md](map-topology.md)). Within a region, the capital's seaboard belongs to one or more sea zones; another port in the **same region** is connected by sea if its sea zone is the same as the capital's or reachable by a **path of sea–sea edges** in that region's topology. An **overseas** port is connected to the capital iff its sea zone is reachable from the capital's sea by following **intra-region** S–S edges and **warp zone** links between regions. For overseas provinces, a tile is connected if it has a road path to a port in that province and that port's sea zone is reachable from the capital's sea (via sea paths within each region and warp zones between them).

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

---

## Acceptance Criteria

- Given a Great Power player selects a capital province and a capital tile `(regionId, provinceId, x, y)` that is adjacent to a sea tile in that region  
  When the system initializes the game at the end of the capital-choice phase  
  Then the system marks that tile as the player’s capital tile and creates a capital port on that tile, and sets the capital province’s `townTileKey` to that tile.

- Given a Great Power player selects a capital province and a capital tile `(regionId, provinceId, x, y)` that is not adjacent to sea and the province contains at least one sea-adjacent land tile  
  When the system initializes the game at the end of the capital-choice phase  
  Then the system creates a port on the sea-adjacent tile in that province with the shortest path (by number of province tiles) to the capital tile and auto-builds a road along that shortest path from the port tile to the capital tile.

- Given a Great Power player has a capital province with a capital tile already placed  
  When the system initializes towns for all provinces  
  Then the capital province’s `townTileKey` is set to the capital tile and every other owned province has exactly one `townTileKey` set to the tile in that province with the shortest valid road or rail path to either the capital tile in the same region or a port in that province for an overseas province.

- Given a Great Power player has a capital province in region `R1` and an owned province `P2` in the same region `R1` with at least one tile reachable by a road or rail path to the capital tile  
  When the system assigns a town for `P2`  
  Then the system selects as `P2`’s `townTileKey` the tile in `P2` whose shortest road or rail path to the capital tile is minimal among tiles in `P2`, breaking ties deterministically according to the map-topology rules.

- Given a Great Power player has an owned province `P3` in region `R2` that is overseas (region `R2` is different from the capital region `R1`) and at least one port tile in `P3` whose sea zone is reachable from the capital’s seaboard via sea-zone and warp-zone edges  
  When the system assigns a town for `P3`  
  Then the system selects as `P3`’s `townTileKey` the tile in `P3` with the shortest road or rail path to any such connected port in `P3`, and marks that port as used for extraction connectivity for that province.

- Given a Great Power player has a capital tile and a port tile `portA` in the same region  
  When the system evaluates whether `portA` is connected to the capital  
  Then `portA` is considered connected if and only if either the capital tile is adjacent to sea or there exists a road or railroad path from the capital tile to `portA` using only tiles in that region.

- Given a Great Power player has a capital tile on the seaboard with sea zone `S_cap` and a port tile `portB` in the same region with sea zone `S_port`  
  When the system evaluates whether `portB` is connected to the capital by sea topology  
  Then `portB` is considered sea-connected to the capital if and only if `S_port` is equal to `S_cap` or reachable from `S_cap` by following sea–sea edges in that region’s sea-topology graph.

- Given a Great Power player has a capital tile in region `R1` with sea zone `S_cap`, a port `portC` in region `R2`, and a multi-region sea topology with warp-zone links  
  When the system evaluates whether `portC` is connected to the capital  
  Then `portC` is considered connected if and only if its sea zone is reachable from `S_cap` by a path that may cross warp-zone edges between regions and sea–sea edges within each region.

- Given a tile `T` in a land province owned by a Great Power player and that province has a `townTileKey` with a valid path to the capital according to the connectivity rules  
  When the system evaluates whether `T` is connected to the capital for extraction  
  Then `T` is considered connected if and only if either `T` is the capital tile or directly edge-adjacent to the capital tile, or `T` lies on or is edge-adjacent to a road or rail tile that has a road or rail path to the province’s town tile, and the town tile has a path to the capital tile.

- Given a tile `T_overseas` in an overseas province owned by a Great Power player, and that province has a port `P_over` that is road or rail connected to `T_overseas` and is itself connected to the capital by sea and land per the port-connection and sea-path rules  
  When the system evaluates whether `T_overseas` is connected to the capital for extraction  
  Then `T_overseas` is considered connected if and only if there exists a road or rail path from `T_overseas` to `P_over` and `P_over` is marked as connected to the capital.

- Given a connected tile `T_conn` with base production `P`, technology cap `TechCap`, a town development level `TownLvl` for its province’s town tile, and a set of transport levels along the chosen connectivity path with minimum value `MinTransport`  
  When the system computes the effective extracted yield for `T_conn`  
  Then the effective yield is `min(P, TechCap, TownLvl, MinTransport)` and is attributed to the player’s stockpile for that turn.

- Given a tile `T_multi` that has two or more distinct valid connectivity paths to the capital with per-path minimum transport levels `MinPath1`, `MinPath2`, …, `MinPathN`  
  When the system computes the transport-limited cap for `T_multi`  
  Then the system selects `max(MinPath1, MinPath2, …, MinPathN)` as the transport constraint used in the effective-yield calculation for that tile.

- Given a Great Power player has a connected province chain from the capital to a remote province and then loses ownership of a province `P_cut` that lies on all road or rail paths between the capital and some other province’s town tile  
  When the system recomputes connectivity during the next extraction phase  
  Then every tile whose only paths to its town or to the capital passed through `P_cut` is marked as not connected and no longer contributes extraction to the player’s stockpile.

- Given a previously disconnected province `P_retake` becomes owned again by a Great Power player during turn resolution, restoring at least one full path from remote tiles through `P_retake` to the capital  
  When the system recomputes connectivity during the next extraction phase  
  Then all tiles in provinces that now have a valid path via `P_retake` to their town and to the capital are marked as connected again and resume contributing extraction according to the normal yield rules.

- Given a player’s capital province is conquered so the player owns zero tiles in that province at the end of combat resolution  
  When the system executes capital loss and reassignment during turn resolution  
  Then the system selects a new capital province from the player’s owned provinces in the original capital region, preferring seaboard provinces when available, assigns a new capital tile using the capital-choice heuristics, applies capital port and road setup per the capital-setup rules, and updates all towns and connectivity based on the new capital before the next extraction phase.

- Given a player has no owned provinces remaining in the original capital region after capital loss  
  When the system executes capital loss and reassignment during turn resolution  
  Then the system sets the player’s capital province and capital tile to `null`, performs no new port or road setup, and in the subsequent extraction phase treats all tiles for that player as not connected for extraction until a new capital is defined by later rules.

- **Implementation:** Capital choice and init: [capital-choice-phase.md](capital-choice-phase.md). Connectivity and extraction: [extraction-pipeline.md](../program/extraction-pipeline.md). Capital reassignment on loss: [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § Combat.
