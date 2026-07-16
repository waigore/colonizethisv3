# Province ownership transfer stages

**SPEC/program** — Named stage helpers for canonical single-province ownership
transfer in `packages/colonizethis_world` (Refs #4038). Semantics of the full
transfer remain in [fog-and-exploration-resolution.md](fog-and-exploration-resolution.md);
this document only pins the stage-module split.

## Motivation

`province_ownership_transfer.dart` orchestrates owner rewrite, military/fleet
reassignment, purchased-land clear, Spy timer clear, visibility, and civilian
relocation. Extracting purchased-land / Spy-count / pre-transfer civilian-count
stages keeps Core and WithResult paths shared and lets each stage be unit-tested
without re-running the full transfer.

## Source of truth

| Artifact | Role |
|----------|------|
| `province_ownership_transfer_stages.dart` | `clearPurchasedTilesForProvinceOwnershipTransfer`, `countSpyTimersClearedForProvinceOwnershipTransfer`, `countIllegalCivilianRelocationsBeforeOwnershipTransfer` |
| `province_ownership_transfer.dart` | Public apply APIs; calls the stage helpers; same-owner early-exit shared by Core and WithResult |

Stages are package-local (not required on the world barrel). Behavior of each
stage matches the former private helpers in the orchestrator.

## Acceptance criteria

- Given a `WorldState` with purchased tiles in province `ow|P1` and another
  province, when the System calls
  `clearPurchasedTilesForProvinceOwnershipTransfer` for `ow|P1`, then the System
  returns a map without the `ow|P1` entries and reports the removed count via
  the callback.
- Given empty `purchasedTilesByTileKey`, when the System calls
  `clearPurchasedTilesForProvinceOwnershipTransfer`, then the System returns the
  same empty map and reports `0` removed.
- Given Spy reveal maps where old owner and/or new owner have a timer for
  province id `P`, when the System calls
  `countSpyTimersClearedForProvinceOwnershipTransfer`, then the System returns
  one count per owner map that contains `P` (0, 1, or 2).
- Given a `Game` with an illegal civilian on a changed province tile, when the
  System calls `countIllegalCivilianRelocationsBeforeOwnershipTransfer`, then
  the System returns a positive count; Given only legal civilians or military
  units, then the System returns `0`.
- Given Core and WithResult ownership-transfer apply paths, when old and new
  owner ids match, then both paths share the same no-op early-exit (game
  identity preserved; WithResult zeroed counts).
