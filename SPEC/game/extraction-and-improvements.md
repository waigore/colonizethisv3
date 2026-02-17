# Extraction and Improvements

**SPEC/game** — Per-tile extraction and improvement types. Derived from GDD 04b. Tiles: [tile-map-and-generation.md](tile-map-and-generation.md). Stockpile flow: [stockpiles-and-production.md](stockpiles-and-production.md). Connectivity: [capital-and-connectivity.md](capital-and-connectivity.md).

---

## Extraction Formula

Each **land tile** in an owned province may have an **extraction improvement** (mine, farm, ranch, plantation, fur post, town, etc.) with an **improvement level** (e.g. 0–4). The tile has at most one **resource** (region- and terrain-constrained per GDD 04b).

**Production** = min(improvement level, owner's tech-allowed max level). **Effective yield** (per connected tile) = min(production, **transport level**). So first cap by tech, then by transport. Example: level 4 farm, tech cap 3, transport level 2 → 2 units per turn. The improvement remains level 4; conquest or tech/transport upgrade can allow more later.

---

## Transport Level (Per Tile)

Each land tile has a **transport level** in {0, 1, 2, 4}. 0 = not connected. 1 = primitive road, 2 = improved road (or future tech), 4 = port or railroad. Source: road level on that tile or adjacent port (port tile = 4). Imperialism II 02-economy: primitive 1, improved 2, port 4, railroad 4.

---

## Flow to Stockpile

Connected tiles’ effective yields are summed by commodity. **Same-region** (land): all added to owning player's stockpile. **Overseas:** sea transport step (cargo limit + priority). No per-province storage. See [stockpiles-and-production.md](stockpiles-and-production.md) and [auto-transport.md](../program/auto-transport.md).

---

## Improvement Types, Roads, Ports

Improvement type matches the resource (e.g. mine for ore, farm for grain). **Improvements** and **roads** are per **tile** in world state (improvement level 0–4; road level 0 / 1 / 2; railroad or port can give transport level 4). **Ports** are at **province-seaboard** level: one port per **seaboard** (each seaboard = one sea zone adjacent to the province per topology). Province with two seaboards: for overseas connectivity, must have a port on the seaboard that has a sea path to the capital’s sea. Implementation: port stored per (provinceId, seaZoneId) or per tile with port + seaZoneId; terrain–resource rules in colonizethis_data; extraction resolution in colonizethis_logic.
