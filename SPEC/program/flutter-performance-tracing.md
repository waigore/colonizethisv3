# Flutter performance tracing

**Scope:** Optional instrumentation to attribute wall time for (1) **New Game** → game screen interactable (GitHub #1710) and (2) **Development panel** open-path sync work (GitHub #4175 Slice E). Complements manual **profile/release** DevTools sessions; does not replace them. Game-app panel/dialog/overlay opens are a **hard 1 000 ms full-load** budget ([ui-surface-budget.md](ui-surface-budget.md)): markers must cover required calculations, minimaps, and Yarn — not first chrome only.

---

## Timeline (Dart DevTools → Performance)

Markers use prefix **`CtAppPerf.`** (filter in the timeline).

### New-game → game screen

| Marker | When |
|--------|------|
| `CtAppPerf.newGameAsync.begin` | First line of `GameService.createNewGameAsync` (after initial UI yield). |
| `CtAppPerf.newGameAsync.phase_0` … `phase_4` | Immediately before each coarse setup phase (aligned with `onProgress` indices 0–4). |
| `CtAppPerf.newGameAsync.complete` | After persist; immediately before returning the new `Game`. |
| `CtAppPerf.navigate.game` | Immediately before emitting `NavigateToRouteEvent(Routes.game)` from new-game setup. |
| `CtAppPerf.mapViewDataProvider.build` | Synchronous `mapViewDataProvider` body (single timeline slice per invalidation). |
| `CtAppPerf.intro.asset_load.begin` / `end` | Before/after loading the intro Yarn asset string. |
| `CtAppPerf.intro.dialogue_begin` | Immediately before `DialogueRunner.startDialogue`. |
| `CtAppPerf.intro.first_line` | First `onStateChanged` callback where `line != null`. |

### Development panel open path (Slice E)

| Marker | When |
|--------|------|
| `CtAppPerf.development.readModelReady` | Post-frame gate flips so overview/list may build (instant). |
| `CtAppPerf.development.interactiveReady` | First frame overview/list/Assign affordance build after read model is available (instant). |
| `CtAppPerf.developmentPanel.connectivity` | Sync `resolveDevelopmentPanelConnectivity` in provider. |
| `CtAppPerf.developmentPanel.staticContext` | Sync `buildPlayerView` + display-name maps in provider. |
| `CtAppPerf.developmentPanel.sharedContext` | Sync idle/connectivity slice from draft orders. |
| `CtAppPerf.developmentPanel.regionScopes.<regionId>` | Sync improvable scopes + extraction for one region. |
| `CtAppPerf.developmentPanel.regionModel.<regionId>` | Sync compose of scopes + assigned civilians for one region. |
| `CtAppPerf.developmentPanel.assignRowCache.<regionId>` | Sync assign-affordance cache for one region tab. |
| `CtAppPerf.developmentPanel.mapSnapshot.<regionId>` | Sync `buildDevelopmentPanelMapSnapshot` for one region minimap. |

Filter `CtAppPerf.development` to isolate panel-open slices. Lazy OW-only open should show Old World `regionScopes` / `regionModel` before any New World counterparts.

### Province sea-zone overlay open path (Refs #4690)

| Marker | When |
|--------|------|
| `CtAppPerf.provinceOverlay.interactiveReady` | Post-frame after narrow/wide chrome + default Political tab body mount (instant). |
| `CtAppPerf.provinceOverlay.humanConnectivity` | Sync human capital-link connectivity for overlay tile previews. |
| `CtAppPerf.provinceOverlay.provinceReadModel.<displayId>` | Sync province-wide extraction/available/town-bonus bundle for one province/sea display id. |

Filter `CtAppPerf.provinceOverlay` for MAP20001 open-path DevTools sessions. The **1.0 s open-to-interactive** wall-clock gate is profile/release on binding hosts (PR evidence); CI covers lazy-tab structural invariants, not debug wall-clock assertions.

### Empire-rail panel open path (Refs #4688)

| Marker | When |
|--------|------|
| `CtAppPerf.production.interactiveReady` | Post-frame after `GAME20001` chrome + Available/Allocation primary body mount (instant; counsel stars may follow in a later frame). |
| `CtAppPerf.production.openPath` | Sync slice for stockpile preview, labour readiness, and forces feeding (`productionPanelOpenPathProvider`). |
| `CtAppPerf.production.industryCounsel` | Deferred industry counsel ranking for Allocation stars (`productionPanelIndustryCounselProvider`). |
| `CtAppPerf.trade.interactiveReady` | Post-frame after `GAME60001` chrome + default Market tab body mount (instant; Deal Book tab deferred via `lazyTabBodies`). |
| `CtAppPerf.civilianUnits.interactiveReady` | Post-frame after `UNIT10001` sheet chrome + primary list mount. |
| `CtAppPerf.militaryUnits.interactiveReady` | Post-frame after `UNIT20001` sheet chrome + primary list mount. |
| `CtAppPerf.militaryUnits.treeBuild` | Sync military tree assembly (`resolveUnitsPanelMilitaryGroups`). |
| `CtAppPerf.navalUnits.interactiveReady` | Post-frame after `UNIT30001` sheet chrome + primary list mount. |
| `CtAppPerf.navalUnits.treeBuild` | Sync naval tree assembly (`resolveUnitsPanelNavalTree`). |
| `CtAppPerf.diplomacy.interactiveReady` | Post-frame after `GAME30001` chrome + faction-row list mount. |
| `CtAppPerf.diplomacy.rowsBuild` | Sync `buildDiplomacyRows` in `diplomacyPanelRowsProvider`. |
| `CtAppPerf.technology.interactiveReady` | Post-frame after `GAME40001` chrome + default Research Slots tab body mount (Tree tab deferred until selected). |
| `CtAppPerf.victory.interactiveReady` | Post-frame after `GAME70001` chrome + standings + political minimap mount. |
| `CtAppPerf.victory.openPath` | Sync standings, ownership colours, and OW minimap view-data bundle (`victoryPanelOpenPathProvider`). |
| `CtAppPerf.development.*` | See § Development panel open path (`GAME80001`). |

Filter `CtAppPerf.production`, `CtAppPerf.trade`, `CtAppPerf.diplomacy`, `CtAppPerf.technology`, `CtAppPerf.victory`, or `CtAppPerf.*Units` for empire-rail DevTools sessions. `GAME90001` Counsel-from-rail markers remain follow-up. The **1.0 s open-to-interactive** wall-clock gate is profile/release on Linux desktop and Android emulator (PR DevTools evidence); CI uses µs profiling anchors in `empire_rail_panel_open_path_timing_test.dart`, not debug wall-clock assertions.

---

## Log lines (app package, `info`)

Correlate with session buffer / grep. Messages omit repeating the logger prefix per `SPEC/program/logging/logging.md`.

| Message token | Logger sub-prefix | When |
|---------------|-------------------|------|
| `newGameAsync begin gameId=…` | (default app) | Start of `createNewGameAsync`. |
| `newGameAsync phase step=N total=5` | (default app) | Before each phase `N` (same indices as `onProgress`). |
| `newGameAsync complete gameId=…` | (default app) | After save, before return. |
| `game_intro asset_load begin asset=…` | `dialogue` | Before `loadString` for intro Yarn. |
| `game_intro asset_load end` | `dialogue` | After parse; includes `chars=` count. |
| `game_intro dialogue_begin node=…` | `dialogue` | Before `startDialogue`. |
| `game_intro first_line_shown` | `dialogue` | First non-null dialogue line in overlay. |

---

## Acceptance criteria

- Given the developer records a **profile** or **release** timeline while starting a new game, when they filter the Dart timeline by `CtAppPerf`, then the timeline shows the new-game markers in the table above in a plausible order (setup phases before `navigate.game`, then `mapViewDataProvider.build`, then intro markers as applicable).

- Given the app logger is configured at **info** for the app package, when a new game is created and the game-start intro runs, then log output includes `newGameAsync phase` lines with `step=` `0` through `4` and `game_intro` lines through `first_line_shown` on the success path.

- Given the developer records a **profile** or **release** timeline while opening Development (`GAME80001`) from the empire rail, when they filter by `CtAppPerf.development`, then the timeline shows `development.readModelReady` and at least the Old World `connectivity` / `staticContext` / `regionScopes` / `regionModel` sync slices before any New World `regionScopes` / `regionModel` slices on first open.

- Given the developer records a **profile** or **release** timeline while opening Production (`GAME20001`) or Trade (`GAME60001`) from the empire rail, when they filter by `CtAppPerf.production` or `CtAppPerf.trade`, then the timeline shows `production.interactiveReady` or `trade.interactiveReady` respectively after the first frame with the primary tab body mounted.
