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
- Pick first tile in Class A (row-major scan), then B, then C. GPs require coastal; Minors/Tribes do not.

**3. Apply:** Set capitalProvinceId and capitalTile. For sea-bound provinces, apply port/road auto-build per [capital-and-connectivity.md](capital-and-connectivity.md) § Capital Setup. For inland Minors/Tribes, skip port/road.

The border-avoidance heuristic is purely aesthetic; it does not affect connectivity or extraction.

---

## Interactions

- [capital-and-connectivity.md](capital-and-connectivity.md) — capital setup rules, connectivity
- [game-setup.md](game-setup.md) — setup pipeline triggers this phase
