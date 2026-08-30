import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_handler_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugShipSpawnAtCapitalHomeFleet', () {
    test('spawns ships into home fleet and advances global ship sequence', () {
      final game = buildDebugHandlerCapitalGame(
        id: 'g-ship-1',
        includeCapitalTile: false,
        nextShipInstanceSeq: 4,
        fleets: [
          Fleet(
            id: 'fleet_p1',
            ownerId: 'p1',
            inPortAtProvinceId: 'oldWorld|1',
            regionId: 'oldWorld',
            ships: const [ShipInstance(id: 'ship_3', typeId: 'carrack')],
          ),
        ],
      );
      const event = SpawnDebugShipAtCapitalHomeFleetEvent(
        humanPlayerId: 'p1',
        shipTypeId: kTechIdShipOfTheLine,
        count: 2,
      );
      final result = applyDebugShipSpawnAtCapitalHomeFleet(
        currentGame: game,
        event: event,
      );
      final next = result.game;
      expect(next, isNotNull);
      expect(result.message, contains('Spawned 2 ship_of_the_line'));
      final fleet = next!.worldState.fleets.singleWhere((f) => f.id == 'fleet_p1');
      expect(fleet.ships.map((s) => s.id), containsAll(['ship_4', 'ship_5']));
      expect(next.worldState.nextShipInstanceSeq, 6);
    });

    test('fails when player has no valid home fleet at capital', () {
      final game = buildDebugHandlerCapitalGame(
        id: 'g-ship-2',
        includeCapitalTile: false,
      );
      const event = SpawnDebugShipAtCapitalHomeFleetEvent(
        humanPlayerId: 'p1',
        shipTypeId: 'carrack',
      );
      final result = applyDebugShipSpawnAtCapitalHomeFleet(
        currentGame: game,
        event: event,
      );
      expect(result.game, isNull);
      expect(result.message, contains('no valid home fleet at capital'));
    });
  });
}
