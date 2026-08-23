// Case bodies for `expand_phase_planner_default_start_futile_minor_peace_test.dart` (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp_own';
const String _gpRival = 'gp_rival';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';

void registerDefaultStartFutileMinorPeaceBoundaryCases() {
  group('defaultStartFutileMinorPeaceTargets — band boundary', () {
    test('includes the default-start +1 band (own == default-start + 1)', () {
      // gp_own at kObserverDefaultStartOldWorldProvincesPerGp + 1, the
      // upper inclusive boundary of the default-start band, must still
      // qualify for the futile-minor pivot. This pins the `<=` band
      // upper bound (`ownOw > default-start + 1` short-circuits).
      const ownOw = kObserverDefaultStartOldWorldProvincesPerGp + 1;
      final game = buildDefaultStartFutileMinorExpandPeaceGame(
        ownProvinces: ownOw,
        minorOwProvincesByMinorId: const {_minor1: []},
        atWarMinorIds: const [_minor1],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: ownOw,
        atWarWith: const [_minor1],
        invadableProvinceIdsSorted: const ['oldWorld|future_target'],
      );
      expect(
        defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot),
        const [_minor1],
        reason:
            'The upper inclusive boundary of the default-start band '
            '(own == default-start + 1) must still qualify; a '
            'regression that flipped `>` to `>=` would short-circuit '
            'here and leave the futile minor war open.',
      );
    });
  });
}
