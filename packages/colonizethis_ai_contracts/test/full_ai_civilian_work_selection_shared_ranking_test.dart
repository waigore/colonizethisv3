import 'package:colonizethis_ai_contracts/src/ai/full_ai_civilian_work_selection_shared.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Pins shared scored-row ranking helper (Refs #4368 Slice A AC1–AC2).
void main() {
  group('bestScoredWorkRow', () {
    test('returns null for empty candidates', () {
      expect(
        bestScoredWorkRow(
          const [],
          scoreOf: (_) => 1,
          compareTieBreak: compareWorkOrderLex,
        ),
        isNull,
      );
    });

    test('picks highest score', () {
      const low = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetExplore,
        targetTileKey: 'oldWorld|p1|0|0',
      );
      const high = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetExplore,
        targetTileKey: 'oldWorld|p2|0|0',
      );
      final picked = bestScoredWorkRow(
        const [low, high],
        scoreOf: (w) => w == high ? 10 : 1,
        compareTieBreak: compareWorkOrderLex,
      );
      expect(picked, same(high));
    });

    test('uses tie-break when scores equal', () {
      const a = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetBuildRail,
        targetTileKey: 'oldWorld|p2|0|0',
      );
      const b = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetBuildRail,
        targetTileKey: 'oldWorld|p1|0|0',
      );
      final picked = bestScoredWorkRow(
        const [a, b],
        scoreOf: (_) => 5,
        compareTieBreak: compareWorkOrderProvinceThenTile,
      );
      expect(picked, same(b));
    });
  });

  group('compareWorkOrderProvinceThenTile', () {
    test('orders province before tile key', () {
      const a = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetBuildRail,
        targetTileKey: 'oldWorld|pB|1|1',
      );
      const b = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetBuildRail,
        targetTileKey: 'oldWorld|pA|9|9',
      );
      expect(compareWorkOrderProvinceThenTile(a, b), greaterThan(0));
      expect(compareWorkOrderProvinceThenTile(b, a), lessThan(0));
    });
  });
}
