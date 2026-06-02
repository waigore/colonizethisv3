# Capital and Connectivity

**SPEC/game** — Capital definition, setup, and connectivity rules for extraction. Reference: Imperialism II 02-economy. Flow: [stockpiles-and-production.md](stockpiles-and-production.md), [auto-transport.md](../program/auto-transport.md). Province and tile identity (capital province, town keys, connectivity state) use prefixed province ids and tile keys per [world-model-identity.md](world-model-identity.md).

Connectivity in this document applies **only to extraction**: it determines which tiles contribute to resource extraction and flow to the player's stockpile. It is a **tile-level** concept — each tile is either connected or not for a given player. Connectivity output is consumed by the extraction pipeline; see [extraction-pipeline.md](../program/extraction-pipeline.md).

**Province and tile identity:** All province ids in game state and in capital/town/connectivity logic use **prefixed** form (`regionId|localId`). Tile keys use the 4-part format `regionId|localId|x|y`. See [world-model-identity.md](world-model-identity.md).

---

## Capital

The **capital** is a designated home province plus a **specific tile** within that province (e.g. `(regionId, provinceId, x, y)`). It is chosen in a **capital-choice phase** before the game starts. The sea-bound requirement applies to **Great Power** capitals only: the topology must have at least one P<->S edge for that province. Minor Nations and Tribes may have inland capitals; they do **not** consume sea transport. They **do** receive capital-tile-rooted connectivity for **non-Great-Power extraction** that feeds the World Market phase (see § Non-Great-Power capital connectivity and [factions.md](factions.md) § Minor and Tribe capital connectivity). See [capital-choice-phase.md](capital-choice-phase.md).

---

## Capital province town development (Great Powers)

For each **Great Power**, the province that is that player’s **capital province** must have **`townDevelopmentLevel = 4`** whenever that player has an active capital **tile**: at **game init** (after the capital-choice phase sets `capitalProvinceId` and the capital tile), and after every **capital reassignment** (§ Capital loss and reassignment), The System sets **`townDevelopmentLevel = 4`** on the **new** capital province.

**Town development** caps **extraction yield** only; it **does not** determine whether a tile is **connected** (see § Connectivity (Game Rule)). See [extraction-and-improvements.md](extraction-and-improvements.md) § Extraction formula and town development cap.

---

## Capital Setup

When the player chooses the capital tile:

- For **each seaboard** (each sea zone adjacent to the capital province), exactly one capital-port entry is created in `portsByProvinceSeaboard` using key `provinceId|seaZoneId`.
- If the capital tile is adjacent to a given seaboard's sea zone, that seaboard's port tile is the capital tile.
- Otherwise, for that seaboard, a port tile is chosen from tiles in the capital province that are adjacent to that seaboard's sea zone and is the tile with the shortest path to the capital tile (deterministic tie-break).
- For each off-capital seaboard port tile, a road is auto-built along the shortest path (on province tiles only) from that seaboard's port tile to the capital tile.

**Map harbor drawable (UI):** Registered port tiles must support **strict sea-only** harbor/fleet placement per [town-port-icons.md](../ui/town-port-icons.md): the port tile cell is sea in topology, or at least one **orthogonal** neighbor is a sea-zone cell. Otherwise map view construction throws; treat as **data/setup** defect (GitHub [#1761](https://github.com/waigore/colonizethisv3/issues/1761)).

**Init order:** Capital placement (province + tile) and port placement happen first; **then** for each such port that is land-connected to the capital, roads are placed along the shortest path to the capital (so the path is computed and applied after all capitals/ports are fixed). **Then** (step 7d) province town assignment: each province gets one **town** tile — see § Town per province.

**Great Power capital province town development (init):** Immediately after the capital tile is fixed for each Great Power, The System sets that Great Power’s **capital province** `townDevelopmentLevel` to **4**.

**Great Power starting grain (map bootstrap):** After province assignment on the tile map **and** the capital tile are both known, The System runs the **deterministic post-pass** in [tile-map-and-generation.md](tile-map-and-generation.md) § Great Power starting grain (bootstrap). **Initial road networking** (§ Init town roads below, including wiring required by the bootstrap) runs **after** that post-pass.

---

## Town per province

At **game init**, every province has exactly one **town** tile assigned (the province's "town" for extraction). The town is: (1) the **capital tile** if the province is that faction's capital province, or (2) otherwise apply **branch eligibility first** (capital exception above; seaboard filter for sea-bound provinces; overseas port when a port exists), then rank remaining candidates in order: (a) **minimum squared Euclidean distance** from the tile cell `(x, y)` to the **province centroid** — centroid is `round(mean x)`, `round(mean y)` over **all** tiles of that province (same formula as sea-zone fleet centroid markers in program); (b) **shortest path** to the capital tile by BFS on province tiles **in that region**, when the branch supplies a capital tile in-region (otherwise this step is skipped and all candidates tie on distance); (c) **ascending lexicographic** `townTileKey` string as final deterministic tie-break. **Neutral** provinces (no `ownerId`) use all province tiles as candidates with steps (a)–(c) and no BFS. **Sea-bound province (non-capital):** candidate set = province tiles **4-adjacent** to a sea-zone cell for a sea zone **P–S-adjacent** to that province in topology; then (a)–(c). **Sea-bound mismatch fallback (tolerant):** if that candidate set is empty, use **all** province tiles with (a)–(c) and emit one `logic:` warning. **Same region (not overseas), not sea-bound:** candidate set = all province tiles; then (a)–(c). **Overseas provinces:** if the province has a registered **port** tile, the town is that port tile (single choice); if there is **no** port, candidate set = all province tiles; then (a)–(c) without BFS to an overseas capital.

Town is stored as province's `townTileKey` or in a region-level map. A tile may be **connected** for extraction by the **Town rule** in § Connectivity (Game Rule) when it is **4-adjacent** to a **town** tile that is itself connected to the capital. **Yield** limits follow **town development** rules in [extraction-and-improvements.md](extraction-and-improvements.md) (town development does **not** decide connectivity).

---

## Init town roads (game start only)

After § Town per province assignment (step **7d**), after the **Great Power starting grain** post-pass ( [tile-map-and-generation.md](tile-map-and-generation.md) § Great Power starting grain (bootstrap)), and **before** naming (7c) in the setup pipeline, The System may place **initial roads** so each faction’s land-reachable **towns** connect to its capital on **owned land only**, and so any **bootstrap grain** tiles for Great Powers that still require the **Road rule** for connectivity are wired the same way (shortest path, owned land, road level ≥ 1 on path tiles).

- **Graph:** 4-neighbor adjacency on tiles that lie in provinces **owned by that faction** in a given **region** (`oldWorld` / `newWorld`). No tiles are added in neutral or foreign-owned provinces.
- **Path:** For each owned province with a `townTileKey`, when the town tile is reachable from the **capital tile** in that graph, The System raises **road level to at least 1** on every tile of one **globally shortest** path from that town to the capital (deterministic tie-break: same 4-neighbor expansion order as port→capital BFS in `capital_choice` setup).
- **Regions:** Which regions run this step is configured by `GameSetupConfig.initTownRoadWiringRegionIds` (program). Default is **`oldWorld` only** so New World tribes are not wired at init unless the ruleset explicitly includes `newWorld`.
- **Factions:** Great Powers, Minor Nations, and Tribes are all considered **when** their **capital tile’s region** is included in that set (so default config wires OW minors and GPs; NW capitals are skipped by default).
- **Merge:** Road levels use **max** with any existing init roads (e.g. capital seaboard links) so nothing is downgraded.
- **Scope:** **Init only** — not applied when the capital moves during turn resolution.

---

## Port connection to capital

A **port** is connected to the player's capital iff: **(1)** the capital is on the seaboard (capital tile adjacent to sea), or **(2)** the capital is not on the seaboard but there exists a path of road/railroad tiles from the capital to that port (same rules as tile connectivity). This applies in both the capital region and overseas: for overseas, a tile is connected if it has a road path to a port in that province that is itself connected to the capital (by (1) or (2)).

---

## Connectivity (Game Rule)

Connectivity is **tile-level** for extraction: it decides **whether** an owned tile may contribute. **`townDevelopmentLevel` does not determine connectivity**; it limits **yield** only (see [extraction-and-improvements.md](extraction-and-improvements.md) § Extraction formula and town development cap).

Unless stated otherwise, **adjacency** means **4-neighbor (cardinal)** adjacency on the tile grid.

### Same region as capital (land)

A land tile `T` in the **same region** as the player's capital, in a province **owned** by the player, is **connected** to the **capital tile** iff **at least one** of:

1. **Road rule:** `T` **lies on** a path of **owned-territory** tiles from the capital tile to `T` where every tile on the path has **transport level ≥ 1** (road, railroad, or port tile per [extraction-and-improvements.md](extraction-and-improvements.md)), **or** `T` is **4-adjacent** to at least one tile that lies on such a path (**on or next to** a road/rail ultimately connected to the capital).
2. **Town rule:** `T` is **4-adjacent** to a **town tile** (that province's `townTileKey`; for the capital province, the town tile is the **capital tile**) that is itself **connected** to the capital under (1), port-sea rules in this document, and § Port connection to capital. *(Base case: the capital tile is connected.)*

### Overseas

A tile in an **overseas** province is connected iff it satisfies the **port and sea path** rules elsewhere in this document (road/rail from `T` to an **owned port** in that province, that port **connected to the capital**, **blockade** rules), **and** the **in-province** link from `T` to that port's province network satisfies **Road rule** or **Town rule** when evaluated on **that player's owned tiles in that province**.

**Blockade** (see § Blockade) severs connectivity for blockaded ports; it does not only intercept cargo.

**Path transport cap** for yield uses **transport level** along the chosen connectivity path; if multiple paths exist, the **maximum** path transport cap is used per [extraction-and-improvements.md](extraction-and-improvements.md). Railroads remain tech-gated for building (see [tech-tree-transport.md](tech-tree-transport.md)).

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
- **Port connection:** Ports are connected to the capital only by (1) capital on seaboard or (2) road/rail path from capital to port (see § Port connection to capital). They do not automatically stay connected "via sea" regardless of land path. **Blockade** severs connectivity for the blockaded port (see § Blockade).
- **Retaking a province:** Re-establishes connections through it immediately.

---

## Blockade

Blockade affects **connectivity** for extraction. It is determined by enemy fleets on **Blockade** mission targeting a specific province (see [ships-and-naval.md](ships-and-naval.md) § Missions and Movement).

- **Blockading fleet must be at sea:** A fleet blockading a province must be **at sea** in a **sea zone adjacent to that province's port**. Fleets in port do not blockade. Ships in port at the blockaded province remain in port; when they leave port into the same sea zone as the blockading fleet, interception (and combat) is resolved like any other fleet entering that zone.

- **At war only:** A player may only **order** or **maintain** a blockade against a nation they are **at war** with. Submitting or validating a blockade order requires the fleet owner to be at war with the target province owner; otherwise the order is rejected. Existing blockade missions are not applied (or are cleared) when the two nations are not at war—e.g. after peace is declared.

- **Blockaded port province:** A port province is **blockaded** for a player when an enemy fleet **at sea** (at war with that player) is on Blockade mission, targets that province, and is in a sea zone adjacent to that province's port. For connectivity, a **blockaded port is not connected** to the capital: the connection between that port province and the capital is **severed**. No tiles in that province contribute to extraction for that player via that port (overseas provinces that relied on that port for sea connection are also cut off for that path).

- **Capital province blockaded:** If the **capital province** itself is blockaded (an enemy fleet at sea is blockading the capital's port), then for that player **all overseas** provinces and **all same-region provinces that are only reachable via sea** (i.e. no land path from capital) are **not** connected. In effect, the entire sea-based connectivity is severed; only tiles reachable by land (road/rail) from the capital remain connected.

Connectivity is recomputed each turn; blockade state is taken from the current fleet missions and positions (only **at-sea** fleets on Blockade count) before the extraction phase. Implementation must pass a set of blockaded province ids (or equivalent) into the connectivity resolver so that these rules are applied; see [extraction-pipeline.md](../program/extraction-pipeline.md).

---

## Non-Great-Power capital connectivity

Minor Nations and Tribes use the **same per-tile connectivity rules** as Great Powers (§ Connectivity (Game Rule)) so that the System can compute which non-Great-Power tiles contribute to per-faction extraction in the World Market phase ([world-market.md](world-market.md) § Minor and tribe auto-sell, [extraction-and-improvements.md](extraction-and-improvements.md) § Non-Great-Power extraction). The resolver iterates `Game.minorNations` and `Game.tribes` instead of `Game.players` and emits one `ConnectivityResult` per faction id, keyed by the Minor Nation id or Tribe id.

Three differences apply to non-Great-Power factions:

- **Land-only output.** Minor Nations are Old-World-only and Tribes are New-World-only per [factions.md](factions.md), so every owned non-Great-Power tile is in the same region as the faction's capital. The Road and Town rules apply unchanged within that region; the overseas branch in § Connectivity (Game Rule) cannot match because non-Great-Power factions never own provinces in the other region.
- **No blockade interaction for market access.** § Blockade severs Great Power port-province connectivity. For Minor Nations and Tribes the resolver passes an **empty** blockade set: war does not block their World-Market participation per [world-market.md](world-market.md) § Minor and tribe auto-sell. (Combat outcomes still affect ownership and capital reassignment normally — see § Capital loss and reassignment, § Minor Nation and Tribe terminal fall.)
- **No GP-only town-development bump.** Capital-province `townDevelopmentLevel` is set to `4` for **Great Power** capitals only (§ Capital province town development (Great Powers), § Capital loss and reassignment). Minor Nations and Tribes inherit whatever `townDevelopmentLevel` § Town per province assigned to their capital province; the non-Great-Power resolver does not mutate it.

The resolver entry point is **separate** from the Great Power `resolveConnectivity` so that Great Power blockade computations and capital-bound state (e.g. `capitalProvinceId`) are not affected. Both resolvers share the same per-tile Road and Town rules and the same path-transport-cap computation, so per-tile outputs for any faction with the same owned set, capital tile, and tile state are identical regardless of faction type. Connectivity is recomputed each turn (§ Dynamic Recompute) just like for Great Powers.

When a Minor Nation or Tribe has `capitalTile == null` (e.g. before § Minor Nation and Tribe terminal fall removes the entry), the resolver emits an empty `ConnectivityResult` for that faction id; no provinces contribute, and the World Market phase treats the faction as having no auto-offers that turn.

---

## Capital loss and reassignment

If a **capital-bearing faction** (Great Power, Minor Nation, or Tribe) no longer owns its capital province (e.g. after conquest), a new capital is chosen during turn resolution (see [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § Combat). This path is **separate** from the init-game capital-choice phase and **does not** use capital-choice A/B/C tile heuristics or § Capital Setup port/road placement. The same selection rules and `townTileKey` invariants apply to all three faction types; differences for Great Powers (town development level, terminal-fall eligibility) are called out below.

**Province:** New capital province is in the faction's **original region** (region of the lost capital), chosen from **owned** provinces in that region. Prefer **seaboard** provinces (P–S edge in region topology). If none, use **inland** owned provinces. Deterministic tie-break: ascending sorted full province id, first entry in the preferred list (seaboard list, else full owned list). The picker is faction-agnostic and uses the same `pickCapitalProvinceIdForReassignment(ownedProvinceIds, topology)` invocation for Great Powers, Minor Nations, and Tribes.

**Tile:** The new capital **tile** is exactly that province's stored **`townTileKey`**, parsed as tile key `regionId|localId|x|y` per [world-model-identity.md](world-model-identity.md). The System **does not** reassign, recompute, or validate `townTileKey` against the tile map during reassignment (post-generation data is authoritative). The System **does not** mutate any province's `townTileKey` during reassignment.

**World state:** Reassignment updates **only** the faction's `capitalProvinceId` and `capitalTile`. It **does not** add or change ports, roads, or other `WorldState.tileState` entries for capital wiring. Minors and Tribes therefore retain **inland** capitals during reassignment without port/road placement.

**Great Power capital province town development (reassignment):** When the new capital province is set for a **Great Power**, The System sets that province’s **`townDevelopmentLevel` to `4`** (see § Capital province town development (Great Powers)). **Minor Nations and Tribes do not** change any province `townDevelopmentLevel` during reassignment.

**Fatal error:** If reassignment must run for a chosen province but `townTileKey` is null, empty, or not parseable to a `CapitalTile` for that province id, The System **throws** a dedicated fatal error, emits **`logic:`** logs at **error** level with **full error and stack trace** for diagnostics, and the host treats this as **end of game** (turn resolution does not complete). The same logging and propagation apply to any other unexpected failure during reassignment, and apply equally to Great Power, Minor Nation, and Tribe reassignment paths.

If the faction has **no** owned provinces in the original region, The System sets `capitalProvinceId` and `capitalTile` to `null` for that faction and performs no throws from the missing-town rule above. For Minor Nations and Tribes, that empty-region condition is also the trigger for **terminal fall** (see § Minor Nation and Tribe terminal fall).

### Great Power fall (loss of capital and ports)

For **Great Powers only**, the capital loss rules have an additional terminal case:

- If, after combat resolution and capital reassignment, a Great Power:
  - no longer owns its original capital province, **and**
  - has **no remaining port provinces** that can serve as a valid capital (i.e. no owned province with a port tile connected per § Port connection to capital),
- then that Great Power **forfeits** (falls) during turn resolution.

When a Great Power falls:

- All provinces previously owned by that Great Power (in all regions) are transferred to the faction that currently owns its last capital province (the conqueror of the original capital in this sequence).
- The fallen Great Power is removed from active play (no further turns, orders, or capital), and its remaining fleets and units are disbanded (removed from world state) unless a future ruleset explicitly describes an alternative transfer behaviour.

This Great Power fall check runs **after** combat and capital reassignment, and **before** the next Extraction phase so that connectivity and extraction for remaining factions are computed with the updated ownership and player list.

### Minor Nation and Tribe terminal fall

For **Minor Nations** and **Tribes**, the capital loss rules have a terminal case parallel to § Great Power fall but with a different eligibility check:

- If, after combat resolution and capital reassignment, a Minor Nation or Tribe:
  - no longer owns its original capital province, **and**
  - has **no owned provinces remaining in the original capital region** (the same `ownedInRegion.isEmpty` condition that prevents reassignment),
- then that Minor Nation or Tribe **falls** during turn resolution.

When a Minor Nation or Tribe falls:

- All provinces previously owned by that faction (in any region) are transferred to the faction that currently owns its lost capital province (the conqueror of the original capital in this sequence). The same per-province owner replacement is applied as in § Great Power fall; per-province ports, roads, and `townTileKey` are not modified.
- All remaining units owned by the falling faction in any region are removed from world state; all remaining fleets owned by the falling faction are removed from world state.
- The falling faction is removed from `Game.minorNations` (for a Minor Nation) or `Game.tribes` (for a Tribe). No diplomacy relations, overtures, or subsidies for the removed faction are mutated by this rule beyond removing the faction entry itself (subsequent phases observe the missing faction and ignore it for active rules).

This Minor Nation and Tribe fall check runs **after** Great Power reassignment and Great Power fall, and **before** the next Extraction phase, so that connectivity, extraction, and AI/diplomacy for remaining factions are computed with the updated ownership and faction lists.

### Debug `/flip_province` capital capture parity

For debug command `/flip_province` (see [debug-console-panel.md](../ui/debug-console-panel.md)), when the command captures a **non-human** faction’s current capital, The System still applies canonical ownership transfer and then executes the same reassignment-plus-fall sequencing as combat capital-loss handling. This parity rule applies equally to Great Powers, Minor Nations, and Tribes in the debug command path: when no eligible reassignment capital exists in that faction’s original region, terminal fall (§ Great Power fall for Great Powers; § Minor Nation and Tribe terminal fall for Minor Nations and Tribes) resolves in the same command transaction.

---

## Acceptance Criteria

- Given a Great Power player selects a capital province with `N` adjacent sea zones and a capital tile `(regionId, provinceId, x, y)` that is adjacent to one of those sea zones in that region  
  When the system initializes the game at the end of the capital-choice phase  
  Then the system marks that tile as the player’s capital tile, creates exactly `N` entries in `portsByProvinceSeaboard` for that capital province (one per adjacent sea zone), sets the entry for the sea zone adjacent to `(x, y)` to that capital tile key, and sets the capital province’s `townTileKey` to that tile.

- Given a Great Power player selects a capital province with one or more adjacent sea zones and a capital tile `(regionId, provinceId, x, y)` that is not adjacent to at least one of those sea zones, and the province contains at least one tile adjacent to each such sea zone  
  When the system initializes the game at the end of the capital-choice phase  
  Then the system creates one port entry per adjacent sea zone, chooses each off-capital seaboard port tile by shortest path (by number of province tiles) to the capital tile with deterministic tie-break, and auto-builds a road along that shortest path from each off-capital seaboard port tile to the capital tile.

- Given a Great Power player has a capital province with a capital tile already placed  
  When the system initializes towns for all provinces  
  Then the capital province’s `townTileKey` is set to the capital tile and every other owned province has exactly one `townTileKey` set as follows: for sea-bound non-capital provinces, a tile adjacent to one of that province’s adjacent sea zones, chosen by province-centroid distance first, then shortest path to the capital when applicable, then lexicographic tile key; for non-sea-bound same-region provinces, the same centroid-then-BFS-then-key ordering over all province tiles; for overseas provinces, the port tile when a port exists, otherwise centroid-then-key over all province tiles (no BFS to capital).

- Given a Great Power player has a capital province in region `R1` and an owned sea-bound province `P2` in region `R1` with at least two distinct tiles in `P2` that are each adjacent to at least one of `P2`’s adjacent sea zones in the generated tile map  
  When the system assigns a town for `P2`  
  Then the system selects as `P2`’s `townTileKey` the seaboard-valid candidate with minimum squared distance from its cell coordinates to `P2`’s province centroid; when two candidates tie on that distance, the system selects the one with smaller BFS distance to the capital on province tiles in `R1`; when still tied, the lexicographically smaller `townTileKey`.

- Given a Great Power player has a sea-bound owned province `P2` in region `R1` where no tile in `P2` is adjacent to any of `P2`’s adjacent sea zones in the generated tile map  
  When the system assigns a town for `P2`  
  Then the system falls back to the full province tile set and selects by province-centroid distance first, then BFS distance to the capital, then lexicographic `townTileKey`, and emits one `logic:` warning describing the seaboard-candidate mismatch.

- Given a Great Power player has an owned province `P3` in region `R2` that is overseas (region `R2` is different from the capital region `R1`) and at least one port tile in `P3` whose sea zone is reachable from the capital’s seaboard via sea-zone and warp-zone edges  
  When the system assigns a town for `P3`  
  Then the system selects as `P3`’s `townTileKey` the port tile itself (the tile with the port), which is used for extraction connectivity for that province. If `P3` has no port and multiple land tiles, the system selects by province-centroid distance then lexicographic `townTileKey`.

- Given a fixed `GameSetupConfig` with a positive integer `seed` and fixed generated tile maps and topologies for both regions  
  When the system runs `createGameFromGeneratedMaps` (or `runInitGame`) twice with that same config and maps  
  Then every province `townTileKey` on the first completed game equals the corresponding `townTileKey` on the second (deterministic town placement).

- Given a Great Power player has a capital tile and a port tile `portA` in the same region  
  When the system evaluates whether `portA` is connected to the capital  
  Then `portA` is considered connected if and only if either the capital tile is adjacent to sea or there exists a road or railroad path from the capital tile to `portA` using only tiles in that region.

- Given a Great Power player has a capital tile on the seaboard with sea zone `S_cap` and a port tile `portB` in the same region with sea zone `S_port`  
  When the system evaluates whether `portB` is connected to the capital by sea topology  
  Then `portB` is considered sea-connected to the capital if and only if `S_port` is equal to `S_cap` or reachable from `S_cap` by following sea–sea edges in that region’s sea-topology graph.

- Given a Great Power player has a capital tile in region `R1` with sea zone `S_cap`, a port `portC` in region `R2`, and a multi-region sea topology with warp-zone links  
  When the system evaluates whether `portC` is connected to the capital  
  Then `portC` is considered connected if and only if its sea zone is reachable from `S_cap` by a path that may cross warp-zone edges between regions and sea–sea edges within each region.

- Given a land tile `T` in the same region as a Great Power player's capital, in a province owned by that player, and a world state with owned-territory roads/rails and town tiles per § Town per province  
  When the system evaluates whether `T` is connected to the capital for extraction  
  Then `T` is considered connected if and only if **Road rule** or **Town rule** in § Connectivity (Game Rule) holds: either `T` lies on a path of transport level ≥ 1 tiles to the capital or is **4-adjacent** to such a path tile, or `T` is **4-adjacent** to a **town tile** that is itself connected to the capital (capital tile is connected by definition).

- Given a tile `T_overseas` in an overseas province owned by a Great Power player, and that province has a port `P_over` that is connected to the capital by sea and land per the port-connection and sea-path rules  
  When the system evaluates whether `T_overseas` is connected to the capital for extraction  
  Then `T_overseas` is considered connected if and only if `P_over` is connected to the capital **and** the **in-province** link from `T_overseas` to the province port network satisfies **Road rule** or **Town rule** on that player's owned tiles in that province **and** there is a road or rail path from `T_overseas` to `P_over` as required by the overseas rules above.

- Given a fixed game state where ownership, roads/rails, ports, sea topology, blockade status, and **`townDevelopmentLevel` on every province** are unchanged, and only a province `townTileKey` value changes to a different coordinate  
  When the system recomputes connectivity  
  Then **Town rule** connectivity may change for tiles that were 4-adjacent only to the old town coordinate; **`townDevelopmentLevel` alone cannot change** the connected set.

- Given a tile `T_multi` in the same region as the capital that has two or more distinct valid connectivity paths to the capital with per-path minimum transport levels `MinPath1`, `MinPath2`, …, `MinPathN`  
  When the system computes the transport-limited cap for `T_multi` for extraction yield  
  Then the system selects `max(MinPath1, MinPath2, …, MinPathN)` as the transport constraint used in the effective-yield calculation for that tile per [extraction-and-improvements.md](extraction-and-improvements.md).

- Given a Great Power player with an active capital province `P_cap` after the capital-choice phase completes  
  When the system finishes capital and town setup for that player  
  Then `P_cap.townDevelopmentLevel` equals `4`.

- Given a new game for which the tile map and Great Power capitals are initialized per [tile-map-and-generation.md](tile-map-and-generation.md) § Great Power starting grain (bootstrap) and § Town and capital tile occupancy  
  When setup completes initial road networking after that bootstrap  
  Then each Great Power has exactly four **eligible** land tiles (excluding capital/town) in its **capital province** with resource id `grain`, improvement level `1`, terrain and resource legality per [resource-terrain-region-rules.md](resource-terrain-region-rules.md), chosen by **closest Manhattan distance** from that player's capital tile coordinates among **eligible** tiles with deterministic tie-break **ascending `y` then ascending `x`**, and those four placements are excluded from **all** resource caps per that section; each such tile is connected for extraction by turn 1 (Road rule or Town rule) after init roads run; the **capital/town** tile has **no** terrain resource and **no** extraction improvement.

- Given a Great Power player has a connected province chain from the capital to a remote province and then loses ownership of a province `P_cut` that lies on all road or rail paths between the capital and some other province’s town tile  
  When the system recomputes connectivity during the next extraction phase  
  Then every tile whose only paths to its town or to the capital passed through `P_cut` is marked as not connected and no longer contributes extraction to the player’s stockpile.

- Given a previously disconnected province `P_retake` becomes owned again by a Great Power player during turn resolution, restoring at least one full path from remote tiles through `P_retake` to the capital  
  When the system recomputes connectivity during the next extraction phase  
  Then all tiles in provinces that now have a valid path via `P_retake` to their town and to the capital are marked as connected again and resume contributing extraction according to the normal yield rules.

- Given a Great Power player no longer owns their capital province and still owns at least one province `P` in the original capital region with a non-null `townTileKey` equal to tile key `T` in canonical form and `P` is the first owned seaboard province in that region when sorted by full province id ascending, or the first owned inland province in that order when no seaboard province exists  
  When the system executes capital loss and reassignment during turn resolution  
  Then the system sets the player’s `capitalProvinceId` to `P.id`, sets `capitalTile` so `capitalTile.toTileKey()` equals `T`, sets `P.townDevelopmentLevel` to `4`, does not modify any province’s `townTileKey`, and does not add or change port or road entries in `WorldState` for reassignment.

- Given a Great Power player no longer owns their capital province and owns provinces `P1` and `P2` in the original region where only `P2` is seaboard and both have valid `townTileKey` values  
  When the system executes capital loss and reassignment during turn resolution  
  Then the system selects `P2` as the new capital province (seaboard preference), sets the player’s capital tile from `P2.townTileKey` only, and sets `P2.townDevelopmentLevel` to `4`.

- Given a Great Power player no longer owns their capital province and owns only non-seaboard provinces in the original region each with a valid `townTileKey`  
  When the system executes capital loss and reassignment during turn resolution  
  Then the system selects the new capital province by ascending sorted full province id among those owned provinces, sets the capital tile from that province’s `townTileKey` only, and sets that province’s `townDevelopmentLevel` to `4`.

- Given a Great Power player no longer owns their capital province and the reassignment-selected province `P` has `townTileKey` that is null, empty, or not parseable as `regionId|localId|x|y` consistent with `P.id`  
  When the system executes capital loss and reassignment during turn resolution  
  Then the system throws a fatal capital-reassignment error, logs at `logic:` error level with full error and stack trace, and does not complete turn resolution (host ends the game session).

- Given a Great Power player no longer owns their capital province and still owns another province in the original region whose `townTileKey` is valid  
  When capital reassignment runs and any unexpected error occurs inside reassignment  
  Then the system logs at `logic:` error level with full error and stack trace and propagates the error (host ends the game session or surfaces diagnostics per program spec).

- Given a player’s capital province is conquered so the player owns zero provinces in the original capital region at the end of combat resolution  
  When the system executes capital loss and reassignment during turn resolution  
  Then the system sets the player’s capital province and capital tile to `null`, performs no port or road changes for reassignment, and does not throw the missing-`townTileKey` fatal error for that player.

- Given two distinct non-capital owned provinces `A` and `B` in the same region before capital loss and reassignment  
  When reassignment completes for a player who still owns both `A` and `B`  
  Then `A.townTileKey` and `B.townTileKey` are unchanged from their values immediately before reassignment.

- Given a Great Power player has an owned port province `P_port` and an enemy fleet **at sea** (at war with that player) is on Blockade mission targeting `P_port` and is in a sea zone adjacent to `P_port`'s port  
  When the system recomputes connectivity during the extraction phase  
  Then no tiles in `P_port` are considered connected to the capital for that player, and any overseas province that was connected only via `P_port` is no longer connected.

- Given a Great Power player's capital province is blockaded (an enemy fleet **at sea** on Blockade mission targets the capital's port and is in a sea zone adjacent to it)  
  When the system recomputes connectivity during the extraction phase  
  Then all overseas provinces and all same-region provinces that are only reachable via sea (no land path from capital) are not connected for that player; only tiles reachable by road/rail from the capital remain connected.

- Given a Minor Nation no longer owns its capital province and still owns at least one other province in the original capital region, including at least one seaboard province with a valid `townTileKey`  
  When the system executes capital loss and reassignment during turn resolution  
  Then the system sets the Minor Nation's `capitalProvinceId` to the first ascending-sorted seaboard owned province in the original region and `capitalTile` to that province's `townTileKey` parsed as a `CapitalTile`; the system does not change `WorldState.tileState`, `WorldState.portsByProvinceSeaboard`, or any province's `townTileKey` or `townDevelopmentLevel`.

- Given a Tribe no longer owns its capital province and still owns at least one other province in the original capital region, including at least one seaboard province with a valid `townTileKey`  
  When the system executes capital loss and reassignment during turn resolution  
  Then the system sets the Tribe's `capitalProvinceId` to the first ascending-sorted seaboard owned province in the original region and `capitalTile` to that province's `townTileKey` parsed as a `CapitalTile`; the system does not change `WorldState.tileState`, `WorldState.portsByProvinceSeaboard`, or any province's `townTileKey` or `townDevelopmentLevel`.

- Given a Minor Nation no longer owns its capital province and still owns only inland (non-seaboard) provinces in the original capital region, each with a valid `townTileKey`  
  When the system executes capital loss and reassignment during turn resolution  
  Then the system selects the new capital province by ascending sorted full province id among those owned inland provinces, sets `capitalTile` from that province's `townTileKey` only, and does not change any province's `townDevelopmentLevel`.

- Given a Minor Nation owned its capital province `C` plus at least one other province `P` outside the original capital region and no owned provinces remain in the original capital region after capital `C` is captured  
  When the system executes capital loss and terminal fall during turn resolution  
  Then the system sets the conqueror of `C` as the new `ownerId` for every province previously owned by that Minor Nation (in any region), removes the Minor Nation entry from `Game.minorNations`, removes every `Unit` whose `ownerId` matches the Minor Nation id from `WorldState.oldWorld.units` and `WorldState.newWorld.units`, and removes every `Fleet` whose `ownerId` matches the Minor Nation id from `WorldState.fleets`.

- Given a Tribe owned its capital province `C` plus at least one other province `P` outside the original capital region and no owned provinces remain in the original capital region after capital `C` is captured  
  When the system executes capital loss and terminal fall during turn resolution  
  Then the system sets the conqueror of `C` as the new `ownerId` for every province previously owned by that Tribe (in any region), removes the Tribe entry from `Game.tribes`, removes every `Unit` whose `ownerId` matches the Tribe id, and removes every `Fleet` whose `ownerId` matches the Tribe id.

- Given a Minor Nation or Tribe still owns its original capital province after combat resolution (and after debug `/flip_province` if applicable)  
  When the system runs the reassignment-plus-terminal-fall sequence during turn resolution  
  Then the system does not modify that faction's `capitalProvinceId`, `capitalTile`, or membership in `Game.minorNations` / `Game.tribes`, and does not remove its units or fleets through this sequence.

- Given a Minor Nation lost its capital and capital reassignment selected a deterministic new capital province `P_new` in the original region  
  When the system serializes the resulting `Game` via `toJson` and deserializes it via `fromJson`  
  Then the deserialized Minor Nation entry has the same `capitalProvinceId == P_new.id` and `capitalTile` equal to the post-reassignment `CapitalTile`, with no other Minor Nation fields changed by the round trip.

- **Implementation:** Capital choice and init: [capital-choice-phase.md](capital-choice-phase.md). Connectivity and extraction: [extraction-pipeline.md](../program/extraction-pipeline.md). Capital reassignment on loss: [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § Combat.
