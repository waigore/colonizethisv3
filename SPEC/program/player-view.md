## PlayerView (per-player knowledge)

**SPEC/program** — Deterministic, fog-of-war-limited projection of `Game` for a single player. Game design: [fog-and-exploration.md](../game/fog-and-exploration.md). Resolution: [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md).

---

### Purpose

`PlayerView` is a **read-only projection** of the full world state for one Great Power `P`. It encodes exactly what `P` is allowed to know under fog of war and exploration rules, and is used by:

- AI planners (strategic and tactical).
- Order suggestion APIs.
- Debug tooling that wants to reason from a player's perspective.

AI and suggestion code must treat `PlayerView` as the **source of truth** for map and opponent information; it may not read hidden data directly from `Game`.

---

### Contents

For a given `Game`, `MapTopology`, and `playerId`:

- **Visibility and prospecting**
  - Tile visibility: `Map<TileKey, VisibilityLevel>` taken from the game's visibility state.
  - Prospected tiles: `Set<TileKey>` indicating where minerals are known.
- **Map knowledge**
  - Known provinces with at least `revealed` visibility, including:
    - Province id and owner id (or `null` if unknown).
    - Whether this is one of `P`'s own provinces (always fully visible).
    - Last-known terrain/resources/improvements for tiles with `fogged` or `fullyVisible` visibility.
- **Own state**
  - All units owned by `P`, including civilian tile positions.
  - Economy: worker pool, stockpile, treasury.
  - Research: unlocked techs and current research slot assignments.
- **Diplomacy**
  - Relations between `P` and other factions (peace/war/etc.) needed for order validation.

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

