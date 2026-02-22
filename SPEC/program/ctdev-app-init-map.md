# ctdev — Init Game Config and Map Debug

**SPEC/program** — Init Game Config Screen, Init Game Map Debug Screen, and Start Game flow. Overview: [ctdev-app.md](ctdev-app.md).

---

## Init Game Config Screen

Form mirroring `GameSetupConfig`: `selectedGreatPowerIds` (checkboxes for the seven GPs; at least one required), `minorNationCount`, `tribeCount`, `numProvincesOldWorld`, `numProvincesNewWorld`, `continentCount`, `seed`, minimum provinces per Minor Nation. When Prussia is selected: leader variant (Frederick the Great | Frederick William) via `leaderVariantByGpId['prussia']`.

- **Defaults:** Prefilled from `GameSetupConfig.defaultConfig`.
- **Seed:** Blank by default; optional. Positive integer → deterministic `GameSetupConfig.seed`. Blank or 0 → ctdev passes 0; `runInitGame` derives effective seed from current time; reproducibility not guaranteed unless effective seed is captured.
- **Render PNG checkbox:** Dev-only, default unchecked; controls whether combined map PNG is rendered.
- **Colour per GP:** Dropdown per selected GP; defaults to GDD colour. If user picks a colour already used, the two GPs swap colours. Stored in `greatPowerColorOverride` (InitGameOptions/InitGameResult).

On submit: validate constraints; call `runInitGame(config, options)` with fixed `cellSize`, `renderPng`, `greatPowerColorOverride`; show loading overlay; save game; navigate to Init Game Map Debug with `InitGameMapViewData`.

---

## Init Game Map Debug Screen

**Input:** `InitGameMapViewData` plus optional seed/config summary.

**Layout:** OW and NW regions side by side. `CustomPainter` over `RegionMapViewData`, `InteractiveViewer` for pan/zoom. `kDebugMapScale` 1.0.

**Overlays:** Ownership (GP/Tribes vibrant, Minor Nations grey); legend as `displayName (factionId)`; province/sea borders; capitals (gold circles), ports (teal squares). Geographic view: terrain palette, resource glyphs (g, t, i, etc.) at tile centres; compact glyph reference and per-region counts (OW/NW). Per-cell inspection: tap/hover shows region, tile coords, Province, owner, terrain, resource; capital tiles show "Capital of [faction]." Toggleable layers: ownership, borders, capitals, ports, on-tile labels.

---

## Pre–Start Game (Sim)

Map, legend, toggles, **AI selector** (Sim Game AI | AI Planner; when AI Planner: "Use full AI" checkbox), **Start Game (Sim)** button. No Next Player / Resolve Turn / Next Turn / Fast-forward (those are on [ctdev-app-running-game.md](ctdev-app-running-game.md)).

---

## Start Game Action

On Start Game: (1) Generate sim session ID; create `logs/ctdev-sim-<sessionId>.log`; flush buffered logs. (2) Take `Game` from InitGameResult or loaded save. (3) Set `aiControlByGpId` true for all GPs. (4) Capture `MapTopology` and tile-map data. (5) Choose deterministic `baseSeed` (from init seed; optionally overridable). (6) Ensure `aiSeedByGpId` populated for all GPs (for `turnSeed[P, T]`). (7) Create Sim Game controller (Game, MapTopology, baseSeed, per-turn log). (8) Navigate to Running Game Screen.

**Turn resolution:** `resolveTurnForGame` runs full TurnResolver ([turn-resolution-phases.md](turn-resolution-phases.md)), including Naval Interception & Naval Combat when naval is in scope.
