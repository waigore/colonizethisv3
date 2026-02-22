# Tech Tree — Gathering and Production

**SPEC/game** — Old World extraction and improvement techs. Reference: Imperialism II 08-technology (Gathering and Production). Overview: [tech-tree.md](tech-tree.md).

---

## Catalog and implementation

The **gathering table below is the GDD source of truth** for ids, effects, and prerequisites. Prerequisites may reference techs defined in **other category docs** (e.g. [tech-tree-labour-economy.md](tech-tree-labour-economy.md) for `university`, [tech-tree-transport.md](tech-tree-transport.md) for `dynamite`, [tech-tree-new-world.md](tech-tree-new-world.md) for `precious_stone_mining` / `precious_metals_mining`, [tech-tree-military.md](tech-tree-military.md) for artillery-related techs). **MVP:** The program-level catalog lives in code (e.g. `colonizethis_data` tech extraction module); it uses **simplified ids** (`gathering_1`, `gathering_2`, `gathering_3`) and a **single scalar** extraction cap. The full per-resource cap model and GDD table ids (e.g. `crop_rotation`, `saw_mill`) are the design target; migration to a full catalog is documented in [tech-and-extraction-cap.md](tech-and-extraction-cap.md). Tech table source is **MVP program-level** (constants); future ruleset-driven catalog per [ruleset-config.md](../program/ruleset-config.md).

---

## Tech Table

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| crop_rotation | Crop Rotation | 1 | — | Cattle herds; leads to sheep, cattle, horse |
| saw_mill | Saw Mill | 1 | — | Timber 2 (forested land) |
| land_enclosure | Land Enclosure | 1 | — | Grain 2 |
| mine_engineering | Mine Engineering | 1 | — | Fort level 2 (see [siege-mechanics.md](siege-mechanics.md)); leads to mining |
| iron_mining | Iron Mining | 1 | mine_engineering | Iron 2 |
| copper_and_tin_mining | Copper and Tin Mining | 1 | mine_engineering | Copper/tin 2; required for Horse Artillery, Weapon Craftsmanship |
| coal_mining | Coal Mining | 1 | mine_engineering | Coal 1 (construct) |
| wind_saw_mill | Wind Saw Mill | 2 | saw_mill | Timber 3 |
| seed_drill | Seed Drill | 2 | land_enclosure | Grain 3 |
| sheep_ranching | Sheep Ranching | 2 | crop_rotation | Wool 2 |
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

- **Table:** Each row has a unique id; prerequisite ids reference techs defined in this doc or other category docs.
- **Extraction cap:** In the full model, per-resource cap is derived from unlocked gathering techs (max level per resource from the table). MVP uses a single scalar cap; see [tech-and-extraction-cap.md](tech-and-extraction-cap.md).
- **Tests:** Unit tests for cap resolution (scalar MVP; future per-resource); extraction pipeline respects player cap; research unlocking gathering tech increases cap.
