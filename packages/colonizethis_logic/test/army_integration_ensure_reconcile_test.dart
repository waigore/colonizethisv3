import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  group('ensureMilitaryArmiesForGame', () {
    test('creates home army for player with capital', () {
      const cap = 'oldWorld|cap';
      const playerId = 'gp1';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: cap, regionId: 'oldWorld', ownerId: playerId),
            ],
          ),
          newWorld: const RegionData(),
          armies: const [],
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'P',
            capitalProvinceId: cap,
            isHuman: true,
          ),
        ],
      );

      final next = ensureMilitaryArmiesForGame(game);
      final hid = homeArmyIdFor(playerId);
      expect(
        next.worldState.armies.any((a) => a.id == hid && a.isHomeArmy),
        isTrue,
      );
    });
  });

  group('reconcileArmiesAfterUnitsChanged', () {
    test('drops dead regiment ids from armies', () {
      const p = 'oldWorld|p1';
      const playerId = 'gp1';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(units: []),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'src',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: p,
              regimentUnitIds: const ['gone'],
              isHomeArmy: false,
            ),
          ],
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'P',
            capitalProvinceId: p,
            isHuman: true,
          ),
        ],
      );

      final ws = reconcileArmiesAfterUnitsChanged(game.worldState, game);
      expect(ws.armies.where((a) => a.id == 'src'), isEmpty);
    });
  });
}
