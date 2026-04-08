# Tech Tree — Military (Infantry, Cavalry, Artillery)

**SPEC/game** — Regiment and fort unlocks. Reference: Imperialism II 08-technology (Military), [military-units.md](military-units.md). Overview: [tech-tree.md](tech-tree.md). Regiment **buildability** is gated only by the tech that unlocks it; no era gate.

---

## Catalog and implementation

The **military tech table in this doc is the GDD source of truth** for tech id, name, era, prerequisites, and regiment/effect mapping. **Implementation:** The program-level tech catalog lives in code (e.g. `colonizethis_data`); build and research order validation use the catalog per [orders.md](../program/orders.md) and the order engine. The program-level catalog may be an **MVP subset** of the full GDD table; migration to a full catalog is a design target. Future ruleset-driven catalog per [ruleset-config.md](../program/ruleset-config.md).

---

## Infantry

| id | name | era | prerequisites | regiment / effect |
|----|------|-----|---------------|-------------------|
| organised_regiments | Organised Regiments | 1 | land_enclosure | **Unlocks:** **Lancers** regiment; **Knights** upgrade path. **Improves:** general cap floor to at least **2** per [military-generals.md](military-generals.md). **Unlocks:** prerequisite paths for `improved_iron_weapons`, `improved_infantry_tactics`, and `weapon_craftsmanship`. |
| improved_iron_weapons | Improved Iron Weapons | 1 | organised_regiments, iron_mining | **Unlocks:** **Halberdiers** regiment; **Pikemen** upgrade path. **Unlocks:** prerequisite for `bayonet` (with `crucible_process`). |
| improved_infantry_tactics | Improved Infantry Tactics | 2 | organised_regiments, printing_press | **Unlocks:** **Calivermen** regiment; **Peasant Levies** upgrade path. **Improves:** general cap floor to at least **3** (same slot as `national_bureaucracy`; see [military-generals.md](military-generals.md)). **Unlocks:** prerequisite for `early_rifles` (with `crucible_process`). |
| crucible_process | Crucible Process | 2 | square_set_timbering, steam_in_mining | **Prerequisite-only:** gates **steel** chain for `bayonet`, `early_rifles`, `long_range_rifles`, `improved_cavalry_weapons`, `heavy_artillery`, `later_steam_engine`, `industrial_machinery`, and `industrial_funding_of_research`; **no regiment** unlocked by this tech alone. |
| bayonet | Bayonet | 2 | improved_iron_weapons, crucible_process | **Unlocks:** **Regulars** regiment; **Halberdiers** upgrade path. **Unlocks:** prerequisite for `needle_guns` (with `industrial_funding_of_research` and `early_rifles`). |
| weapon_craftsmanship | Weapon Craftsmanship | 2 | organised_regiments, copper_and_tin_mining | **Unlocks:** **Musketeers** regiment; **Arquebusiers** upgrade path. **Unlocks:** prerequisite for `explosives` (with `industrial_machinery`). |
| industrial_machinery | Industrial Machinery | 3 | trained_journeymen, steam_in_mining, university | Improves (deferred in MVP): military attack treasury cost by **25%** once the application point is chosen per **Deferred effect types** below. Unlocks: prerequisite for `explosives`, `improved_cavalry_weapons`, and `industrial_funding_of_research`. |
| explosives | Explosives | 3 | weapon_craftsmanship, industrial_machinery | Unlocks: **Grenadiers** regiment. Improves: **Musketeers** upgrade path. Prerequisite for: `elite_military_training`. |
| early_rifles | Early Rifles | 3 | improved_infantry_tactics, crucible_process | Unlocks: **Skirmishers** regiment. Improves: **Calivermen** upgrade path. Prerequisite for: `long_range_rifles`, `scouting`, `needle_guns`. |
| long_range_rifles | Long Range Rifles | 3 | early_rifles, crucible_process | Unlocks: **Sharpshooters** regiment. Improves: **Skirmishers** upgrade path. |
| needle_guns | Needle Guns | 4 | industrial_funding_of_research, bayonet, early_rifles | Unlocks: **Rifle Infantry** regiment. Improves: **Regulars** upgrade path. Prerequisite for: `elite_military_training`. |
| elite_military_training | Elite Military Training | 4 | modern_military_funding, needle_guns, explosives | Unlocks: **Guards** regiment. Improves: **Grenadiers** upgrade path. |

---

## Cavalry

| id | name | era | prerequisites | regiment / effect |
|----|------|-----|---------------|-------------------|
| recruit_steppe_horsemen | Recruit Steppe Horsemen | 1 | crop_rotation | Unlocks: **Cossacks** regiment. Improves: **Squires** upgrade path. Prerequisite for: `hussars`. |
| improved_cavalry_tactics | Improved Cavalry Tactics | 2 | printing_press, animal_husbandry | Unlocks: **Harquebusiers** regiment. Prerequisite for: `hussars` and `improved_cavalry_weapons`. |
| hussars | Hussars | 2 | improved_cavalry_tactics, recruit_steppe_horsemen | Unlocks: **Hussars** regiment. Improves: **Cossacks** upgrade path. Prerequisite for: `scouting`. |
| improved_cavalry_weapons | Improved Cavalry Weapons | 3 | industrial_machinery, crucible_process, improved_cavalry_tactics | Unlocks: **Cuirassiers** regiment. Improves: **Harquebusiers** upgrade path. Prerequisite for: `repeating_cavalry_carbine`. |
| scouting | Scouting | 3 | hussars, early_rifles | Unlocks: **Scouts** regiment. Improves: **Hussars** upgrade path. |
| repeating_cavalry_carbine | Repeating Cavalry Carbine | 4 | industrial_funding_of_research, improved_cavalry_weapons | Unlocks: **Carbine Cavalry** regiment. Improves: **Cuirassiers** upgrade path. |

---

## Artillery and Forts

| id | name | era | prerequisites | regiment / effect |
|----|------|-----|---------------|-------------------|
| horse_artillery | Horse Artillery | 1 | animal_husbandry, copper_and_tin_mining | Unlocks: **Horse Artillery** regiment (field artillery). Prerequisite for: `light_artillery_tactics`. |
| siege_engineering | Siege Engineering | 2 | printing_press, copper_and_tin_mining | Unlocks: **Royal Artillery** regiment. Improves: **Culverin** upgrade path. Prerequisite for: `modern_forts`, `heavy_emplaced_artillery`. |
| light_artillery_tactics | Light Artillery Tactics | 3 | crucible_process, university | Unlocks: **Light Artillery** regiment. Improves: **Horse Artillery** upgrade path. Prerequisite for: `field_artillery_tactics`. |
| modern_forts | Modern Forts | 3 | siege_engineering, university | Enables: Builder **fort level 3** (Modern fort: 3 emplaced guns and strongest wall profile per [siege-mechanics.md](siege-mechanics.md)). Unlocks: prerequisite for `heavy_artillery` and `modern_military_funding`. |
| heavy_artillery | Heavy Artillery | 3 | modern_forts, crucible_process | Unlocks: **Heavy Artillery** regiment. Improves: **Royal Artillery** upgrade path. Prerequisite for: `high_grade_steel`, `emplaced_siege_guns`. |
| heavy_emplaced_artillery | Heavy Emplaced Artillery | 3 | road_construction, national_bureaucracy, siege_engineering | Improves: defender **emplaced fort batteries** to **Heavy** quality (Royal → Heavy → Siege line per [siege-mechanics.md](siege-mechanics.md)). Prerequisite for: `emplaced_siege_guns`. |
| field_artillery_tactics | Field Artillery Tactics | 4 | light_artillery_tactics, modern_military_funding | Unlocks: **Field Artillery** regiment. Improves: **Light Artillery** upgrade path. |
| high_grade_steel | High Grade Steel | 4 | heavy_artillery, industrial_funding_of_research, modern_military_funding | Unlocks: **Siege Guns** regiment (field). Improves: **Heavy Artillery** upgrade path. |
| emplaced_siege_guns | Emplaced Siege Guns | 4 | heavy_artillery, heavy_emplaced_artillery | Improves: defender **emplaced fort batteries** to **Siege Gun** quality (final emplaced tier per [siege-mechanics.md](siege-mechanics.md)). |
| modern_military_funding | Modern Military Funding | 3 | banking, large_precious_stone_mines, modern_forts | Improves (deferred in MVP): cheaper military attack once the application point is fixed per **Deferred effect types** below. Unlocks: prerequisite for `field_artillery_tactics`, `high_grade_steel`, and `elite_military_training`. |
| industrial_funding_of_research | Industrial Funding of Research | 3 | industrial_machinery, crucible_process | Improves (deferred in MVP): research efficiency for military/naval tech per [research-resolution.md](../program/research-resolution.md) and **Deferred effect types** below. Unlocks: prerequisite for `needle_guns`, `repeating_cavalry_carbine`, `high_grade_steel`, and `advanced_iron_working`. |

---

## Notes

- Bowmen, Knights, Lancers have no upgrade path (obsolete in later eras). Starting regiments (e.g. Peasant Levies, Pikemen, Arquebusiers, Culverin, Squires) are buildable from game start or earliest techs.
- Military level for minor parity = highest era among regiment types any GP can build (per [factions.md](factions.md)).

---

## Deferred effect types (MVP)

The following effect types appear in the tech table above but are **deferred** for MVP: no implementation applies them in the current codebase.

| Tech id | Effect text | Where it would apply when implemented |
|---------|-------------|----------------------------------------|
| industrial_machinery | 25% cheaper military attack | See **Cheaper attack (owner decision)** below. |
| modern_military_funding | Cheaper attack | Same as above. |
| industrial_funding_of_research | Research efficiency; military/naval tech | Research points or cost modifier for military/naval tech per [research-resolution.md](../program/research-resolution.md). |

**Cheaper attack (owner decision):** The exact application point for *industrial_machinery* (25% cheaper military attack) and *modern_military_funding* (Cheaper attack) is **not yet decided**. Candidate application points:

- **Treasury cost** when issuing an attack order (e.g. declaring war, launching attack) — modifier would apply in order validation or cost resolution per [orders.md](../program/orders.md).
- **Combat strength or damage** in auto-resolve / Quick Battle — modifier would apply in [combat-resolution.md](../program/combat-resolution.md) or [quick-battle-resolution.md](../program/quick-battle-resolution.md).

The magnitude (e.g. 25% for industrial_machinery, and the value for modern_military_funding) may be fixed in design or configurable via ruleset per [ruleset-config.md](../program/ruleset-config.md); owner decision required. Once decided, document the chosen application point and configurability here and in the relevant TDD.

**Implementation status:** No TDD or code path currently applies these modifiers. The table in this doc remains the GDD source of truth for tech id, prerequisites, and regiment unlocks; the deferred effects are documented here so contributors can distinguish implemented behaviour (regiment/fort unlocks) from deferred behaviour (cost/efficiency modifiers). See [tech-tree.md](tech-tree.md) § Effect Types for the general effect taxonomy.

---

## Acceptance criteria

- **Regiment buildability:** A regiment type is buildable iff its unlocking tech (per this doc) is in the player's `techUnlocked` set.
- **Military level:** Military level (1–4) = highest era among regiment types any Great Power can build; minors receive this as `effectiveMilitaryLevel` per [factions.md](factions.md); tribes are capped at 1 (no parity).
- **Table as source of truth:** The tech table in this doc is the source of truth for tech id, name, era, prerequisites, and regiment/effect mapping.
- **Fort prerequisites:** Fort level 2 requires Mine Engineering (see [tech-tree-gathering.md](tech-tree-gathering.md)); fort level 3 requires Modern Forts (this doc). Build validation and resolution: [siege-mechanics.md](siege-mechanics.md), [development-resolution.md](../program/development-resolution.md).
