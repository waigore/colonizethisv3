# Extraction and Improvements

**SPEC/game** — Per-tile extraction and improvement types. Derived from GDD 04b. Tiles: [tile-map-and-generation.md](tile-map-and-generation.md). Stockpile flow: [stockpiles-and-production.md](stockpiles-and-production.md). Connectivity: [capital-and-connectivity.md](capital-and-connectivity.md).

---

## Extraction Formula

Each **land tile** in an owned province may have an **extraction improvement** (mine, farm, ranch, plantation, fur post, town, etc.) with an **improvement level** (e.g. 0–4). The tile has at most one **resource** (region- and terrain-constrained per GDD 04b). Full resource list and rules: [resource-terrain-region-rules.md](resource-terrain-region-rules.md).

**Production** = min(improvement level, owner's tech-allowed max level). **Effective yield** (per connected tile) = min(production, **transport level**). So first cap by tech, then by transport. Example: level 4 farm, tech cap 3, transport level 2 → 2 units per turn. The improvement remains level 4; conquest or tech/transport upgrade can allow more later.

**Minerals require prospecting:** iron, copper, tin, coal, silver, gold, gems, diamonds. Extraction only from tiles that (a) are connected and (b) the player has prospected. Non-minerals (grain, meat, wool, etc.) do not require prospecting. See [fog-and-exploration.md](fog-and-exploration.md), [resource-terrain-region-rules.md](resource-terrain-region-rules.md).

---

## Transport Level (Per Tile)

Each land tile has a **transport level** in {0, 1, 2, 4}. 0 = not connected. 1 = primitive road, 2 = improved road, 4 = port or railroad. **Road level 2 (improved roads) and level 4 (railroad or port) require explicit player action:** an Engineer builds roads (level 1 or, with Road Construction tech, level 2); a Rail Builder builds railroads (with Early Steam Engine and related techs). Tech only **allows** building that level—it does not change existing tiles by itself. Ports and railroads both provide transport level 4. Source: road level on that tile or adjacent port (port tile = 4). Imperialism II 02-economy: primitive 1, improved 2, port 4, railroad 4. See [tech-tree-transport.md](tech-tree-transport.md).

---

## Flow to Stockpile

Connected tiles’ effective yields are summed by commodity. **Same-region** (land): all added to owning player's stockpile. **Overseas:** sea transport step (cargo limit + priority). No per-province storage. See [stockpiles-and-production.md](stockpiles-and-production.md) and [auto-transport.md](../program/auto-transport.md).

---

## Improvement Types, Roads, Ports

Improvement type matches the resource (e.g. mine for ore, farm for grain). **Improvements** and **roads** are per **tile** in world state (improvement level 0–4; road level 0 / 1 / 2; railroad or port can give transport level 4). Building improved roads (level 2) or railroads requires the corresponding tech (Road Construction, Early Steam Engine, etc.) and a work order by an Engineer or Rail Builder. **Ports** are at **province-seaboard** level: one port per **seaboard** (each seaboard = one sea zone adjacent to the province per topology). Province with two seaboards: for overseas connectivity, must have a port on the seaboard that has a sea path to the capital’s sea. Implementation: port stored per (provinceId, seaZoneId) or per tile with port + seaZoneId; terrain–resource rules in colonizethis_data; extraction resolution in colonizethis_logic.

All **terrain development** (Builder improvements, Engineer roads/ports/forts, Rail Builder railroads) is applied via civilian work orders during the **Build/Work** phase. Each development action is a **multi-turn build**: work duration and material cost increase with target level (e.g. Level 4 improvement slower and more expensive than Level 1), mirroring Imperialism II. Progress is tracked per working unit; on completion, the relevant tile or province state is updated, and subsequent Extraction phases use the new improvement and transport levels. Exact per-action costs and turn counts are defined in the ruleset and [development-resolution.md](../program/development-resolution.md).
