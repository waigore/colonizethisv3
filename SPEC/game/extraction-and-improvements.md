# Extraction and Improvements

**SPEC/game** — Per-tile extraction and improvement types. Derived from GDD 04b. Tiles: [tile-map-and-generation.md](tile-map-and-generation.md). Stockpile flow: [stockpiles-and-production.md](stockpiles-and-production.md).

---

## Extraction Formula

Each **land tile** in an owned province may have an **extraction improvement** (mine, farm, ranch, plantation, fur post, town, etc.) with an **improvement level** (e.g. 0–4). The tile has at most one **resource** (region- and terrain-constrained per GDD 04b).

**Effective extraction** = min(improvement level, owner's tech-allowed max level). The controlling player's technology caps how much of the improvement level counts. Example: level 4 farm, tech cap 3 → 3 units of that resource per turn. The improvement remains level 4; conquest or tech advance can allow full extraction later.

---

## Flow to Stockpile

All extracted commodities from owned province tiles flow to the **owning player's central stockpile** each turn (via auto-transport). No per-province storage. See [stockpiles-and-production.md](stockpiles-and-production.md) and [auto-transport](../program/auto-transport.md).

---

## Improvement Types and Max Level

Improvement type matches the resource (e.g. mine for ore, farm for grain). Max improvement level is configurable (e.g. 4); tech can cap the effective level per player. Roads are separate (any land tile; affect transport). Implementation and terrain–resource rules live in colonizethis_data; extraction resolution in colonizethis_logic.
