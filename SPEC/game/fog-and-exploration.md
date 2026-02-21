# Fog of War and Exploration

## Overview

Per-player tile visibility governing what each Great Power knows about the map. Exploration and prospecting reveal tiles and mineral deposits.

---

## Rules

### Visibility Levels

Four levels per player per tile:

- **Unknown:** No knowledge; exploration/prospecting impossible. New World tiles start here for all GPs.
- **Revealed:** Province boundary and owner known; terrain and resources unknown.
- **Fogged:** Terrain, non-prospect resources, and last-known improvements visible. Applies to other-faction provinces only when no Explorer/Spy is working there. Decay is immediate when units leave.
- **Fully Visible:** Everything known except unprospected minerals. Own provinces are always fully visible.

### Own vs Other Provinces

Own provinces are always fully visible and never decay. Fogged applies only to other factions' provinces.

### Initial Visibility

- **Old World:** Starts fogged (own provinces fully visible).
- **New World:** Starts unknown; ships reveal coastal tiles when entering adjacent sea zones.

### Exploration (Province-Level)

Explorer with work order target `explore` reveals all tiles in a province. Turns required: `ceil(3 * tilesInProvince / maxTilesInAnyProvince)` (up to 3 turns). On completion, all tiles set to fully visible for that player.

### Prospecting (Tile-Level)

Explorer with work order target `prospect` prospects the tile under the unit. One turn per tile. Per-player; minerals must be prospected before extraction.

### Prospect-Required Resources

**Require prospecting:** iron, copper, tin, coal, silver, gold, gems, diamonds.

**Known from terrain when visible:** grain, meat, wool, horses, timber, sugarCane, tobacco, cotton, furs, spices.

Mineral-eligible terrain: swamp, hills, mountain, desert (for diamonds). See [resource-terrain-region-rules.md](resource-terrain-region-rules.md).

### Fog Decay

When a player's last Explorer/Spy leaves another faction's province, all tiles in that province immediately revert to fogged (retaining last-known state). Own provinces never decay.

### Explorer vs Spy

**Explorer** reveals terrain, resources, and improvements but not armies/navies.

**Spy** reveals everything including garrison and naval strength.

### Order Visibility Requirements

**Move orders:**

- Source province: at least one tile with visibility ≠ unknown.
- Destination province: at least one tile with visibility ≠ unknown.

**Work orders** (unit must be in the province):

| Unit type | Work target | Minimum visibility |
|---|---|---|
| Explorer | explore | Province at least revealed |
| Explorer | prospect | Tile at least fogged |
| Builder | build_improvement, upgrade_town | At least fogged (own = fully visible) |
| Engineer | build_road, build_port, build_fort | Same as Builder |
| Rail Builder | build_rail | Same as Builder |

### Extraction Gating

Mineral resources may only be extracted from tiles that are (a) connected and (b) prospected by that player. Non-minerals unchanged.

---

## Configurable Values

| Parameter | Default | Notes |
|---|---|---|
| Explore max turns | 3 | Scaled by province size |
| Prospect turns per tile | 1 | |
| Old World initial visibility | fogged | Own = fully visible |
| New World initial visibility | unknown | |

---

## Interactions

- Civilian units: [civilian-units.md](civilian-units.md)
- Ship coastal reveal: [ships-and-naval.md](ships-and-naval.md)
- Resource/terrain rules: [resource-terrain-region-rules.md](resource-terrain-region-rules.md)
- Extraction gating: [extraction-and-improvements.md](extraction-and-improvements.md)
- World model (tile positioning): [world-model.md](world-model.md)
