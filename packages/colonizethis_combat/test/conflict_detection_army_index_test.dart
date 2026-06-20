import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('detectConflicts army index', () {
    test('defender army selection ignores unrelated armies in other provinces', () {
      const ow = 'oldWorld';
      final contested = '$ow|P1';
      final safeProvince = '$ow|P2';
      final game = Game(
        id: 'g_army_index',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: contested, regionId: ow, ownerId: 'player2'),
              Province(id: safeProvince, regionId: ow, ownerId: 'player2'),
            ],
            units: [
              Unit(
                id: 'u_attacker',
                type: 'musketeers',
                ownerId: 'player1',
                locationProvinceId: contested,
              ),
              Unit(
                id: 'u_defender',
                type: 'pikemen',
                ownerId: 'player2',
                locationProvinceId: contested,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'army_defender_here',
              ownerId: 'player2',
              regionId: ow,
              stationedProvinceId: contested,
              regimentUnitIds: const ['u_defender'],
            ),
            Army(
              id: 'army_defender_elsewhere',
              ownerId: 'player2',
              regionId: ow,
              stationedProvinceId: safeProvince,
              regimentUnitIds: const ['u_defender'],
            ),
          ],
        ),
        players: [
          Player(id: 'player1', displayName: 'P1', isHuman: true),
          Player(id: 'player2', displayName: 'P2', isHuman: true),
        ],
      );
      final orders = Orders(
        moveOrdersByPlayerId: {
          'player1': [
            MoveOrder(
              unitId: 'u_attacker',
              destinationTileKey: '$contested|0|0',
            ),
          ],
        },
      );

      final battles = detectConflicts(game, orders);

      expect(battles.length, 1);
      expect(battles.single.defenderArmyIds, ['army_defender_here']);
    });
  });
}
