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

Each tech has: **id** (slug), **display name**, **era**, **category**, **prerequisite ids**, **effects**. The **name** column in each category table is the user-facing display name for UI and tools. Full tables per category:

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

The global tech catalog must contain exactly **113** technologies, matching the Imperialism II 08-technology Technology Chart (all categories). Every tech in the catalog must be **reachable** from the set of techs with no prerequisites (the "starting" techs): there must exist a path in the prerequisite DAG from some root to every node.

### Discovery prerequisites

Techs whose prerequisite is "(Explorer finds X)" (see [tech-tree-new-world.md](tech-tree-new-world.md)) are available for research only when the player has revealed at least one tile containing the corresponding resource(s). "Revealed" means the tile is visible to that player (visibility fully visible or fogged); for prospect-required resources (gold, silver, gems, diamonds), that tile must also have been prospected by the player. See [fog-and-exploration.md](fog-and-exploration.md).

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

**Research point costs (per tier):** Each tech's RP `cost` is derived from its cost tier (the existing era bucket `1..4`) via `cost(tier) = 1800 + (tier - 1) * 600`. The four tiers are therefore:

| Cost tier | RP cost | Turns at Medium (300 RP/turn) |
|-----------|---------|-------------------------------|
| 1 (lowest)  | 1800 | 6  |
| 2           | 2400 | 8  |
| 3           | 3000 | 10 |
| 4 (highest) | 3600 | 12 |

These costs target one completed tech per active slot roughly every 6–12 turns at the **Medium** funding preset, rather than instant completion. Funding presets (gold/RP rates below) are unchanged; only the catalog `cost` values follow this formula. The **Industrial Funding of Research** bonus (+20% RP, floored, for military/naval techs) is applied on top of the funding RP per allocation and is unchanged. In-progress research saved under older cost values is **not** migrated.

**Funding presets:**

| Preset  | Gold/Turn | RP/Turn | Efficiency                     |
| ------- | --------- | ------- | ------------------------------ |
| None    | 0         | 0       | —                              |
| Low     | 50        | 100     | 2.0 RP/gold                    |
| Medium  | 150       | 300     | 2.0 RP/gold                    |
| High    | 400       | 800     | 2.0 RP/gold                    |
| Maximum | 1000      | 2500    | 2.5 RP/gold (efficiency bonus) |

**Goal slot:** Optional goal tech for UI sorting only; no spending. **The goal slot is UI-only and is NOT part of the research order payload**; it is purely client/UI state for sorting the research queue display. **Cancel:** Clearing a slot **loses all progress** (per Imp2). Research phase runs after Production and Consumption; see [research-resolution.md](../program/research-resolution.md).

---

## Acceptance Criteria

- Given a global tech catalog constructed from this doc and its category sub-docs, where each tech has an id, category, era, prerequisites list, and effect set  
  When the System validates the catalog at startup  
  Then the System ensures that the catalog contains exactly 113 technologies (matching the Imperialism II 08-technology Technology Chart), that every tech id is unique, that every prerequisite id refers to a tech present in the catalog, that the directed graph formed by prerequisite edges is acyclic (a DAG), and that every tech is reachable from the set of techs with no prerequisites; the System rejects the catalog if any of these conditions fail.

- Given the global tech catalog constructed from this doc and its category sub-docs, where each tech is classified by its **effect-or-prerequisite role** as having at least one of: a non-empty regiment unlock set, a non-empty ship unlock set, an entry in the resource extraction-cap map (per [tech-and-extraction-cap.md](tech-and-extraction-cap.md)), a non-empty discovery-resource gate, a documented runtime effect hook recorded in the audit's documented-runtime-effect set, or at least one dependent tech (it appears as a prerequisite of another catalog tech)  
  When the System audits the catalog  
  Then the System ensures that **every** catalog tech satisfies at least one of those criteria, and the System rejects the catalog (the audit fails) if any tech has no structural effect, no documented runtime effect, and no dependent — this guards against silently adding a tech with no gameplay effect and no prerequisite role.

- Given a discovery tech with prerequisite "(Explorer finds X)" per [tech-tree-new-world.md](tech-tree-new-world.md)  
  When the System computes researchable techs for a player  
  Then the System includes that tech only if the player has at least one tile that (a) has visibility fully visible or fogged for that player, (b) contains a resource that satisfies X (per the discovery-resource mapping in that doc), and (c) if that resource is prospect-required, the tile has been prospected by that player.

- Given a player has a `techUnlocked` set on the Player object as described in [research-state.md](research-state.md) and a current research slot assigned to a tech id whose prerequisites are all present in `techUnlocked`  
  When the System completes research on that tech in the Research phase  
  Then the System adds that tech id to `techUnlocked`, clears the research slot (losing any remaining progress if the slot is cancelled), and updates `researchableTechIds` to include any tech whose prerequisites are now all in `techUnlocked`.

- Given a research slot is configured with one of the funding presets defined in the table above and a tech that has not yet been unlocked  
  When the System advances the game by one turn and executes the Research phase  
  Then the System deducts the configured gold-per-turn from the player treasury for that slot unless the preset is `None`, adds the configured RP-per-turn to that tech’s research progress, and, when the accumulated RP reaches or exceeds that tech’s cost, marks the tech as completed and unlocked at the end of that phase.

- Given the global tech catalog after the cost rebalance, where each tech has a cost tier (era) in `1..4`  
  When the System evaluates a tech's `cost`  
  Then the cost equals `1800 + (tier - 1) * 600`, so tier-1 techs cost `1800` RP, tier-2 cost `2400` RP, tier-3 cost `3000` RP, and tier-4 cost `3600` RP, and the set of distinct catalog costs is exactly `{1800, 2400, 3000, 3600}`.

- Given a tier-1 tech (cost `1800` RP) assigned to one slot at **Medium** funding (300 RP/turn) with all prerequisites unlocked and treasury sufficient to fund every turn  
  When exactly 5 Research phases resolve  
  Then the tech is not yet in `techUnlocked` (progress `1500` RP `< 1800`); and when the 6th Research phase resolves, the tech is in `techUnlocked`.

- Given a tier-4 tech (cost `3600` RP) assigned to one slot at **Medium** funding (300 RP/turn) with all prerequisites unlocked and treasury sufficient to fund every turn  
  When exactly 11 Research phases resolve  
  Then the tech is not yet in `techUnlocked` (progress `3300` RP `< 3600`); and when the 12th Research phase resolves, the tech is in `techUnlocked`.

- Given a tier-2 tech (cost `2400` RP) assigned at **Low** funding (100 RP/turn) with prerequisites unlocked  
  When one Research phase resolves  
  Then the tech's research progress increases by exactly `100` RP and the tech remains not unlocked (`100 < 2400`).

- Given **Industrial Funding of Research** is unlocked and a tier-2 **military** tech (cost `2400` RP) is assigned at **Medium** funding (300 RP/turn) with prerequisites unlocked  
  When one Research phase resolves  
  Then the tech's research progress increases by exactly `floor(300 × 1.2) = 360` RP.
