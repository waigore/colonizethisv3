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
| `CtAppPerf.trade.counselBuild` | Deferred sync `rankTradeCounselRecommendationsForHuman` for Market counsel stars (`tradePanelSessionCacheProvider`). |
| `CtAppPerf.civilianUnits.interactiveReady` | Post-frame after `UNIT10001` sheet chrome + primary list mount. |
| `CtAppPerf.militaryUnits.interactiveReady` | Post-frame after `UNIT20001` sheet chrome + primary list mount. |
| `CtAppPerf.militaryUnits.treeBuild` | Sync military tree assembly (`resolveUnitsPanelMilitaryGroups`). |
| `CtAppPerf.navalUnits.interactiveReady` | Post-frame after `UNIT30001` sheet chrome + primary list mount. |
| `CtAppPerf.navalUnits.treeBuild` | Sync naval tree assembly (`resolveUnitsPanelNavalTree`). |
| `CtAppPerf.diplomacy.interactiveReady` | Post-frame after `GAME30001` chrome + faction-row list mount. |
| `CtAppPerf.diplomacy.rowsBuild` | Sync `buildDiplomacyRows` in `diplomacyPanelRowsProvider`. |
| `CtAppPerf.technology.interactiveReady` | Post-frame after `GAME40001` chrome + default Research Slots tab body mount (Tree tab deferred until selected). |
| `CtAppPerf.technology.slotsOpenPath` | Sync Slots-tab preview bundle (`technologyPanelSlotsOpenPathProvider`). |
| `CtAppPerf.victory.interactiveReady` | Post-frame after `GAME70001` chrome + standings + political minimap mount. |
| `CtAppPerf.victory.openPath` | Sync standings, ownership colours, and OW minimap view-data bundle (`victoryPanelOpenPathProvider`). |
| `CtAppPerf.counsel.interactiveReady` | Post-frame after `GAME90001` chrome + initial-tab body mount (instant; off-tabs deferred until first selection). |
| `CtAppPerf.counsel.industryBuild` | Sync `rankIndustryCounselRecommendations` (`counselPanelSessionCacheProvider`). |
| `CtAppPerf.counsel.tradeBuild` | Sync `rankTradeCounselRecommendationsForHuman` (`counselPanelSessionCacheProvider`). |
| `CtAppPerf.counsel.militaryBuild` | Sync `rankMilitaryCounselRecommendations` (`counselPanelSessionCacheProvider`). |
| `CtAppPerf.counsel.developmentBuild` | Sync `rankDevelopmentCounselRecommendations` (`counselPanelSessionCacheProvider`). |
| `CtAppPerf.development.*` | See § Development panel open path (`GAME80001`). |

Filter `CtAppPerf.production`, `CtAppPerf.trade`, `CtAppPerf.diplomacy`, `CtAppPerf.technology`, `CtAppPerf.victory`, `CtAppPerf.counsel`, or `CtAppPerf.*Units` for empire-rail DevTools sessions. The **1.0 s open-to-interactive** wall-clock gate is profile/release on Linux desktop and Android emulator (PR DevTools evidence); CI uses µs profiling anchors in `empire_rail_panel_open_path_timing_test.dart` and full-widget pump-to-interactive surrogates in `app/test/empire_rail_panel_open_surface_budget_test.dart` — not debug wall-clock assertions.

**Binding-host replay harness (Refs #4688):**

Operator wrapper: `tool/run_ui_surface_profile_evidence.sh <surface> [--host linux|android|auto]` from repo root. Use `all-empire-rail` to run trade through units in one session. Android CI artifact: `ui-surface-profile-evidence-android-empire-rail` (workflow `.github/workflows/ui-surface-profile-evidence-android-empire-rail.yml`).

- **Production (`GAME20001`):** `tool/run_ui_surface_profile_evidence.sh production` → `app/integration_test/production_panel_surface_open_profile_test.dart`. Capture cold open and same-turn warm re-open `ui_surface_open surface=production … host=linux_desktop_profile` or `host=android_emulator_profile` lines.
- **Trade (`GAME60001`):** `tool/run_ui_surface_profile_evidence.sh trade` (`surface=trade`).
- **Technology (`GAME40001`):** `tool/run_ui_surface_profile_evidence.sh technology` (`surface=technology`).
- **Diplomacy (`GAME30001`):** `tool/run_ui_surface_profile_evidence.sh diplomacy` (`surface=diplomacy`).
- **Victory (`GAME70001`):** `tool/run_ui_surface_profile_evidence.sh victory` (`surface=victory`).
- **Counsel (`GAME90001`):** `tool/run_ui_surface_profile_evidence.sh counsel` (`surface=counsel`).
- **Unit sheets (`UNIT10001` / `UNIT20001` / `UNIT30001`):** `tool/run_ui_surface_profile_evidence.sh units` (`surface=civilianUnits`, `surface=militaryUnits`, or `surface=navalUnits`).

### Turn-shell surfaces open path (Refs #4715)

| Marker | When |
|--------|------|
| `CtAppPerf.nextTurnConfirm.interactiveReady` | Post-frame after `DLG60001` title, body, compact staged summary (when present), idle-civilian rows (when warn variant), and **Yes** / **No** mount (instant). |
| `CtAppPerf.turnNews.interactiveReady` | Post-frame after `DLG50001` title, gazette or empty copy, optional court block, and **Close** mount (instant). |
| `CtAppPerf.playerTurnEventFeed.interactiveReady` | Post-frame after `OVL70001` card chrome and row list or empty copy mount (instant). |

Filter `CtAppPerf.nextTurnConfirm`, `CtAppPerf.turnNews`, or `CtAppPerf.playerTurnEventFeed` for turn-shell DevTools sessions. The **1.0 s open-to-interactive** wall-clock gate is profile/release on binding hosts (PR evidence); CI uses full-widget pump-to-interactive surrogates in `app/test/turn_shell_surface_open_surface_budget_test.dart` — not debug wall-clock assertions.

**Binding-host replay harness (Refs #4715):** `tool/run_ui_surface_profile_evidence.sh turn-shell` → `app/integration_test/turn_shell_surface_open_profile_test.dart`. Capture `ui_surface_open surface=nextTurnConfirm`, `surface=turnNews`, and `surface=playerTurnEventFeed` lines with `host=linux_desktop_profile` or `host=android_emulator_profile`.

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
| `ui_surface_open surface=development elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `development.interactiveReady` fires (Refs #4687). |
| `ui_surface_open surface=production elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `production.interactiveReady` fires (Refs #4688). |
| `ui_surface_open surface=trade elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `trade.interactiveReady` fires (Refs #4688). |
| `ui_surface_open surface=technology elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `technology.interactiveReady` fires (Refs #4688). |
| `ui_surface_open surface=diplomacy elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `diplomacy.interactiveReady` fires (Refs #4688). |
| `ui_surface_open surface=victory elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `victory.interactiveReady` fires (Refs #4688). |
| `ui_surface_open surface=counsel elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `counsel.interactiveReady` fires (Refs #4688). |
| `ui_surface_open surface=civilianUnits elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `civilianUnits.interactiveReady` fires (Refs #4688). |
| `ui_surface_open surface=militaryUnits elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `militaryUnits.interactiveReady` fires (Refs #4688). |
| `ui_surface_open surface=navalUnits elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `navalUnits.interactiveReady` fires (Refs #4688). |
| `ui_surface_open surface=nextTurnConfirm elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `nextTurnConfirm.interactiveReady` fires (Refs #4715). |
| `ui_surface_open surface=turnNews elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `turnNews.interactiveReady` fires (Refs #4715). |
| `ui_surface_open surface=playerTurnEventFeed elapsed_ms=… budget_ms=… host=…` | `perf` | Profile/release when `playerTurnEventFeed.interactiveReady` fires (Refs #4715). |

---

## Acceptance criteria

- Given the developer records a **profile** or **release** timeline while starting a new game, when they filter the Dart timeline by `CtAppPerf`, then the timeline shows the new-game markers in the table above in a plausible order (setup phases before `navigate.game`, then `mapViewDataProvider.build`, then intro markers as applicable).

- Given the app logger is configured at **info** for the app package, when a new game is created and the game-start intro runs, then log output includes `newGameAsync phase` lines with `step=` `0` through `4` and `game_intro` lines through `first_line_shown` on the success path.

- Given the developer records a **profile** or **release** timeline while opening Development (`GAME80001`) from the empire rail, when they filter by `CtAppPerf.development`, then the timeline shows `development.readModelReady` and at least the Old World `connectivity` / `staticContext` / `regionScopes` / `regionModel` sync slices before any New World `regionScopes` / `regionModel` slices on first open.

- Given the developer records a **profile** or **release** timeline while opening Production (`GAME20001`) or Trade (`GAME60001`) from the empire rail, when they filter by `CtAppPerf.production` or `CtAppPerf.trade`, then the timeline shows `production.interactiveReady` or `trade.interactiveReady` respectively after the first frame with the primary tab body mounted.
