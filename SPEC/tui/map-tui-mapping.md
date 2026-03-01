# Map TUI mapping

**SPEC/tui** — Ctterm’s mapping from map/PlayerView data to terminal display. Base data comes from [SPEC/program/map-visualization.md](../program/map-visualization.md) and [SPEC/program/player-view.md](../program/player-view.md); ctterm is a consumer and defines only the terminal representation.

---

## Responsibility

- Define how terrain, province ownership, capitals, ports, visibility, and other map data are rendered in the terminal (characters, symbols, colors/styles).
- Single place for implementors to extend or change the TUI map look without touching game logic.

---

## Data source

- **Base layer data:** Same as map-visualization and player-view: tile keys (`regionId|localId|x|y`), terrain, resources, province ownership, capitals, ports, visibility (fog, revealed, fully visible).
- **No logic here:** This doc describes only the **display mapping**. Province identity and visibility rules are in world-model-identity and player-view.

---

## Placeholder mapping (to implement)

| Data | Terminal representation (placeholder) |
|------|----------------------------------------|
| Terrain (e.g. land, sea) | Character or symbol per terrain type (e.g. `.` land, `~` water). Extend per ruleset. |
| Province ownership | Color or style per owner (e.g. distinct terminal colors for each GP). |
| Capital | Symbol or marker (e.g. `*` or `C`) on capital tile. |
| Port | Symbol (e.g. `#`) on port tile. |
| Visibility | Fog = dimmed or `?`; revealed = outline; fully visible = full detail. |

Exact characters and palette are implementation choices; document them in ctterm code or comments and keep this spec updated when the mapping is finalized.

---

## Cross-references

- [ctterm.md](ctterm.md) §2 Map (ASCII/Unicode art), §5 Development setup
- [SPEC/program/map-visualization.md](../program/map-visualization.md) — data contract
- [SPEC/game/world-model-identity.md](../game/world-model-identity.md) — province/tile keys
