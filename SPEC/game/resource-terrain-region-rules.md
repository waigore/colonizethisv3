# Resource–Terrain–Region Rules

**SPEC/game** — Canonical table for extractable resources, allowed regions, terrain types, and spawn weights. Source: Imperialism II Terrain and Development table (03-units-civilian).

---

## Table

| Resource | Region | Terrain types | Default market price |
|----------|--------|---------------|----------------------|
| grain | OW only | plains | 50 |
| meat | OW only | plains | 45 |
| wool | OW only | hills | 40 |
| horses | OW only | plains | 60 |
| timber | both | forest | 30 |
| iron | both | hills, mountain | 80 |
| copper | both | hills, mountain | 70 |
| tin | both | swamp | 75 |
| coal | both | hills, mountain | 90 |
| sugarCane | NW only | plains | 35 |
| tobacco | NW only | plains | 40 |
| cotton | NW only | plains | 45 |
| furs | NW only | forest | 55 |
| spices | NW only | plains | 50 |
| silver | NW only | hills | 100 |
| gold | NW only | mountain | 166 |
| gems | NW only | mountain | 250 |
| diamonds | NW only | swamp | 500 |

Spawn weight = 1 / default market price (higher price = rarer).

**Prospect-required (per Imperialism II):** iron, copper, tin, coal, silver, gold, gems, diamonds. These minerals must be prospected by an Explorer before extraction. All others (grain, meat, wool, horses, timber, sugarCane, tobacco, cotton, furs, spices) are known from terrain when tile is revealed. See [fog-and-exploration.md](fog-and-exploration.md).

---

## Multi-region resource cap (Pass 7)

On each map (oldWorld and newWorld), at most 30% of placed resources may be multi-region ("both") resources. The rest are reserved for region-exclusive resources. When the cap is reached and a land cell could receive either a "both" or a region-only resource, only region-only resources are eligible. When a cell can only receive "both" resources (e.g. Old World forest, mountain, swamp have no OW-only alternatives), place "both" regardless; the cap is applied only when a choice exists.

---

## Notes

- **Fish:** Water tiles only. Pass 7 assigns resources to land cells only. Fish is future scope (water-resource pass or separate handling).
- **Diamonds:** Imperialism II has Desert terrain; current TerrainType has no Desert. Diamonds use swamp as proxy until Desert terrain exists.
- **Riches:** silver, gold, gems, diamonds, spices align with riches-to-treasury base prices (defined in ruleset config).
