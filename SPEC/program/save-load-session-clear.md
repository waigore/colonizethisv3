# Save/Load — Game-session memory clear

**SPEC/program** — Single API and ordered sequence to clear player-app in-memory game-session state before load, resume, new game, and exit. Complements [save-load.md](save-load.md) (disk envelope). UI call sites: [load-game-list-dialog.md](../ui/load-game-list-dialog.md), [main-menu.md](../ui/main-menu.md), [pause-menu-panel.md](../ui/pause-menu-panel.md), [game-screen.md](../ui/game-screen.md).

---

## Responsibility

- Define `clearActiveGameSession` (app session layer): the only supported way to drop active game-session memory.
- Define the mandatory ordered load/activate sequence so a prior session cannot bleed into the next.
- Non-goals: process death, Flutter/Flame asset caches, deleting Hive disk saves, multiplayer isolation, ctdev/sim runners unless they call the same API.

---

## Clear API

`clearActiveGameSession(container)` (or equivalent `Ref`/`ProviderContainer` entry point) must:

1. **Providers (session-only):** set `currentGame` null; `currentOrders` empty; `productionDesiredOutput` `{}`; `observeSession` default; `pendingDiplomacy` null; tribe herald queue empty; heralds-shown empty; intro-shown empty; `mapProvincePanel` default; region minimap + map visibility toggles to their defaults; `turnResolutionBlocking` false; offline queue empty.
2. **Keep** `settingsProvider` unchanged.
3. **Caches:** clear entire `GameService` map cache and all turn-trace sessions.
4. **Bus:** call `AppEventBus.dropUnconsumedEvents()` (increments delivery generation so deferred/async deliveries from the prior session are discarded; may drop in-flight non-game UI events — acceptable).
5. **Leave** Flutter/Flame image/asset caches and all Hive keys intact.

---

## Ordered load / activate sequence

Mandatory for Load (main menu + pause), Resume (auto-save), and successful New Game install:

1. `clearActiveGameSession`
2. Load save + map from disk into cache for the **target only** (or create new game, which populates cache for the new id)
3. Set providers from the loaded/created session (game, draft orders, production desired)
4. Navigate / close UI chrome

Never set `currentGame` before clear. If step 2 fails after clear, remain with empty/no game (do not resurrect the previous in-memory game). Same storage id / same `game.id` reload still runs full clear + restore.

**Exit to main menu:** `clearActiveGameSession` then navigate to shell (no restore).

---

## Pause while turn resolution is active

While `turnResolutionBlockingProvider == true`, the in-game **pause control must be disabled** (no `OpenPauseMenuPanelEvent` from the top bar / fallback pause affordance). `AppEventHandler` also suppresses `OpenPauseMenuPanelEvent` during blocking. `ClosePanelEvent` remains allowed so an already-open modal can dismiss. This supersedes the prior #2160 exception that kept pause openable mid-resolve, so load/exit cannot start a session clear during resolution.

---

## Acceptance criteria

- Given a dirty in-memory session (non-empty herald queue and/or pending diplomacy, non-empty drafts), when the system calls `clearActiveGameSession`, then game is null, orders empty, desired `{}`, observe default, pending diplomacy null, herald queue and heralds-shown empty, intro-shown empty, map panel default, minimap/visibility defaults, turn-resolution blocking false, offline queue empty, and settings are unchanged.
- Given `GameService` has map cache and turn-trace entries for game A, when clear runs, then the map cache is empty and turn-trace sessions are empty.
- Given the app event bus delivery generation is `G`, when clear runs, then `dropUnconsumedEvents` yields generation `G+1` (deferred handlers for generation `G` must not apply session mutations).
- Given two persisted saves with different map seeds, session A dirty with herald/diplomacy content, when clear+load B completes, then B’s providers hold only B’s envelope drafts/desired, A’s queue/diplomacy content is absent, and map cache contains B only (A absent).
- Given clear then a failed load (null session), when the load path finishes, then `currentGame` remains null (no resurrection of the prior in-memory game).
- Given dirty session then exit to main menu, when clear+navigate completes, then session providers match the post-clear empty state and Hive saves remain.
- Given dirty session then new game success, when clear→create→apply completes, then providers reflect only the new game and map cache has only the new id.
- Given `turnResolutionBlockingProvider == true`, when the pause control is inspected, then it is disabled and emitting `OpenPauseMenuPanelEvent` is suppressed by `AppEventHandler`.
- Given Hive named/auto-save slots exist, when clear runs, then those disk keys are unchanged.
