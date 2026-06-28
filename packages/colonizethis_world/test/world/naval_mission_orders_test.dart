import 'package:colonizethis_world/src/world/naval_mission_orders.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  group('applyNavalMissionOrders', () {
    test(
      'sequential mission updates on the same fleet apply both (Refs #2394)',
      () {
        const ow = 'oldWorld';
        final game = TestFixtures.minimalGame(
          id: 'g1',
          turnNumber: 0,
          players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
              mission: FleetMission.none,
            ),
          ],
        );

        final next = applyNavalMissionOrders(game, {
          'p1': [
            NavalMissionOrder(fleetId: 'f1', mission: FleetMission.patrol.name),
            NavalMissionOrder(fleetId: 'f1', mission: FleetMission.defend.name),
          ],
        });

        expect(next.worldState.fleets, hasLength(1));
        expect(next.worldState.fleets.single.mission, FleetMission.defend);
      },
    );
  });
}
