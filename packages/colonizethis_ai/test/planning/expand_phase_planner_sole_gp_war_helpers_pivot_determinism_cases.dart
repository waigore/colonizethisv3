// Topic-split pins from `expand_phase_planner_sole_gp_war_helpers_pivot_cases.dart`
// (Refs #4669 Slice D).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_planner_sole_gp_war_helpers_test_support.dart';

void registerExpandPhasePlannerSoleGpWarHelpersPivotDeterminismCases() {
  group('canPivotFromSoleGpWarAfterPeace', () {
    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = soleGpWarHelpersGameWithProvinces(
        owProvinces: [
          ...soleGpWarHelpersGp1OwProvinces(8),
          const Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: soleGpWarHelpersMinor1,
          ),
        ],
        minorNations: const [
          MinorNation(id: soleGpWarHelpersMinor1, displayName: 'M1'),
        ],
      );
      final snapshot = soleGpWarHelpersPivotSnapshotFor(
        oldWorldProvincesOwned: 8,
        invadableProvinceIdsSorted: const ['oldWorld|minor1_a'],
      );
      final first = canPivotFromSoleGpWarAfterPeace(
        game: game,
        snapshot: snapshot,
      );
      final second = canPivotFromSoleGpWarAfterPeace(
        game: game,
        snapshot: snapshot,
      );
      final third = canPivotFromSoleGpWarAfterPeace(
        game: game,
        snapshot: snapshot,
      );
      expect(first, isTrue);
      expect(second, first);
      expect(third, first);
    });
  });
}
