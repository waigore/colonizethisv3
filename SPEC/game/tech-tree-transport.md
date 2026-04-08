# Tech Tree — Transport and Infrastructure

**SPEC/game** — Road and railroad techs. Reference: Imperialism II 08-technology (Transport and Infrastructure). Overview: [tech-tree.md](tech-tree.md). Roads/railroads require **explicit player action** (Engineer/Rail Builder); tech only allows building that level. Ports and railroads both give transport level 4. See [extraction-and-improvements.md](extraction-and-improvements.md).

---

## Tech Table

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| road_construction | Road Construction | 1 | saw_mill, land_enclosure, iron_mining | Enables: Engineer build orders that set transport level **2** roads (capacity **2 units/tile**). Unlocks: prerequisite for `early_steam_engine`. |
| early_steam_engine | Early Steam Engine | 2 | road_construction, square_set_timbering, steam_in_mining | Enables: Rail Builder unit and railroad build orders on flat terrain only (transport level **4**, capacity **4 units/tile**). Unlocks: prerequisite for `later_steam_engine`, `tobacco_industry`, and `riverboats`. |
| later_steam_engine | Later Steam Engine | 3 | early_steam_engine, crucible_process | Enables: railroad build orders on hills and swamps in addition to flat terrain (transport level **4**). Unlocks: prerequisite for `dynamite` and `excessive_fur_harvesting`. |
| dynamite | Dynamite | 4 | later_steam_engine, banking, explosives | Enables: railroad build orders on mountains (completes flat/hill/swamp/mountain rail coverage at transport level **4**). Unlocks: prerequisite for `safety_lamp`, `geological_prospecting`, and `amalgamation_process`. |

---

## Effect Semantics

- **Transport level 2:** Engineer can build improved roads (transport level 2) only when Road Construction is researched.
- **Railroad (level 4):** Rail Builder can build railroads when Early Steam Engine (flat), Later Steam Engine (hills/swamps), or Dynamite (mountains) is researched as applicable. Ports also give transport level 4 and are built by Engineers per topology.

---

## Acceptance Criteria

- Given the Transport and Infrastructure tech table in this doc and the global tech catalog  
  When the System validates the catalog at startup  
  Then the System ensures that each transport tech id is unique, that its prerequisites refer to techs present in the catalog, and that the effects listed here (road and rail build permissions) line up with the transport levels and terrain rules described in [extraction-and-improvements.md](extraction-and-improvements.md).

- Given a player has `road_construction` in `techUnlocked`  
  When the System validates or executes Engineer work orders that build roads on land tiles per [extraction-and-improvements.md](extraction-and-improvements.md) and [development-resolution.md](../program/development-resolution.md)  
  Then the System allows the Engineer to set the road level on a tile to 2 only if `road_construction` is unlocked and otherwise restricts newly built roads to level 1, leaving existing road levels unchanged unless a valid upgrade is applied.

- Given a player has unlocked `early_steam_engine`, `later_steam_engine`, or `dynamite`  
  When the System validates or executes Rail Builder work orders on tiles of various terrain types  
  Then the System allows railroads (transport level 4) to be built on flat tiles once `early_steam_engine` is unlocked, on hills and swamps once `later_steam_engine` is unlocked, and on mountains only after `dynamite` is unlocked, and prevents building railroads on terrain types that are not yet enabled by the player’s unlocked transport techs.
