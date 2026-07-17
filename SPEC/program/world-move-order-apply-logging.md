# World move-order apply logging (SoT)

**SPEC/program** — Shared debug-gated ignore and info apply-summary logging for
army and civilian move apply in `packages/colonizethis_world` (Refs #4038).
Does not change ignore-reason strings, trace callbacks, or movement semantics
in [movement.md](movement.md).

## Source of truth

| Artifact | Role |
|----------|------|
| `lib/src/world/move_order_apply_logging.dart` | `logMoveOrderIgnoredIfDebug`, `logMoveOrderApplySummary` |
| `army_movement.dart` | Same-region army apply uses shared helpers; message text stays army-specific |
| `movement.dart` | Civilian tile apply uses shared helpers; message text stays civilian-specific |

## Rules

- Per-order **debug** ignore lines call `logMoveOrderIgnoredIfDebug` (gated on
  `Level.debug` vs `Logger.level`). Call sites supply the full message
  (`army_move ignored …` or `civilian movement ignored …`).
- Pass **info** apply summaries call `logMoveOrderApplySummary` when
  `applied + ignored > 0`. Call sites supply the full message.

## Acceptance criteria

- Given `Logger.level` is `Level.debug` and an army home-army lock ignore
  occurs in `applyArmyMoveOrdersToRegion`, when the apply path runs, then the
  system emits one debug line containing `army_move ignored` and
  `reason=home_army_locked` via `logMoveOrderIgnoredIfDebug`.
- Given `Logger.level` is `Level.info` and the same home-army lock ignore
  occurs, when the apply path runs, then the system does not emit that
  per-order debug ignore line, and still emits the info apply-summary line.
- Given a civilian `unit_not_found` ignore under `Level.debug`, when
  `applyCivilianTileMoveOrdersToWorldRegions` runs, then the system emits
  `civilian movement ignored` with `reason=unit_not_found` via the shared
  debug helper (existing civilian logging ACs remain).
