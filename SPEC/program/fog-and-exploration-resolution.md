# Fog and Exploration Resolution

## Responsibility

Maintains per-player visibility and prospected state on world state; resolves exploration and prospecting work orders; constructs PlayerView for AI and tooling. Game rules: [fog-and-exploration.md](../game/fog-and-exploration.md).

---

## Data Model

**Visibility state:** `Map<playerId, Map<tileKey, VisibilityLevel>>` — enum: unknown, revealed, fogged, fullyVisible. Tile key format: `regionId|provinceId|x|y`. Stored on WorldState.

**Prospected state:** `Map<playerId, Set<tileKey>>` — tiles the player has prospected. Only mineral-eligible terrain per game rules.

**Source province:** A unit's source province is derived from its tileKey (for civilians) or provinceId. Must not be unknown; raises exception if so.

---

## Algorithm / Flow

**Exploration resolution** (Build/Work phase):

1. For each Explorer with work order `explore` in province P, accumulate progress.
2. Turns required per game rules: `ceil(3 * tilesInP / maxTilesInAnyProvince)`.
3. On completion, set all tiles in P to fullyVisible for that player.

**Prospect resolution** (Build/Work phase):

1. For each Explorer with work order `prospect` on tile T, verify T is mineral-eligible.
2. Add T to player's prospected set. One turn.

**Fog decay** (End-of-turn phase):

1. For each other-faction province where player had Explorer/Spy, if none remain, set all tiles to fogged (retain last-known state).
2. Own provinces never decay.

**Ship reveal** (Naval Movement phase):

1. When fleet enters sea zone S, set all coastal land tiles of adjacent provinces to revealed for that player.
2. Delegated to [naval-movement-resolution.md](naval-movement-resolution.md).

**PlayerView construction:**

`buildPlayerView(game, topology, playerId)` derives a per-player view from authoritative world state. Includes: tile visibility map, prospected set, last-known terrain/resources/improvements, province ownership, player's own units/economy/research. All AI and order suggestion logic must read through PlayerView, never directly from world state. See [player-view.md](player-view.md).

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
