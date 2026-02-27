# Fog and Exploration Resolution

## Responsibility

Maintains per-player visibility and prospected state on world state; resolves exploration and prospecting work orders; constructs PlayerView for AI and tooling. Game rules: [fog-and-exploration.md](../game/fog-and-exploration.md).

---

## Data Model

**Visibility state:** `Map<playerId, Map<tileKey, VisibilityLevel>>` — enum: unknown, revealed, fogged, fullyVisible. Tile key format: `regionId|provinceId|x|y` (second segment = local province id; full province id = `regionId|localId` per [world-model-identity.md](../game/world-model-identity.md)). Any province id used in visibility or Spy timer state (e.g. keys keyed by province) must be the **prefixed** form (`regionId|localId`) per world-model-identity.md for multi-region correctness. Stored on WorldState.

**Prospected state:** `Map<playerId, Set<tileKey>>` — tiles the player has prospected. Only mineral-eligible terrain per game rules.

**Spy reveal timer:** `Map<playerId, Map<provinceKey, int>>` — for each player, provinces that were previously revealed by a Spy and are now fog-decaying: value = turns left until tiles in that province are set back to fogged (0 = already fogged). `provinceKey` is the **prefixed** province id (`regionId|localId`) per [world-model-identity.md](../game/world-model-identity.md). When a Spy **leaves** a **non-owner** province, set timer to the Spy fog decay turns (default 5; see [fog-and-exploration.md](../game/fog-and-exploration.md) § Configurable Values) for (Spy owner, that province). **Spy timers MUST NEVER be created for a player's own provinces**, and any existing timers for own provinces MUST be ignored (and may be cleared) during decay so they cannot affect visibility. Stored on WorldState.

**Source province:** A unit's source province is derived from its tileKey (for civilians) or provinceId. Must not be unknown; raises exception if so.

---

## Algorithm / Flow

**Exploration resolution** (Build/Work phase):

1. For each Explorer with work order `explore` in province P, accumulate progress.
2. Turns required per game rules: `ceil(3 * tilesInP / maxTilesInAnyProvinceInRegion)`, where `maxTilesInAnyProvinceInRegion` is the maximum tile count in any province **in the same region** as the Explorer's province.
3. On completion, set all tiles in P to fullyVisible for that player.

**Prospect resolution** (Build/Work phase):

1. For each Explorer with work order `prospect` on tile T, verify T is mineral-eligible.
2. Add T to player's prospected set. One turn.

**Spy presence reveal:** When building visibility (or PlayerView), for each Spy in a **non-owner** province, that province's tiles are treated as **fully visible** for the Spy's owner for as long as the Spy is there.

**Fog decay (Spy):** When a Spy **leaves** an **other-faction** province (move or removal), start a timer for (Spy owner, that province) with duration = Spy fog decay turns (default 5; see GDD § Configurable Values). **Do not start timers when a Spy leaves their own provinces.** At end of turn: decrement all spy-reveal timers; for each (player, province) where timer reaches 0, set all tiles in that province to fogged for that player. (Explorer/Spy fog decay: if no Explorer/Spy remain in an other-faction province, also set tiles to fogged unless a Spy timer is active.)

**Fog decay** (End-of-turn phase):

1. Decrement spy reveal timers; where timer hits 0, set that province's tiles to fogged for that player **only when the province is owned by another faction**. Timers for a player's own provinces are ignored and cleared without changing visibility.
2. For each other-faction province where player had Explorer/Spy, if none remain (and no Spy timer), set all tiles to fogged (retain last-known state).
3. Own provinces never decay.

**Ship reveal** (Naval Movement phase):

1. When fleet enters sea zone S, set all coastal land tiles of adjacent provinces to revealed for that player.
2. Delegated to [naval-movement-resolution.md](naval-movement-resolution.md).

**PlayerView construction:**

`buildPlayerView(game, topology, playerId)` derives a per-player view from authoritative world state. Includes: tile visibility map, prospected set, last-known terrain/resources/improvements, province ownership, player's own units/economy/research. All AI and order suggestion logic must read through PlayerView, never directly from world state. See [player-view.md](player-view.md).

**Spy invisibility:** When building PlayerView for player P, any unit of type Spy owned by **another** player is **excluded** from P's view (unit list and province occupancy). Spy locations are never visible to other players; only the Spy's owner sees their own Spies.

---

## Integration

| Phase | Action |
|---|---|
| Naval Movement | Ship reveal (coastal tiles → revealed) |
| Build/Work | Exploration progress; prospect resolution |
| End-of-turn | Fog decay for provinces without Explorer/Spy |

**Upstream:** World state (provinces, tile map, units, owners).

**Downstream:** PlayerView consumed by AI, order suggestion API, order validation engine.

---

## Constraints

- Visibility and prospected state are authoritative on WorldState; PlayerView is derived (read-only).
- Ship coastal reveal and fog decay logic resolve provinces by `(regionId, provinceId)` or prefixed id only; see [world-model-identity.md](../game/world-model-identity.md).
- Extraction gating (mineral prospecting + connectivity) is enforced by the extraction pipeline, not this module.
- Order visibility rules are defined in game/fog-and-exploration.md; this module enforces them at validation time via PlayerView.

---

## Acceptance criteria

- **Exploration timing and scope:** Exploration work orders use the region-scoped timing formula (`ceil(3 * tilesInP / maxTilesInAnyProvinceInRegion)`) and, on completion, set all tiles in the target province to fullyVisible for the exploring player only.
- **Prospecting:** Prospect work orders validate that the target tile is mineral-eligible per game rules; on completion the tile is added to the player's prospected set in WorldState and does not change visibility by itself.
- **Spy reveal and decay:** While a Spy is present in a non-owner province, that province is fully visible to the Spy's owner via PlayerView; when the Spy leaves, a per-(player, province) timer (duration = Spy fog decay turns, default 5 per GDD Configurable Values) is started **only if the province is owned by another faction** and, when it reaches 0, tiles in that province decay to fogged for that player. Spy timers MUST NOT be created for a player's own provinces and MUST NOT change visibility in own provinces.
- **Explorer/Spy fog decay:** At end of turn, for each other-faction province where the player previously had Explorer/Spy presence, if no Explorer/Spy remains and no Spy timer is active, all tiles in that province decay to fogged while preserving last-known state.
- **Ship reveal and integration:** When a fleet enters a sea zone, coastal tiles of adjacent provinces become revealed for that player, delegated to naval-movement-resolution; PlayerView construction (including Spy invisibility rules) is the single source for AI and order-suggestion visibility, never reading visibility directly from WorldState.

### Additional Given–When–Then acceptance criteria

- Given a player owns a province \(P\) and at least one tile in \(P\) is `fullyVisible` for that player  
  When any Spy belonging to that player leaves province \(P\) or is removed from the game  
  Then the system does not create or retain any spy reveal timer entry for \((player, P)\) and no tiles in \(P\) ever change visibility due to spy timers (own provinces remain fully visible and do not decay).

- Given a Spy belonging to player A is located in a province \(P\) owned by player B and \(P\) has at least one tile key in `tileKeysByRegionAndProvince`  
  When the system builds `PlayerView` for player A  
  Then all tile keys in province \(P\) are present in that `PlayerView.visibilityByTile` map with visibility `fullyVisible` for player A, regardless of their stored visibility in `WorldState.playerVisibilityByTile`, and any Spies owned by player B remain absent from that `PlayerView`.
