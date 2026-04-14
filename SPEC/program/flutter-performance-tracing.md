# Flutter performance tracing (new-game → game screen)

**Scope:** Optional instrumentation to attribute wall time after **New Game** completes until the **game screen** is interactable (GitHub #1710). Complements manual **profile/release** DevTools sessions; does not replace them.

---

## Timeline (Dart DevTools → Performance)

Markers use prefix **`CtAppPerf.`** (filter in the timeline).

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

- Given the developer records a **profile** or **release** timeline while starting a new game, when they filter the Dart timeline by `CtAppPerf`, then the timeline shows the markers in the table above in a plausible order (setup phases before `navigate.game`, then `mapViewDataProvider.build`, then intro markers as applicable).

- Given the app logger is configured at **info** for the app package, when a new game is created and the game-start intro runs, then log output includes `newGameAsync phase` lines with `step=` `0` through `4` and `game_intro` lines through `first_line_shown` on the success path.
