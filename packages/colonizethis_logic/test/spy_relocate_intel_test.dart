import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'spy_relocate_intel_fixtures.dart';

void main() {
  group('isForeignProvinceForPlayer', () {
    test('returns true for rival-owned province', () {
      final game = spyRelocateTwoProvinceGame();
      expect(
        isForeignProvinceForPlayer(
          game: game,
          prefixedProvinceId: 'oldWorld|p2',
          humanPlayerId: kSpyRelocateHumanId,
        ),
        isTrue,
      );
    });

    test('returns false for human-owned province', () {
      final game = spyRelocateTwoProvinceGame();
      expect(
        isForeignProvinceForPlayer(
          game: game,
          prefixedProvinceId: 'oldWorld|p1',
          humanPlayerId: kSpyRelocateHumanId,
        ),
        isFalse,
      );
    });

    test('returns false for unknown province', () {
      final game = spyRelocateTwoProvinceGame();
      expect(
        isForeignProvinceForPlayer(
          game: game,
          prefixedProvinceId: 'oldWorld|missing',
          humanPlayerId: kSpyRelocateHumanId,
        ),
        isFalse,
      );
    });
  });

  group('countOwnSpiesProjectedInProvince', () {
    test('counts Spies projected in foreign province', () {
      final game = spyRelocateTwoProvinceGame();
      expect(
        countOwnSpiesProjectedInProvince(
          game: game,
          orders: const Orders(),
          humanPlayerId: kSpyRelocateHumanId,
          prefixedProvinceId: 'oldWorld|p2',
        ),
        1,
      );
    });

    test('uses pending move destination for projection', () {
      final game = spyRelocateTwoProvinceGame();
      const orders = Orders(
        moveOrdersByPlayerId: {
          kSpyRelocateHumanId: [
            MoveOrder(
              unitId: 'spy1',
              destinationTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      expect(
        countOwnSpiesProjectedInProvince(
          game: game,
          orders: orders,
          humanPlayerId: kSpyRelocateHumanId,
          prefixedProvinceId: 'oldWorld|p2',
        ),
        0,
      );
      expect(
        countOwnSpiesProjectedInProvince(
          game: game,
          orders: orders,
          humanPlayerId: kSpyRelocateHumanId,
          prefixedProvinceId: 'oldWorld|p1',
        ),
        1,
      );
    });
  });

  group('applySpyRelocateMoveToOrders', () {
    test('stages move and clears conflicting work order', () {
      const orders = Orders(
        workOrdersByPlayerId: {
          kSpyRelocateHumanId: [
            WorkOrder(
              unitId: 'spy1',
              target: kWorkTargetCounterSpy,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      final next = applySpyRelocateMoveToOrders(
        orders: orders,
        humanPlayerId: kSpyRelocateHumanId,
        spyUnitId: 'spy1',
        destinationTileKey: 'oldWorld|p1|1|0',
      );
      expect(next.workOrdersByPlayerId[kSpyRelocateHumanId], isEmpty);
      expect(
        pendingCivilianMoveForUnit(
          orders: next,
          humanPlayerId: kSpyRelocateHumanId,
          unitId: 'spy1',
        ),
        const MoveOrder(
          unitId: 'spy1',
          destinationTileKey: 'oldWorld|p1|1|0',
        ),
      );
    });

    test('replaces prior draft move for same Spy', () {
      const orders = Orders(
        moveOrdersByPlayerId: {
          kSpyRelocateHumanId: [
            MoveOrder(
              unitId: 'spy1',
              destinationTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      final next = applySpyRelocateMoveToOrders(
        orders: orders,
        humanPlayerId: kSpyRelocateHumanId,
        spyUnitId: 'spy1',
        destinationTileKey: 'oldWorld|p1|2|0',
      );
      expect(next.moveOrdersByPlayerId[kSpyRelocateHumanId], hasLength(1));
      expect(
        next.moveOrdersByPlayerId[kSpyRelocateHumanId]!.single
            .destinationTileKey,
        'oldWorld|p1|2|0',
      );
    });
  });

  group('removePendingCivilianMoveForUnit', () {
    test('removes pending move when present', () {
      const orders = Orders(
        moveOrdersByPlayerId: {
          kSpyRelocateHumanId: [
            MoveOrder(
              unitId: 'spy1',
              destinationTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      final next = removePendingCivilianMoveForUnit(
        orders: orders,
        humanPlayerId: kSpyRelocateHumanId,
        unitId: 'spy1',
      );
      expect(next.moveOrdersByPlayerId[kSpyRelocateHumanId], isEmpty);
    });

    test('returns same orders when no pending move', () {
      const orders = Orders();
      expect(
        identical(
          removePendingCivilianMoveForUnit(
            orders: orders,
            humanPlayerId: kSpyRelocateHumanId,
            unitId: 'spy1',
          ),
          orders,
        ),
        isTrue,
      );
    });
  });
}
