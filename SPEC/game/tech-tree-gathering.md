# Tech Tree — Gathering and Production

**SPEC/game** — Old World extraction and improvement techs. Reference: Imperialism II 08-technology (Gathering and Production). Overview: [tech-tree.md](tech-tree.md).

---

## Catalog and implementation

The **gathering table below is the GDD source of truth** for ids, effects, and prerequisites. Prerequisites may reference techs defined in **other category docs** (e.g. [tech-tree-labour-economy.md](tech-tree-labour-economy.md) for `university`, [tech-tree-transport.md](tech-tree-transport.md) for `dynamite`, [tech-tree-new-world.md](tech-tree-new-world.md) for `precious_stone_mining` / `precious_metals_mining`, [tech-tree-military.md](tech-tree-military.md) for artillery-related techs). The program-level catalog lives in code (`colonizethis_data` tech modules) and uses these same ids. **Unlock and prerequisite validation** use the shared tech catalog. **Extraction caps** are resolved per resource per [tech-and-extraction-cap.md](tech-and-extraction-cap.md) (`tech_extraction_caps.dart`). Tech table source is program-level constants; future ruleset-driven catalog per [ruleset-config.md](../program/ruleset-config.md).

---

## Tech Table

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| crop_rotation | Crop Rotation | 1 | — | Unlocks: `sheep_ranching`, `animal_husbandry`, and `recruit_steppe_horsemen` research paths. Improves: establishes the first agriculture baseline required before wool/meat specialization techs can grant higher extraction caps. |
| saw_mill | Saw Mill | 1 | — | Improves: timber extraction cap to **2** on forested provinces (effective output still bounded by transport and improvement level). Unlocks: prerequisite for `wind_saw_mill`. |
| land_enclosure | Land Enclosure | 1 | — | Improves: grain extraction cap to **2**. Unlocks: prerequisite for `seed_drill`, `money_lending`, and `organised_regiments`. |
| mine_engineering | Mine Engineering | 1 | — | Enables: builder fort upgrades to **Fort Level 2** (see [siege-mechanics.md](siege-mechanics.md)). Unlocks: prerequisite for `iron_mining`, `copper_and_tin_mining`, and `coal_mining`. |
| iron_mining | Iron Mining | 1 | mine_engineering | Improves: iron extraction cap to **2**. Unlocks: prerequisite for `steam_in_mining`. |
| copper_and_tin_mining | Copper and Tin Mining | 1 | mine_engineering | Improves: copper/tin extraction cap to **2**. Unlocks: prerequisite for `large_copper_and_tin_mines`. Enables: satisfies part of military prerequisites that reference this tech (for example Horse Artillery and Weapon Craftsmanship branches). |
| coal_mining | Coal Mining | 1 | mine_engineering | Enables: coal extraction at cap **1** (first coal production permission). Unlocks: prerequisite for `square_set_timbering`. |
| wind_saw_mill | Wind Saw Mill | 2 | saw_mill | Improves: timber extraction cap to **3**. Unlocks: prerequisite for `circular_saw`. |
| seed_drill | Seed Drill | 2 | land_enclosure | Improves: grain extraction cap to **3**. Unlocks: prerequisite for `moldboard_plow`. |
| sheep_ranching | Sheep Ranching | 2 | crop_rotation | Improves: wool extraction cap to **2**. Unlocks: prerequisite for `scientific_sheep_breeding`. |
| animal_husbandry | Animal Husbandry | 2 | crop_rotation | Improves: meat extraction cap to **3**. Unlocks: prerequisite for `scientific_cattle_breeding` (with University). Enables: satisfies military prerequisites that reference this tech (for example Improved Cavalry Tactics and Horse Artillery). |
| square_set_timbering | Square-set Timbering | 2 | coal_mining | Improves: coal extraction cap to **2**. Unlocks: prerequisite for `large_coal_mines` together with `steam_in_mining`. Enables: satisfies transport and military prerequisites (for example Early Steam Engine and Crucible Process). |
| steam_in_mining | Steam in Mining | 2 | iron_mining | Improves: iron extraction cap to **3**. Unlocks: prerequisite for `large_coal_mines` together with `square_set_timbering`; prerequisite for `industrial_iron_mining`, `early_steam_engine`, `crucible_process`, and `industrial_machinery`. |
| large_coal_mines | Large Coal Mines | 2 | square_set_timbering, steam_in_mining | Improves: coal extraction cap to **3**. Unlocks: prerequisite for `safety_lamp` (with Dynamite) and `efficient_extraction_of_copper_and_tin`. |
| large_copper_and_tin_mines | Large Copper and Tin Mines | 2 | copper_and_tin_mining | Improves: copper/tin extraction cap to **3**. Unlocks: prerequisite for `efficient_extraction_of_copper_and_tin` (with Large Coal Mines) and `ship_of_the_line` (with Large Hulls). |
| circular_saw | Circular Saw | 3 | wind_saw_mill, university | Improves: timber extraction cap to **4**. Unlocks: prerequisite for `clipper_ships` (with Advanced Hull Design). |
| scientific_sheep_breeding | Scientific Sheep Breeding | 3 | sheep_ranching, university | Improves: wool extraction cap to **3** (raises cap from Sheep Ranching **2**). No other tech in the current product catalog lists this id as a prerequisite. |
| scientific_cattle_breeding | Scientific Cattle Breeding | 3 | animal_husbandry, university | Improves: meat extraction cap to **4** (raises cap from Animal Husbandry **3**). No other tech in the current product catalog lists this id as a prerequisite. |
| moldboard_plow | Moldboard Plow | 3 | seed_drill | Improves: grain extraction cap to **4** (raises cap from Seed Drill **3**). No other tech in the current product catalog lists this id as a prerequisite. |
| safety_lamp | Safety Lamp | 4 | large_coal_mines, dynamite | Improves: coal extraction cap to **4** (raises cap from Large Coal Mines **3**). No other tech in the current product catalog lists this id as a prerequisite. |
| large_precious_stone_mines | Large Precious Stone Mines | 3 | precious_stone_mining, university | Improves: gems/diamonds extraction cap to **3**. Unlocks: prerequisite for `geological_prospecting` (with Dynamite) and `modern_military_funding` (with Banking and Modern Forts). |
| extraction_of_precious_metals | Extraction of Precious Metals | 3 | precious_metals_mining, university | Improves: gold/silver extraction cap to **3**. Unlocks: prerequisite for `amalgamation_process` (with Dynamite). |
| geological_prospecting | Geological Prospecting | 4 | large_precious_stone_mines, dynamite | Improves: gems/diamonds extraction cap to **4**. Prerequisite-only in current product catalog: no other tech lists this id as a prerequisite; cap increase is the active benefit. |
| amalgamation_process | Amalgamation Process | 4 | dynamite, extraction_of_precious_metals | Improves: gold/silver extraction cap to **4**. Prerequisite-only in current product catalog: no other tech lists this id as a prerequisite; cap increase is the active benefit. |
| industrial_iron_mining | Industrial Iron Mining | 4 | industrial_funding_of_research, steam_in_mining | Improves: iron extraction cap to **4**. Prerequisite-only in current product catalog: no other tech lists this id as a prerequisite; cap increase is the active benefit. |
| efficient_extraction_of_copper_and_tin | Efficient Extraction of Copper & Tin | 4 | large_coal_mines, large_copper_and_tin_mines | Improves: copper/tin extraction cap to **4**. Prerequisite-only in current product catalog: no other tech lists this id as a prerequisite; cap increase is the active benefit. |

---

## Notes

- Numeric effects (e.g. Timber 2) denote max improvement level for that resource; builders apply improvements; effective extraction = min(improvement, tech cap, transport level) per [extraction-and-improvements.md](extraction-and-improvements.md).
- Copper and Tin Mining appears in both gathering and military (artillery); same tech id.

---

## Acceptance criteria

- Given the `crop_rotation`, `saw_mill`, `land_enclosure`, `mine_engineering`, `iron_mining`, `copper_and_tin_mining`, `coal_mining`, `wind_saw_mill`, `seed_drill`, and `sheep_ranching` rows in this tech table  
  When the System or UI layer renders their design descriptions from SPEC-authorized wording  
  Then each row includes at least one fixed-field phrase (`Unlocks:`, `Improves:`, `Enables:`, or `Prerequisite-only:`), names concrete mechanics or explicit unlock targets, and does not use generic fallback wording.

- Given the `animal_husbandry`, `square_set_timbering`, `steam_in_mining`, `large_coal_mines`, `large_copper_and_tin_mines`, `circular_saw`, `scientific_sheep_breeding`, `scientific_cattle_breeding`, `moldboard_plow`, and `safety_lamp` rows in this tech table  
  When the System or UI layer renders their design descriptions from SPEC-authorized wording  
  Then each row includes at least one fixed-field phrase (`Unlocks:`, `Improves:`, `Enables:`, or `Prerequisite-only:`), states extraction caps with explicit numeric levels where applicable, names concrete unlock targets or explicitly states that the current product catalog has no dependent techs, and does not use generic fallback wording.

- Given the `large_precious_stone_mines`, `extraction_of_precious_metals`, `geological_prospecting`, `amalgamation_process`, `industrial_iron_mining`, and `efficient_extraction_of_copper_and_tin` rows in this tech table  
  When the System or UI layer renders their design descriptions from SPEC-authorized wording  
  Then each row includes at least one fixed-field phrase (`Unlocks:`, `Improves:`, `Enables:`, or `Prerequisite-only:`), states extraction caps with explicit numeric levels where applicable, names concrete unlock targets or explicitly states that the current product catalog has no dependent techs, and does not use generic fallback wording.

- **Table:** Each row has a unique id; prerequisite ids reference techs defined in this doc or other category docs.
- **Extraction cap:** Per-resource cap is derived from unlocked gathering techs (max level per resource from the table), with explicit design-capped exceptions declared in [tech-and-extraction-cap.md](tech-and-extraction-cap.md).
- **Tests:** Unit tests for per-resource cap resolution and exception validation; extraction pipeline respects per-resource caps; research unlocking gathering tech increases cap for the affected resource.
- **Integration invariant (per resource):** Given a controlled tile for resource **R** where effective extraction is bound by the per-resource tech cap (improvement, transport, and town-development are all high enough not to bind), when the player completes any research unlock that increases `extractionCapForResourceForUnlocked` for **R** during turn `T`, then extraction on turn `T+1` (the immediately following resolved turn) increases to the new cap for that resource on the same tile with infrastructure unchanged.
