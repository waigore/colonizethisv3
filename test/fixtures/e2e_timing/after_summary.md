# E2E timing run fixture (after — post-refactor dev tip)

Medians from PR #3329 verification (Linux desktop 1280×1024 xvfb, 3 consecutive passes per scenario).

### new_game_full_turn_e2e_test
- min: 31.20s
- median: 32.50s
- max: 33.80s

### new_game_capital_panel_e2e_test
- min: 9.50s
- median: 10.00s
- max: 10.40s

### new_game_fleet_reaches_new_world_e2e_test
- min: 34.60s
- median: 34.70s
- max: 34.80s

## Aggregate (sum of per-test medians)
- **77.20s** (3 tests)
