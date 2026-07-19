// Ported from colonizethis_logic (Refs #4090 Slice D).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('applyNavalMoveOrderForPlayer', () {
    test('replaces prior naval move for same fleet', () {
      const p1 = 'p1';
      final before = Orders(
        navalMoveOrdersByPlayerId: {
          p1: [
            const NavalMoveOrder(
              fleetId: 'f1',
              destinationSeaZoneId: 'sea1',
            ),
          ],
        },
      );
      final after = applyNavalMoveOrderForPlayer(
        before,
        p1,
        const NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: 'sea2',
        ),
      );
      expect(
        after.navalMoveOrdersByPlayerId[p1],
        equals([
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
        ]),
      );
    });

    test('removes naval mission orders for same fleet', () {
      const p1 = 'p1';
      final before = Orders(
        navalMoveOrdersByPlayerId: {
          p1: [
            const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          ],
        },
        navalMissionOrdersByPlayerId: {
          p1: [
            NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
            NavalMissionOrder(fleetId: 'f2', mission: 'patrol'),
          ],
        },
      );
      final after = applyNavalMoveOrderForPlayer(
        before,
        p1,
        const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea3'),
      );
      expect(
        after.navalMissionOrdersByPlayerId[p1]?.map((e) => e.fleetId).toList(),
        equals(['f2']),
      );
    });
  });

  group('navalMissionOrdersRespectingNavalMoves', () {
    test('drops mission for fleet that has a move order', () {
      const p1 = 'p1';
      final missions = {
        p1: [
          NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
        ],
      };
      final moves = {
        p1: [
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'z'),
        ],
      };
      final out = navalMissionOrdersRespectingNavalMoves(missions, moves);
      expect(out.isEmpty, isTrue);
    });
  });
}
