# Tech Tree — Gathering and Production

**SPEC/game** — Old World extraction and improvement techs. Reference: Imperialism II 08-technology (Gathering and Production). Overview: [tech-tree.md](tech-tree.md).

---

## Tech Table

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| crop_rotation | Crop Rotation | 1 | — | Cattle herds; leads to sheep, cattle, horse |
| saw_mill | Saw Mill | 1 | — | Timber 2 (forested land) |
| land_enclosure | Land Enclosure | 1 | — | Grain 2 |
| mine_engineering | Mine Engineering | 1 | — | Fort level 2; leads to mining |
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

- Numeric effects (e.g. Timber 2) denote max improvement level for that resource; builders apply improvements; effective extraction = min(improvement, tech cap, transport level).
- Copper and Tin Mining appears in both gathering and military (artillery); same tech id.
