# sim_scenarios — Batch Scenario Test Driver

**SPEC/program** — Batch test driver that runs scenario tests from JSON files. Each scenario initializes a deterministic game, runs scripted orders for 1-5 turns, and verifies game state assertions. Province and tile identity follow [world-model-identity.md](../game/world-model-identity.md).

---

## Province and tile identity

Province ids in scenario JSON (setup units, order targets, assertion `province` / `capitalProvinceId` / `tileKey`) must be **full** province ids or tile keys per [world-model-identity.md](../game/world-model-identity.md): province id format `regionId|localId` (e.g. `oldWorld|p1`), tile key format `regionId|localId|x|y`. Do not use bare local ids in multi-region scenarios; resolution is region-scoped and uses the prefixed form.

- **Setup units:** The runner accepts either a full province id or a local id in `province`. When the value does not contain `|`, the runner prefixes it with `oldWorld` (single-region or Old World default). For New World provinces use the full id (e.g. `newWorld|nw1`).
- **Assertions:** StateVerifier resolves province assertions by full id. When optional `region` is present, lookup is restricted to that region; the `province` field must still be the full province id (`regionId|localId`) to match game state. Tile keys in assertions (e.g. fog/exploration, capital) use the 4-part format.

---

## Responsibility

Run composite integration tests that verify game systems work correctly together. Unlike unit tests, scenarios test the full pipeline: game initialization → turn resolution → state verification. Provides a tool for CI/testing workflows via `melos run sim_scenarios`. **CI:** batch driver runs in **`.github/workflows/nightly.yml`** (not the PR `quality` workflow); local parity: **`tool/run_nightly_gate_tests.sh`**.

---

## Supported Modes

| Mode | Description |
|------|-------------|
| **Single scenario** | Run one scenario file (`--scenario=path.json`) |
| **Batch** | Run all JSON files in directory (`--directory=scenarios/`) |
| **Generate** | Run scenario and output current state as assertions (`--generate-assertions`); **not yet implemented** (see below) |

**Generate mode (`--generate-assertions`):** The CLI accepts the flag but this mode is **not yet implemented**. The tool does not currently serialize the current game state to assertion JSON. When implemented, it will run the scenario (or a subset of turns) and output the resulting state in the assertion format for use as a scaffold in scenario authoring.

---

## Scenario Sources

Two initialization types:

**Fresh initialization** — Creates new game from seed:
```json
{
  "init": {
    "type": "fresh",
    "config": {
      "seed": 12345,
      "greatPowers": ["england", "france", "spain"]
    }
  }
}
```

**Saved game** — Loads from save ID:
```json
{
  "init": {
    "type": "saved",
    "gameId": "save_abc123"
  }
}
```

**From-topology (connectivity scenarios)** — Builds game from a fixed Old World (and optional New World) topology and grid. Used for connectivity and capital assertions. `init.type`: `"fromTopology"`. `init.config`: optional `greatPowers`, `seed`, `tribeCount` (for NW). `init.oldWorld` / `init.newWorld`: `{ "grid": [[...]], "nodes": [...], "edges": [...] }`. Optional **resourceGrid**: same dimensions as grid; each cell is a resource name (e.g. `"grain"`) or null; used for extraction scenarios (SPEC/game/extraction-and-improvements.md). Optional **terrainGrid**: same dimensions as grid; each cell is a `TerrainType` name (e.g. `"plains"`, `"hills"`) or null for sea cells; used when scenarios need per-tile terrain (e.g. `build_rail` validation per SPEC/game/tech-tree-transport.md). **Behaviour:** No Minor Nations (minor count and min provinces per minor are forced to 0) so that province assignment only assigns to Great Powers and, when present, Tribes on the New World. Aligns with [game-setup.md](../game/game-setup.md) (config from scenario).

For saved games (or after fresh/fromTopology init), optional `setup` block injects units and can override player economy for specific test scenarios:
```json
{
  "setup": {
    "units": [
      {"player": "france", "type": "infantry", "province": "normandy", "count": 3}
    ],
    "initialWorkers": {
      "gp1": { "peasants": 2, "apprentices": 0, "journeymen": 0, "masters": 0 }
    },
    "initialStockpile": {
      "gp1": { "grain": 1, "meat": 0 }
    }
  }
}
```
- **initialWorkers:** Optional. Map player id → `{ "peasants", "apprentices", "journeymen", "masters" }`. Overrides that player's worker pool before the first turn. Used for consumption / food-strike scenarios (SPEC/game/workers-and-population.md).
- **initialStockpile:** Optional. Map player id → `{ commodityId: quantity, ... }`. Overrides that player's stockpile (replaces) before the first turn. Commodity ids are canonical (e.g. `grain`, `meat`).
- **productionAssignments:** Optional. List of `{ "recipeId": "<id>", "assignedLabour": <n> }`. Passed to the Production phase for each turn so scenarios can verify SPEC/game/stockpiles-and-production.md (inputs consumed, outputs added to central stockpile). Same list is used for every turn in the scenario. Recipe ids are from the program-level catalog (e.g. `lumber_from_timber`, `castIron_from_timber_iron_coal`).
- **initialTileState:** Optional. Map tile key (e.g. `"oldWorld|p1|0|0"`) → `{ "improvementLevel": 0–4, "roadLevel": 0|1|2|4 }`. Applied to `worldState.tileState` before the first turn. Used for extraction scenarios (SPEC/game/extraction-and-improvements.md).
- **leaderKeys:** Optional. Map player id → leaderKey (string). Overrides each Great Power's `Player.leaderKey` after init. Used for leader-bonus scenarios (SPEC/game/leader-bonuses.md).
- **initialTech:** Optional. Map player id → list of tech ids. Overrides that player's `Player.techUnlocked` (each listed tech id set to true) before the first turn. Used for regiment buildability (SPEC/game/military-units.md), deployment-limit (SPEC/game/military-generals.md: base 10 vs 12 with Nationalism), and tech-tree scenarios.
- **initialTreasury:** Optional. Map player id → integer treasury (pounds). Overrides that player's `Player.treasury` before the first turn. Used for Join Empire scenarios (SPEC/game/diplomacy.md) where cost scales with target size.
- **defaultCombatMode:** Optional. String `"quickBattle"` or `"autoResolve"`. Overrides `Game.defaultCombatMode` so combat in the scenario uses Quick Battle or auto-resolve. Used for Quick Battle scenarios (SPEC/game/quick-battle.md).

---

## Order Scripts

Each turn specifies orders for one or more players:

```json
{
  "turns": [
    {
      "turn": 1,
      "orders": [
        {"player": "england", "type": "move", "unit": "england_infantry_0", "to": "yorkshire"},
        {"player": "france", "type": "build", "unitType": "cavalry", "in": "ile_de_france"}
      ]
    }
  ]
}
```

Supported order types: `move`, `build`, `work`, `diplomatic`, `research`, `naval_move`, `naval_mission`.

- **work orders:** Use `type: "work"` with:
  - `unit` — unit id in the game state.
  - `workType` — work target id (`explore`, `prospect`, `build_improvement`, `build_road`, `build_port`, `build_fort`, `build_rail`, `counter_spy`, `purchase_land`).
  - `targetTileKey` (optional but **required** for tile-level work such as `build_improvement`, `build_road`, `build_port`, `build_fort`, `build_rail`): tile key string in format `regionId|provinceId|x|y`. When omitted, the runner uses the work target’s own default behaviour (e.g. province-level `explore`). For **build_improvement**, the target tile must have a resource in world state and the ordering player's tech cap must allow the next improvement level; otherwise the order engine rejects the order (see [extraction-and-improvements.md](../game/extraction-and-improvements.md), [development-resolution.md](development-resolution.md)). For **build_rail**, the tile must have transport level 1 or 2, the scenario must supply **terrainGrid** (or otherwise provide tile map terrain) so terrain is known, and the player's unlocked tech must allow rail on that terrain; otherwise validation rejects the order (see [tech-tree-transport.md](../game/tech-tree-transport.md)).

Each turn may optionally include **workerAssignments** (production phase): a list of `{ "recipeId": "<id>", "assignedLabour": <n> }`. These are passed as default production assignments for that turn so the Production phase can run recipes; see SPEC/game/production-recipes.md. Scenario setup may include **initialStockpile** and **initialWorkers** per player (map from player id to commodity quantities or worker counts) to set economy state before turns run.

### Diplomatic orders

Diplomatic orders use `type: "diplomatic"` with additional fields to select the diplomatic action:

```json
{
  "player": "gp1",
  "type": "diplomatic",
  "diplomaticType": "declareWar",
  "targetFactionId": "gp2"
}
```

`diplomaticType` maps to `DiplomaticOrderType` (`declareWar`, `offerPeace`, `alliance`, `establishOverture`, `grantAid`, `setSubsidy`). Optional fields:

- `amount` — for `grantAid` / `setSubsidy` orders (integer pounds)
- `overtureStage` — for `establishOverture` (`tradeConsulate`, `embassy`, `nap`, `joinEmpire`)

If `diplomaticType` is omitted, the parser defaults to `declareWar`.

---

## Assertions

State verification after each turn or at final state:

```json
{
  "assertions": [
    {"turn": 1, "province": "yorkshire", "owner": "england"},
    {"turn": 1, "province": "ile_de_france", "unitCount": 1},
    {"turn": 2, "stockpile": 100, "matchType": "atLeast"},
    {"turn": 2, "province": "yorkshire", "hasPlayerUnits": "france"}
  ]
}
```

Assertion fields:
- `turn` — Which turn to check (optional, defaults to final state)
- `province` — Province ID to check (full id `regionId|localId` per § Province and tile identity)
- `owner` — Expected owner player ID
- `notOwner` — Negative assertion: province must not be owned by this player ID
- `unitCount` — Expected unit count (exact or range via `matchType`)
- `hasUnit` — Specific unit ID that must be present
- `hasPlayerUnits` — Any units belonging to player must be present
- `provinceDisplayName` — With `province`: expected `Province.displayName` (SPEC/game/naming.md). Verifies naming phase assigned the expected name (e.g. GP capital gets capital city name).
- `stockpile` — Resource stockpile amount (sum of all commodities in player stockpile)
- `stockpileCommodity` — With `player` and `commodity` (commodity id): expected quantity of that commodity in the player's central stockpile. Supports `matchType`.
- `treasury` — Treasury amount
- `matchType` — `exact` (default), `range`, `atLeast`, `atMost`

**Worker and stockpile assertions** (SPEC/game/workers-and-population.md): use `player` with optional `workerPeasants`, `workerApprentices`, `workerJourneymen`, `workerMasters` (expected count each). Use `player` with `commodity` (commodity id, e.g. `grain`) and `stockpileCommodity` (expected quantity) for per-commodity stockpile checks.

**Capital assertions** (SPEC/game/capital-choice-phase.md):
- Use `player` (Great Power id, e.g. `gp1`) with `capitalProvince` — expected full province id (e.g. `oldWorld|p1`) for that player's capital. Verifies the capital-choice phase selected the expected province.
- `player` (faction id: `gp1`, `minor1`, `tribe1`, etc.) + `capitalProvinceId` — the faction's capital province must equal this full province id (e.g. `oldWorld|p1`). Optional `capitalTileKey` — the faction's capital tile must equal this key (format `regionId|provinceId|x|y`). Example: `{"turn": 1, "player": "gp1", "capitalProvinceId": "oldWorld|p1", "capitalTileKey": "oldWorld|p1|0|0"}`.

**Diplomacy assertions** (SPEC/game/diplomacy.md):
- Use `player` for the first faction (typically a Great Power) and `relationWith` for the other faction id.
- `relationState` — Expected relation state between `player` and `relationWith` (`atPeace` or `atWar`).
- `relationScore` — Expected integer relation score (0–100).
- `relationLevel` — Expected relation level (`hostile`, `neutral`, `friendly`, `allied`).
- `relationSinceTurn` — Expected `sinceTurn` value on the relation.
- `relationLastInteractionTurn` — Expected `lastInteractionTurn` value on the relation.
- `overtureStage` — Expected overture stage between a Great Power (`player`) and a Minor/Tribe (`relationWith`): one of `none`, `tradeConsulate`, `embassy`, `nap`, `joinEmpire`.

**Resource-placement assertions** (SPEC/game/resource-terrain-region-rules.md):
- `region` + `resource` (no `province`/`player`) — **regionHasNoResource:** no tile in the given region has this resource (negative). Example: `{"region": "oldWorld", "resource": "sugarCane"}`.
- `everyTileResourceAllowedInRegion` — For each tile in `resourceByTileKey`, the resource is allowed in that tile's region per resource rules. Optional `region` restricts to one region.
- `region` + `maxBothFraction` — **resourcePlacementCap:** in the given region, the fraction of placed resources that are “both” (timber, iron, copper, tin, coal) is ≤ this value (default 0.30). Example: `{"region": "oldWorld", "maxBothFraction": 0.30}`.

**Economy / production assertions** (SPEC/game/production-recipes.md): use `player`, `commodity` (commodity id), and `stockpileCommodity` (expected quantity) to assert per-commodity stockpile after a turn or final state; supports `matchType`.

**Faction count assertions** (SPEC/game/factions.md): use `greatPowerCount`, `minorNationCount`, `tribeCount` (expected integer counts) to verify that game setup created the configured Great Powers, Minor Nations, and Tribes. Example: `{"turn": 1, "greatPowerCount": 1, "minorNationCount": 1, "tribeCount": 1}`.

**Faction effective military level** (SPEC/game/factions.md): use `player` (Minor or Tribe faction id, e.g. `minor1`, `tribe1`) and `effectiveMilitaryLevel` (expected integer 1–4) to verify parity step: minors get max GP level; tribes always 1. Example: `{"turn": 1, "player": "tribe1", "effectiveMilitaryLevel": 1}`.

**Fog/exploration assertions** (SPEC/game/fog-and-exploration.md): use `player`, `tileKey` (format `regionId|provinceId|x|y`), and optionally `tileVisibility` (expected level: `unknown`, `revealed`, `fogged`, `fullyVisible`) and/or `tileProspected` (boolean). Example: `{"turn": 1, "player": "gp1", "tileKey": "oldWorld|p1|0|0", "tileVisibility": "fullyVisible"}`; `{"player": "gp1", "tileKey": "oldWorld|p2|2|0", "tileVisibility": "fogged", "tileProspected": false}`. For **sea zone tiles**, the second segment of `tileKey` is the sea zone local id (e.g. `oldWorld|s1|0|0` for a cell in sea zone `s1`). Visibility scenario coverage (including coastal sea zone full visibility) is defined in [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md) § Visibility test scenarios.

**Improvement naming assertions** (SPEC/game/extraction-and-improvements.md): when the scenario runner exposes a UI-facing view for tiles, use `tileKey` (format `regionId|provinceId|x|y`) with `tileImprovementName` (expected string) to verify that the improvement naming table is applied correctly. Example: `{"turn": 1, "tileKey": "oldWorld|p1|0|0", "tileImprovementName": "Farm"}` for a tile whose resource id is `grain` and improvement level is between 1 and 4 inclusive.
  
**Road / transport-level assertions** (SPEC/game/capital-and-connectivity.md, SPEC/program/development-resolution.md): use `tileKey` with `tileRoadLevel` (expected integer in `{0,1,2,4}`) to verify the per-tile road/transport level in `worldState.tileState`. Example: `{"turn": 2, "tileKey": "oldWorld|p1|1|1", "tileRoadLevel": 2}` for a tile that should have been upgraded by a `build_road` work order and any adjacency propagation rules.

**Leader assertions** (SPEC/game/leader-bonuses.md): use `player` (Great Power id) and `leaderKey` (expected leader key, e.g. `napoleon`, `frederick`, `reserve`). Example: `{"turn": 1, "player": "gp1", "leaderKey": "napoleon"}`.

**Research-state assertions** (SPEC/game/research-state.md): use `player` and `techUnlocked` (array of tech ids that must be true in that player’s techUnlocked map). Example: `{"turn": 1, "player": "gp1", "techUnlocked": ["gathering_1", "road_construction"]}`.

**Victory assertions** (SPEC/game/victory.md): use `victoryWinner` (expected winner player id), `victoryType` (e.g. `military`), and optionally `victoryTurn` (turn number when victory was set). Verifies `Game.victory` after end-of-turn. Example: `{"turn": 1, "victoryWinner": "gp1", "victoryType": "military", "victoryTurn": 0}`.

---

## Execution Flow

1. **Load** scenario JSON
2. **Initialize** game (fresh or saved)
3. **Apply** setup (unit injection if specified)
4. **For each turn**:
   - Parse orders → `Orders` object
   - Call `resolveTurnForGameFromOrderEngine()` with deterministic seed
   - Verify assertions for that turn
5. **Verify** final assertions
6. **Output** markdown report

---

## Output

Markdown report with:
- Summary (total, passed, failed)
- Per-scenario results with assertion table
- Detailed failure messages

```
# Scenario Test Results

**Run:** 2024-01-15 10:30:00
**Total:** 5 scenarios
**Passed:** 4
**Failed:** 1

---

## ✅ basic_turn_1

| Turn | Check | Result |
|------|-------|--------|
| 1 | province.yorkshire.owner == england | ✅ |

**Status:** PASSED
```

---

## Integration

- Entry: `melos run sim_scenarios`
- Depends on: `runInitGame()` from colonizethis_logic, `GameSaveAdapter` from colonizethis_save
- Shares init code with ctdev via `init_game_orchestrator.dart`

---

## Seaboard and port audit (GitHub [#1766](https://github.com/waigore/colonizethisv3/issues/1766))

**Purpose:** After each scenario’s game is initialized and optional `setup` is applied, the runner performs a **seaboard / port data audit** so invalid `portsByProvinceSeaboard` geometry or missing capital-port registry entries fail **before** map view construction. Complements strict harbor placement in [town-port-icons.md](../ui/town-port-icons.md) (GitHub [#1761](https://github.com/waigore/colonizethisv3/issues/1761)).

**Where:** `tool/sim_scenarios/lib/seaboard_port_audit.dart`, invoked from `tool/sim_scenarios/lib/scenario_runner.dart` immediately after setup.

**Predicate (summary):**

- **Seaboard province:** same as map view / capital setup — province node with a **P↔S** topology edge to a **sea zone** node in that region’s topology (local sea zone ids), per [map-topology.md](../game/map-topology.md) and `init_game_map_view_builder` coastal detection.
- **Drawable sea cell:** for every `portsByProvinceSeaboard` entry, `computePortDrawableSeaCellForMap` (colonizethis_map) must not throw for that entry’s port tile key and the region’s tile map + sea zone id set.
- **Capital port completeness:** for each Great Power, Minor Nation, and Tribe with a **capital tile** in a region whose topology marks that capital province as **sea-bound** (`isProvinceSeaBound`), every adjacent sea zone in that topology must have a matching `portsByProvinceSeaboard` key `fullProvinceId|seaZoneId` (same shape as `applyCapitalPortAndRoad` in capital setup). Inland capitals are not checked for port registry completeness.

- **Unowned provinces:** [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Town per province applies only to **owned** provinces; unowned provinces get a default town tile from setup (first tile in the province). The audit **does not** require or check `portsByProvinceSeaboard` entries for provinces with **no** `ownerId`.

- **Overseas owned provinces (town vs port):** Per [capital-and-connectivity.md](../game/capital-and-connectivity.md) § Town per province, a province **overseas** for its owner (province `regionId` ≠ capital province’s region) with **at least one** port registry entry for that full province id must have **`townTileKey` equal to one of those port tile values** (same rule as init town assignment’s overseas branch). Failure kind: `overseas_town_not_port_tile`.

**Skipped audit:** Init paths without both `tileMapByRegion` and `topologyByRegion` (e.g. `saved` scenarios that load a game without map data in the runner) skip the audit and record `skipped: true` in the JSON summary; they do **not** fail the scenario on that basis alone.

**Output:** Batch and single-scenario runs append a fenced **JSON** block after the markdown report with `seaboardPortAuditVersion` and per-scenario `portAudit` objects (`skipped`, `skipReason`, `failures` with structured fields). Any non-skipped audit failure fails the scenario run and exits non-zero (same CI gate as `melos run sim_scenarios`).
