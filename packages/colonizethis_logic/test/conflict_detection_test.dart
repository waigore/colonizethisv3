import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('detectConflicts', () {
    test('returns one battle when two factions in same province', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'player2'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'player1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'player1',
                provinceId: '$ow|P1',
              ),
              Unit(
                id: 'u2',
                type: 'pikemen',
                ownerId: 'player2',
                provinceId: '$ow|P1',
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
            MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P1'),
          ],
        },
      );

      final battles = detectConflicts(game, orders);

      expect(battles.length, 1);
      expect(battles[0].provinceId, 'oldWorld|P1');
      expect(battles[0].defenderFactionId, 'player2');
      expect(battles[0].defenderUnitIds, ['u2']);
      expect(battles[0].attackers.length, 1);
      expect(battles[0].attackers[0].factionId, 'player1');
      expect(battles[0].attackers[0].unitIds, ['u1']);
    });

    test('returns no battle when only one faction in province', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'player1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'player1',
                provinceId: '$ow|P1',
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
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'player2'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'player1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'player1',
                provinceId: '$ow|P1',
              ),
              Unit(
                id: 'u2',
                type: 'pikemen',
                ownerId: 'player2',
                provinceId: '$ow|P1',
              ),
              Unit(
                id: 'u3',
                type: 'musketeers',
                ownerId: 'player2',
                provinceId: '$ow|P2',
              ),
              Unit(
                id: 'u4',
                type: 'pikemen',
                ownerId: 'player1',
                provinceId: '$ow|P2',
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
            MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P1'),
          ],
          'player2': [
            MoveOrder(unitId: 'u3', destinationProvinceId: '$ow|P2'),
          ],
        },
      );

      final battles = detectConflicts(game, orders);

      expect(battles.length, 2);
      expect(
        battles.map((b) => b.provinceId).toList()..sort(),
        ['oldWorld|P1', 'oldWorld|P2'],
      );
      expect(battles.firstWhere((b) => b.provinceId == 'oldWorld|P1').defenderFactionId, 'player2');
      expect(battles.firstWhere((b) => b.provinceId == 'oldWorld|P2').defenderFactionId, 'player1');
    });

    test('civilians alone do not trigger battles', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'player2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'Explorer',
                ownerId: 'player1',
                provinceId: '$ow|P1',
              ),
              Unit(
                id: 'u2',
                type: 'Builder',
                ownerId: 'player2',
                provinceId: '$ow|P1',
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
      expect(battles, isEmpty);
    });
  });
}
