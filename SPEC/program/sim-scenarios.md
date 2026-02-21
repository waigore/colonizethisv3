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
- `unitCount` — Expected unit count (exact or range via `matchType`)
- `hasUnit` — Specific unit ID that must be present
- `hasPlayerUnits` — Any units belonging to player must be present
- `stockpile` — Resource stockpile amount
- `treasury` — Treasury amount
- `matchType` — `exact` (default), `range`, `atLeast`, `atMost`

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
