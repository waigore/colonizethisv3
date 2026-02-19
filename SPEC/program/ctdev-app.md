# ctdev — ColonizeThis Dev App

**SPEC/program** — Flutter dev-only application for debug/diagnostic visualization. Consumes init_game outputs and shared map view models; not player-facing.

---

## Purpose and Scope

- **Purpose:** Provide developers/designers with a lightweight way to run init-game-style map generation from a UI, load savegames, and view rich debug overlays (ownership, capitals, ports) without player UX constraints.
- **Scope:** Dev tooling only; ctdev is not shipped to players. Primarily run as a desktop app (macOS); web supported but may feel less responsive.

---

## Main Flows

- **Init Game:** Home → Init Game Config Screen (form mirrors `GameSetupConfig`). On submit: validate, call `runInitGame`, save game, navigate to Init Game Map Debug. See [ctdev-app-init-map.md](ctdev-app-init-map.md).
- **Load Savegame:** Select saved game, load via colonizethis_save, build `InitGameMapViewData`, navigate to Init Game Map Debug.
- **Start Game (Sim):** From Init Game Map Debug, press Start Game → creates Sim Game controller, navigates to Running Game Screen. See [ctdev-app-running-game.md](ctdev-app-running-game.md).

---

## Main Screens / Tabs

| Screen | Route / Tab | Content |
|--------|-------------|---------|
| Init Game Config | Home flow | Form: GP select, counts, seed, colour overrides, Render PNG; submit runs init_game. |
| Init Game Map Debug | After init or load | OW + NW map, overlays, legend, toggles, per-cell inspection; AI selector; Start Game button. |
| Running Game | After Start Game | Control bar (Next Player, Resolve Turn, Next Turn, Fast-forward 10); tabs: Map, Game Overview, Orders (AI history), Player (GP) tabs. |

---

## Common Patterns

- **Loading state:** Init-game and sim runs wrap work in a busy overlay; submit/controls disabled during resolution.
- **Map rendering:** `CustomPainter` over `RegionMapViewData`, `InteractiveViewer` for pan/zoom; `kDebugMapScale` 1.0; ownership from `greatPowerColorOverride` when present.
- **Data source:** All screens read from `InitGameResult`, loaded `Game`, or `SimGameController.game` / `SimGameController.pendingOrdersByPlayerId`.

---

## Relationship to init_game CLI

`tool/init_game` remains a headless CLI (savegames, optional PNG/markdown). ctdev is the canonical visualization surface: developers run init-game flows inside ctdev or load CLI-generated saves.
