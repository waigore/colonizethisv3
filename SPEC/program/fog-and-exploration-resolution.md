# Fog and Exploration Resolution

**SPEC/program** — Visibility state, prospected state, and resolution logic. Game design: [fog-and-exploration.md](../game/fog-and-exploration.md). Ship reveal: [naval-movement-resolution.md](naval-movement-resolution.md).

---

## Visibility State

`Map<playerId, Map<tileKey, VisibilityLevel>>` where `VisibilityLevel` is `unknown | revealed | fogged | fullyVisible`. Stored in WorldState (e.g. `WorldState.playerVisibility` or `Player.visibilityByTile`). Tile key format: `regionId|provinceId|x|y`.

---

## Prospected State

`Map<playerId, Set<tileKey>>` — tiles the player has prospected. Per [resource-terrain-region-rules](../game/resource-terrain-region-rules.md); only mineral tiles (swamp, hills, mountain) are prospect-eligible. Minerals: iron, copper, tin, coal, silver, gold, gems, diamonds.

---

## Tile-Level Unit

Civilian units have `provinceId` and `tileKey` (format `regionId|provinceId|x|y`). Military units remain province-only.

---

## WorkOrder Resolution: Explore

When Explorer has WorkOrder target `explore` in province P: add progress toward full province reveal. Turns required = `ceil(3 * tilesInP / maxTilesInAnyProvince)`. When complete, set all tiles in P to `fullyVisible` for that player. Resolution in Build/work phase. See [orders.md](orders.md), [turn-resolution-phases.md](turn-resolution-phases.md).

---

## WorkOrder Resolution: Prospect

When Explorer has WorkOrder target `prospect` on tile T: if T is mineral-eligible (swamp, hills, mountain per I2 terrain), add T to player's prospected set. One turn per prospect. Resolution in Build/work phase.

---

## Fog Decay

At end of turn (or when unit leaves): for each other-faction province where player had Explorer/Spy working, if no Explorer/Spy remains, set all tiles in that province to `fogged` (retain last visible state). Own provinces never decay. Run in End-of-turn phase or after Movement.

---

## Ship Reveal

When fleet enters sea zone S (naval movement phase): for each coastal province P adjacent to S, set all coastal land tiles of P to `revealed` for that player. Implemented in [naval-movement-resolution.md](naval-movement-resolution.md).

---

## Extraction Gating

In `resource_extractor.dart`: for mineral resources (iron, copper, tin, coal, silver, gold, gems, diamonds), only extract from tiles that are (a) in player's connectivity and (b) in player's prospected set. Non-minerals unchanged.

---

## Phase Integration

- **Movement:** Land movement; naval movement (ship reveal on fleet enter).
- **Build/work:** Exploration progress; prospect (add to prospected set).
- **End-of-turn:** Fog decay for other-faction provinces with no Explorer/Spy.

---

## PlayerView consumers

Resolution code maintains the authoritative visibility and prospected state on `WorldState`. A separate `buildPlayerView(game, topology, playerId)` helper (see `player-view.md`) derives a **per-player view** from this state for AI and tooling. All AI and order suggestion logic must read visibility and prospecting **through PlayerView**, never by directly inspecting hidden tiles or enemy units on `WorldState`.
