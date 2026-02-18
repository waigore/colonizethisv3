# Fog of War and Exploration

**SPEC/game** — Per-player tile visibility and exploration/prospecting. Reference: Imperialism II 03-units-civilian. Technical resolution: [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md). Civilian units: [civilian-units.md](civilian-units.md).

---

## Visibility Levels (per player, per tile)

Four levels, applied at tile granularity:

- **Unknown:** No knowledge; exploration/prospecting impossible. New World tiles start here for all GPs.
- **Revealed:** Province boundary and owner known; terrain and resources unknown. Reached when a tile is first revealed (e.g. ship enters adjacent sea zone).
- **Fogged:** Tile and terrain known; non-prospect resources (grain, timber, etc.) known; improvements at last visible state known. **Other faction provinces only**; applies when no Explorer/Spy working in province. Decay is **immediate** when units leave.
- **Fully visible:** Everything known except unprospected mineral resources. **Own provinces are always fully visible.**

---

## Own vs Other Provinces

Own provinces never fogged. Fogged only applies to other factions' provinces.

---

## Exploration (province-level)

Explorer with WorkOrder target `explore` spends turns revealing province tiles. Reveals **all tiles** in the province; takes **up to 3 turns** scaled by province size: `turns = ceil(3 * tilesInProvince / maxTilesInAnyProvince)`. Must have WorkOrder to explore.

---

## Prospecting (tile-level)

Explorer with WorkOrder target `prospect` prospects the **tile under the unit**. Per player; minerals must be prospected before extraction. One turn per tile.

---

## Prospect-Required Resources (per I2)

**Prospect-required:** iron, copper, tin, coal, silver, gold, gems, diamonds.

**Known from terrain when tile revealed/fogged/fully visible:** grain, meat, wool, horses, timber, sugarCane, tobacco, cotton, furs, spices.

See [resource-terrain-region-rules.md](resource-terrain-region-rules.md). Mineral tiles (swamp, hills, mountain) are prospect-eligible.

---

## Initial Visibility

- **Old World:** Starts **fogged** (own provinces fully visible).
- **New World:** Starts **unknown**; ships reveal coastal tiles when entering adjacent sea zone. See [ships-and-naval.md](ships-and-naval.md).

---

## Explorer vs Spy

**Explorer** pushes fog (terrain, resources, improvements) but **not** armies/navies stationed in the province.

**Spy** reveals everything including garrison and naval strength.

---

## Civilian Positioning

Civilians (Explorer, Builder, Engineer, etc.) have **tile-level** location. Military units remain province-level only. See [world-model.md](world-model.md), [civilian-units.md](civilian-units.md).

---

## Per-player knowledge and PlayerView

Fog of war defines **what each player can know** about the map at any time. For a given Great Power `P`, the game derives a **knowledge state** consisting of:

- Tile visibility per `VisibilityLevel` (unknown, revealed, fogged, fullyVisible) per tile key.
- Prospected tiles for `P` (which mineral tiles have been prospected).
- Last-known terrain, resources, and improvements for tiles that are at least fogged.
- Ownership and boundaries for provinces that have been at least revealed.
- Full information about `P`'s own units, economy (stockpile, treasury, workers) and research state.

This knowledge state is exposed to AI and tooling via a **PlayerView** abstraction (see `SPEC/program/player-view.md`). PlayerView is the **only source of per-player world knowledge** that AI and order suggestion logic may use; it may not see tiles or units that are hidden by fog of war.
