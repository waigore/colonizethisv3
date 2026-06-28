# Tile Map and Map Generation

**SPEC/game** — Tile map (per-region 2D grid) and tile-based map generation. See [world-model.md](world-model.md) for provinces and tiles; [map-topology.md](map-topology.md) for topology.

---

## Tile map

A **tile map** is the 2D grid for **one region**. Each cell is assigned to a **province** or **sea zone** (by id). Each **land** cell has a **terrain type** and an optional **resource** (at most one). Resource placement must satisfy **region** (oldWorld only, newWorld only, or both) and **terrain** (allowed terrain types per resource) rules. Full table: [resource-terrain-region-rules.md](resource-terrain-region-rules.md). Improvements (extraction level, road) are **mutable** and stored in world state; the tile map holds static terrain and resource (and optional initial improvement state for scenarios). The grid is per region; the world has one tile map per region, not one global grid.

---

## Map generation

The tile map is generated for **one region** (oldWorld or newWorld) at a time. Terrain and resource rules use this **map-level region**, not per-province. Province identity is assigned in the **final** pass (Voronoi on land) so province borders are smooth.

Map-first is the **only** generation method. Input = province count (N), continent count (C), region, map params. Land shape and province assignment use N and C; topology is **inferred** from the grid after Voronoi (Pass 9), optional join (Pass 10), and sea zone subdivision (Pass 11). **Each continent should have a similar number of provinces** (≈ N/C); this is achieved by partitioning province ids across continents and by using similar land budget and land seeds per continent in Pass 2–3, so Pass 9 (province assignment) naturally yields balanced province sizes. **Pass 4 lakes:** fillable sea pockets are those **4-connected** to exactly **one** continent via orthogonal in-grid land neighbors (map border seals; see program spec); ocean for moats matches that lake pass.

Adjacency and strategic layout are **emergent** from the grid; no topology verification (topology = grid by construction). Future enhancement = separate procedural land generation; for now land-shape pipeline stays unchanged.

Requirements:

- Shapes and borders are semi-random (e.g. Voronoi-style), not fixed templates.
- **Province size target:** Average tiles per province is configurable (~30–40); **grid size** is chosen so the generated map respects this target.
- **Terrain:** **Terrain types differ by region** (Old World vs New World per canonical table). Terrain assignment must use only **terrain types allowed for that region**; assignment must produce **contiguous blobs** (e.g. hill ranges, forest/plains clusters), not per-cell random splotches. Region–terrain rules are defined in ruleset config. A **noise-perturbation pass** (see [tile-map-gen-algorithm.md § Pass 6b.5](../program/tile-map-gen-algorithm.md)) tempers overly homogeneous blobs by scattering small patches of other terrains inside their interiors while preserving blob edges and overall contiguity; it is configurable via `terrainVariation` (`0.0`–`1.0`) and is bypassed without RNG advance at `0.0`.
- Generation must assign terrain and at most one resource per tile respecting region and terrain rules, and must control resource spawn rates so distribution is in inverse proportion to default market price (see [resource-terrain-region-rules.md](resource-terrain-region-rules.md) and Pass 7 in [tile-map-gen-resources.md](../program/tile-map-gen-resources.md)). Multi-region resource cap: at most 30% of resources per map may be multi-region compatible; the remainder are region-exclusive.

Input: province count (N), continent count (C), region, map params (target tiles per province, grid size or derived size, seed, border noise). Output: per-region 2D grid (tile → province/sea zone id, terrain, optional resource) and **inferred topology**. A map generation tool may export a PNG: cells colored by terrain type (sea = deep blue), land borders as black lines, sea zone borders as light blue, **region ids in red** on each tile for identification, and a legend mapping colors to terrain (and Sea). **Tile size** is configurable for readability. Full contract: SPEC/program/map-visualization.md § Tile map PNG export.

---

## Algorithm spec

Generation is a **multi-pass pipeline**: **land seeds** = one **continent seed** per continent plus a **cluster** of land-shape seeds around it (count derived from province count; **Gaussian jitter** by default, cluster shape configurable). **Per-continent land budget** and optional **Voronoi noise** for irregular boundaries. Fill lakes; terrain and resources by **map region** (before provinces); **province seeds on land**; **province assignment** (Pass 9) uses the same **Voronoi assignment** as sea zones. Optional **join step** after Pass 9 when a continent has multiple land components (carve land bridges). **Sea zone subdivision** (Pass 11) uses the same Voronoi assignment; sea zones are capped at a max fraction of total sea (e.g. 5%). **Topology inference** runs after all passes (including join). Full pass list: [tile-map-gen-algorithm.md](../program/tile-map-gen-algorithm.md) and [tile-map-gen-resources.md](../program/tile-map-gen-resources.md). Config: [tile-map-gen-config.md](../program/tile-map-gen-config.md).

---

## Town and capital tile occupancy

A land tile that is a **town** (that province’s `townTileKey`) or a **capital** (any Great Power, Minor Nation, or Tribe `capitalTile`) **must not** hold a **terrain resource** or **extraction improvement** (farm, mine, etc.). **Transport infrastructure** (**roads, railroads, ports**) may apply to those tiles. Enforcement:

1. **Game setup:** Immediately after **§7d Province town assignment**, The System clears static map **resource**, `resourceByTileKey`, and **extraction improvement** on **every** town and capital tile (all factions, both regions). **Road/port/rail levels are preserved.**
2. **Combat capital reassignment:** When a player’s capital moves to a new tile, The System applies the same clear on the **new** capital tile (which is that province’s town) when tile maps are available to turn resolution.

Pass 7 may still roll RNG resources on land cells that **later** become town or capital; the setup strip removes them before gameplay. Bootstrap farms are chosen only from **eligible** tiles (excluding town/capital) per below.

---

## GP Old World terrain redistribution (setup)

**When:** Immediately after **§7d.strip** and **before** §7d.redist resource redistribution. **Program order** matches `createGameFromGeneratedMaps` in `colonizethis_logic`. **Applicability:** same as §7d.redist — both Old World `terrainGrid` and `resourceGrid` must be present; otherwise skipped. **Not** configurable off when applicable.

**What:** Reassigns **terrain types** on **Great Power–owned** Old World **land** tiles only (same scope exclusions as §7d.redist: **minor-owned** tiles unchanged; **town/capital** tiles excluded from the reassignment pool — their terrain is left as after strip). Uses **capacity-weighted Hamilton quotas** per terrain type then a deterministic **permutation** across eligible tiles so each in-scope terrain-type total `N_T` is preserved exactly. **Fairness** is diagnostic only (no setup hard-fail). Full algorithm: [game-setup-pipeline.md](../program/game-setup-pipeline.md) §7d.terrain.

---

## GP Old World resource redistribution (setup)

**When:** Immediately after **§7d.terrain** (when grids exist) and **before** Great Power starting grain bootstrap. **Program order** matches `createGameFromGeneratedMaps` in `colonizethis_logic` (after strip and terrain balance, **before** `applyGreatPowerStartingGrainBootstrap`, **before** init town→capital roads). **Mandatory** whenever the Old World map has both `terrainGrid` and `resourceGrid`; skipped only when either grid is missing (same applicability as grain bootstrap). **Not** configurable off via `GameSetupConfig`, ruleset JSON, or CLI for the current product.

**What:** Rebalances **terrain resources** on **Great Power–owned** Old World land tiles only; **minor-owned** Old World tiles are untouched. Clears all resources and extraction improvements on GP in-scope land (including town/capital tiles on GP land), then places back each resource type `r` in the active **S** set per [resource-terrain-region-rules.md](resource-terrain-region-rules.md) / `ResourceRules` so per-type totals match pre-clear inventory on GP tiles (town/capital excluded from counts). **Pass 7’s global 30% multi-region resource cap is not re-evaluated** during this pass (only rearranges resources already present on GP tiles). **Fairness diagnostic** (before grain bootstrap): `max_{g,r} |A_{g,r} − N_r/G|` per [game-setup-pipeline.md](../program/game-setup-pipeline.md) §7d.redist.

---

## Great Power starting grain (bootstrap)

**When:** After **§7d.strip**, after **§7d.redist** (when OW grids exist), each **Great Power** has a **capital tile** fixed, **§7d** towns are assigned, and **town/capital occupancy** strip has run. **Not** part of Pass 7 resource RNG — a **deterministic post-pass** on the grid and/or scenario overlay applied during **game setup**.

**Who:** **Great Powers only** for the four farms. **Occupancy** rules apply to **all** factions.

**What:** For each Great Power, select **exactly four** distinct **eligible** **land** tiles in that player’s **capital province** (same **region** and **local province id** as the capital tile). **Eligible** means **not** a town tile and **not** a capital tile (in the capital province, town and capital coincide; both excluded). Assign **resource `grain`** (subject to [resource-terrain-region-rules.md](resource-terrain-region-rules.md)); set **improvement level `1`** in world `tileState`. Tiles are chosen by **minimum Manhattan distance** from the capital tile coordinates among **eligible** tiles only; **tie-break:** lower **`y`**, then lower **`x`**. These placements are **guaranteed** and **independent** of any RNG resource from Pass 7 on the same cells (Pass 7 may have left another resource; the post-pass **replaces** those cells’ resource with `grain` as required on farm tiles only).

**Caps:** Bootstrap **`grain`** tiles **do not count** toward **any** generator or ruleset resource accounting — including the **multi-region compatible** share, **Pass 7** spawn weights / totals, per-resource frequency caps, or any other map-level resource budget.

**Roads:** **Initial road networking** (see [capital-and-connectivity.md](capital-and-connectivity.md) § Init town roads) runs **after** this post-pass so **towns** and these **farms** gain **Road rule** connectivity where required. Tiles that are **4-adjacent** to a **connected town** already satisfy **Town rule** and need no extra road solely for connectivity.

**Edge case:** If the capital province has **fewer than four** **eligible** land cells that can legally host `grain` (after excluding town/capital), the post-pass cannot satisfy the guarantee and raises its error. The **init orchestrator** treats this like other infeasible-layout failures (e.g. partition-gate exhaustion): it **regenerates with a bumped map seed** for up to the bounded retry budget (`kMaxInitPipelineAttempts`). Only when **every** attempt remains infeasible does The System surface a **fatal setup error** with `logic:` diagnostics (exact message implementation-defined). Maps or rulesets used for shipping **must** ensure sufficient candidates (e.g. by province size and terrain mix) so a feasible seed is found well within the retry budget.

---

## Acceptance Criteria

- Given map-generation input that specifies a region id, a province count `N`, a continent count `C`, and map parameters including a target tiles-per-province range  
  When the System runs the tile-map generation pipeline for that region  
  Then the System produces one 2D grid for that region, assigns each grid cell to either a province id or a sea zone id, and achieves an average number of land tiles per province that lies within the configured tiles-per-province range.

- Given resource–terrain–region rules from [resource-terrain-region-rules.md](resource-terrain-region-rules.md) and a chosen region  
  When the System assigns terrain and at most one resource per land tile during generation for that region  
  Then the System uses only terrain types allowed for that region, places resources only on tiles whose terrain type and region are allowed for that resource, and enforces the multi-region resource cap so that no more than the configured percentage of resources on the map are multi-region compatible.

- Given generation input with a province count `N` and a continent count `C` for a region  
  When the System generates continents, places province seeds, and assigns provinces as described in [tile-map-gen-algorithm.md](../program/tile-map-gen-algorithm.md)  
  Then the System produces continents whose number of provinces is approximately `N/C` per continent (within a small integer tolerance) and derives province and sea-zone topology directly from the resulting grid without any separate hand-authored topology file.

- Given `createGameFromGeneratedMaps` (or equivalent setup) completes with terrain and resource grids  
  When The System finishes province town assignment  
  Then **no** town tile and **no** capital tile has a terrain **resource** or **extraction improvement**; **road/rail/port** levels on those tiles may be non-zero  

- Given the Old World `TileMapResult` includes `terrainGrid` and `resourceGrid` and `createGameFromGeneratedMaps` reaches §7d.strip  
  When The System proceeds toward Great Power starting grain bootstrap  
  Then The System runs **§7d.terrain** GP Old World terrain redistribution **before** §7d.redist, runs **§7d.redist** GP Old World resource redistribution **before** grain bootstrap, **does not** re-apply Pass 7’s global 30% multi-region resource cap during that redistribution pass, and **does not** modify **minor-owned** Old World land tiles in either pass.

- Given a Great Power’s capital province contains at least **four** **eligible** land tiles (excluding its capital/town tile) that may host resource `grain` per [resource-terrain-region-rules.md](resource-terrain-region-rules.md) and the capital tile is fixed  
  When the System runs the **Great Power starting grain (bootstrap)** post-pass then initial road networking per [capital-and-connectivity.md](capital-and-connectivity.md)  
  Then the System assigns **exactly four** distinct **eligible** tiles in that capital province with resource `grain`, improvement level **1**, selected by **minimum Manhattan distance** from the capital among **eligible** tiles with tie-break **ascending `y` then `x`**, **none** of which is the capital/town tile, and those assignments are **omitted** from every resource-cap accounting rule in [tile-map-gen-resources.md](../program/tile-map-gen-resources.md)

- Given the bootstrap post-pass assigns `grain` to a tile that previously held another resource from Pass 7  
  When accounting for Pass 7 multi-region cap or any other map resource budget after the post-pass  
  Then the **replaced** RNG resource **does not** count toward those caps and the **new** `grain` bootstrap tiles **also do not** count

- Given a Great Power’s capital province contains **fewer than four** **eligible** land tiles rules-legal for `grain` (town/capital excluded) on the current attempt’s generated map and the init orchestrator has remaining attempts in its retry budget  
  When the System runs the bootstrap post-pass and the post-pass raises its infeasibility error  
  Then the System **regenerates** the maps with a bumped map seed and retries setup rather than failing immediately

- Given **every** attempt within the init retry budget produces a Great Power capital province with **fewer than four** **eligible** land tiles rules-legal for `grain`  
  When the System exhausts the retry budget  
  Then the System **fails setup** with a **fatal error** and `logic:` diagnostics (implementation-defined message)
