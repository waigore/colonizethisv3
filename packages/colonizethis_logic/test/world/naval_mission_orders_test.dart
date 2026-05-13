import 'package:colonizethis_logic/src/world/naval_mission_orders.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('applyNavalMissionOrders', () {
    test('applies sequential mission updates without full index rebuild each order', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'fa',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
            Fleet(
              id: 'fb',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final next = applyNavalMissionOrders(game, {
        'p1': [
          NavalMissionOrder(fleetId: 'fa', mission: FleetMission.patrol.name),
          NavalMissionOrder(fleetId: 'fb', mission: FleetMission.patrol.name),
        ],
      });

      final byId = {for (final f in next.worldState.fleets) f.id: f};
      expect(byId['fa']!.mission, FleetMission.patrol);
      expect(byId['fb']!.mission, FleetMission.patrol);
    });

    test('join home fleet removes absorbed fleet from id map; later orders for that id noop', () {
      const ow = 'oldWorld';
      const cap = '$ow|CAP';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: cap, regionId: ow, ownerId: 'p1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'fleet_p1',
              ownerId: 'p1',
              regionId: ow,
              inPortAtProvinceId: cap,
              shipTypeIds: const ['carrack'],
            ),
            Fleet(
              id: 'f_aux',
              ownerId: 'p1',
              regionId: ow,
              inPortAtProvinceId: cap,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: cap,
          ),
        ],
      );

      final next = applyNavalMissionOrders(game, {
        'p1': [
          const NavalMissionOrder(fleetId: 'f_aux', mission: 'join_home_fleet'),
          NavalMissionOrder(fleetId: 'f_aux', mission: FleetMission.patrol.name),
        ],
      });

      expect(next.worldState.fleets.map((f) => f.id).toSet(), {'fleet_p1'});
      final home = next.worldState.fleets.single;
      expect(home.ships.length, 2);
      expect(home.mission, FleetMission.none);
    });
  });
}
