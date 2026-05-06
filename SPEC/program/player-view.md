## PlayerView (per-player knowledge)

**SPEC/program** — Deterministic, fog-of-war-limited projection of `Game` for a single player. Game design: [fog-and-exploration.md](../game/fog-and-exploration.md). Resolution: [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).

---

### Purpose

`PlayerView` is a **read-only projection** of the full world state for one Great Power `P`. It encodes exactly what `P` is allowed to know under fog of war and exploration rules, and is used by:

- AI planners (strategic and tactical).
- Order suggestion APIs.
- **Province / sea zone detail overlay:** `foreignCivilianVisibleToPlayer` uses `PlayerView` tile visibility to decide whether non-owned civilian units appear in the Civilian section and tile civilian count ([province-sea-zone-detail-overlay.md](../ui/province-sea-zone-detail-overlay.md)).
- **Map province-label presence icons:** app map labels use PlayerView-derived province class presence (civilian, regiment, ship) and suppress icons when intel does not expose class presence for that province ([map-widget.md](../ui/map-widget.md)).
- Debug tooling that wants to reason from a player's perspective.

AI and suggestion code must treat `PlayerView` as the **source of truth** for map and opponent information; it may not read hidden data directly from `Game`.

**Single source of truth for visibility:** PlayerView (derived from `WorldState.playerVisibilityByTile` and related state) is the single source of truth for per-player visibility used by both the **order suggestion API** and the **order engine** when validating with context. Neither the suggester nor the engine may use raw `Game` or `WorldState` for visibility; both must use the same visibility view (PlayerView or the same derivation). See [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md) for order visibility rules.

---

### Principle: PlayerView as channel

When obtaining information from the map or submitting orders from a player's perspective, everything must go through **PlayerView**. Direct access to or modification of world state is only appropriate in a small set of cases (e.g. authoritative turn resolution, save/load, debug omniscient tools). AI, order suggestion, order validation, and any UI that reasons "as" a player must use PlayerView (and the same visibility, unit, and province data it exposes).

---

### Contents

For a given `Game`, `MapTopology`, and `playerId`:

- **Visibility and prospecting**
  - Tile visibility: `Map<TileKey, VisibilityLevel>` taken from the game's visibility state.
  - Prospected tiles: `Set<TileKey>` indicating where minerals are known.
  - Derived explore scope semantics input: `visibilityByTile` is the sole visibility input used by order-suggestion logic to compute per-player partially-revealed provinces (`known` + `unknown` mix in the same prefixed province). App UI may cache that computed scope for selection UX, but the semantic definition remains this PlayerView-derived rule.
- **Map knowledge**
  - Known provinces with at least `revealed` visibility, including:
    - Province id (prefixed form per [world-model-identity.md](../game/world-model-identity.md)) and owner id (or `null` if unknown).
    - Whether this is one of `P`'s own provinces (always fully visible).
    - Last-known terrain/resources/improvements for tiles with `fogged` or `fullyVisible` visibility.
- **Own state**
  - All units owned by `P`, including civilian tile positions.
  - Economy: worker pool, stockpile, treasury.
  - Research: unlocked techs and current research slot assignments.
- **Diplomacy**
  - Relations between `P` and other factions (peace/war/etc.) needed for order validation.
- **Naval state** (when naval is in scope): Own fleets (sea zone, mission, ship list); known sea zones and ports; for visibility-allowed sea zones, any enemy or neutral fleet presence so the AI can issue naval orders (move, patrol, blockade, beachhead) and the order suggestion API can propose valid naval candidates. See [ships-and-naval.md](../game/ships-and-naval.md), [naval-movement-resolution.md](naval-movement-resolution.md).

`PlayerView` deliberately omits:

- Exact enemy unit or garrison positions, except where later enabled by spy/intel rules.
- Hidden mineral resources on unprospected tiles.

---

### Construction and determinism

`buildPlayerView(game, topology, playerId)` must:

- Be a **pure function**: same inputs → same `PlayerView`.
- Only expose information allowed by the fog-of-war rules.
- Never branch on hidden data when computing AI decisions; any such logic must instead depend on what `PlayerView` exposes.

All AI and order suggestion APIs MUST accept a `PlayerView` for their world knowledge, plus shared rules/configuration (unit catalogs, tech catalogs, etc.).

