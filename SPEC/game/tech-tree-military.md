# Tech Tree — Military (Infantry, Cavalry, Artillery)

**SPEC/game** — Regiment and fort unlocks. Reference: Imperialism II 08-technology (Military), [military-units.md](military-units.md). Overview: [tech-tree.md](tech-tree.md). Regiment **buildability** is gated only by the tech that unlocks it; no era gate.

---

## Catalog and implementation

The **military tech table in this doc is the GDD source of truth** for tech id, name, era, prerequisites, and regiment/effect mapping. **Implementation:** The program-level tech catalog lives in code (e.g. `colonizethis_data`); build and research order validation use the catalog per [orders.md](../program/orders.md) and the order engine. The program-level catalog may be an **MVP subset** of the full GDD table; migration to a full catalog is a design target. Future ruleset-driven catalog per [ruleset-config.md](../program/ruleset-config.md).

---

## Infantry

| id | name | era | prerequisites | regiment / effect |
|----|------|-----|---------------|-------------------|
| organised_regiments | Organised Regiments | 1 | land_enclosure | Lancers; Knights upgrade path |
| improved_iron_weapons | Improved Iron Weapons | 1 | organised_regiments, iron_mining | Halberdiers; Pikemen upgrade |
| improved_infantry_tactics | Improved Infantry Tactics | 2 | organised_regiments, printing_press | Calivermen; Peasant Levies upgrade |
| crucible_process | Crucible Process | 2 | square_set_timbering, steam_in_mining | Steel; leads to Bayonet and more |
| bayonet | Bayonet | 2 | improved_iron_weapons, crucible_process | Regulars; Halberdiers upgrade |
| weapon_craftsmanship | Weapon Craftsmanship | 2 | organised_regiments, copper_and_tin_mining | Musketeers; Arquebusiers upgrade |
| industrial_machinery | Industrial Machinery | 3 | trained_journeymen, steam_in_mining, university | 25% cheaper military attack; leads to Explosives |
| explosives | Explosives | 3 | weapon_craftsmanship, industrial_machinery | Grenadiers; Musketeers upgrade |
| early_rifles | Early Rifles | 3 | improved_infantry_tactics, crucible_process | Skirmishers; Calivermen upgrade |
| long_range_rifles | Long Range Rifles | 3 | early_rifles, crucible_process | Sharpshooters; Skirmishers upgrade |
| needle_guns | Needle Guns | 4 | industrial_funding_of_research, bayonet, early_rifles | Rifle Infantry; Regulars upgrade |
| elite_military_training | Elite Military Training | 4 | modern_military_funding, needle_guns, explosives | Guards; Grenadiers upgrade |

---

## Cavalry

| id | name | era | prerequisites | regiment / effect |
|----|------|-----|---------------|-------------------|
| recruit_steppe_horsemen | Recruit Steppe Horsemen | 1 | crop_rotation | Cossacks; Squires upgrade |
| improved_cavalry_tactics | Improved Cavalry Tactics | 2 | printing_press, animal_husbandry | Harquebusiers |
| hussars | Hussars | 2 | improved_cavalry_tactics, recruit_steppe_horsemen | Hussars; Cossacks upgrade |
| improved_cavalry_weapons | Improved Cavalry Weapons | 3 | industrial_machinery, crucible_process, improved_cavalry_tactics | Cuirassiers; Harquebusiers upgrade |
| scouting | Scouting | 3 | hussars, early_rifles | Scouts; Hussars upgrade |
| repeating_cavalry_carbine | Repeating Cavalry Carbine | 4 | industrial_funding_of_research, improved_cavalry_weapons | Carbine Cavalry; Cuirassiers upgrade |

---

## Artillery and Forts

| id | name | era | prerequisites | regiment / effect |
|----|------|-----|---------------|-------------------|
| horse_artillery | Horse Artillery | 1 | animal_husbandry, copper_and_tin_mining | Horse Artillery |
| siege_engineering | Siege Engineering | 2 | printing_press, copper_and_tin_mining | Royal Artillery; Culverin upgrade |
| light_artillery_tactics | Light Artillery Tactics | 3 | crucible_process, university | Light Artillery; Horse Artillery upgrade |
| modern_forts | Modern Forts | 3 | siege_engineering, university | Fort level 3; leads to Modern Military Funding |
| heavy_artillery | Heavy Artillery | 3 | modern_forts, crucible_process | Heavy Artillery; Royal Artillery upgrade |
| heavy_emplaced_artillery | Heavy Emplaced Artillery | 3 | road_construction, national_bureaucracy, siege_engineering | All emplaced artillery → Heavy |
| field_artillery_tactics | Field Artillery Tactics | 4 | light_artillery_tactics, modern_military_funding | Field Artillery; Light Artillery upgrade |
| high_grade_steel | High Grade Steel | 4 | heavy_artillery, industrial_funding_of_research, modern_military_funding | Siege Guns; Heavy Artillery upgrade |
| emplaced_siege_guns | Emplaced Siege Guns | 4 | heavy_artillery, heavy_emplaced_artillery | All emplaced → Siege Guns |
| modern_military_funding | Modern Military Funding | 3 | banking, large_precious_stone_mines, modern_forts | Cheaper attack; leads to elite units |
| industrial_funding_of_research | Industrial Funding of Research | 3 | industrial_machinery, crucible_process | Research efficiency; military/naval tech |

---

## Notes

- Bowmen, Knights, Lancers have no upgrade path (obsolete in later eras). Starting regiments (e.g. Peasant Levies, Pikemen, Arquebusiers, Culverin, Squires) are buildable from game start or earliest techs.
- Military level for minor parity = highest era among regiment types any GP can build (per [factions.md](factions.md)).

---

## Acceptance criteria

- **Regiment buildability:** A regiment type is buildable iff its unlocking tech (per this doc) is in the player's `techUnlocked` set.
- **Military level:** Military level (1–4) = highest era among regiment types any Great Power can build; minors and tribes receive this as `effectiveMilitaryLevel` per [factions.md](factions.md).
- **Table as source of truth:** The tech table in this doc is the source of truth for tech id, name, era, prerequisites, and regiment/effect mapping.
- **Fort prerequisites:** Fort level 2 requires Mine Engineering (see [tech-tree-gathering.md](tech-tree-gathering.md)); fort level 3 requires Modern Forts (this doc). Build validation and resolution: [siege-mechanics.md](siege-mechanics.md), [development-resolution.md](../program/development-resolution.md).
