// Pins (Refs #4602 Slice B).

// Pins canonical home in `expand_phase_planner_peer_peace.dart` for
// `weakHoldingsInvadableBlockerPeaceTargets` (Refs #2509 S1).
//
// The decider was relocated from
// `diplomacy_planner_peace_targets.dart` so it survives the planned
// S1 deletion of that file. The canonical implementation lives in
// `expand_phase_planner_peer_peace.dart` (part of `expand_phase_planner.dart`);
// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
// stub for the legacy
// `diplomacy_planner_below_quota_peace_test.dart` and
// `diplomacy_planner_below_quota_peace_part3_test.dart` fixtures and
// the in-file `_expandRatchetGreatPowerPeaceTargets` /
// `collectStalledGreatPowerPeaceTargets` `preserveBlockerPeace` /
// `stalledOwExpansionNeedsPeacePass` consumer chains until the
// planned deletion.
//
// Behavioral invariants pinned at the canonical entry point:
//
//   1. Outer guard returns `const []` when the active player is not
//      in any of three "critically weak" rows:
//      a. `oldWorldProvincesOwned > kFewOldWorldProvincesDefendThreshold`
//      b. NOT `isBelowObserverConquestQuota(...)`
//      c. NOT (zero regiments AND `isStalledOldWorldExpansion(...)`)
//   2. Returns `const []` when the invadable OW frontier is GP-only
//      (`isOldWorldGpOnlyInvadableFrontier` is true) — the
//      `stalledGpBlockerFocusPeaceTargets` collector owns this
//      decision instead.
//   3. Returns `const []` when the primary OW frontier blocker is
//      null, not in `threats.atWarWith`, or not a Great Power.
//   4. Returns `const []` when the blocker's lead falls below the
//      band-dependent `minLead` table:
//      a. Below quota at default-start + 2 OW or fewer: `1`.
//      b. Below quota above default-start + 2: `kUnwinnableSoleGpMinProvinceDeficit`.
//      c. Above quota (defensive zero-regiment / stalled
//         critical-weak entry path): `kDeclareWarAggressorSuppressWeakGpLeadThreshold`.
//   5. Returns `[blocker]` (single-element list) when all guards pass.
//
// Determinism (Must-have #7): identical `(Game, snapshot)` inputs
// always yield identical results across repeated invocations.
//
// Stub delegation parity: the delegating stub in
// `diplomacy_planner_peace_targets.dart` returns the same value as
// the canonical helper for every representative input — required so
// the legacy fixtures and in-file consumer chains agree.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

void registerWeakHoldingsInvadableBlockerPeaceDeterminismCases() {
  group('Determinism (Must-have #7)', () {
    test('weakHoldingsInvadableBlockerPeaceTargets is identical on repeat', () {
      final game = buildWeakHoldingsInvadableBlockerGame(
        ownProvinces: 7,
        blockerOwnProvinces: 9,
        extraInvadableOwners: const {
          kWeakHoldingsGpBlocker: ['oldWorld|inv_blocker'],
          kWeakHoldingsMinor1: ['oldWorld|inv_minor'],
        },
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [kWeakHoldingsGpBlocker],
        invadableProvinceIdsSorted: const [
          'oldWorld|inv_blocker',
          'oldWorld|inv_minor',
        ],
      );
      final first = weakHoldingsInvadableBlockerPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = weakHoldingsInvadableBlockerPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(first, equals(second));
      expect(first, const [kWeakHoldingsGpBlocker]);
    });
  });
}
