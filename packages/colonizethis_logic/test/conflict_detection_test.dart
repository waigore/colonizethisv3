import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('detectConflicts', () {
    test('returns one battle when two factions in same province', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'player2'),
              Province(id: 'P2', regionId: 'oldWorld', ownerId: 'player1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'player1',
                provinceId: 'P1',
              ),
              Unit(
                id: 'u2',
                type: 'pikemen',
                ownerId: 'player2',
                provinceId: 'P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'player1', displayName: 'P1', isHuman: true),
          Player(id: 'player2', displayName: 'P2', isHuman: true),
        ],
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'player1': [
            MoveOrder(unitId: 'u1', destinationProvinceId: 'P1'),
          ],
        },
      );

      final battles = detectConflicts(game, orders);

      expect(battles.length, 1);
      expect(battles[0].provinceId, 'P1');
      expect(battles[0].defenderFactionId, 'player2');
      expect(battles[0].defenderUnitIds, ['u2']);
      expect(battles[0].attackers.length, 1);
      expect(battles[0].attackers[0].factionId, 'player1');
      expect(battles[0].attackers[0].unitIds, ['u1']);
    });

    test('returns no battle when only one faction in province', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'player1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'player1',
                provinceId: 'P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'player1', displayName: 'P1', isHuman: true),
        ],
      );

      final orders = Orders();

      final battles = detectConflicts(game, orders);

      expect(battles, isEmpty);
    });

    test('multiple provinces with conflicts return multiple battles', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'player2'),
              Province(id: 'P2', regionId: 'oldWorld', ownerId: 'player1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'player1',
                provinceId: 'P1',
              ),
              Unit(
                id: 'u2',
                type: 'pikemen',
                ownerId: 'player2',
                provinceId: 'P1',
              ),
              Unit(
                id: 'u3',
                type: 'musketeers',
                ownerId: 'player2',
                provinceId: 'P2',
              ),
              Unit(
                id: 'u4',
                type: 'pikemen',
                ownerId: 'player1',
                provinceId: 'P2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'player1', displayName: 'P1', isHuman: true),
          Player(id: 'player2', displayName: 'P2', isHuman: true),
        ],
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'player1': [
            MoveOrder(unitId: 'u1', destinationProvinceId: 'P1'),
          ],
          'player2': [
            MoveOrder(unitId: 'u3', destinationProvinceId: 'P2'),
          ],
        },
      );

      final battles = detectConflicts(game, orders);

      expect(battles.length, 2);
      expect(
        battles.map((b) => b.provinceId).toList()..sort(),
        ['P1', 'P2'],
      );
      expect(battles.firstWhere((b) => b.provinceId == 'P1').defenderFactionId, 'player2');
      expect(battles.firstWhere((b) => b.provinceId == 'P2').defenderFactionId, 'player1');
    });
  });
}
