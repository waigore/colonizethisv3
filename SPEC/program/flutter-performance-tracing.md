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
| `ui_surface_open surface=development elapsed_ms=… budget_ms=…` | `perf` | Profile/release when `development.interactiveReady` fires (Refs #4687). |
| `ui_surface_open surface=provinceOverlay elapsed_ms=… budget_ms=…` | `perf` | Profile/release when `provinceOverlay.interactiveReady` fires (Refs #4690). |

---

## Acceptance criteria

- Given the developer records a **profile** or **release** timeline while starting a new game, when they filter the Dart timeline by `CtAppPerf`, then the timeline shows the new-game markers in the table above in a plausible order (setup phases before `navigate.game`, then `mapViewDataProvider.build`, then intro markers as applicable).

- Given the app logger is configured at **info** for the app package, when a new game is created and the game-start intro runs, then log output includes `newGameAsync phase` lines with `step=` `0` through `4` and `game_intro` lines through `first_line_shown` on the success path.

- Given the developer records a **profile** or **release** timeline while opening Development (`GAME80001`) from the empire rail, when they filter by `CtAppPerf.development`, then the timeline shows `development.readModelReady` and at least the Old World `connectivity` / `staticContext` / `regionScopes` / `regionModel` sync slices before any New World `regionScopes` / `regionModel` slices on first open.
