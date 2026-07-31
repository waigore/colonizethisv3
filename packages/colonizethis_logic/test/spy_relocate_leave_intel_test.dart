import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'spy_relocate_intel_fixtures.dart';

void main() {
  group('spyLeaveIntelWarningNeeded', () {
    test('warns when last Spy would leave foreign province', () {
      final game = spyRelocateTwoProvinceGame();
      expect(
        spyLeaveIntelWarningNeeded(
          game: game,
          orders: const Orders(),
          humanPlayerId: kSpyRelocateHumanId,
          spyUnitId: 'spy1',
          newDestinationTileKey: 'oldWorld|p1|0|0',
        ),
        isTrue,
      );
    });

    test('no warning when another Spy remains in foreign province', () {
      final game = spyRelocateDualSpyForeignGame();
      expect(
        spyLeaveIntelWarningNeeded(
          game: game,
          orders: const Orders(),
          humanPlayerId: kSpyRelocateHumanId,
          spyUnitId: 'spy1',
          newDestinationTileKey: 'oldWorld|p1|0|0',
        ),
        isFalse,
      );
    });

    test(
      'warns when other Spy pending move already vacates foreign province',
      () {
        final game = spyRelocateDualSpyForeignGame();
        const orders = Orders(
          moveOrdersByPlayerId: {
            kSpyRelocateHumanId: [
              MoveOrder(
                unitId: 'spy2',
                destinationTileKey: 'oldWorld|p1|0|0',
              ),
            ],
          },
        );
        expect(
          spyLeaveIntelWarningNeeded(
            game: game,
            orders: orders,
            humanPlayerId: kSpyRelocateHumanId,
            spyUnitId: 'spy1',
            newDestinationTileKey: 'oldWorld|p1|1|0',
          ),
          isTrue,
        );
      },
    );

    test(
      'no warning when other Spy pending move stays in foreign province',
      () {
        final game = spyRelocateDualSpyForeignGame();
        const orders = Orders(
          moveOrdersByPlayerId: {
            kSpyRelocateHumanId: [
              MoveOrder(
                unitId: 'spy2',
                destinationTileKey: 'oldWorld|p2|2|0',
              ),
            ],
          },
        );
        expect(
          spyLeaveIntelWarningNeeded(
            game: game,
            orders: orders,
            humanPlayerId: kSpyRelocateHumanId,
            spyUnitId: 'spy1',
            newDestinationTileKey: 'oldWorld|p1|0|0',
          ),
          isFalse,
        );
      },
    );

    test('returns false for unknown unit', () {
      final game = spyRelocateTwoProvinceGame();
      expect(
        spyLeaveIntelWarningNeeded(
          game: game,
          orders: const Orders(),
          humanPlayerId: kSpyRelocateHumanId,
          spyUnitId: 'missing',
          newDestinationTileKey: 'oldWorld|p1|0|0',
        ),
        isFalse,
      );
    });

    test('returns false when relocating from owned province', () {
      final game = spyRelocateOwnedProvinceSpyGame();
      expect(
        spyLeaveIntelWarningNeeded(
          game: game,
          orders: const Orders(),
          humanPlayerId: kSpyRelocateHumanId,
          spyUnitId: 'spy1',
          newDestinationTileKey: 'oldWorld|p1|1|0',
        ),
        isFalse,
      );
    });
  });
}
