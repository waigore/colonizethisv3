# sim_scenarios — Batch Scenario Test Driver

**SPEC/program** — Batch test driver that runs scenario tests from JSON files. Each scenario initializes a deterministic game, runs scripted orders for 1-5 turns, and verifies game state assertions.

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

**From-topology (connectivity scenarios)** — Builds game from a fixed Old World (and optional New World) topology and grid. Used for connectivity and capital assertions. `init.type`: `"fromTopology"`. `init.config`: optional `greatPowers`, `seed`, `tribeCount` (for NW). `init.oldWorld` / `init.newWorld`: `{ "grid": [[...]], "nodes": [...], "edges": [...] }`. **Behaviour:** No Minor Nations (minor count and min provinces per minor are forced to 0) so that province assignment only assigns to Great Powers and, when present, Tribes on the New World. Aligns with [game-setup.md](../game/game-setup.md) (config from scenario).

For saved games, optional `setup` block injects units for specific test scenarios:
```json
{
  "setup": {
    "units": [
      {"player": "france", "type": "infantry", "province": "normandy", "count": 3}
    ]
  }
}
```

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
- `province` — Province ID to check
- `owner` — Expected owner player ID
- `notOwner` — Negative assertion: province must not be owned by this player ID
- `unitCount` — Expected unit count (exact or range via `matchType`)
- `hasUnit` — Specific unit ID that must be present
- `hasPlayerUnits` — Any units belonging to player must be present
- `stockpile` — Resource stockpile amount (sum of all commodities in player stockpile)
- `treasury` — Treasury amount
- `matchType` — `exact` (default), `range`, `atLeast`, `atMost`

**Capital assertions** (SPEC/game/capital-choice-phase.md):
- Use `player` (Great Power id, e.g. `gp1`) with `capitalProvince` — expected full province id (e.g. `oldWorld|p1`) for that player’s capital. Verifies the capital-choice phase selected the expected province.

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
