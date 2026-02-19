# Tech Tree — Transport and Infrastructure

**SPEC/game** — Road and railroad techs. Reference: Imperialism II 08-technology (Transport and Infrastructure). Overview: [tech-tree.md](tech-tree.md). Roads/railroads require **explicit player action** (Engineer/Rail Builder); tech only allows building that level. Ports and railroads both give transport level 4. See [extraction-and-improvements.md](extraction-and-improvements.md).

---

## Tech Table

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| road_construction | Road Construction | 1 | saw_mill, land_enclosure, iron_mining | Allows building transport level 2 (2 units/tile); leads to railroads |
| early_steam_engine | Early Steam Engine | 2 | road_construction, square_set_timbering, steam_in_mining | Railroads in flat terrain; 4 units/tile; unlocks Rail Builder |
| later_steam_engine | Later Steam Engine | 3 | early_steam_engine, crucible_process | Rail through hills and swamps |
| dynamite | Dynamite | 4 | later_steam_engine, banking, explosives | Railroads through mountains |

---

## Effect Semantics

- **Transport level 2:** Engineer can build improved roads (transport level 2) only when Road Construction is researched.
- **Railroad (level 4):** Rail Builder can build railroads when Early Steam Engine (flat), Later Steam Engine (hills/swamps), or Dynamite (mountains) is researched as applicable. Ports also give transport level 4 and are built by Engineers per topology.
