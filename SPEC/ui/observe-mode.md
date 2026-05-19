# In-app observe mode (debug console)

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

---

## Player-scoped surfaces (P1–P17)

See issue #2556 table. **Global:** P12+P11 omniscient; others `not defined`. **Player:** bind to `viewingPlayerId`.

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
