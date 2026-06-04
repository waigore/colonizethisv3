# Extraction and Improvements

## Overview

Per-tile resource extraction using improvements, constrained by tech level and transport infrastructure. Civilian work orders build improvements, roads, ports, and railroads. Province and tile identity (e.g. owned provinces, tile keys, town and port lookup) follow [world-model-identity.md](world-model-identity.md): extraction and connectivity use **tile keys** (format `regionId|localId|x|y`) and **province ids** (prefixed `regionId|localId`); province lookup must be region-scoped.

---

## Rules

### Province and tile identity

Extraction and connectivity use **tile keys** (format `regionId|localId|x|y`) and **province ids** (prefixed `regionId|localId`). Province lookup must be region-scoped; see [world-model-identity.md](world-model-identity.md).

### Extraction Formula

Each land tile in an owned province may have one extraction improvement (mine, farm, ranch, plantation, fur post, etc.) with an improvement level (0–4) and at most one resource (terrain-constrained per [resource-terrain-region-rules.md](resource-terrain-region-rules.md)), **except** tiles that are a **capital** or a province **town** (`townTileKey`): those tiles **never** hold a terrain resource or extraction improvement; only **roads / rail / ports** apply ([tile-map-and-generation.md](tile-map-and-generation.md) § Town and capital tile occupancy).

**Production** = min(improvement level, owner's tech-allowed max level).

**Connectivity** (whether the tile may extract at all) is defined in [capital-and-connectivity.md](capital-and-connectivity.md); **`townDevelopmentLevel` does not determine connectivity.**

### Extraction formula and town development cap

Let **T** be a connected land tile in province **P** owned by the player. **Path transport cap** = minimum transport level along the chosen connectivity path to the capital, or the **maximum** of such minima if multiple paths exist (see [capital-and-connectivity.md](capital-and-connectivity.md)). **Tile transport** is the tile’s road/rail/port level per § Transport Level (Per Tile).

**Effective yield** applies only if **T** is **connected** for extraction.

1. **Capital province (`P` is the player’s capital province):**  
   **Effective yield** = min(production, tile/path transport caps per connectivity resolver, **`P.townDevelopmentLevel`**). For **Great Powers**, **`P.townDevelopmentLevel`** is **`4`** at init and after capital reassignment (see [capital-and-connectivity.md](capital-and-connectivity.md) § Capital province town development (Great Powers)).

2. **Non-capital province:**  
   - If there exists a **road/rail path** from **T** to the **capital tile** using only **owned-territory** tiles with **transport level ≥ 1** (4-neighbor adjacency): **town development level does not limit** yield — **Effective yield** = min(production, tile/path transport caps).  
   - **Else** ( **`T` is connected only via **Town rule** — 4-adjacent to a connected town — and not by the road-path rule above):  
     - If **`P`’s town tile** is a **port tile** and that **port is connected to the capital** per [capital-and-connectivity.md](capital-and-connectivity.md) § Port connection to capital: **Effective yield** = min(production, tile/path transport caps, **`P.townDevelopmentLevel`**).  
     - **Else** (inland **non-capital** town; not a port connected to the capital): **town development level does not limit yield** — **Effective yield** = min(production, tile/path transport caps).

Tech caps first in production; transport caps use path and tile rules above. Example: level 4 farm, tech cap 3, transport 2 → production 3, then min with path cap → effective ≤ 2. The improvement stays at level 4; tech/transport upgrades or conquest can unlock more later.

### Improvement Naming

Improvement **names** are purely descriptive; they do **not** change extraction rules or yields, which continue to follow the formula above. The UI derives the displayed name from the tile's **resource id**, independent of improvement level:

| Resource id (or group) | Default improvement name |
|------------------------|--------------------------|
| `grain`                | Farm                     |
| `meat`, `horses`       | Ranch                    |
| `wool`                 | Pasture                  |
| `timber`               | Lumber camp              |
| `sugarCane`, `tobacco`, `cotton`, `spices` | Plantation  |
| `furs`                 | Fur post                 |
| `iron`, `copper`, `tin`, `coal`, `silver`, `gold`, `gems`, `diamonds` | Mine |

If a tile has **no resource id** (e.g. development-only tile in a future ruleset), the improvement name is `Improvement` by default. UI layers **may** append the numeric level for clarity (e.g. `Farm (L2)`), but the canonical base name is given by the table above.

Acceptance criteria (naming only):

- Given a land tile with resource id `gold` and improvement level \(N\) where \(N\) is an integer between 1 and 4 inclusive  
  When the UI layer queries the tile's improvement name for display  
  Then the UI layer uses the base name `Mine` for that tile, regardless of the value of \(N\)

- Given a land tile with resource id `grain` and improvement level \(N\) where \(N\) is an integer between 1 and 4 inclusive  
  When the UI layer queries the tile's improvement name for display  
  Then the UI layer uses the base name `Farm` for that tile, regardless of the value of \(N\)

- Given a land tile with resource id `furs` and improvement level \(N\) where \(N\) is an integer between 1 and 4 inclusive  
  When the UI layer queries the tile's improvement name for display  
  Then the UI layer uses the base name `Fur post` for that tile, regardless of the value of \(N\)

- Given a land tile with no resource id and improvement level \(N\) where \(N\) is an integer between 1 and 4 inclusive  
  When the UI layer queries the tile's improvement name for display  
  Then the UI layer uses the base name `Improvement` for that tile

### Town and extraction

Each province has one **town** tile assigned at game init (see [capital-and-connectivity.md](capital-and-connectivity.md) § Town per province). A tile's resources are extractable only if the tile is **connected to the capital** per connectivity rules (**Road rule** or **Town rule**). **`townTileKey` does not by itself mean “connected”**; adjacency uses the Town rule in [capital-and-connectivity.md](capital-and-connectivity.md). **Town development level** (raised by Builder `upgrade_town` work) **limits yield** per § Extraction formula and town development cap; it **does not** decide connectivity. If multiple paths exist from a tile to the capital, the **maximum** path transport cap determines the transport constraint.

### Mineral Prospecting Gate

Iron, copper, tin, coal, silver, gold, gems, diamonds require prospecting before extraction. Tile must be (a) connected and (b) prospected by that player. Non-minerals do not require prospecting. See [fog-and-exploration.md](fog-and-exploration.md).

### Transport Level (Per Tile)

**Road level** (the value stored per tile for roads/railroads/ports) is the **transport level** used in the formula "effective yield = min(production, transport level)". Each land tile has transport level in {0, 1, 2, 4}:

- **0** — not connected.
- **1** — primitive road.
- **2** — improved road (requires Road Construction tech + Engineer work order).
- **4** — port or railroad (requires Early Steam Engine and related techs + Engineer/Rail Builder work order).

Tech only **allows** building — it does not upgrade existing tiles. Ports and railroads both provide level 4. Railroads are a tech-gated road type; for connectivity they function like roads (tiles with road/railroad form paths). No separate "railroad" connectivity rule. Adjacent port tile grants level 4 to that tile. See [tech-tree-transport.md](tech-tree-transport.md), [capital-and-connectivity.md](capital-and-connectivity.md).

### Flow to Stockpile

Connected tiles' effective yields are summed by commodity. **Same-region:** added to owning player's stockpile. **Overseas:** sea transport step (cargo limit + priority). No per-province storage. See [stockpiles-and-production.md](stockpiles-and-production.md).

### Capital tile grain bonus (Great Powers)

Each **Great Power** player with a non-null **`capitalTile`** receives a fixed quantity of **`grain`** added to **land** (same-region) extraction totals **every Extraction phase**. The default amount is **5** per turn (`capitalTileGrainBonusPerTurn` in program-level `StartingResourcesConfig`, copied onto `Game` at setup for saves). This bonus is **not** tied to terrain resources on the capital tile (capital tiles remain non-extractable per § Extraction Formula) and applies **unconditionally** — it does **not** require connectivity, blockade state, or overseas paths. Minor Nations and Tribes do not use this rule (they are not `Game.players`). Scenarios may set the bonus to **0** via starting-resources config.

**Acceptance criteria**

- Given a Great Power player with `capitalTile` set and `Game.capitalTileGrainBonusPerTurn` equal to a non-negative integer **B**  
  When the System runs `computeExtraction` for that game state  
  Then that player's **land** extraction totals include **B** additional units of commodity id `grain`, even when that player's connected tile set is empty.

### Non-Great-Power extraction (Minor Nations and Tribes)

Minor Nations and Tribes are **not** `Game.players` (they do not hold a `Player` stockpile and never submit orders per [factions.md](factions.md)). Their extraction is computed by a parallel function on the same per-tile formula, with three differences from Great Power extraction:

1. **Tech cap:** Minors and Tribes do **not** research tech. Their per-tile production uses **`defaultExtractionCap = 1`** for every resource — no per-resource cap unlock, no scalar override. The improvement level on a non-GP tile is therefore clamped to **`min(improvementLevel, 1)`** before the transport-cap step in § Extraction formula and town development cap. Starting developed tiles seeded per [factions.md](factions.md) § Starting developed resources (Minor Nations and Tribes) are at improvement level **1** by design, so this clamp does not reduce baseline yield.

2. **Prospecting:** Minors and Tribes do **not** have Explorers and never prospect. **Mineral resources** (iron, copper, tin, coal, silver, gold, gems, diamonds) on non-GP tiles are **always excluded** from non-GP extraction (the § Mineral Prospecting Gate's "(b) prospected" arm can never be satisfied). Non-mineral resources (grain, meat, wool, horses, timber, sugarCane, tobacco, cotton, furs, spices) follow the same formula as GPs.

3. **No overseas, no capital-tile grain bonus:** Minors are Old-World-only and Tribes are New-World-only per [factions.md](factions.md); every tile a non-GP faction owns is in the **same region** as that faction's capital. Non-GP extraction therefore produces **land-only** totals — no overseas bucket, no naval-interception interaction, no cargo allocation. The `capitalTileGrainBonusPerTurn` (Great-Power-only by definition above) is **not** added to non-GP totals.

Connectivity resolution for non-GP factions is specified separately under [capital-and-connectivity.md](capital-and-connectivity.md); the non-GP extraction function takes a per-faction `ConnectivityResult` as input so the connectivity resolver and the extraction pipeline remain decoupled.

Non-GP extraction totals are returned per-faction-id (minor or tribe id) and are consumed by the World Market phase as system-authored offers — they are **not** added to any `Player.stockpile` and do **not** flow through Riches-to-treasury, Consumption, or Production. The full auto-offer flow is specified in [world-market.md](world-market.md) § Minor and tribe auto-sell.

**Acceptance criteria**

- Given a Minor Nation `m` with a `capitalProvinceId` in region `OW`, a connected non-mineral resource tile with improvement level `L ≥ 1`, transport cap `T ≥ 1`, and the province's `townDevelopmentLevel` is `D`  
  When the System runs non-GP extraction for `m`  
  Then `m`'s extraction totals for that resource's commodity include exactly `min(min(L, 1), T, D')` units, where `D' = D` if the tile is in `m`'s capital province (or a non-capital province with port town connected to capital per § Extraction formula and town development cap) and `D' = ∞` otherwise

- Given a Tribe `t` with a `capitalProvinceId` in region `NW` and a connected **mineral** resource tile (iron, copper, tin, coal, silver, gold, gems, or diamonds) of any improvement level  
  When the System runs non-GP extraction for `t`  
  Then `t`'s extraction totals do **not** include any units for that mineral commodity (minerals are excluded for non-GP factions because Minors and Tribes never prospect)

- Given a Minor Nation `m` with `capitalTile` set and `Game.capitalTileGrainBonusPerTurn` equal to a non-negative integer `B`  
  When the System runs non-GP extraction for `m`  
  Then `m`'s extraction totals do **not** include the `B` grain bonus (the bonus is Great-Power-only); `m`'s grain total is determined solely by connected grain tile yields

- Given the System runs non-GP extraction for any Minor Nation or Tribe  
  When the function returns its result  
  Then every per-faction totals map produced contains only **land** quantities (no overseas bucket), and the function does **not** invoke sea-transport allocation, naval interception, or `Player`-stockpile mutation

### Improvement Build Eligibility (Builder)

A Builder may build an improvement on a tile only if: (a) the tile has a **resource** (per terrain/ruleset; no improvement on empty tiles), (b) the tile's improvement level is below the **max improvement level** (4), and (c) the **next** improvement level (current + 1) does not exceed the player's **tech-allowed extraction cap** (see [tech-and-extraction-cap.md](tech-and-extraction-cap.md)). The order engine rejects build_improvement work orders when the tile has no resource or when the player lacks sufficient tech to build the next level.

### Improvement Build Costs (Builder)

| Level | Material Cost | Output |
|---|---|---|
| 1 | 1 lumber + 1 cast iron | 1 resource/turn |
| 2 | 4 lumber + 4 cast iron | 2 resources/turn |
| 3 | 8 lumber + 8 cast iron | 3 resources/turn |
| 4 | 16 lumber + 16 cast iron | 4 resources/turn |

**H8 feedstock bootstrap (level 1 only).** When the feedstock-extraction gate is active for a player (`feedstockExtractionResourceIdsForPlayer` non-empty; see [economy-planner.md](../ai/economy-planner.md) § H8-extraction) and the Builder targets an **unimproved** tile whose resource id is in that gate set, the level-0 `build_improvement` cost may omit **cast iron** while the player's stockpile holds at least **1 lumber** but **fewer than 1 cast iron** — breaking the circular dependency where extracting `timber` / `iron` to produce cast iron itself requires cast iron. Once the player holds enough cast iron for the ordinary level-1 cost, or the gate is inactive, or the tile is not an unimproved feedstock resource, the full **1 lumber + 1 cast iron** cost applies. Authoritative logic: `feedstockBootstrapBuildImprovementCastIronWaived` and `WorkOrderCostCalculator` in `colonizethis_logic`.

- Given a player whose feedstock-extraction gate is active, an unimproved `timber` resource tile, stockpile `{lumber: 1, castIron: 0}`, and a `build_improvement` work order on that tile at improvement level 0, when the system validates material cost, then the required commodities are `{lumber: 1}` only.
- Given the same player and tile but stockpile `{lumber: 1, castIron: 1}`, when the system validates material cost, then the required commodities are `{lumber: 1, castIron: 1}` (negative control — waiver clears once cast iron is affordable).
- Given a player whose feedstock-extraction gate is **inactive** and stockpile `{lumber: 1, castIron: 0}`, when the system validates a level-0 `build_improvement` on any tile, then the required commodities remain `{lumber: 1, castIron: 1}`.

### Road Costs (Engineer)

1 lumber + 1 cast iron per tile (transport level 1). **Improved road (level 2):** requires **Road Construction** tech; validation and completion must check tech before setting road level to 2.

### Railroad Costs (Rail Builder)

2 lumber + 2 steel per tile (authoritative values in `work_order_costs.dart`).

### Port Placement

One port per seaboard (seaboard = one sea zone adjacent to the province). Province with two seaboards: overseas connectivity requires a port on the seaboard with a sea path to the capital's sea.

### Fort Costs

See [siege-mechanics.md](siege-mechanics.md).

1 extra turn per build level, capped at 3 turns.

### Commodities in the Game

Extractable commodities are exactly the same as in Imp2. See [commodity-catalog.md](commodity-catalog.md).

---

## Configurable Values

| Parameter | Default | Notes |
|---|---|---|
| Max improvement level | 4 | |
| Transport levels | 0, 1, 2, 4 | |
| Improvement cost scaling | 1, 4, 8, 16 per level | lumber + cast iron |
| Road cost | 1 lumber + 1 cast iron | Per tile |

---

## Interactions

- Province and tile identity: [world-model-identity.md](world-model-identity.md)
- Connectivity: [capital-and-connectivity.md](capital-and-connectivity.md)
- Stockpile flow: [stockpiles-and-production.md](stockpiles-and-production.md)
- Transport tech: [tech-tree-transport.md](tech-tree-transport.md)
- Fog/prospecting: [fog-and-exploration.md](fog-and-exploration.md)
- Development resolution: see program/development-resolution.md
- Tile generation: [tile-map-and-generation.md](tile-map-and-generation.md)

---

## Acceptance Criteria

- Given a land tile with improvement level N (0-4) in an owned province
  When the system computes extraction for that tile
  Then the production equals min(N, owner's tech-allowed max level for that terrain/resource)

- Given a connected land tile in a Great Power's **capital province** with production `P` (from improvement and tech cap), path transport cap `MinTransport`, and that province's `townDevelopmentLevel` equal to `4`
  When the system computes effective yield for that tile on turn 1
  Then the effective yield equals `min(P, MinTransport, 4)` and any non-mineral resource (e.g. grain from a level-1 farm with tech cap ≥ 1) contributes at least what connectivity and transport allow up to that cap

- Given a connected land tile in a **non-capital** province with production `P`, path transport cap `MinTransport`, and **a road/rail path** from that tile to the capital as in § Extraction formula and town development cap
  When the system computes effective yield
  Then **town development level does not reduce** the effective yield: the yield equals `min(P, MinTransport)` (subject to tile transport rules)

- Given a connected land tile in a **non-capital** province with production `P`, path transport cap `MinTransport`, **no** road/rail path from that tile to the capital, connectivity **only** via **Town rule**, province town development level `D`, and the province **town tile is a port** connected to the capital per [capital-and-connectivity.md](capital-and-connectivity.md)
  When the system computes effective yield
  Then the effective yield equals `min(P, MinTransport, D)`

- Given a connected land tile in a **non-capital** province with production `P`, path transport cap `MinTransport`, **no** road/rail path from that tile to the capital, connectivity **only** via **Town rule**, and the province **town is not** a port connected to the capital
  When the system computes effective yield
  Then **town development level does not reduce** yield: the effective yield equals `min(P, MinTransport)`

- Given a new game where each Great Power receives four bootstrap `grain` tiles at improvement level `1` in the capital province per [tile-map-and-generation.md](tile-map-and-generation.md) § Great Power starting grain (bootstrap), and the per-resource grain extraction cap is **1** when no grain-cap gathering tech is unlocked per [tech-and-extraction-cap.md](tech-and-extraction-cap.md)
  When the system runs the **first** Extraction phase after setup
  Then each Great Power's extraction totals include **exactly 4** units of commodity `grain` from those four tiles (land/same-region bucket), absent unrelated rules that would remove connectivity

- Given a player attempts to build a level 2 road (transport level 2) on a tile
  When the system validates the build_road work order
  Then the system checks that the player has the Road Construction tech; if not, the order is rejected

- Given a tile with a resource that requires prospecting (iron, copper, tin, coal, silver, gold, gems, or diamonds)
  When the system evaluates whether that resource can be extracted
  Then the system requires both (a) the tile is connected to the capital and (b) the player has prospected that tile

- Given a player submits a build_improvement work order for a tile that has no resource (resource id missing or empty)
  When the order engine validates the work order
  Then the system rejects the order with reason that the tile has no resource

- Given a player submits a build_improvement work order for a tile whose next improvement level (current + 1) would exceed the player's tech-allowed extraction cap
  When the order engine validates the work order
  Then the system rejects the order with reason that the player lacks sufficient tech to build the next level

- Given a Builder civilian unit completes a build_improvement work order on a tile
  When the system applies the work effect
  Then the tile's improvement level increases by 1, up to the tech-allowed max for that terrain/resource

- Given a Builder civilian unit completes an upgrade_town work order on a province's town tile
  When the system applies the work effect
  Then the province's town development level increases by 1

- Given an Engineer civilian unit completes a build_road work order on a tile with transport level 0 or 1
  When the system applies the work effect
  Then the tile's transport level is set to 1 (or 2 if the player has Road Construction tech)

- Given a Rail Builder civilian unit completes a build_rail work order on a land tile with transport level 1 or 2, per-tile terrain is available from the tile map, and the player has the transport technology required for that terrain per [tech-tree-transport.md](tech-tree-transport.md)
  When the system applies the work effect
  Then the tile's transport level is set to 4 (railroad) and 2 lumber and 2 steel are consumed for that work order per ruleset cost

- Given a player submits a build_rail work order when the tile has transport level 0, or terrain data is missing for that tile, or the player lacks the rail tech required for that tile's terrain
  When the system validates the work order at submit time
  Then the system rejects the order with a clear reason

- Given a player has multiple paths from a tile to the capital
  When the system computes transport level cap for that tile's extraction
  Then the system uses the maximum transport level among all valid paths

- Given an overseas province has an owned port tile adjacent to a sea zone and that sea zone has a valid path to the capital sea (subject to blockade)
  When the system evaluates connectivity for overseas extraction
  Then that province is considered connected via sea transport using that port regardless of the province `townTileKey` location

- Given a fixed game state where ownership, roads/rails, ports, sea topology, blockade status, and all `townDevelopmentLevel` values are unchanged, and only a province `townTileKey` value changes coordinate
  When the system recomputes connectivity and extraction
  Then tiles that were connected **only** via **Town rule** to the old town coordinate may become disconnected or connect differently; `townDevelopmentLevel` **alone** still does not define connectivity

- Given a tile's improvement level, transport level, or town development level changes
  When the next production phase runs
  Then extraction recalculates using the updated values
