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

**2. Choose tile (Class A/B/C + plains):**
- **Class A:** Coastal, not adjacent to another province. **Class B:** Interior, not adjacent to another province. **Class C:** Remaining.
- **Within each class:** Prefer first **plains** tile (row-major); else first tile. Class rank beats terrain (Class A non-plains beats Class B plains).
- **Great Powers:** Class A (plains-first); else first coastal Class C (plains-first). No coastal tile → invalid.
- **Minor Nations / Tribes:** Class A, then B, then C (plains-first within each).

**3. Select-then-convert:** If the winning tile is not `TerrainType.plains`, convert it to plains and clear resource/extraction on that tile.

**4. Apply:** Set capitalProvinceId and capitalTile. Sea-bound: port/road per [capital-and-connectivity.md](capital-and-connectivity.md). Inland Minors/Tribes: skip port/road.

---

## Acceptance Criteria

- Given a Great Power owns at least one sea-bound province (P–S edge)  
  When capital auto-choice runs for that Great Power  
  Then The System selects the first sea-bound owned province by sorted id as capital province

- Given a Great Power owns no sea-bound provinces  
  When capital auto-choice runs for that Great Power  
  Then The System fails setup with code `no_sea_bound_capital_province`

- Given a Minor Nation or Tribe owns at least one sea-bound and at least one inland province  
  When capital auto-choice runs for that faction  
  Then The System prefers sea-bound owned provinces and selects the first by sorted id

- Given a Minor Nation or Tribe owns no sea-bound provinces but owns inland provinces  
  When capital auto-choice runs for that faction  
  Then The System selects the first inland owned province by sorted id

- Given a sea-bound GP capital province with at least one Class A tile  
  When The System selects the capital tile  
  Then The System picks the first plains Class A tile in row-major order if any, else the first Class A tile, then converts to plains and clears resource/extraction if the selected tile was non-plains

- Given a capital province with a Class A non-plains tile earlier than a Class B plains tile  
  When The System selects the capital tile  
  Then The System selects the Class A tile (class beats plains) and converts it to plains if needed

- Given a sea-bound GP capital province with no Class A but at least one coastal Class C tile  
  When The System selects the capital tile  
  Then The System picks the first coastal plains Class C tile if any, else the first coastal Class C tile, then converts to plains if needed

- Given a sea-bound GP capital province with no coastal Class A or Class C tiles  
  When The System selects the capital tile  
  Then The System fails setup with code `no_coastal_capital_tile_for_gp`

- Given a Minor/Tribe capital province with Class A/B/C tiles  
  When The System selects the capital tile  
  Then The System picks Class A then B then C (plains-first within class) and converts to plains if the selected tile is non-plains

- Given a sea-bound capital for any faction  
  When capital-choice completes for that faction  
  Then The System applies port/road auto-build exactly once per `capital-and-connectivity.md` § Capital Setup

- Given an inland Minor/Tribe capital  
  When capital-choice completes for that faction  
  Then The System creates no ports or sea connections for that capital

## Interactions

- [capital-and-connectivity.md](capital-and-connectivity.md) — capital setup rules, connectivity
- [game-setup.md](game-setup.md) — setup pipeline triggers this phase
