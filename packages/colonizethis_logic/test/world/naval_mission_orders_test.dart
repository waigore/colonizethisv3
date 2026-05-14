import 'package:colonizethis_logic/src/world/naval_mission_orders.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('applyNavalMissionOrders', () {
    test(
      'sequential mission updates on the same fleet apply both (Refs #2394)',
      () {
        const ow = 'oldWorld';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
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
          ),
          players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
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

    test(
      'join_home_fleet merges ships into home and preserves fleet order (Refs #2394)',
      () {
        const ow = 'oldWorld';
        final capId = '$ow|cap1';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fleet_p1',
                ownerId: 'p1',
                regionId: ow,
                inPortAtProvinceId: capId,
                ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
              ),
              Fleet(
                id: 'f_mid',
                ownerId: 'p1',
                regionId: ow,
                inPortAtProvinceId: capId,
                ships: const [ShipInstance(id: 'ship_mid', typeId: 'carrack')],
              ),
              Fleet(
                id: 'f_join',
                ownerId: 'p1',
                regionId: ow,
                inPortAtProvinceId: capId,
                ships: const [ShipInstance(id: 'ship_join', typeId: 'galleon')],
              ),
            ],
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'A',
              isHuman: true,
              capitalProvinceId: capId,
            ),
          ],
        );

        final next = applyNavalMissionOrders(game, {
          'p1': [
            NavalMissionOrder(fleetId: 'f_join', mission: 'join_home_fleet'),
          ],
        });

        expect(next.worldState.fleets, hasLength(2));
        expect(next.worldState.fleets.map((f) => f.id).toList(), [
          'fleet_p1',
          'f_mid',
        ]);
        final home = next.worldState.fleets.first;
        expect(home.ships.map((s) => s.id).toList(), ['ship_1', 'ship_join']);
        expect(next.worldState.fleets[1].ships.single.id, 'ship_mid');
      },
    );
  });
}
