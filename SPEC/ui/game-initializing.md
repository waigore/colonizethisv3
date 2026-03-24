# Game initialization (new game)

**SPEC/ui** — User-visible progress and errors while the app builds a new game (map generation, setup pipeline, persistence). Aligns with pipeline phases in [game-setup-pipeline.md](../program/game-setup-pipeline.md).

---

## Scope

- **In scope:** Shell flow after the user confirms **Start** on the **new game setup dialog** (`new_game_leader_selection`, `NewGameLeaderSelectionDialog`): nation + leader per slot, optional fair-assignment flag. Then show progress, run setup on the **main isolate** with **async yields** between coarse steps (Option A — no background isolate). The dialog includes an optional control (default off) that sets **`GameSetupConfig.enforceFairGpOldWorldAssignment`**: when on, the pipeline runs GP Old World connectivity repair and assignment retries per [game-setup.md](../game/game-setup.md); when off, setup uses the fast single-pass OW assignment (see [game-setup-pipeline.md](../program/game-setup-pipeline.md) step 6b).
- **Also applies:** Any future full-screen Game Setup (`CtGameSetup`) path that uses the same app setup API should match the same progress and error behavior unless a separate spec says otherwise.
- **Out of scope:** Cancel mid-setup; fine-grained per-tile progress.

---

## Presentation

The shell may use a **modal progress dialog** (blocking the shell) or a dedicated full-screen initializing view. Both satisfy this spec if the ACs below hold.

| Element | Requirement |
|--------|-------------|
| Title | Short label (e.g. “Creating game”). |
| Step text | One **coarse** label visible at a time; updates when the pipeline advances. |
| Indicator | Indeterminate progress (e.g. circular progress) is sufficient. |
| Dismiss | None while work is in progress. |

**Coarse steps (minimum set):** The UI layer must expose at least these phases in order (labels are implementation-defined; l10n keys in `app/lib/l10n/`). Program indices `0..4` match `GameService.newGameSetupProgressStepCount` (`app/lib/core/services/game_service.dart`):

| Index | Phase |
|-------|--------|
| 0 | Generating Old World map |
| 1 | Generating New World map |
| 2 | Linking Old World and New World (warp zones) |
| 3 | Building world (`createGameFromGeneratedMaps`: assignment, connectivity repair, capitals, naming, initial units) |
| 4 | Saving game (cache, map persistence, save, `NewGameCreatedEvent` when configured) |

The implementation may merge adjacent steps for fewer on-screen updates if every listed phase still runs in order before the next.

---

## Execution model

- Work runs on the **Dart UI isolate**; between coarse steps the app **yields** (e.g. `await Future<void>.delayed(Duration.zero)`) so Flutter can **paint** updated step text and keep the UI responsive for that dialog.
- **Success:** Close progress UI, set the current game in app state, navigate to **`Routes.game`**, emit **`NewGameCreatedEvent`** when the bus is configured (existing `GameService` contract).

---

## Failure and retry

- On **any** thrown error during setup (map generation, `createGameFromGeneratedMaps`, save, etc.), the progress UI closes and the UI layer shows an **error dialog** with:
  - A short title (e.g. “Could not create game”).
  - The error **message** as returned by the exception’s `toString()` (or equivalent single string), suitable for debugging; not required to be end-user polished.
- **Retry:** A **Retry** action dismisses the error dialog and **starts setup again** from step 1 with a **new RNG seed** derived from the **base** config seed: `effectiveSeed = baseSeed + attemptIndex`, where `baseSeed` is `GameSetupConfig.seed` from the user’s chosen leaders/config before the first attempt, and `attemptIndex` is `0` on the first try, `1` on the first retry, `2` on the second retry, etc. NW map generator continues to use a derived seed consistent with the existing app rule (e.g. `effectiveSeed + 1` for New World params when that is how the synchronous API behaves).
- **Dismiss:** A **Close** (or **OK**) action dismisses the error dialog only; the shell does **not** navigate to the game; no new game is set as current.

---

## Acceptance criteria (Given–When–Then)

- Given the user confirmed **Start** on the leader selection dialog, when the shell begins new-game setup, then the UI layer shows a progress UI with a title and the first coarse step label (Old World map generation) before that step’s heavy work completes.
- Given the progress UI is visible, when the pipeline completes the Old World map phase and begins the New World map phase, then the displayed step label updates to reflect New World map generation (or a merged label that still includes that phase per the minimum set above).
- Given the progress UI is visible, when the pipeline completes New World map generation and begins warp generation, then the displayed step label updates to reflect linking regions / warp zones.
- Given the progress UI is visible, when the pipeline enters `createGameFromGeneratedMaps` (assignment, repair, capitals, naming, units), then the displayed step label updates to reflect building the world.
- Given the progress UI is visible, when the pipeline begins persisting the game and map data, then the displayed step label updates to reflect saving.
- Given new-game setup completes without error, when the pipeline finishes, then the progress UI is closed, the created `Game` is stored as the current game, the shell navigates to `Routes.game`, and the `GameService` emits `NewGameCreatedEvent` on the app event bus when configured.
- Given new-game setup throws an error during any phase, when the error propagates to the shell handler, then the progress UI is closed and the UI layer shows an error dialog with a Retry control and a Close (or OK) control, and the error’s `toString()` text (or equivalent) is shown to the user.
- Given the error dialog is shown after a failed attempt with `attemptIndex == N` (non-negative integer), when the user taps **Retry**, then the error dialog closes and setup runs again with `GameSetupConfig.seed` set to `baseSeed + (N + 1)` where `baseSeed` is the seed from the config used before the first attempt in this dialog session, and the progress UI appears again from the first step.
- Given the error dialog is shown, when the user taps **Close** (or **OK**), then the dialog closes and the shell does not navigate to the game and does not set a new current game from that failed run.

---

## Integration

- **App:** `GameService` exposes an async phased API used by the shell; synchronous `createNewGame` may remain for tools/tests that do not need progress.
- **Wiring:** Leader confirmation and progress/error dialogs are **local** to the shell flow (`showDialog` / `Navigator` from the handler context is allowed per [app-ui-wiring.md](../program/app-ui-wiring.md) § Local by design).

---

## Related

- [game-setup.md](game-setup.md) — full Game Setup screen (six slots); § App flow references initializing behavior.
- [SPEC/program/game-setup-pipeline.md](../program/game-setup-pipeline.md) — pipeline phases.
