# Fog and Exploration Resolution

## Responsibility

Maintains per-player visibility and prospected state on world state; resolves exploration and prospecting work orders; constructs PlayerView for AI and tooling. Game rules: [fog-and-exploration.md](../game/fog-and-exploration.md).

---

## Data Model

**Visibility state:** `Map<playerId, Map<tileKey, VisibilityLevel>>` — enum: unknown, revealed, fogged, fullyVisible. Tile key format: `regionId|provinceId|x|y`. Province and tile key formats: [world-model-identity.md](../game/world-model-identity.md). Stored on WorldState.

**Prospected state:** `Map<playerId, Set<tileKey>>` — tiles the player has prospected. Only mineral-eligible terrain per game rules.

**Spy reveal timer:** `Map<playerId, Map<provinceKey, int>>` — for each player, provinces that were previously revealed by a Spy and are now fog-decaying: value = turns left until tiles in that province are set back to fogged (0 = already fogged). When a Spy **leaves** a non-owner province, set timer to 5 for (Spy owner, that province). Stored on WorldState.

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

**Fog decay (Spy):** When a Spy **leaves** a province (move or removal), start a 5-turn timer for (Spy owner, that province). At end of turn: decrement all spy-reveal timers; for each (player, province) where timer reaches 0, set all tiles in that province to fogged for that player. (Explorer/Spy fog decay: if no Explorer/Spy remain in an other-faction province, also set tiles to fogged unless a Spy timer is active.)

**Fog decay** (End-of-turn phase):

1. Decrement spy reveal timers; where timer hits 0, set that province's tiles to fogged for that player.
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
- Extraction gating (mineral prospecting + connectivity) is enforced by the extraction pipeline, not this module.
- Order visibility rules are defined in game/fog-and-exploration.md; this module enforces them at validation time via PlayerView.

---

## Acceptance criteria

- **Exploration timing and scope:** Exploration work orders use the region-scoped timing formula (`ceil(3 * tilesInP / maxTilesInAnyProvinceInRegion)`) and, on completion, set all tiles in the target province to fullyVisible for the exploring player only.
- **Prospecting:** Prospect work orders validate that the target tile is mineral-eligible per game rules; on completion the tile is added to the player's prospected set in WorldState and does not change visibility by itself.
- **Spy reveal and decay:** While a Spy is present in a non-owner province, that province is fully visible to the Spy's owner via PlayerView; when the Spy leaves, a 5-turn per-(player, province) timer is started and, when it reaches 0, tiles in that province decay to fogged for that player (other-faction provinces only; own provinces never decay).
- **Explorer/Spy fog decay:** At end of turn, for each other-faction province where the player previously had Explorer/Spy presence, if no Explorer/Spy remains and no Spy timer is active, all tiles in that province decay to fogged while preserving last-known state.
- **Ship reveal and integration:** When a fleet enters a sea zone, coastal tiles of adjacent provinces become revealed for that player, delegated to naval-movement-resolution; PlayerView construction (including Spy invisibility rules) is the single source for AI and order-suggestion visibility, never reading visibility directly from WorldState.
