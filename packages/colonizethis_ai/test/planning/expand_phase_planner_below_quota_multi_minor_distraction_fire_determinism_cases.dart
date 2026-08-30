// Topic-split case module (Refs #4602 Slice B).

// Topic-split case module (Refs #3997 Phase 8).
// Pin/row coverage preserved 1:1 from the former combined cases file.

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

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp_own';
const String _gpRival = 'gp_rival';
const String _minorAlpha = 'minor_alpha';
const String _minorBeta = 'minor_beta';
const String _minorGamma = 'minor_gamma';
const String _tribeOne = 'tribe_one';

void
registerExpandPhasePlannerBelowQuotaMultiMinorDistractionFireDeterminismCases() {
  group('Determinism (Must-have #7)', () {
    test(
      'belowQuotaMultiMinorDistractionPeaceTargets returns identical results on repeat',
      () {
        final game = buildExpandPeaceMultiMinorGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp - 2,
          ownRegiments: 2,
          minorOwnedInvadables: const {
            _minorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
            _minorBeta: ['oldWorld|beta_1'],
            _minorGamma: ['oldWorld|gamma_1'],
          },
          atWarMinors: const [_minorAlpha, _minorBeta, _minorGamma],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
          atWarWith: const [_minorGamma, _minorAlpha, _minorBeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
            'oldWorld|beta_1',
            'oldWorld|gamma_1',
          ],
        );
        final first = belowQuotaMultiMinorDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = belowQuotaMultiMinorDistractionPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(first, equals(second));
        expect(first, const [_minorBeta, _minorGamma]);
      },
    );
  });
}
