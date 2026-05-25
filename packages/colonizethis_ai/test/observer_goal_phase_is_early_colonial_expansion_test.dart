import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  // `isEarlyColonialExpansion` is the early-colonial conquer-score bonus
  // gate used by `evaluateStrategicGoalScores` in `goal_manager.dart`.
  // Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the gate
  // survives the planned deletion of that file. The acquisition-targets
  // half of the conjunction is shared with `hasColonialAcquisitionTargets`
  // (pinned in `observer_goal_phase_test.dart`); the holdings-floor half
  // (`newWorldProvincesOwned < kColonialFewNwProvincesThreshold`)
  // distinguishes "early" expansion from later colonial phases and is
  // exercised exclusively here so the parent suite stays under the
  // 1000-non-comment-line cap (`repo.dart_file_non_comment_line_size`).
  group('isEarlyColonialExpansion', () {
    test(
      'true when invadable NW provinces remain and no NW provinces owned',
      () {
        const colonial = ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
        );
        expect(isEarlyColonialExpansion(colonial), isTrue);
        expect(hasColonialAcquisitionTargets(colonial), isTrue);
      },
    );

    test(
      'true when adjacent NW tribe owners remain and no NW provinces owned',
      () {
        const colonial = ColonialSummary(
          adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
        );
        expect(isEarlyColonialExpansion(colonial), isTrue);
      },
    );

    test('true just below the few-NW-provinces threshold with targets', () {
      const colonial = ColonialSummary(
        newWorldProvincesOwned: kColonialFewNwProvincesThreshold - 1,
        invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
      );
      expect(isEarlyColonialExpansion(colonial), isTrue);
    });

    test(
      'false when no acquisition targets visible despite zero NW holdings',
      () {
        const colonial = ColonialSummary();
        expect(isEarlyColonialExpansion(colonial), isFalse);
        expect(hasColonialAcquisitionTargets(colonial), isFalse);
      },
    );

    test('false when many NW provinces owned despite invadable targets', () {
      const colonial = ColonialSummary(
        newWorldProvincesOwned: kColonialFewNwProvincesThreshold,
        invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
      );
      expect(isEarlyColonialExpansion(colonial), isFalse);
      expect(hasColonialAcquisitionTargets(colonial), isTrue);
    });

    test('false at the few-NW-provinces threshold (boundary)', () {
      const colonial = ColonialSummary(
        newWorldProvincesOwned: kColonialFewNwProvincesThreshold,
        adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
      );
      expect(isEarlyColonialExpansion(colonial), isFalse);
    });

    test('determinism: identical input returns identical bool', () {
      const colonial = ColonialSummary(
        invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
        adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
      );
      final a = isEarlyColonialExpansion(colonial);
      final b = isEarlyColonialExpansion(colonial);
      expect(a, b);
    });
  });
}
