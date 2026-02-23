# Tech Tree

**SPEC/game** — Technology structure, eras, categories, effects, catalog, and research model. Extraction: [tech-and-extraction-cap.md](tech-and-extraction-cap.md). Units: [military-units.md](military-units.md), [civilian-units.md](civilian-units.md). Diplomacy: [diplomacy.md](diplomacy.md). Transport: [extraction-and-improvements.md](extraction-and-improvements.md).

---

## Eras

Each tech has an **era** (1-4). Eras are descriptive only; they do not block research or building.

| Era | Name | Character |
|-----|------|-----------|
| 1 | Renaissance | Exploration, basic tech |
| 2 | Enlightenment | Scientific revolution |
| 3 | Revolution | Political upheaval |
| 4 | Industrial | Steam power, final push |

---

## Categories

Techs are grouped by **category**: gathering, transport, labour, diplomatic, naval, military, new-world. Categories drive UI filters; they do not gate prerequisites (prereqs are explicit per tech).

---

## Prerequisites

The tree is a **DAG**. Each tech lists zero or more **prerequisite tech ids**. Prerequisites may be techs from **any category** (defined in this doc’s category sub-docs). A tech is available for research only when all prerequisites are in the player's `techUnlocked` set. A tech cannot start in the same turn its prerequisite completes.

---

## Catalog (Category Sub-Docs)

Each tech has: **id** (slug), **display name**, **era**, **category**, **prerequisite ids**, **effects**. Full tables per category:

| Category | Doc |
|----------|-----|
| Gathering and Production | [tech-tree-gathering.md](tech-tree-gathering.md) |
| Transport and Infrastructure | [tech-tree-transport.md](tech-tree-transport.md) |
| Labour and Economy | [tech-tree-labour-economy.md](tech-tree-labour-economy.md) |
| Diplomacy and Civilian | [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md) |
| Naval (Merchant and Warships) | [tech-tree-naval.md](tech-tree-naval.md) |
| Military (Infantry, Cavalry, Artillery) | [tech-tree-military.md](tech-tree-military.md) |
| New World Resources | [tech-tree-new-world.md](tech-tree-new-world.md) |

**Regiment buildability:** A regiment is buildable iff the unlocking tech is in `techUnlocked`. **Ship buildability:** A ship type is buildable iff it has no unlocking tech or that tech is in `techUnlocked`. See [tech-tree-naval.md](tech-tree-naval.md), [ships-and-naval.md](ships-and-naval.md). **Extraction cap** per resource = max level from any researched tech (see [tech-and-extraction-cap.md](tech-and-extraction-cap.md)).

---

## Effect Types

Techs grant **effects** when researched (no separate "apply" step):

- **Extraction cap:** Max improvement level (1-4) per resource. Effective yield = min(improvement, tech cap). See [tech-and-extraction-cap.md](tech-and-extraction-cap.md).
- **Transport:** Allows building higher transport levels. See [extraction-and-improvements.md](extraction-and-improvements.md).
- **Regiment unlocks:** Tech id -> regiment id(s). No era gate. See [military-units.md](military-units.md).
- **Ship unlocks:** Tech id -> ship type id(s). Starting ships (e.g. Carrack) have no prerequisite. See [tech-tree-naval.md](tech-tree-naval.md), [ships-and-naval.md](ships-and-naval.md).
- **Civilian unit unlocks:** e.g. Merchant, Rail Builder. See [civilian-units.md](civilian-units.md).
- **Diplomatic options:** e.g. embassies, Join Empire. See [diplomacy.md](diplomacy.md).
- **Labour / economy:** Worker tiers, trade slots, fourth research slot (University).

---

## Research Model

**Slots:** 3 by default; 4 with University tech. Each slot holds at most one active tech (or is empty).

**Funding presets:**

| Preset  | Gold/Turn | RP/Turn | Efficiency                     |
| ------- | --------- | ------- | ------------------------------ |
| None    | 0         | 0       | —                              |
| Low     | 50        | 100     | 2.0 RP/gold                    |
| Medium  | 150       | 300     | 2.0 RP/gold                    |
| High    | 400       | 800     | 2.0 RP/gold                    |
| Maximum | 1000      | 2500    | 2.5 RP/gold (efficiency bonus) |

**Goal slot:** Optional goal tech for UI sorting only; no spending. **Cancel:** Clearing a slot **loses all progress** (per Imp2). Research phase runs after Production and Consumption; see [research-resolution.md](../program/research-resolution.md).
