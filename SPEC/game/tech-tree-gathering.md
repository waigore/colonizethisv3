# Tech Tree — Gathering and Production

**SPEC/game** — Old World extraction and improvement techs. Reference: Imperialism II 08-technology (Gathering and Production). Overview: [tech-tree.md](tech-tree.md).

---

## Catalog and implementation

The **gathering table below is the GDD source of truth** for ids, effects, and prerequisites. Prerequisites may reference techs defined in **other category docs** (e.g. [tech-tree-labour-economy.md](tech-tree-labour-economy.md) for `university`, [tech-tree-transport.md](tech-tree-transport.md) for `dynamite`, [tech-tree-new-world.md](tech-tree-new-world.md) for `precious_stone_mining` / `precious_metals_mining`, [tech-tree-military.md](tech-tree-military.md) for artillery-related techs). **MVP:** The program-level catalog lives in code (e.g. `colonizethis_data` tech extraction module); it uses **simplified ids** (`gathering_1`, `gathering_2`, `gathering_3`) and a **single scalar** extraction cap. The full per-resource cap model and GDD table ids (e.g. `crop_rotation`, `saw_mill`) are the design target; migration to a full catalog is documented in [tech-and-extraction-cap.md](tech-and-extraction-cap.md). Tech table source is **MVP program-level** (constants); future ruleset-driven catalog per [ruleset-config.md](../program/ruleset-config.md).

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
| animal_husbandry | Animal Husbandry | 2 | crop_rotation | Meat 3 |
| square_set_timbering | Square-set Timbering | 2 | coal_mining | Coal 2 |
| steam_in_mining | Steam in Mining | 2 | iron_mining | Iron 3 |
| large_coal_mines | Large Coal Mines | 2 | square_set_timbering, steam_in_mining | Coal 3 |
| large_copper_and_tin_mines | Large Copper and Tin Mines | 2 | copper_and_tin_mining | Copper/tin 3 |
| circular_saw | Circular Saw | 3 | wind_saw_mill, university | Timber 4 |
| scientific_sheep_breeding | Scientific Sheep Breeding | 3 | sheep_ranching, university | Wool 3 |
| scientific_cattle_breeding | Scientific Cattle Breeding | 3 | animal_husbandry, university | Meat 4 |
| moldboard_plow | Moldboard Plow | 3 | seed_drill | Grain 4 |
| safety_lamp | Safety Lamp | 4 | large_coal_mines, dynamite | Coal 4 |
| large_precious_stone_mines | Large Precious Stone Mines | 3 | precious_stone_mining, university | Gems/diamonds 3 |
| extraction_of_precious_metals | Extraction of Precious Metals | 3 | precious_metals_mining, university | Gold/silver 3 |
| geological_prospecting | Geological Prospecting | 4 | large_precious_stone_mines, dynamite | Gems/diamonds 4 |
| amalgamation_process | Amalgamation Process | 4 | dynamite, extraction_of_precious_metals | Gold/silver 4 |
| industrial_iron_mining | Industrial Iron Mining | 4 | industrial_funding_of_research, steam_in_mining | Iron 4 |
| efficient_extraction_of_copper_and_tin | Efficient Extraction of Copper & Tin | 4 | large_coal_mines, large_copper_and_tin_mines | Copper/tin 4 |

---

## Notes

- Numeric effects (e.g. Timber 2) denote max improvement level for that resource; builders apply improvements; effective extraction = min(improvement, tech cap, transport level) per [extraction-and-improvements.md](extraction-and-improvements.md).
- Copper and Tin Mining appears in both gathering and military (artillery); same tech id.

---

## Acceptance criteria

- Given the `crop_rotation`, `saw_mill`, `land_enclosure`, `mine_engineering`, `iron_mining`, `copper_and_tin_mining`, `coal_mining`, `wind_saw_mill`, `seed_drill`, and `sheep_ranching` rows in this tech table  
  When the System or UI layer renders their design descriptions from SPEC-authorized wording  
  Then each row includes at least one fixed-field phrase (`Unlocks:`, `Improves:`, `Enables:`, or `Prerequisite-only:`), names concrete mechanics or explicit unlock targets, and does not use generic fallback wording.

- **Table:** Each row has a unique id; prerequisite ids reference techs defined in this doc or other category docs.
- **Extraction cap:** In the full model, per-resource cap is derived from unlocked gathering techs (max level per resource from the table). MVP uses a single scalar cap; see [tech-and-extraction-cap.md](tech-and-extraction-cap.md).
- **Tests:** Unit tests for cap resolution (scalar MVP; future per-resource); extraction pipeline respects player cap; research unlocking gathering tech increases cap.
- **Integration invariant (generic):** Given a controlled tile where effective extraction is bound by the player's tech cap (improvement, transport, and town-development are all >= 4), when the player completes any research unlock that increases `extractionCapForUnlocked` during turn `T`, then extraction on turn `T+1` (the immediately following resolved turn) increases to the new cap for the same tile with infrastructure unchanged.
