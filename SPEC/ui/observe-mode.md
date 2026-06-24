# In-app observe mode (debug console)

**Screen ID:** `OVL60001` — stable; do not reassign.
**SPEC/ui** — Session-only spectator mode entered via `/observe` when `CT_DEBUG_CONSOLE=true`. Out of scope: `tool/run_observer_game` CLI ([run_observer_game-tool.md](../program/run_observer_game-tool.md)).

---

## Modes

| Mode | Map visibility | Player chrome (P1–P10, P13–P17) | Detail overlay (P11) |
|------|----------------|----------------------------------|----------------------|
| **off** | Human `PlayerView` | Human GP | Human knowledge |
| **global** | `CtMapVisibilityMode.full` (no fog) | Sentinel `not defined` | Omniscient raw `Game` |
| **player** | `buildPlayerView(..., targetGpId)` | Target GP data | Target GP knowledge |

**Read-only UI:** `canMutateViaUi == false` while observing; debug console mutating commands remain allowed and target `lastControlledPlayerId`.

**Control handoff:** On enter, session sets all `Player.isHuman = false` and `aiControlByGpId[gpId] = true` on in-memory `Game` only. On `/observe off`, restore `priorHumanPlayerId` human flag and baseline `aiControlByGpId` from session snapshot. **Not persisted** in save JSON (strip before save).

**Observe phase:** When no human GP (`effectiveHumanPlayerId == null`), shell shows `Observe — Turn N (YYYY)`; order UI inactive; **Next turn** enabled and runs Full AI for all GPs.

**Banner:** `GameMapControls` shows `Observing: global` or `Observing: <id> (<displayName>)`.

**Shell-entry auto-center:** The in-game map's one-shot capital auto-center and home-to-capital button gate on the current player (`viewingPlayerId`). **Player observe** auto-centers on the observed GP's capital and **enables** the home-to-capital button; **global observe** (`viewingPlayerId == null`) **skips** auto-centering and **disables** the button. See [empire-overview.md](empire-overview.md) § Initial map viewport (shell entry) and § Home-to-capital button.

---

## Player-scoped surfaces (P1–P17)

See issue #2556 table. **Global:** P12+P11 omniscient; others `not defined` (P10 turn-event feed toggle shows the sentinel and hides the feed card). **Player:** bind to `viewingPlayerId`.

**P6 carve-out (civilian inspection):** Global observe still shows **`not defined`** for treasury, production, diplomacy, and other GP-scoped chrome panels, but the **Civilian Units** panel and map **civilian tile markers** remain available read-only for **all factions** (great powers, minor nations, tribes) that own civilians with a `tileKey`. Mutating controls (Assign, Cancel, Train, work-target selection) are disabled while observe is active.

## Map civilian markers (observe-aware owner set)

Civilian tile markers must not depend on `Player.isHuman` because observe handoff clears that flag for every player ([Modes](#modes) → control handoff). The map builder (`colonizethis_map` `buildInitGameMapViewData` `civilianMarkerOwnerIds`) and the civilian draft projection (`GameMapAreaCivilianDraftProjection.project` `civilianMarkerOwnerIds`) accept an explicit owner-id set so the shell can resolve the correct markers per mode:

| Mode | `civilianMarkerOwnerIdsFor(shell, game)` |
|------|------------------------------------------|
| **off** | `null` (map builder falls back to `Player.isHuman`; panel uses `resolveCivilianMarkerOwnerIds` for the human GP) |
| **global** | Every `Player.id`, `MinorNation.id`, and `Tribe.id` in the session `Game` |
| **player** | `{ viewingPlayerId }` (observed GP only) |

Draft projection enumerates world-state civilians for the same owner set when base markers are empty. Player-view fog rules and Chebyshev ≤ 2 reveal-halo behavior for civilian markers are unchanged ([map-widget.md](map-widget.md) § Civilian Marker Icons). `civilianMarkerOwnerIdsFor` is the single source of truth for the base map view and draft projection; `resolveCivilianMarkerOwnerIds` covers the Civilian Units panel (non-null owner set, including minors/tribes in global observe per [P6 carve-out](#player-scoped-surfaces-p1p17)).

---

## Save / load

- **Save:** `prepareGameForPersistence` restores control flags from `ObserveSessionState.controlBaseline` before `Game.toJson()`.
- **Load / leave shell:** `observeSessionProvider.notifier.reset()` → `ObserveMode.off`.

---

## Acceptance criteria

- Given `CT_DEBUG_CONSOLE=true`, when `/observe`, then global mode and banner `Observing: global`.
- Given player observe for `gp2`, when treasury top bar renders, then `gp2` treasury (not `not defined`).
- Given global observe, when treasury top bar renders, then `not defined`.
- Given control of `gp1`, when `/observe`, then no human GP and `gp1` in `aiControlByGpId` for turn resolution.
- Given `/observe off` after `gp1`, when off, then `gp1.isHuman == true` in session.
- Given observe active, when save+reload, then observe off and `isHuman` matches file baseline.
- Given observe + `lastControlledPlayerId == gp1`, when `/add_money 100`, then `gp1` treasury increases.
- Given a game where at least two GPs each own at least one civilian unit on the map, when the user enters global observe (`/observe`), then `civilianMarkerOwnerIdsFor(shell, game)` resolves to every GP id and the map view's `civilianTileMarkers` include at least one marker per owning GP.
- Given GP `gp2` owns at least one civilian unit on the map and another GP `gp3` also owns civilians, when the user enters player observe for `gp2` (`/observe gp2`), then `civilianMarkerOwnerIdsFor(shell, game)` resolves to `{ "gp2" }` and the map view's `civilianTileMarkers` include `gp2`'s civilians while excluding `gp3`'s civilians.
- Given observe was active (global or player) and is then turned off (`/observe off`), when the human player resumes control of `gp1`, then `civilianMarkerOwnerIdsFor(shell, game)` returns `null` (legacy single-player) and the map view's `civilianTileMarkers` only include `gp1`'s civilians (no other GP civilians remain after handoff revert).
- Given normal play with `Player.isHuman == true` for one GP and observe mode `off`, when the map view builds, then the legacy `isHuman` filter behavior is preserved with no regression for non-observe sessions.
- Given global observe and civilians owned by at least two factions, when the Empire map renders, then civilian tile markers appear for every owning faction on visible tiles (no fog).
- Given player observe for `gp2` with civilians on the map, when the Empire map renders, then civilian tile markers appear for `gp2` only and respect `gp2` player-view fog.
- Given global observe, when the user opens the Civilian Units panel, then the UI lists all factions' civilians read-only (grouped by owner) and does not show the `not defined` sentinel.
- Given observe is active, when the Civilian Units panel is open, then Assign, Cancel, Train, and work-target selection are disabled; Locate remains available.
- Given `/observe off` after global observe and the human GP controls the session again, when the Civilian Units panel is open, then Assign/Cancel/Train behave as in normal play and map markers follow the human-player-only rule.
