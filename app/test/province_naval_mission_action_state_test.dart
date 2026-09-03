// Pins MAP20001 Naval Blockade/Beachhead action state (Refs #4413).

import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'province_naval_mission_action_state_fixtures.dart';

void main() {
  suppressLogsForTests();

  test('enabled when one adjacent at-sea fleet can legally blockade', () {
    final game = gameWith(fleets: [atSeaFleet()]);
    final state = computeProvinceNavalMissionActionState(
      game: game,
      humanPlayerId: human,
      provinceId: foreign,
      topology: coastalTopology(),
      isSeaZoneContext: false,
    );
    expect(state.showControls, isTrue);
    expect(state.enabled, isTrue);
    expect(state.eligibleFleetIds, ['f_sea']);
  });

  test('visible disabled when at-sea fleet exists but is not adjacent', () {
    final game = gameWith(fleets: [atSeaFleet(seaZoneId: 'sea_elsewhere')]);
    final state = computeProvinceNavalMissionActionState(
      game: game,
      humanPlayerId: human,
      provinceId: foreign,
      topology: coastalTopology(),
      isSeaZoneContext: false,
    );
    expect(state.showControls, isTrue);
    expect(state.enabled, isFalse);
    expect(state.eligibleFleetIds, isEmpty);
  });

  test('hidden for own, inland, peacetime, sea-zone, and Home Fleet only', () {
    final atSea = atSeaFleet();
    final home = Fleet(
      id: homeFleetIdFor(human),
      ownerId: human,
      seaZoneId: sea,
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    );
    final inPort = Fleet(
      id: 'f_port',
      ownerId: human,
      inPortAtProvinceId: owned,
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    );
    expect(
      computeProvinceNavalMissionActionState(
        game: gameWith(fleets: [atSea]),
        humanPlayerId: human,
        provinceId: owned,
        topology: coastalTopology(),
        isSeaZoneContext: false,
      ).showControls,
      isFalse,
    );
    expect(
      computeProvinceNavalMissionActionState(
        game: gameWith(fleets: [atSea]),
        humanPlayerId: human,
        provinceId: inland,
        topology: coastalTopology(),
        isSeaZoneContext: false,
      ).showControls,
      isFalse,
    );
    expect(
      computeProvinceNavalMissionActionState(
        game: gameWith(fleets: [atSea], relation: RelationState.atPeace),
        humanPlayerId: human,
        provinceId: foreign,
        topology: coastalTopology(),
        isSeaZoneContext: false,
      ).showControls,
      isFalse,
    );
    expect(
      computeProvinceNavalMissionActionState(
        game: gameWith(fleets: [atSea]),
        humanPlayerId: human,
        provinceId: foreign,
        topology: coastalTopology(),
        isSeaZoneContext: true,
      ).showControls,
      isFalse,
    );
    expect(
      computeProvinceNavalMissionActionState(
        game: gameWith(fleets: [atSea]),
        humanPlayerId: human,
        provinceId: wild,
        topology: coastalTopology(),
        isSeaZoneContext: false,
      ).showControls,
      isFalse,
    );
    expect(
      computeProvinceNavalMissionActionState(
        game: gameWith(fleets: [home, inPort]),
        humanPlayerId: human,
        provinceId: foreign,
        topology: coastalTopology(),
        isSeaZoneContext: false,
      ).showControls,
      isFalse,
    );
  });

  test('sea-zone stay missions enabled for one in-zone at-sea fleet', () {
    final game = gameWith(fleets: [atSeaFleet()]);
    final state = computeSeaZoneNavalStayMissionActionState(
      game: game,
      humanPlayerId: human,
      seaZoneId: 'oldWorld|$sea',
      topology: coastalTopology(),
      draftOrders: const Orders(),
    );
    expect(state.showControls, isTrue);
    expect(state.enabled, isTrue);
    expect(state.eligibleFleetIds, ['f_sea']);
  });

  test('sea-zone stay missions hidden with no in-zone human at-sea fleet', () {
    final inPort = Fleet(
      id: 'f_port',
      ownerId: human,
      inPortAtProvinceId: owned,
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    );
    final elsewhere = atSeaFleet(seaZoneId: 'sea_elsewhere');
    expect(
      computeSeaZoneNavalStayMissionActionState(
        game: gameWith(fleets: [inPort, elsewhere]),
        humanPlayerId: human,
        seaZoneId: 'oldWorld|$sea',
        topology: coastalTopology(),
        draftOrders: const Orders(),
      ).showControls,
      isFalse,
    );
  });

  test('sea-zone stay missions visible disabled when slot occupied', () {
    final onMission = atSeaFleet().copyWith(mission: FleetMission.patrol);
    final pendingMission = computeSeaZoneNavalStayMissionActionState(
      game: gameWith(fleets: [atSeaFleet()]),
      humanPlayerId: human,
      seaZoneId: 'oldWorld|$sea',
      topology: coastalTopology(),
      draftOrders: Orders(
        navalMissionOrdersByPlayerId: {
          human: [
            NavalMissionOrder(
              fleetId: 'f_sea',
              mission: FleetMission.defend.name,
            ),
          ],
        },
      ),
    );
    expect(pendingMission.showControls, isTrue);
    expect(pendingMission.enabled, isFalse);

    final pendingMove = computeSeaZoneNavalStayMissionActionState(
      game: gameWith(fleets: [atSeaFleet()]),
      humanPlayerId: human,
      seaZoneId: 'oldWorld|$sea',
      topology: coastalTopology(),
      draftOrders: Orders(
        navalMoveOrdersByPlayerId: {
          human: [
            const NavalMoveOrder(
              fleetId: 'f_sea',
              destinationSeaZoneId: 'sea2',
            ),
          ],
        },
      ),
    );
    expect(pendingMove.showControls, isTrue);
    expect(pendingMove.enabled, isFalse);

    final worldMission = computeSeaZoneNavalStayMissionActionState(
      game: gameWith(fleets: [onMission]),
      humanPlayerId: human,
      seaZoneId: 'oldWorld|$sea',
      topology: coastalTopology(),
      draftOrders: const Orders(),
    );
    expect(worldMission.showControls, isTrue);
    expect(worldMission.enabled, isFalse);
  });
}
