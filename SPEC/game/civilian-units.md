# Civilian Units

**SPEC/game** — All six civilian unit types and their roles. Derived from GDD 05, TDD 05. Reference: Imperialism II 03-units-civilian (GDD).

---

## Overview

**The game supports all six civilian types** per Imperialism II 03-units-civilian: Explorer, Engineer, Builder, Spy, Merchant, Rail Builder. Civilian units are map units — they deploy, move, and work on terrain. They are distinct from workers (population for industry; see [workers-and-population.md](workers-and-population.md)).

---

## Civilian Types and Roles

| Unit | Role | Cost | Unlock | Special |
|------|------|------|--------|---------|
| **Explorer** | Explore fog of war; prospect for minerals | Free | Starting | Minerals must be prospected before extraction; free exploration and prospecting |
| **Engineer** | Build roads, ports, fortifications | Lumber + metal (cast iron/bronze/steel) | Starting | Roads gather resources; ports and forts in cities/rivers |
| **Builder** | Improve terrain production (mines, farms, ranches, plantations, fur posts, towns) | Lumber + cast iron | Starting | Increases output 1→2→3→4; tech caps max level |
| **Spy** | Scout garrison strength; steal technology; defensive counter-spy | Free | Starting | Must be assigned to province; invisible to enemies |
| **Merchant** | Purchase land in Minor Nations/Tribes and New World | Cash | Merchant Companies tech, embassy | Creates economic control; protects New World province from invasion |
| **Rail Builder** | Upgrade roads to railroads | Steel + lumber | Early Steam Engine tech | Rail transports up to 4 resources per tile |

---

## Relations

- **Unit** (type = civilian) → has owner (player id), location (province id).
- Civilian units consume construction costs (paper, cash, lumber, metal) from player stockpile when built.
- Civilian units do not eat food; they do not consume workers when built (unlike military/naval).

---

## Implementation

Unit model in colonizethis_models; movement and work orders in colonizethis_logic. See [world-model.md](world-model.md) for Unit entity. Which unit types are in current implementation scope: [unit-types.md](unit-types.md).
