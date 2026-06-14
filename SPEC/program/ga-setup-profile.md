# GA Setup Profile Builder

## Purpose

Derive a **realistic, budget-scaled** `GameSetupConfig` and per-faction province
targets for GA observer games so evolved profiles are scored against worlds that
match player-app province-assignment invariants (full non-empty ownership,
app-default per-GP Old World share, mandatory minors and tribes ≥ 3 each). Refs
#3447. Parent: [ga-runner.md](ga-runner.md).

## Location

`tool/ga_runner/lib/setup/ga_setup_profile.dart`, exported from
`package:ga_runner/ga_runner.dart`. The builder reuses the existing
`computeFairTargets`
(`packages/colonizethis_setup/lib/src/setup/province_assignment.dart`); no new
fair-split helper is introduced.

## Faction minimums

The builder rejects (`FormatException`, CLI exit **1**) any request with
`minorCount < 3` or `tribeCount < 3` (including `0`). This mirrors the
parse-time validation in `GaConfig.fromJson` so both the config path and the
builder enforce the same minimum.

## Per-faction province targets

- **Per-GP Old World target is 7** (`kGpOwTargetPerGp`). This matches app-default
  math: 60 OW − 6 minors × 3 `minProvincesPerMinor` = 42 ÷ 6 GPs = 7. The target
  holds even with only 2 tuned GPs.
- **Old World total:** `numProvincesOldWorld = gpCount × 7 + minorCount ×
  minProvincesPerMinor`.
- **Minor OW targets:** equal per-minor split of the reserved pool
  (`minorCount × minProvincesPerMinor`) via `computeFairTargets` (±1 tolerance).
  With `minProvincesPerMinor = 3` each minor target is exactly 3.
- **Tribe NW targets:** equal per-tribe split of `numProvincesNewWorld` via
  `computeFairTargets` (±1 tolerance).
- **New World total** is scaled below the full app default (60/30) so
  turn-resolution stays within the 15 s budget.

## Orphan-continent rule (normative)

The builder guarantees **no landmass is left without a painting faction**:

- When `continentCount <= gpCount`, GPs cover every Old World continent; no minor
  delegation is required.
- When `continentCount > gpCount`, the builder assigns **one minor nation per
  otherwise-unowned continent** and **rejects setup (`FormatException`, exit 1)**
  when `minorCount < (continentCount - gpCount)`.

## Output

`buildGaSetupProfile(...)` returns a `GaSetupProfile`:

- `setupConfig`: the derived `GameSetupConfig`.
- `gpOwTargetPerGp`: `7`.
- `minorOwTargets`: list of per-minor OW targets (length `minorCount`).
- `tribeNwTargets`: list of per-tribe NW targets (length `tribeCount`).

## Acceptance criteria

- Given a profile request with `gpCount = 2`, `minorCount = 3`, `tribeCount = 3`,
  and `minProvincesPerMinor = 3`, when the builder runs, then `gpOwTargetPerGp ==
  7`, `setupConfig.numProvincesOldWorld == 23` (2 × 7 + 3 × 3), every
  `minorOwTargets` entry equals **3**, and `tribeNwTargets` sums to
  `setupConfig.numProvincesNewWorld` with max − min ≤ 1.
- Given a profile request with `minorCount` in `{0, 1, 2}`, when the builder
  runs, then the builder throws a `FormatException` naming the minimum of 3
  minors.
- Given a profile request with `tribeCount` in `{0, 1, 2}`, when the builder
  runs, then the builder throws a `FormatException` naming the minimum of 3
  tribes.
- Given a profile request where `continentCount > gpCount` and `minorCount >=
  (continentCount - gpCount)`, when the builder runs, then `setupConfig`
  preserves `continentCount` and returns without error (one minor covers each
  otherwise-unowned continent).
- Given a profile request where `continentCount > gpCount` and `minorCount <
  (continentCount - gpCount)`, when the builder runs, then the builder throws a
  `FormatException` about orphan continents.
- Given `continentCount <= gpCount`, when the builder runs, then no minor
  delegation is required and the builder returns without error.
