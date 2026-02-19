# Province Identity and Lookup (Multi-Region)

**SPEC/game** — Province identity rules for a multi-region world. Part of the GDD world model. See [world-model.md](world-model.md).

---

## Why Prefixed Province Ids

In a multi-region world, **province lookup must always use regionId + provinceId**. A bare province id is not sufficient: the same local id can exist in more than one region (e.g. `p1` in Old World and `p1` in New World).

---

## Game-State Province Id Format

All province ids stored in game state (e.g. Province id, Unit province location, Player capital, order fields) use a **prefixed** form: `regionId|localId` (e.g. `oldWorld|p1`, `newWorld|nw1`). This makes every province id globally unique and prevents a province from being resolved in the wrong region.

---

## Tile Key Format

Tile keys remain 4-part: `regionId|localId|x|y`. The second segment is the **local** province id (as in topology/tile maps); the full province id is `regionId|localId`.

---

## Map Visualizer Identity Rules

When turning topology/tile maps into view models (ownership fill, per-player maps, unit markers), logic MUST first derive the full province id from the region + local id before reading any game state.

- **Ownership:** Convert region + local cell id (e.g. `oldWorld` + `p1`) into `oldWorld|p1` and use that full id to query province owner.
- **Province names:** Resolve full id (`oldWorld|p1` / `newWorld|p1`) into the corresponding Province and use its display name.
- **Unit markers:** Build a map from **full** province id (`regionId|localId`) to a representative tile (x, y), then place markers by looking up units via their province id (also full). Do not key these maps by bare local ids.

---

## Lookup Rule

Logic must never locate a province by province id alone. Use (regionId, provinceId) or a prefixed full id, and resolve the province only within that region. Do **not** infer region by searching regions in sequence or by string heuristics. If a province cannot be found, treat it as a logic error; do not fall back to a default region.
