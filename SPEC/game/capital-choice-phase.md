# Capital Choice Phase

**SPEC/game** — Phase before game start where each Great Power chooses their capital. Capital setup rules and connectivity: [capital-and-connectivity.md](capital-and-connectivity.md). Topology: [map-topology.md](map-topology.md).

---

## Overview

The capital-choice phase runs **before the game starts** as a distinct setup phase. It applies to **Great Powers only**. Minor Nations and Tribes receive their capital during game setup (see [game-setup.md](game-setup.md)).

---

## Rules

- The chosen province must be **sea-bound** (topology has at least one P–S edge).
- The player selects a **province** and a **tile** within that province.
- Port/road auto-build per [capital-and-connectivity.md](capital-and-connectivity.md) § Capital Setup.
- Phase 2 stub: **auto-choice during setup** (no UI); a future UI lets GPs confirm or override.

---

## Auto-Choice Algorithm

When UI is deferred, capitals are set automatically during game setup. Runs once per faction (GPs, then Minors, then Tribes).

**1. Choose province:**
- **Great Powers:** From owned provinces, keep only sea-bound (P–S edge). Pick first by sorted id. If none sea-bound, setup is invalid.
- **Minor Nations / Tribes:** Prefer sea-bound; otherwise any owned province. Pick first by sorted id.

**2. Choose tile (border-avoidance heuristic):**
- **Class A:** Coastal tiles not adjacent to any other province.
- **Class B:** Interior tiles not adjacent to any other province.
- **Class C:** All remaining tiles.
- **Great Powers:** Pick first tile in Class A (row-major scan). If Class A is empty, pick the first coastal tile in Class C (row-major scan). If no coastal tile exists in the selected province, setup is invalid.
- **Minor Nations / Tribes:** Pick first tile in Class A (row-major scan), then Class B, then Class C.

**3. Apply:** Set capitalProvinceId and capitalTile. For sea-bound provinces, apply port/road auto-build per [capital-and-connectivity.md](capital-and-connectivity.md) § Capital Setup. For inland Minors/Tribes, skip port/road.

The border-avoidance heuristic is purely aesthetic; it does not affect connectivity or extraction.

---

## Acceptance Criteria

- Given a Great Power owns at least one province marked as sea-bound in the map topology (has at least one P–S edge)  
  When the system runs the capital auto-choice phase for that Great Power during game setup  
  Then the system selects the first sea-bound owned province by sorted province id and marks that province as the capital province for that Great Power

- Given a Great Power owns no provinces marked as sea-bound in the map topology (no P–S edges on any owned province)  
  When the system runs the capital auto-choice phase for that Great Power during game setup  
  Then the system marks game setup as invalid for that game configuration and surfaces an error reason `no_sea_bound_capital_province` for that Great Power

- Given a Minor Nation or Tribe owns at least one sea-bound province and at least one inland province  
  When the system runs the capital auto-choice phase for that faction during game setup  
  Then the system filters to sea-bound owned provinces first, selects the first by sorted province id, and marks that province as the capital province for that faction

- Given a Minor Nation or Tribe owns no sea-bound provinces but owns at least one inland province  
  When the system runs the capital auto-choice phase for that faction during game setup  
  Then the system selects the first inland owned province by sorted province id and marks that province as the capital province for that faction

- Given the system has selected a capital province for a Great Power that is sea-bound and the province contains at least one tile in Class A (coastal tiles not adjacent to any other province)  
  When the system selects the capital tile for that Great Power during game setup  
  Then the system selects the first tile in Class A in row-major order and sets that tile as the capital tile

- Given the system has selected a capital province for a Great Power that is sea-bound and the province contains no tiles in Class A but contains at least one coastal tile in Class C (remaining tiles)  
  When the system selects the capital tile for that Great Power during game setup  
  Then the system selects the first coastal tile in Class C in row-major order and sets that tile as the capital tile

- Given the system has selected a capital province for a Great Power that is sea-bound and the province contains no coastal tiles in Class A or Class C  
  When the system selects the capital tile for that Great Power during game setup  
  Then the system marks game setup as invalid for that game configuration and surfaces an error reason `no_coastal_capital_tile_for_gp` for that Great Power

- Given the system has selected a capital province for a Minor Nation or Tribe and classified its tiles into Class A (coastal, no foreign border), Class B (interior, no foreign border), and Class C (remaining)  
  When the system selects the capital tile for that faction during game setup  
  Then the system selects the first available tile in Class A in row-major order, or if Class A is empty the first tile in Class B, or if Class B is also empty the first tile in Class C

- Given the system has set a sea-bound capital province and capital tile for any faction during game setup  
  When the capital-choice phase completes for that faction  
  Then the system applies port and road auto-build for that capital exactly once according to `capital-and-connectivity.md` § Capital Setup and records the resulting connectivity in the map data

- Given the system has set an inland capital province and capital tile for a Minor Nation or Tribe during game setup  
  When the capital-choice phase completes for that faction  
  Then the system does not create any port structures or sea connections for that capital and leaves existing road topology unchanged

## Interactions

- [capital-and-connectivity.md](capital-and-connectivity.md) — capital setup rules, connectivity
- [game-setup.md](game-setup.md) — setup pipeline triggers this phase
