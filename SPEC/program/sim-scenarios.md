# sim_scenarios — Batch Scenario Test Driver

**SPEC/program** — Batch test driver that runs scenario tests from JSON files. Each scenario initializes a deterministic game, runs scripted orders for 1-5 turns, and verifies game state assertions. Province and tile identity follow [world-model-identity.md](../game/world-model-identity.md).

---

## Province and tile identity

Province ids in scenario JSON (setup units, order targets, assertion `province` / `capitalProvinceId` / `tileKey`) must be **full** province ids or tile keys per [world-model-identity.md](../game/world-model-identity.md): province id format `regionId|localId` (e.g. `oldWorld|p1`), tile key format `regionId|localId|x|y`. Do not use bare local ids in multi-region scenarios; resolution is region-scoped and uses the prefixed form.

- **Setup units:** The runner accepts either a full province id or a local id in `province`. When the value does not contain `|`, the runner prefixes it with `oldWorld` (single-region or Old World default). For New World provinces use the full id (e.g. `newWorld|nw1`).
- **Assertions:** StateVerifier resolves province assertions by full id. When optional `region` is present, lookup is restricted to that region; the `province` field must still be the full province id (`regionId|localId`) to match game state. Tile keys in assertions (e.g. fog/exploration, capital) use the 4-part format.

---

## Responsibility

Run composite integration tests that verify game systems work correctly together. Unlike unit tests, scenarios test the full pipeline: game initialization → turn resolution → state verification. Provides a tool for CI/testing workflows via `melos run sim_scenarios`.

---

## Supported Modes

| Mode | Description |
|------|-------------|
| **Single scenario** | Run one scenario file (`--scenario=path.json`) |
| **Batch** | Run all JSON files in directory (`--directory=scenarios/`) |
| **Generate** | Run scenario and output current state as assertions (`--generate-assertions`) |

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

**From-topology (connectivity scenarios)** — Builds game from a fixed Old World (and optional New World) topology and grid. Used for connectivity and capital assertions. `init.type`: `"fromTopology"`. `init.config`: optional `greatPowers`, `seed`, `tribeCount` (for NW). `init.oldWorld` / `init.newWorld`: `{ "grid": [[...]], "nodes": [...], "edges": [...] }`. Optional **resourceGrid**: same dimensions as grid; each cell is a resource name (e.g. `"grain"`) or null; used for extraction scenarios (SPEC/game/extraction-and-improvements.md). **Behaviour:** No Minor Nations (minor count and min provinces per minor are forced to 0) so that province assignment only assigns to Great Powers and, when present, Tribes on the New World. Aligns with [game-setup.md](../game/game-setup.md) (config from scenario).

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
- **initialWorkers:** Optional. Map player id → `{ "peasants", "apprentices", "journeymen", "masters" }`. Overrides that player's worker pool before the first turn. Used for consumption/starvation scenarios (SPEC/game/workers-and-population.md).
- **initialStockpile:** Optional. Map player id → `{ commodityId: quantity, ... }`. Overrides that player's stockpile (replaces) before the first turn. Commodity ids are canonical (e.g. `grain`, `meat`).
- **productionAssignments:** Optional. List of `{ "recipeId": "<id>", "assignedLabour": <n> }`. Passed to the Production phase for each turn so scenarios can verify SPEC/game/stockpiles-and-production.md (inputs consumed, outputs added to central stockpile). Same list is used for every turn in the scenario. Recipe ids are from the program-level catalog (e.g. `lumber_from_timber`, `castIron_from_timber_iron_coal`).
- **initialTileState:** Optional. Map tile key (e.g. `"oldWorld|p1|0|0"`) → `{ "improvementLevel": 0–4, "roadLevel": 0|1|2|4 }`. Applied to `worldState.tileState` before the first turn. Used for extraction scenarios (SPEC/game/extraction-and-improvements.md).
- **leaderKeys:** Optional. Map player id → leaderKey (string). Overrides each Great Power’s `Player.leaderKey` after init. Used for leader-bonus scenarios (SPEC/game/leader-bonuses.md).
- **initialTech:** Optional. Map player id → list of tech ids. Overrides that player’s `Player.techUnlocked` (each listed tech id set to true) before the first turn. Used for regiment buildability scenarios (SPEC/game/military-units.md, tech-tree).
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
- `stockpile` — Resource stockpile amount (sum of all commodities in player stockpile)
- `stockpileCommodity` — With `player` and `commodity` (commodity id): expected quantity of that commodity in the player's central stockpile. Supports `matchType`.
- `treasury` — Treasury amount
- `matchType` — `exact` (default), `range`, `atLeast`, `atMost`

**Worker and stockpile assertions** (SPEC/game/workers-and-population.md): use `player` with optional `workerPeasants`, `workerApprentices`, `workerJourneymen`, `workerMasters` (expected count each). Use `player` with `commodity` (commodity id, e.g. `grain`) and `stockpileCommodity` (expected quantity) for per-commodity stockpile checks.

**Capital assertions** (SPEC/game/capital-choice-phase.md):
- Use `player` (Great Power id, e.g. `gp1`) with `capitalProvince` — expected full province id (e.g. `oldWorld|p1`) for that player’s capital. Verifies the capital-choice phase selected the expected province.
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
- `everyTileResourceAllowedInRegion` — For each tile in `resourceByTileKey`, the resource is allowed in that tile’s region per resource rules. Optional `region` restricts to one region.
- `region` + `maxBothFraction` — **resourcePlacementCap:** in the given region, the fraction of placed resources that are “both” (timber, iron, copper, tin, coal) is ≤ this value (default 0.30). Example: `{"region": "oldWorld", "maxBothFraction": 0.30}`.

**Economy / production assertions** (SPEC/game/production-recipes.md): use `player`, `commodity` (commodity id), and `stockpileCommodity` (expected quantity) to assert per-commodity stockpile after a turn or final state; supports `matchType`.

**Faction count assertions** (SPEC/game/factions.md): use `greatPowerCount`, `minorNationCount`, `tribeCount` (expected integer counts) to verify that game setup created the configured Great Powers, Minor Nations, and Tribes. Example: `{"turn": 1, "greatPowerCount": 1, "minorNationCount": 1, "tribeCount": 1}`.

**Fog/exploration assertions** (SPEC/game/fog-and-exploration.md): use `player`, `tileKey` (format `regionId|provinceId|x|y`), and optionally `tileVisibility` (expected level: `unknown`, `revealed`, `fogged`, `fullyVisible`) and/or `tileProspected` (boolean). Example: `{"turn": 1, "player": "gp1", "tileKey": "oldWorld|p1|0|0", "tileVisibility": "fullyVisible"}`; `{"player": "gp1", "tileKey": "oldWorld|p2|2|0", "tileVisibility": "fogged", "tileProspected": false}`.

**Leader assertions** (SPEC/game/leader-bonuses.md): use `player` (Great Power id) and `leaderKey` (expected leader key, e.g. `napoleon`, `frederick`, `reserve`). Example: `{"turn": 1, "player": "gp1", "leaderKey": "napoleon"}`.

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
