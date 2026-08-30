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

void registerWeakHoldingsInvadableBlockerPeaceTailCases() {
  group(
    'weakHoldingsInvadableBlockerPeaceTargets — band-dependent minLead',
    () {
      test('default-start critical row (ownOw <= 9) fires at lead == 1', () {
        // ownOw = 7 (default-start) → minLead = 1; blocker total = 7
        // base + 1 extra invadable = 8 (lead = 1) → fires.
        final game = buildWeakHoldingsInvadableBlockerGame(
          ownProvinces: 7,
          blockerOwnProvinces: 7,
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
        expect(
          weakHoldingsInvadableBlockerPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          const [kWeakHoldingsGpBlocker],
          reason:
              'Default-start critical row (ownOw <= '
              'kObserverDefaultStartOldWorldProvincesPerGp + 2 = 9) '
              'sets minLead = 1; blocker lead 8-7 = 1 hits the floor '
              '→ peace blocker.',
        );
      });

      test('default-start row does NOT fire at lead == 0 (equal strength)', () {
        // ownOw = 7, blocker total = 6 base + 1 extra invadable = 7 →
        // lead 0 < minLead 1 → no peace.
        final game = buildWeakHoldingsInvadableBlockerGame(
          ownProvinces: 7,
          blockerOwnProvinces: 6,
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
        expect(
          weakHoldingsInvadableBlockerPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Lead 0 < minLead 1 → equal-strength wars are not '
              '"unwinnable" so the helper holds the war open.',
        );
      });

      test('zero-regiment + stalled fires above defend threshold', () {
        // ownOw = 8 → above defend threshold (6) AND below quota →
        // below-quota row applies. Blocker total = 9 base + 1 extra
        // invadable = 10, lead 10-8 = 2 → fires below-quota arm
        // (ownOw 8 <= default-start + 2 = 9 → minLead 1; lead 2 >= 1).
        final game = buildWeakHoldingsInvadableBlockerGame(
          ownProvinces: 8,
          blockerOwnProvinces: 9,
          extraInvadableOwners: const {
            kWeakHoldingsGpBlocker: ['oldWorld|inv_blocker'],
            kWeakHoldingsMinor1: ['oldWorld|inv_minor'],
          },
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const [kWeakHoldingsGpBlocker],
          invadableProvinceIdsSorted: const [
            'oldWorld|inv_blocker',
            'oldWorld|inv_minor',
          ],
        );
        expect(
          weakHoldingsInvadableBlockerPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          const [kWeakHoldingsGpBlocker],
          reason:
              'Below quota at ownOw == 8 (default-start + 1) → minLead '
              '= 1; lead 10 - 8 = 2 >= 1 → peace blocker.',
        );
      });
    },
  );
}
