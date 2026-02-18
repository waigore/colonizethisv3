# Tech Tree

**SPEC/game** — Technology structure, eras, categories, effects, and research model. Full catalog: [tech-tree-catalog.md](tech-tree-catalog.md) and category sub-docs. Extraction: [tech-and-extraction-cap.md](tech-and-extraction-cap.md). Units: [military-units.md](military-units.md), [civilian-units.md](civilian-units.md). Diplomacy: [diplomacy.md](diplomacy.md). Transport: [extraction-and-improvements.md](extraction-and-improvements.md).

---

## Eras

Each tech has an **era** (1–4). Eras are descriptive only; they do not block research or building. Reference: GDD 08, Imperialism II.

| Era | Name | Character |
|-----|------|-----------|
| 1 | Renaissance | Exploration, basic tech |
| 2 | Enlightenment | Scientific revolution |
| 3 | Revolution | Political upheaval |
| 4 | Industrial | Steam power, final push |

---

## Categories

Techs are grouped by **category**: gathering, transport, labour, diplomatic, naval (merchant / warship), military (infantry, cavalry, artillery), new-world. Categories drive UI filters and the show_tech diagram; they do not gate prerequisites (prereqs are explicit per tech).

---

## Prerequisites

The tree is a **DAG**. Each tech lists zero or more **prerequisite tech ids**. A tech **B** is **available for research** only when every prerequisite **A** is in the player’s `techUnlocked` set. A tech cannot be started in the same turn its prerequisite completes; the prerequisite must be fully researched first. Implementation: colonizethis_data holds the catalog; colonizethis_logic and order engine enforce “all prereqs unlocked” before a tech can be assigned to a slot.

---

## Effect Types

Techs grant **effects** when researched (no separate “apply” step; effects are read from catalog when needed):

- **Extraction cap:** Max effective improvement level (1–4) per resource or improvement type. Effective yield = min(improvement level, owner’s tech cap). See [tech-and-extraction-cap.md](tech-and-extraction-cap.md).
- **Transport:** Tech **allows** the player to build higher road levels via **explicit action** (Engineer: road level 2 with Road Construction; Rail Builder: railroad with Early Steam Engine). Roads/railroads/ports are built by work orders; ports and railroads both give transport level 4. See [extraction-and-improvements.md](extraction-and-improvements.md).
- **Regiment unlocks:** Tech id → regiment id(s). A regiment is **buildable** iff the player has researched the tech that unlocks it. No era gate. See [military-units.md](military-units.md).
- **Civilian unit unlocks:** e.g. Merchant (Merchant Companies), Rail Builder (Early Steam Engine). See [civilian-units.md](civilian-units.md).
- **Diplomatic options:** e.g. embassies (Diplomatic Expertise), Join Empire (Empire Building). See [diplomacy.md](diplomacy.md).
- **Labour / economy:** Worker tiers, trade slots, fourth research slot (University), etc. Defined in catalog and used by production/consumption and UI.

---

## Research Model

**Slots:** 3 by default; 4 with University tech. Each slot holds at most one active tech (or is empty). **Funding:** Presets (None / Low / Medium / High / Maximum) map to gold per turn; cost is **committed from treasury** for that turn and validated before/during turn resolution. **Goal slot:** One optional goal tech for UI sorting only; no spending on goal. **Cancel:** Clearing a slot **loses all progress** for that tech (GDD / Imperialism II). Research phase runs **after** Production and Consumption; see [turn-resolution-phases.md](../program/turn-resolution-phases.md) and [research-resolution.md](../program/research-resolution.md).
