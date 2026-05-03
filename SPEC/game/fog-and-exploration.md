# Fog of War and Exploration

## Overview

Per-player tile visibility governing what each Great Power knows about the map. Exploration and prospecting reveal tiles and mineral deposits.

**Program alignment:** `explore` assignment visibility (partial reveal on **land** tiles) and deferred completion for `prospect` / `purchase_land` primary effects are specified in [orders.md](../program/orders.md) and [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md).

---

## Rules

### Visibility Levels

Three levels per player per tile (`unknown` < `fogged` < `fullyVisible`). Visibility state is keyed by player and by province (prefixed province id) or tile (tile key); see [world-model-identity.md](world-model-identity.md).

- **Unknown:** No knowledge; exploration/prospecting impossible. New World land and sea start here for all GPs until a positive reveal rule applies. No rule may promote `unknown` to `fogged` or higher without such a reveal (including end-of-turn fog decay).
- **Fogged:** Terrain, non-prospect resources, and last-known improvements visible for other-faction provinces when no Explorer/Spy grants higher intel. Old World other-faction land and sea start here (before coastal sea passes). End-of-turn decay may downgrade **only** stored `fullyVisible` → `fogged` for applicable other-faction tiles; `unknown` and `fogged` are never decay targets.
- **Fully Visible:** Everything known except unprospected minerals. Own provinces are always fully visible. Successful fleet entry into a sea zone sets **coastal ring** land tiles (orthogonal to that zone’s water) and **water** in that zone to `fullyVisible`; **inland** land in the same province stays `unknown` until exploration (or another explicit rule) completes.

### Own vs Other Provinces

Own provinces are always fully visible and never decay. Fogged applies only to other factions' provinces.

### Province ownership intel

Province ownership shown in UI (Political sections, labels, ownership metadata) is always authoritative from `Province.ownerId` for every player and is not obfuscated by fog states.

### Coastal sea zone visibility

For each **Great Power** (including the human player), all tiles in sea zones that are **immediately adjacent** (P–S edge in topology) to a province that player **fully owns** are **fully visible** to that player. Unknown or fogged tiles in those sea zones are overridden to fully visible.

- **Ownership:** Only provinces with direct ownership (`Province.ownerId == playerId`). Vassals/puppets do not count.
- **Application:** Applied twice: (1) during Game Setup, immediately after initial visibility assignment, so players can see adjacent sea zones from turn 0; and (2) every turn at turn resolution, **after** all phases that affect visibility: Movement (ship reveal), Combat (ownership change), Build/work (exploration, prospecting), End-of-turn fog decay. The coastal sea zone visibility step runs inEnd-of-turn after fog decay so visibility is consistent for all players before the turn advances.
- **Scope:** Full game rule: authoritative visibility state and PlayerView are updated; map widget, order suggestions, and AI use the same visibility.

### Distant sea zone fog (End-of-turn)

For each **Great Power**, after Explorer/Spy fog decay each turn and **before** the coastal sea zone pass:

A **sea zone** S (per region) reverts to **fogged** for that player for all **water** tiles in S **only when** both hold: (1) no province **fully owned** by that player has a **P–S** edge to S; and (2) that player has **no** fleet **at sea** in S (fleets **in port** do not count). Tiles that are **unknown** stay **unknown**.

While a fleet **enters** S during Movement, that player’s water tiles in S are set **fully visible** until this rule applies (see [ships-and-naval.md](ships-and-naval.md), [naval-movement-resolution.md](../program/naval-movement-resolution.md), [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md)).

**Map UI (display-only):** While the human player has a **draft naval move** pending for a fleet shown on the region map, the map renderer may paint terrain within **Chebyshev distance ≤ 2** of that fleet’s marker tile as if **fully visible**. This affects **drawing only** and does not change stored visibility or turn rules.

### Initial Visibility

- **Old World:** Starts fogged (own provinces fully visible); coastal sea zones adjacent to owned provinces are set to fully visible during Game Setup.
- **New World:** Starts unknown; ships reveal coastal tiles when entering adjacent sea zones.

### Exploration (Province-Level)

Explorer with work order target `explore` reveals all tiles in a province. **Turns required:** `ceil(3 * tilesInProvince / maxTilesInAnyProvinceInRegion)` (up to 3 turns), where the scale is the maximum tile count in any province **in that region** (so exploration time is comparable within the same region). On completion, all tiles set to fully visible for that player.

For explore target selection, a province is **partially revealed** for a player when that player has at least one tile in the province at `fogged` or `fullyVisible` and at least one tile at `unknown`.

### Prospecting (Tile-Level)

Explorer with work order target `prospect` prospects the target tile. **One** `currentWork` turn; the tile is added to the player's prospected set when that work **completes** in the Build/Work phase (not merely when the order is accepted). Per-player; minerals must be prospected before extraction.

### Prospect-Required Resources

**Require prospecting:** iron, copper, tin, coal, silver, gold, gems, diamonds.

**Known from terrain when visible:** grain, meat, wool, horses, timber, sugarCane, tobacco, cotton, furs, spices.

Tiles with a **known** non-prospect (terrain-known) resource are not mineral-eligible for `prospect`, even when the underlying terrain type is normally prospectable.

Mineral-eligible terrain: swamp, hills, mountain, desert (for diamonds). See [resource-terrain-region-rules.md](resource-terrain-region-rules.md).

### Fog Decay

- **Explorer / end-of-turn pass:** When no Explorer or Spy of the viewer remains in an other-faction province and no Spy decay timer applies for that province, **only** tiles currently stored as `fullyVisible` are set to `fogged`. Tiles that are `unknown` or `fogged` are unchanged (no `unknown` → `fogged` from this rule).
- **Spy timer expiry:** When the Spy fog-decay timer for (player, province) reaches 0, apply the same rule as Explorer decay: **only** `fullyVisible` → `fogged`; `unknown` and `fogged` unchanged. When a Spy leaves an other-faction province, a timer (Spy fog decay turns, default 5; see Configurable Values) starts for (player, province). Spy timers are **per-player, per-province counters** (playerId, fullProvinceId) and **MUST NEVER be started for, or cause visibility changes in, the Spy owner's own provinces.

Own provinces never decay (they remain fully visible regardless of Explorer/Spy presence or timers). When a player gains ownership of a province for which they previously had an active Spy timer, that timer is cleared immediately and can no longer cause decay in that province.

### Explorer vs Spy

**Explorer** reveals terrain, resources, and improvements but not armies/navies.

**Spy** reveals everything including garrison and naval strength. When a Spy belonging to player A is safely located in a province owned by another faction, that province's tiles are treated as fully visible for player A while the Spy remains there, without changing the underlying stored visibility for other systems.

### Order Visibility Requirements

**Move orders:**

- Source province: at least one tile at `fogged` or `fullyVisible`.
- Destination province: at least one tile at `fogged` or `fullyVisible`.

**Work orders** (unit must be in the province):

| Unit type | Work target | Minimum visibility |
|---|---|---|
| Explorer | explore | Province at least fogged |
| Explorer | prospect | Tile at least fogged |
| Builder | build_improvement, upgrade_town | At least fogged (own = fully visible) |
| Engineer | build_road, build_port, build_fort | Same as Builder |
| Rail Builder | build_rail | Same as Builder |

### Extraction Gating

Mineral resources may only be extracted from tiles that are (a) connected and (b) prospected by that player. Non-minerals unchanged.

### Province and tile identity

Per [world-model-identity.md](world-model-identity.md):

- **Tile keys** (visibility map, prospected set) use the 4-part format `regionId|provinceId|x|y`; the second segment is the local province id within the region; full province id is `regionId|localId`.
- **Province keys** (e.g. Spy reveal timer `provinceKey`) must be **full province id** (`regionId|localId`), not bare local id, so that lookups and multi-region consistency are correct.
- **Ship coastal reveal** and **fog decay** logic resolve provinces by `(regionId, provinceId)` or prefixed id only.

---

## Configurable Values

| Parameter | Default | Notes |
|---|---|---|
| Explore max turns | 3 | Scaled by province size |
| Prospect turns per tile | 1 | |
| Spy fog decay turns | 5 | **Fixed constant for current product** (not ruleset-configurable). When Spy leaves other-faction province, turns until that province's tiles revert to fogged |
| Old World initial visibility | fogged | Own = fully visible |
| New World initial visibility | unknown | |

**Notes on non-configurable values:**

- **Exploration scale** (`maxTilesInAnyProvinceInRegion`): This value is **derived from map topology**, not a ruleset parameter. It is computed as the maximum tile count of any province in the same region as the exploring unit's province. This ensures exploration time is comparable across provinces within the same region. See [world-model.md](world-model.md) and [map-topology.md](map-topology.md).

---

## Interactions

- **App map (Flutter):** Province and sea-zone topology strokes and political border strokes are drawn only along edges where at least one adjacent tile is not **unknown** from the player’s view, except in the map widget’s **full visibility** mode (debug/tooling), which draws all boundaries. Mapping: game **unknown** → `CellViewData.visibility` **`unrevealed`**; **fogged** / **fully visible** → non-`unrevealed` in the view model. See [map-widget.md](../ui/map-widget.md) § Layer model and Visibility modes.
- **App map province labels:** Unit-presence label icons (civilian/regiment/ship) use player-constrained intel; when PlayerView for a province does not expose class-presence knowledge, the map renders no presence icons for that province even if hidden world state contains units there. See [map-widget.md](../ui/map-widget.md) and [player-view.md](../program/player-view.md).

- Civilian units: [civilian-units.md](civilian-units.md)
- Ship coastal reveal: [ships-and-naval.md](ships-and-naval.md)
- Resource/terrain rules: [resource-terrain-region-rules.md](resource-terrain-region-rules.md)
- Extraction gating: [extraction-and-improvements.md](extraction-and-improvements.md)
- World model (tile positioning): [world-model.md](world-model.md)
- Province and tile identity (prefixed ids, tile keys): [world-model-identity.md](world-model-identity.md)

---

## Acceptance criteria

- **Visibility levels:** Three levels per player per tile (`unknown`, `fogged`, `fullyVisible`). Ordering: `unknown` < `fogged` < `fullyVisible`. Own provinces are always fully visible and never decay; fog decay never promotes `unknown` and only downgrades `fullyVisible` → `fogged` where rules apply.
- **Initial visibility:** Old World starts fogged (own fully visible); New World starts unknown; coastal tiles reveal when ships enter adjacent sea zones per ships-and-naval.
- **Exploration:** Explorer work `explore` uses region-scoped formula: turns = `ceil(3 * tilesInProvince / maxTilesInAnyProvinceInRegion)` (max 3). On completion, all tiles in the province become fully visible for that player only.
- **Prospecting:** Explorer work `prospect` is one turn per tile; minerals require prospecting before extraction; mineral-eligible terrain and prospect-required vs terrain-known resources are as listed in Rules.
- **Fog decay:** Explorer/Spy end-of-turn pass and Spy timer expiry: for other-faction provinces, **only** tiles stored as `fullyVisible` become `fogged`; `unknown` and `fogged` tiles are unchanged. Spy timers are never started for a player's own provinces and can never cause tiles in own provinces to decay. Own provinces never decay.
- **Order visibility:** Move orders require source and destination each with at least one tile at `fogged` or `fullyVisible`. Work orders require minimum visibility per unit type and target (e.g. explore ≥ fogged, prospect ≥ fogged, build_* ≥ fogged); province and tile identity use prefixed form per world-model-identity.
- **Extraction gating:** Minerals extractable only from connected, prospected tiles for that player; non-minerals unchanged.
- **Implementation:** Visibility resolution, Spy timer, and PlayerView construction: [fog-and-exploration-resolution.md](../program/fog-and-exploration-resolution.md).
- **Coastal sea zone visibility:** For each Great Power, all tiles in sea zones adjacent (P–S) to provinces they fully own are fully visible; recalculated every turn in End-of-turn after fog decay; only direct ownership; overrides unknown/fogged for those tiles.
- **App map boundaries:** In player-constrained map mode, topology and political strokes follow [map-widget.md](../ui/map-widget.md) (edges gated unless at least one adjacent tile is known to the player).

### Given–When–Then acceptance criteria

- Given a player A has an active Spy timer for province `P` that is currently owned by player B and at least one tile in `P` is fully visible for player A  
  When player A gains ownership of province `P` via any game rule (e.g. combat conquest, Join Empire/Colony)  
  Then the system immediately removes the Spy timer entry for `(player A, P)` and leaves all tiles in `P` for player A at their current visibility (no tiles in `P` become fogged for player A due to that timer).

- Given a player owns a province `P` and that province's tiles are fully visible for that player  
  When any Spy owned by that player moves out of, or is removed from, province `P`  
  Then the system does not start or maintain any Spy fog-decay timer for `(player, P)` and no tiles in `P` ever revert from `fullyVisible` to `fogged` due to Spy timers or Explorer/Spy fog decay (own provinces remain fully visible).

- Given a Spy belonging to player A is located in a province owned by player B and that province has at least one land tile  
  When the system constructs the PlayerView for player A  
  Then all land tiles in that province appear in player A's PlayerView with visibility level `fullyVisible` while the Spy remains there, and this enhanced visibility does not change tile visibility for any other player.

- Given a Great Power owns at least one coastal province P and sea zone S is adjacent to P (P–S edge in topology)  
  When game setup completes (before turn 0)  
  Then every tile in sea zone S has visibility `fullyVisible` for that player in WorldState and in that player's PlayerView.

- Given a Great Power owns at least one coastal province P and sea zone S is adjacent to P (P–S edge in topology)  
  When the system has run the End-of-turn phase including the coastal sea zone visibility step  
  Then every tile in sea zone S has visibility `fullyVisible` for that player in WorldState and in that player's PlayerView.

- Given a Great Power conquers a coastal province P so that P becomes owned by them, and sea zone S is adjacent to P  
  When the system has run the End-of-turn phase including the coastal sea zone visibility step  
  Then every tile in sea zone S has visibility `fullyVisible` for that player (even if those tiles were previously unknown or fogged).

- Given a Great Power no longer owns any province adjacent to sea zone S (e.g. lost the only coastal province next to S)  
  When the system has run the End-of-turn phase including the coastal sea zone visibility step  
  Then coastal sea zone visibility does not force S's tiles to fully visible for that player; their visibility remains whatever they were from other sources (e.g. ship reveal, or they may become fogged/unrevealed over time per other rules).

- Given a fresh game where a Great Power player owns only Old World provinces and has no units in the New World, and every New World **land** tile for that player is `unknown` after setup  
  When the system completes `runEndOfTurnPhase` advancing from turn 0 to turn 1  
  Then every such New World **land** tile remains `unknown` in `WorldState.playerVisibilityByTile` unless a positive reveal rule fired during that turn.
