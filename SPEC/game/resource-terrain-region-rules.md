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
| timber | both | hardwoodForest, scrubForest | 30 |
| iron | both | hills, mountain | 80 |
| copper | both | hills, mountain | 70 |
| tin | both | swamp | 75 |
| coal | both | hills, mountain | 90 |
| sugarCane | NW only | plains | 35 |
| tobacco | NW only | plains | 40 |
| cotton | NW only | plains | 45 |
| furs | NW only | hardwoodForest | 55 |
| spices | NW only | plains | 50 |
| silver | NW only | hills | 100 |
| gold | NW only | mountain | 166 |
| gems | NW only | mountain | 250 |
| diamonds | NW only | desert | 500 |

Spawn weight = 1 / default market price (higher price = rarer).

**Prospect-required (per Imperialism II):** iron, copper, tin, coal, silver, gold, gems, diamonds. These minerals must be prospected by an Explorer before extraction. All others (grain, meat, wool, horses, timber, sugarCane, tobacco, cotton, furs, spices) are known from terrain when tile is revealed. See [fog-and-exploration.md](fog-and-exploration.md).

---

## Forest terrain split (hardwood vs scrub)

The generic `forest` terrain is split into two distinct terrain types
(`TerrainType.forest` is removed entirely; no save back-compat). See issue #3573.

- **hardwoodForest** — high-quality timber, rarer. Hosts `timber` (both regions)
  and `furs` (New World only). Combat: attacker ×0.9, defender ×1.5 (dense cover).
  Timber extraction follows the normal gathering-tech cap progression
  (`saw_mill`→2, `wind_saw_mill`→3, `circular_saw`→4).
- **scrubForest** — low-quality timber, common. Hosts `timber` only (both
  regions); never `furs`. Combat: attacker ×0.9, defender ×1.1 (same as the
  legacy forest). Timber extraction is hard-capped at **level 1** regardless of
  unlocked gathering tech.

**Map distribution weights** (`terrain_region_rules.dart`, both regions): total
forest weight is halved (legacy 3.0 → 1.5) at a 1:4 hardwood:scrub ratio
(`hardwoodForest` 0.3, `scrubForest` 1.2); the freed 1.5 weight is added to
`plains` (4.0 → 5.5).

**Guaranteed forest resource spawn:** every forest cell (hardwood or scrub)
always receives a resource (100%), overriding the global place probability.
Scrub → always `timber`; hardwood OW → always `timber`; hardwood NW → 70% `furs`
/ 30% `timber`. These guaranteed placements are excluded from the multi-region
cap accounting (mirroring the bootstrap-grain exclusion) and the 30% cap applies
only to non-forest cells.

---

## Multi-region resource cap (Pass 7)

On each map (oldWorld and newWorld), at most 30% of placed resources may be multi-region ("both") resources. The rest are reserved for region-exclusive resources. When the cap is reached and a land cell could receive either a "both" or a region-only resource, only region-only resources are eligible. When a cell can only receive "both" resources (e.g. Old World forest, mountain, swamp have no OW-only alternatives), place "both" regardless; the cap is applied only when a choice exists.

---

## Notes

- **Fish:** Water tiles only. Pass 7 assigns resources to land cells only. Fish is future scope (water-resource pass or separate handling).
- **Diamonds:** Spawn on desert terrain (New World only). Imperialism II Terrain and Development table.
- **Riches:** silver, gold, gems, diamonds, spices align with riches-to-treasury base prices (defined in ruleset config).

---

## Acceptance Criteria

- Given the active ruleset defines a resource–terrain–region table where each row specifies a resource id, a region scope (`OW only`, `NW only`, or `both`), a non-empty set of terrain types, and a default market price  
  When the System loads this table at game start  
  Then the System validates that each resource id is unique, that terrain types listed for each row are valid terrain types for the specified region, and that default prices are positive integers, rejecting the ruleset with a clear error if any of these conditions fail.

- Given a tile map for a region such as `oldWorld` with terrain types assigned to each land cell and the resource–terrain–region rules have been loaded successfully  
  When the System assigns resources to land tiles according to these rules  
  Then the System only assigns a resource to a tile if the tile’s region and terrain type match at least one table row for that resource, and it never places a resource on a tile whose region or terrain is not allowed by the table.

- Given a map for `oldWorld` and `newWorld` and a configured multi-region cap of 30% for resources whose region scope is `both`  
  When the System runs the resource placement pass that can choose between resources with scope `both` and resources with region-exclusive scope for a candidate tile  
  Then the System ensures that no more than 30% of all placed resources on that map are `both`-scope resources, and when the cap has been reached it only considers region-exclusive resources for tiles that have both options available.

- Given a land tile in the New World with desert terrain and no Old World-only resources that are legal on desert tiles in that region  
  When the System assigns resources to land tiles for the New World  
  Then the System may assign `diamonds` to that tile even if the multi-region cap for `both` resources has already been reached, because the cap is applied only when there is a choice between `both` and region-exclusive resources.

- Given the loaded resource–terrain rules after the forest split  
  When the System evaluates allowed terrains for `timber` and `furs`  
  Then `timber` is allowed on both `hardwoodForest` and `scrubForest`, `furs` is allowed on `hardwoodForest` only and never on `scrubForest`, and no rule references a `forest` terrain type.

- Given the Old World and New World terrain distributions after the forest split  
  When the System computes normalized terrain fractions  
  Then the `scrubForest` weight (1.2) is exactly four times the `hardwoodForest` weight (0.3), the combined forest weight (1.5) is half of the legacy forest weight (3.0), and the `plains` weight is 5.5 in both regions.

- Given a battle resolved on a province whose terrain is `hardwoodForest`  
  When the System applies terrain combat modifiers  
  Then the attacker strength multiplier is 0.9 and the defender strength multiplier is 1.5; for `scrubForest` the multipliers are 0.9 (attacker) and 1.1 (defender).
