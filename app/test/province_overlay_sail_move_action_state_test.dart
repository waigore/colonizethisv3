// Pins MAP20001 Naval Sail / Move occupancy predicate (Refs #4735).

import 'package:colonizethis_app/features/game/flame/map_state/province_overlay_sail_move_action_state.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'province_naval_mission_action_state_fixtures.dart';

void main() {
  suppressLogsForTests();

  test('sea-zone shows enabled Sail / Move for one in-zone sea-going fleet', () {
    final state = computeProvinceOverlaySailMoveActionState(
      game: gameWith(fleets: [atSeaFleet()]),
      humanPlayerId: human,
      displayId: 'oldWorld|$sea',
      showsFullNavalIntel: true,
      isSeaZoneContext: true,
      canMutateViaUi: true,
    );
    expect(state.show, isTrue);
    expect(state.enabled, isTrue);
    expect(state.fleetIds, ['f_sea']);
  });

  test('sea-zone lists multiple occupying fleets sorted by id', () {
    final state = computeProvinceOverlaySailMoveActionState(
      game: gameWith(
        fleets: [
          atSeaFleet(id: 'f_b'),
          atSeaFleet(id: 'f_a'),
        ],
      ),
      humanPlayerId: human,
      displayId: 'oldWorld|$sea',
      showsFullNavalIntel: true,
      isSeaZoneContext: true,
      canMutateViaUi: true,
    );
    expect(state.fleetIds, ['f_a', 'f_b']);
  });

  test('owned port shows Sail / Move for in-port sea-going non-Home fleet', () {
    final inPort = Fleet(
      id: 'f_port',
      ownerId: human,
      inPortAtProvinceId: owned,
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    );
    final state = computeProvinceOverlaySailMoveActionState(
      game: gameWith(fleets: [inPort]),
      humanPlayerId: human,
      displayId: owned,
      showsFullNavalIntel: true,
      isSeaZoneContext: false,
      canMutateViaUi: true,
    );
    expect(state.show, isTrue);
    expect(state.enabled, isTrue);
    expect(state.fleetIds, ['f_port']);
  });

  test('hides for observe, fog, foreign port, Home-only, and empty sea', () {
    final home = Fleet(
      id: homeFleetIdFor(human),
      ownerId: human,
      inPortAtProvinceId: owned,
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    );
    final inPortForeign = Fleet(
      id: 'f_foreign_port',
      ownerId: human,
      inPortAtProvinceId: foreign,
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    );
    expect(
      computeProvinceOverlaySailMoveActionState(
        game: gameWith(fleets: [atSeaFleet()]),
        humanPlayerId: human,
        displayId: 'oldWorld|$sea',
        showsFullNavalIntel: true,
        isSeaZoneContext: true,
        canMutateViaUi: false,
      ).show,
      isFalse,
    );
    expect(
      computeProvinceOverlaySailMoveActionState(
        game: gameWith(fleets: [atSeaFleet()]),
        humanPlayerId: human,
        displayId: 'oldWorld|$sea',
        showsFullNavalIntel: false,
        isSeaZoneContext: true,
        canMutateViaUi: true,
      ).show,
      isFalse,
    );
    expect(
      computeProvinceOverlaySailMoveActionState(
        game: gameWith(fleets: [inPortForeign]),
        humanPlayerId: human,
        displayId: foreign,
        showsFullNavalIntel: true,
        isSeaZoneContext: false,
        canMutateViaUi: true,
      ).show,
      isFalse,
    );
    expect(
      computeProvinceOverlaySailMoveActionState(
        game: gameWith(fleets: [home]),
        humanPlayerId: human,
        displayId: owned,
        showsFullNavalIntel: true,
        isSeaZoneContext: false,
        canMutateViaUi: true,
      ).show,
      isFalse,
    );
    expect(
      computeProvinceOverlaySailMoveActionState(
        game: gameWith(fleets: const []),
        humanPlayerId: human,
        displayId: 'oldWorld|$sea',
        showsFullNavalIntel: true,
        isSeaZoneContext: true,
        canMutateViaUi: true,
      ).show,
      isFalse,
    );
  });
}
