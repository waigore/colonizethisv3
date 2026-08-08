// Case bodies for `expand_phase_planner_below_quota_multi_minor_distraction_peace_test.dart` (Refs #3977 Phase 6).
// Registered from the thin contract file of the same stem.
// Pin/row coverage is preserved 1:1 from the former inline suite.

// Pins the canonical home in `expand_phase_planner.dart` for
// `belowQuotaMultiMinorDistractionPeaceTargets` (Refs #2509 S1).
//
// The helper was relocated from `diplomacy_planner_peace_targets.dart`
// so it survives the now-completed S1 deletion of that file. The canonical
// implementation lives in `expand_phase_planner.dart` alongside the
// `stalledFocusMinorTarget` helper it composes;
// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
// stub for the in-file `collectStalledGreatPowerPeaceTargets`
// `minorTribePeace` consumer chain and the legacy
// `diplomacy_planner_below_quota_peace_part3_test.dart` fixture until
// the now-completed S1 deletion.
//
// Behavioral invariants pinned at the canonical entry point:
//
// `belowQuotaMultiMinorDistractionPeaceTargets`:
//   1. Returns `const []` when
//      `isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)`
//      is `false` — at and above quota the quota-met / consolidate /
//      near-quota deciders own the multi-minor decision instead.
//   2. Returns `const []` when `regimentCountForPlayer` returns 0 —
//      the zero-regiment survival deciders own the peace decision
//      below the affordability gate.
//   3. Returns `const []` when `regimentCountForPlayer` returns a
//      value `>= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar` — once
//      the active player can sustain multiple fronts the
//      distraction-peace pivot is not warranted.
//   4. Returns `const []` when
//      `snapshot.conquest.invadableProvinceIdsSorted` is empty —
//      no OW frontier means no minor war to concentrate on.
//   5. Returns `const []` when `stalledFocusMinorTarget` returns
//      `null` — without an at-war minor owning an invadable OW
//      province the pivot has no target to preserve.
//   6. When all guards pass, returns every at-war minor in
//      `ThreatSummary.atWarWith` except the focused-minor target
//      preserved by `stalledFocusMinorTarget`. Tribes and Great
//      Powers are dropped because their respective peace deciders
//      own those decisions.
//   7. Sorts the result ascending so emission order is deterministic
//      for fixed inputs (Refs #2509 Must-have #7).
//
// Delegation parity:
//   * The delegating stub in `diplomacy_planner_peace_targets.dart`
//     returns the same value as the canonical helper for every
//     representative input — required so the in-file
//     `collectStalledGreatPowerPeaceTargets` `minorTribePeace`
//     consumer resolves to the same multi-minor peace set until the
//     now-completed S1 deletion.

// ignore_for_file: unused_element
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

const String _gpOwn = 'gp_own';
const String _minorAlpha = 'minor_alpha';
const String _minorBeta = 'minor_beta';

void registerExpandPhasePlannerBelowQuotaMultiMinorDistractionGuardsCases() {
  group(
    'belowQuotaMultiMinorDistractionPeaceTargets — canonical outer guards',
    () {
      test('returns const [] at quota even with two at-war minors', () {
        // ownOw == quota → isBelowObserverConquestQuota is false →
        // outer guard fires before the regiment, frontier, and focus
        // checks. Even with two at-war minors clearly contested on
        // the same frontier, the helper returns const [] at quota.
        final game = buildExpandPeaceMultiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          ownRegiments: 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
            _minorBeta: ['oldWorld|beta_1'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [_minorAlpha, _minorBeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
            'oldWorld|beta_1',
          ],
        );
        expect(
          belowQuotaMultiMinorDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'At quota the quota-met / consolidate deciders own the '
              'multi-minor peace decision. A regression flipping the '
              'guard from `<` to `<=` would silently engage the '
              'distraction pivot and peace minor_beta even when the '
              'consolidate arm intended to hold both wars open.',
        );
      });

      test('returns const [] with zero regiments (zero-band reserved)', () {
        // regimentCount == 0 → the zero-regiment survival deciders
        // (`stalledZeroRegimentAllFactionPeaceTargets` /
        // `stalledZeroRegimentGpPeaceTargets`) own the peace decision
        // below the affordability gate; this helper must defer.
        final game = buildExpandPeaceMultiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: 0,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1'],
            _minorBeta: ['oldWorld|beta_1'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorAlpha, _minorBeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|beta_1',
          ],
        );
        expect(
          belowQuotaMultiMinorDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'Zero regiments → the zero-regiment survival arm owns '
              'the peace decision; the distraction-peace pivot must '
              'defer so it does not double-emit a peace target the '
              'survival arm already produced.',
        );
      });

      test('returns const [] when regiments reach the declare-war floor', () {
        // regimentCount == kBelowQuotaPeaceMinRegimentsBeforeDeclareWar
        // → the player can sustain multiple fronts so the
        // distraction-peace pivot is not warranted. The boundary is
        // `>=`, so the exact threshold value triggers the outer
        // guard.
        final game = buildExpandPeaceMultiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1'],
            _minorBeta: ['oldWorld|beta_1'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorAlpha, _minorBeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|beta_1',
          ],
        );
        expect(
          belowQuotaMultiMinorDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'A regression flipping the threshold check from `>=` '
              'to `>` would silently engage the pivot at the floor '
              'value and force-peace minor_beta even though the '
              'player can sustain the second front.',
        );
      });

      test('returns const [] when invadable OW frontier is empty', () {
        // Empty invadableProvinceIdsSorted → the active player has
        // no OW frontier to concentrate on; the pivot has no
        // purpose so the helper returns const [] before invoking
        // the focused-minor scan.
        final game = buildExpandPeaceMultiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_home'],
            _minorBeta: ['oldWorld|beta_home'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorAlpha, _minorBeta],
          invadableProvinceIdsSorted: const [],
        );
        expect(
          belowQuotaMultiMinorDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'No invadable OW frontier → the distraction-peace '
              'pivot has no front to concentrate on so it returns '
              'const [] instead of arbitrarily peacing one of the '
              'two minors.',
        );
      });

      test('returns const [] when focused-minor scan finds no candidate', () {
        // Below quota, regiments in the active band, non-empty
        // invadable list, but neither at-war minor owns an
        // invadable OW province → stalledFocusMinorTarget returns
        // null → the helper passes that null through as const [].
        final game = buildExpandPeaceMultiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_home'],
            _minorBeta: ['oldWorld|beta_home'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorAlpha, _minorBeta],
          // Frontier is non-empty but none of these provinces
          // are owned by the at-war minors.
          invadableProvinceIdsSorted: const ['oldWorld|gp_rival_1'],
        );
        expect(
          belowQuotaMultiMinorDistractionPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          isEmpty,
          reason:
              'No focused minor → no minor war to preserve; the '
              'helper must not invent a focus target and start '
              'peacing the only at-war minors arbitrarily.',
        );
      });
    },
  );

}
