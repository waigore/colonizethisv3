# Fog and Exploration Resolution

## Responsibility

Maintains per-player visibility and prospected state on world state; resolves exploration and prospecting work orders; constructs PlayerView for AI and tooling. Game rules: [fog-and-exploration.md](../game/fog-and-exploration.md).

---

## Data Model

**Visibility state:** `Map<playerId, Map<tileKey, VisibilityLevel>>` — enum: `unknown`, `fogged`, `fullyVisible` (ordering `unknown` < `fogged` < `fullyVisible`). Legacy persisted value `revealed` is not loaded or migrated. Tile key format: `regionId|provinceId|x|y` (second segment = local province id; full province id = `regionId|localId` per [world-model-identity.md](../game/world-model-identity.md)). Any province id used in visibility or Spy timer state (e.g. keys keyed by province) must be the **prefixed** form (`regionId|localId`) per world-model-identity.md for multi-region correctness. Stored on WorldState.

**Prospected state:** `Map<playerId, Set<tileKey>>` — tiles the player has prospected. Only mineral-eligible terrain per game rules.

**Spy reveal timer:** `Map<playerId, Map<provinceKey, int>>` — for each player, provinces that were previously revealed by a Spy and are now fog-decaying: value = turns left until tiles in that province are set back to fogged (0 = already fogged). `provinceKey` is the **prefixed** province id (`regionId|localId`) per [world-model-identity.md](../game/world-model-identity.md). When a Spy **leaves** a **non-owner** province, set timer to the Spy fog decay turns (**fixed at 5 for current product, not ruleset-configurable**) for (Spy owner, that province). Spy timers are **per-(player, province)** counters; they **MUST NEVER be created for a player's own provinces**, and any existing timers for own provinces MUST be ignored (and may be cleared) during decay so they cannot affect visibility. Whenever any game rule transfers ownership of a province to a new owner (e.g. combat conquest, Join Empire/Colony), any existing Spy timer for `(newOwner, thatProvince)` MUST be cleared immediately so it can no longer cause decay there, **and** any existing Spy timer for `(priorOwner, thatProvince)` MUST be cleared immediately so the prior owner does not retain a decay timer on a province they no longer own. Stored on WorldState.

**Source province:** A unit's source province is derived from its tileKey (for civilians) or provinceId. Must not be unknown; raises exception if so.

---

## Algorithm / Flow

**Exploration resolution** (Build/Work phase):

1. For each Explorer with work order `explore` in province P, accumulate progress.
2. Turns required per game rules: `ceil(3 * tilesInP / maxTilesInAnyProvinceInRegion)`, where `maxTilesInAnyProvinceInRegion` is the maximum tile count in any province **in the same region** as the Explorer's province.
3. On completion, set all tiles in P to fullyVisible for that player.

**Prospect resolution** (Build/Work phase):

1. For each Explorer with `currentWork.target == prospect` on tile T whose `remainingTurns` reaches **0** this tick, verify T is mineral-eligible.
2. Add T to the player's prospected set. **Assign** only validates and sets `currentWork` (typically `totalTurns = 1` from `totalTurnsForWork`); the prospected-set mutation occurs at **completion**, same tick ordering as other civilian work. For pending civilian row display before resolution, shared logic duration preview returns `1` turn for `prospect` and `purchase_land` so panel turn counters stay deterministic.

**Spy presence reveal:** When building visibility (or PlayerView), for each Spy in a **non-owner** province, that province's tiles are treated as **fully visible** for the Spy's owner for as long as at least one Spy from that owner remains there.

**Fog decay (Spy):** **Immediate** — no grace timer. At end of turn, for each other-faction province where the player had Explorer/Spy presence, if **no** Explorer or Spy from that player remains, **only** tiles stored as `fullyVisible` become `fogged` (`unknown` / `fogged` unchanged). Multi-spy: fog reverts only when the last Spy from that owner leaves or is killed. Legacy `spyRevealTurnsByPlayer` is no longer written or decremented (save field may persist harmlessly). Refs #3834.

**Fog decay** (End-of-turn phase):

1. Decrement spy reveal timers; where timer hits 0, apply **only** `fullyVisible` → `fogged` per tile for that province for that player **only when the province is owned by another faction**. Timers for a player's own provinces are ignored and cleared without changing visibility.
2. For each other-faction province where the player had Explorer/Spy, if none remain (and no Spy timer), for each tile in that province, **only** if stored visibility is `fullyVisible`, set it to `fogged`; `unknown` and `fogged` unchanged—**except** tiles on the **ship-reveal coastal ring** for a sea zone where that player currently has a **non–home fleet at sea** (same orthogonal-to-water geometry as Naval Movement ship reveal): those tiles are **skipped** so coastal intel is not stripped while the fleet remains offshore.
3. Own provinces never decay.

**Initial visibility** (Game Setup phase):

1. Old World land tiles: own provinces `fullyVisible`, other factions' provinces `fogged`.
2. Old World sea tiles: `fogged` initially, then coastal sea zone visibility applied (below).
3. New World tiles: `unknown` for all players.
4. **Coastal sea zone full visibility** is applied immediately after initial visibility assignment, before the first turn.

**Coastal sea zone full visibility** (Game Setup phase after initial visibility, and End-of-turn phase after fog decay):

1. For each **Great Power** player (including human): collect all provinces that player **fully owns** (`Province.ownerId == playerId`).
2. For each such province P, from topology get all sea zones S with a P–S edge (same region).
3. For each such sea zone S, get all tile keys whose cell belongs to S from `tileKeysByRegionAndProvince[regionId][regionId|seaZoneLocalId]` (canonical prefixed sea-zone bucket key).
4. Set each of those tile keys to `fullyVisible` for that player in `WorldState.playerVisibilityByTile` (overrides unknown or fogged).
5. **Runs twice:** (a) during Game Setup, immediately after initial visibility assignment, so players can see adjacent sea zones from turn 0; and (b) during End-of-turn after fog decay, so visibility remains consistent after ownership changes. Tribes and Minor Nations do not get this rule.

**Immediate ownership-transfer coastal update** (debug `flip_province` command path):

1. When debug command `flip_province` succeeds through canonical single-province ownership transfer, apply immediate province land visibility update for old/new owners.
2. In the same debug command transaction, run coastal sea-zone full-visibility normalization so Great Power visibility for sea zones adjacent to newly owned or lost coastal provinces is updated immediately, not deferred until end-of-turn.
3. The immediate coastal step is additive with the normal End-of-turn sequence (`applyDistantSeaZoneFogRevert` then `applyCoastalSeaZoneFullVisibility`) and must not contradict those invariants.

**Immediate debug reveal update** (debug `reveal_province` command path):

1. When `/reveal_province` succeeds for the human player during Orders phase and the debug command resolves one province target (by prefixed id or global display-name match), set all target province land tiles to `fullyVisible` for the human player immediately in `WorldState.playerVisibilityByTile`.
2. In the same transaction, invoke `applyCoastalSeaZoneFullVisibilityForProvinceTargets` so water tiles in sea zones with direct P–S topology adjacency to that province (same region) become `fullyVisible` for that player, using the same adjacency geometry as **Coastal sea zone full visibility**; this debug path is **not** gated on Great Power ownership of the revealed province. See [debug-console-panel.md](../ui/debug-console-panel.md).
3. If all required land and adjacent sea-zone tiles are already `fullyVisible` for the player, return deterministic success/no-op feedback and keep world state unchanged.

**Distant sea zone fog** (End-of-turn phase, after Explorer/Spy fog decay, **before** coastal sea zone full visibility):

1. For each Great Power player and each sea zone S in each region (from topology sea-zone nodes in that region):
   - **Skip** S if there exists a province P with a **P–S** edge to S (same regional topology slice) such that `P` is **fully owned** by that player.
   - **Skip** S if that player has **any fleet at sea** in S (`Fleet.seaZoneId == S`, `Fleet.regionId` matches S’s region, `fleet.ownerId == playerId`). Fleets **in port** do not count for this check.
   - Otherwise, for each water tile key in S from `tileKeysByRegionAndProvince[regionId][regionId|seaZoneLocalId]`, set visibility to **fogged** unless the tile is **unknown** (leave unknown unchanged).
   - **Implementation note (region identity):** When iterating `WorldState.fleets` to test the “fleet at sea in S” condition for a given regional sea zone S, the implementation **must** filter by `Fleet.regionId == regionId` for that pass **before** canonicalizing `Fleet.seaZoneId` with that region’s id. Prefixed sea-zone ids from another region must never be canonicalized against the wrong region (see [world-model-identity.md](../game/world-model-identity.md)); cross-region fleet entries are ignored for the S-in-this-region check.
2. **Ordering:** This step runs after `applyFogDecay` and **before** `applyCoastalSeaZoneFullVisibility` so coastal waters return to full visibility when the player owns adjacent land.

**Ship reveal** (Naval Movement phase):

1. When fleet **successfully** enters sea zone S, set **coastal ring** land tiles (orthogonal neighbor to a water tile of S) of adjacent provinces in S’s region to `fullyVisible` for that player; **inland** land in those provinces stays unchanged (typically `unknown` in the New World until exploration). Set all **water** tile keys for S to `fullyVisible` for that player. Province land tiles are resolved from `tileKeysByRegionAndProvince[regionId]` using the **full** province id (`regionId|localId`) when present, else the **local** province id bucket (same dual-key rule as other map lookups). Sea-zone water tiles are resolved only from canonical sea-zone bucket keys (`tileKeysByRegionAndProvince[regionId][regionId|seaZoneLocalId]`); local-id sea-zone bucket keys are legacy-save input only and must hard-fail during `WorldState.fromJson` load.
2. Delegated to [naval-movement-resolution.md](naval-movement-resolution.md).

**PlayerView construction:**

`buildPlayerView(game, topology, playerId)` derives a per-player view from authoritative world state. Includes: tile visibility map, prospected set, last-known terrain/resources/improvements, province ownership, player's own units/economy/research. All AI and order suggestion logic must read through PlayerView, never directly from world state. See [player-view.md](player-view.md).

**Spy invisibility:** When building PlayerView for player P, any unit of type Spy owned by **another** player is **excluded** from P's view (unit list and province occupancy). Spy locations are never visible to other players; only the Spy's owner sees their own Spies.

---

## Integration

| Phase | Action |
|---|---|
| Game Setup | Initial visibility (OW: own fully visible, others fogged; NW: unknown); **coastal sea zone full visibility** (for each GP, set all tiles in sea zones adjacent to owned provinces to fullyVisible) |
| Naval Movement | Ship reveal (coastal ring land → `fullyVisible`; sea water in S → `fullyVisible`) |
| Build/Work | Exploration progress; prospect resolution |
| End-of-turn | Fog decay (Spy timer + Explorer/Spy); **distant sea zone fog** (sea zones not adjacent to owned coast and with no player fleet at sea in that zone → water tiles fogged, unknown unchanged); **coastal sea zone full visibility** (for each GP, set all tiles in sea zones adjacent to owned provinces to fullyVisible) |

**Upstream:** World state (provinces, tile map, units, owners).

**Downstream:** PlayerView consumed by AI, order suggestion API, order validation engine.

---

## Constraints

- Visibility and prospected state are authoritative on WorldState; PlayerView is derived (read-only).
- Land-province tile buckets accessed by explore completion, fog decay, and turn-news province discovery use canonical **full province id** keys (`regionId|localId`) only; local-only fallback lookups are disallowed in these guarded paths.
- Ship coastal reveal and fog decay logic resolve provinces by `(regionId, provinceId)` or prefixed id only; see [world-model-identity.md](../game/world-model-identity.md).
- Extraction gating (mineral prospecting + connectivity) is enforced by the extraction pipeline, not this module.
- Order visibility rules are defined in game/fog-and-exploration.md; this module enforces them at validation time via PlayerView.

---

## Acceptance criteria

- **Exploration timing and scope:** Exploration work orders use the region-scoped timing formula (`ceil(3 * tilesInP / maxTilesInAnyProvinceInRegion)`) and, on completion, set all tiles in the target province to fullyVisible for the exploring player only.
- **Prospecting:** Prospect work orders validate that the target tile is mineral-eligible per game rules, is not already in that player's `playerProspectedTiles`, and meets visibility (province at least fogged); on application the tile is added to the player's prospected set in WorldState and does not change visibility by itself. Order validation uses the same mineral-eligibility helper as application (including optional per-region tile maps when provided at validation time).
- **Spy reveal and decay:** While a Spy is present in a non-owner province, that province is fully visible to the Spy's owner via PlayerView; when the Spy leaves, a per-(player, province) timer (duration = Spy fog decay turns, **fixed at 5 for current product**) is started **only if the province is owned by another faction** and, when it reaches 0, **only** tiles stored as `fullyVisible` in that province become `fogged` for that player (`unknown` / `fogged` unchanged). Spy timers MUST NOT be created for a player's own provinces and MUST NOT change visibility in own provinces.
- **Explorer/Spy fog decay:** At end of turn, for each other-faction province where the player previously had Explorer/Spy presence, if no Explorer/Spy remains and no Spy timer is active, **only** `fullyVisible` tiles in that province become `fogged`; `unknown` and `fogged` are unchanged.
- **Ship reveal and integration:** When a fleet successfully enters a sea zone, **coastal ring** land tiles of adjacent provinces become **`fullyVisible`** and **water** tiles in that sea zone become **`fullyVisible`** for that player, delegated to naval-movement-resolution; PlayerView construction (including Spy invisibility rules) is the single source for AI and order-suggestion visibility, never reading visibility directly from WorldState.
- **Coastal sea zone full visibility:** During Game Setup (after initial visibility) and every turn in End-of-turn (after fog decay), for each Great Power (including human): all tiles in sea zones that are adjacent (P–S in topology) to provinces that player fully owns are set to fullyVisible in WorldState; PlayerView reflects this; Tribes and Minor Nations do not receive this rule.
- **Immediate debug ownership-transfer visibility contract:** Given debug command `flip_province` applies canonical transfer successfully, when the command transaction completes, then the system applies immediate land ownership visibility changes and an immediate coastal sea-zone full-visibility normalization pass for affected Great Powers before control returns to callers.
- **Immediate debug reveal visibility contract:** Given debug command `reveal_province` applies successfully for a resolved province target, when the command transaction completes, then the system sets target province land tiles and directly adjacent sea-zone water tiles to `fullyVisible` for the human player in `WorldState.playerVisibilityByTile`, and if those tiles were already fully visible the command returns deterministic success/no-op feedback without mutating state.

- **Distant sea zone fog:** given a Great Power player, a sea zone S in region R, and water tile keys for S in `tileKeysByRegionAndProvince`, when End-of-turn runs after Movement and S is **not** P–S adjacent to any province owned by that player and that player has **no** fleet **at sea** in S, then every such water tile that is **not** `unknown` in that player’s visibility map is set to **fogged** before the coastal sea zone visibility pass; when that player **does** have a fleet **at sea** in S, water tiles in S are **not** forced to fogged by this rule solely due to lack of adjacent owned coast.

### Additional Given–When–Then acceptance criteria

- Given a player owns a province \(P\) and at least one tile in \(P\) is `fullyVisible` for that player  
  When any Spy belonging to that player leaves province \(P\) or is removed from the game  
  Then the system does not create or retain any spy reveal timer entry for \((player, P)\) and no tiles in \(P\) ever change visibility due to spy timers (own provinces remain fully visible and do not decay).

- Given a Spy belonging to player A is located in a province \(P\) owned by player B and \(P\) has at least one tile key in `tileKeysByRegionAndProvince`  
  When the system builds `PlayerView` for player A  
  Then all tile keys in province \(P\) are present in that `PlayerView.visibilityByTile` map with visibility `fullyVisible` for player A, regardless of their stored visibility in `WorldState.playerVisibilityByTile`, and any Spies owned by player B remain absent from that `PlayerView`.

- Given a Great Power owns a coastal province \(P\) and sea zone \(S\) is adjacent to \(P\) (P–S edge in topology) and the tile map has at least one tile in \(S\)  
  When game setup completes (before turn 0)  
  Then every tile key that belongs to sea zone \(S\) (second segment of tile key = \(S\)'s local id in that region) is set to `fullyVisible` for that player in `WorldState.playerVisibilityByTile`.

- Given a Great Power \(G\) owns no province with a P–S edge to sea zone \(S\) in region \(R\), and \(G\) has no fleet at sea in \(S\), and a water tile \(T\) in \(S\) is listed in `tileKeysByRegionAndProvince` for \(R\) with key \(S\), and \(G\)’s visibility for \(T\) is `fullyVisible`  
  When the system completes the End-of-turn **distant sea zone fog** step (before coastal sea zone full visibility)  
  Then \(G\)’s visibility for \(T\) in `WorldState.playerVisibilityByTile` is `fogged`.

- Given a Great Power \(G\) has a fleet at sea in sea zone \(S\) (same region as \(S\)) and \(G\) owns no coastal province adjacent to \(S\)  
  When the system completes the End-of-turn **distant sea zone fog** step  
  Then \(G\)’s visibility for water tiles in \(S\) is not set to `fogged` by that step solely because of missing adjacent owned coast (fleet presence preserves open-water visibility until the fleet leaves).

- Given a Great Power owns a coastal province \(P\) and sea zone \(S\) is adjacent to \(P\) (P–S edge in topology) and the tile map has at least one tile in \(S\)  
  When the system runs the End-of-turn phase including the coastal sea zone full visibility step  
  Then every tile key that belongs to sea zone \(S\) (second segment of tile key = \(S\)'s local id in that region) is set to `fullyVisible` for that player in `WorldState.playerVisibilityByTile`.

- Given a Great Power has no owned province adjacent to sea zone \(S\)  
  When the system runs the End-of-turn phase including the coastal sea zone full visibility step  
  Then the step does not add or change visibility for tiles in \(S\) for that player (their visibility remains from other sources only).

---

## Visibility test scenarios

The following scenarios must be covered by tests (unit tests in colonizethis_logic and/or sim_scenarios with fog assertions) to verify visibility behaviour including coastal sea zone full visibility.

| Scenario | Given | When | Then (assert) |
|----------|--------|------|----------------|
| **Coastal sea zone — game setup** | Game is initialized with a Great Power owning a coastal province P and sea zone S adjacent (P–S). | Game setup completes (before turn 0). | For that GP, every tile key in S has `tileVisibility` `fullyVisible`. |
| **Coastal sea zone — GP owns coastal** | Game with topology where a Great Power owns a coastal province P and sea zone S is adjacent (P–S). | End-of-turn has run (after turn 0 or later). | For that GP, every tile key in S has `tileVisibility` `fullyVisible`. |
| **Coastal sea zone — conquest** | GP1 does not own coastal province P; GP2 owns P; sea zone S adjacent to P. | Combat or Join Empire transfers P to GP1; turn resolves including End-of-turn. | For GP1, every tile in S has `tileVisibility` `fullyVisible`. |
| **Coastal sea zone — loss** | GP owns only one coastal province P adjacent to sea zone S; no fleet has ever entered S. | Combat (or other rule) transfers P to another faction; End-of-turn runs. | Coastal sea zone step does not set S's tiles to fullyVisible for that GP; visibility for S for that player is not forced (e.g. remains unknown or from other sources). |
| **Coastal sea zone — multiple GPs** | Two GPs each own different coastal provinces; each has at least one adjacent sea zone (same or different). | End-of-turn has run. | Each GP has `fullyVisible` only for sea zones adjacent to provinces they own; GP1 does not see GP2's exclusive adjacent sea zones as fully visible unless also adjacent to GP1's province. |
| **Human player** | Human is a Great Power and owns a coastal province P; S adjacent to P. | End-of-turn has run. | Human player's visibility for all tiles in S is `fullyVisible` (same rule as other GPs). |
| **Tribes / minors** | Tribe or Minor Nation owns a coastal province (if scenario supports it). | End-of-turn has run. | Coastal sea zone full visibility is not applied for tribes/minors; their sea zone visibility is from other sources only (e.g. ship reveal) per GP-only rule. |

Sea zone tile keys use the same format `regionId|provinceId|x|y` where the second segment is the **sea zone local id** for water cells; sea-zone tile buckets are keyed by canonical prefixed sea-zone id (`regionId|localSeaZoneId`) in `tileKeysByRegionAndProvince` (see [map-data.md](map-data.md), [world-model-identity.md](../game/world-model-identity.md)). Sim_scenarios fog assertions use `player`, `tileKey`, and `tileVisibility` per [sim-scenarios.md](sim-scenarios.md) § Fog/exploration assertions.
