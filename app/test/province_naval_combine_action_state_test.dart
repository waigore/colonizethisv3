// Pins MAP20001 Naval Combine visibility/enablement (Refs #4659).

import 'package:colonizethis_app/features/game/flame/map_state/province_naval_combine_action_state.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show homeFleetIdFor;

void main() {
  suppressLogsForTests();

  const human = 'gp1';
  const port = 'oldWorld|p1';
  const sea = 'oldWorld|sea_a';

  Fleet atPort(String id, {List<ShipInstance> ships = const []}) => Fleet(
    id: id,
    ownerId: human,
    regionId: 'oldWorld',
    inPortAtProvinceId: port,
    ships: ships.isEmpty
        ? [ShipInstance(id: '${id}_s', typeId: 'carrack')]
        : ships,
  );

  Fleet atSea(String id, {List<ShipInstance> ships = const []}) => Fleet(
    id: id,
    ownerId: human,
    regionId: 'oldWorld',
    seaZoneId: 'sea_a',
    ships: ships.isEmpty
        ? [ShipInstance(id: '${id}_s', typeId: 'carrack')]
        : ships,
  );

  Game gameWith(List<Fleet> fleets) => Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players: [
      Player(
        id: human,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: port,
      ),
    ],
  );

  test('two in-port fleets show enabled Combine', () {
    final state = computeProvinceNavalCombineActionState(
      game: gameWith([atPort('a'), atPort('b')]),
      humanPlayerId: human,
      displayId: port,
      draftOrders: const Orders(),
      showsFullNavalIntel: true,
      isSeaZoneContext: false,
      canMutateViaUi: true,
    );
    expect(state.show, isTrue);
    expect(state.enabled, isTrue);
    expect(state.fleetIds, ['a', 'b']);
  });

  test('two at-sea fleets show enabled Combine on sea zone', () {
    final state = computeProvinceNavalCombineActionState(
      game: gameWith([atSea('a'), atSea('b')]),
      humanPlayerId: human,
      displayId: sea,
      draftOrders: const Orders(),
      showsFullNavalIntel: true,
      isSeaZoneContext: true,
      canMutateViaUi: true,
    );
    expect(state.show, isTrue);
    expect(state.enabled, isTrue);
  });

  test('Home + empty non-Home at sea is enabled (locality-only)', () {
    final homeId = homeFleetIdFor(human);
    final state = computeProvinceNavalCombineActionState(
      game: gameWith([
        Fleet(
          id: homeId,
          ownerId: human,
          regionId: 'oldWorld',
          seaZoneId: 'sea_a',
          ships: const [ShipInstance(id: 'hs', typeId: 'fluyte')],
        ),
        Fleet(
          id: 'empty',
          ownerId: human,
          regionId: 'oldWorld',
          seaZoneId: 'sea_a',
          ships: const [],
        ),
      ]),
      humanPlayerId: human,
      displayId: sea,
      draftOrders: const Orders(),
      showsFullNavalIntel: true,
      isSeaZoneContext: true,
      canMutateViaUi: true,
    );
    expect(state.show, isTrue);
    expect(state.enabled, isTrue);
    expect(state.fleetIds.first, homeId);
  });

  test('pending NavalMoveOrder disables Combine', () {
    final state = computeProvinceNavalCombineActionState(
      game: gameWith([atPort('a'), atPort('b')]),
      humanPlayerId: human,
      displayId: port,
      draftOrders: Orders(
        navalMoveOrdersByPlayerId: {
          human: [
            const NavalMoveOrder(
              fleetId: 'a',
              destinationSeaZoneId: 'sea_b',
            ),
          ],
        },
      ),
      showsFullNavalIntel: true,
      isSeaZoneContext: false,
      canMutateViaUi: true,
    );
    expect(state.show, isTrue);
    expect(state.enabled, isFalse);
    expect(state.hasPendingOrder, isTrue);
  });

  test('one fleet or obfuscated Naval or observe hides Combine', () {
    final game = gameWith([atPort('a'), atPort('b')]);
    expect(
      computeProvinceNavalCombineActionState(
        game: gameWith([atPort('a')]),
        humanPlayerId: human,
        displayId: port,
        draftOrders: const Orders(),
        showsFullNavalIntel: true,
        isSeaZoneContext: false,
        canMutateViaUi: true,
      ).show,
      isFalse,
    );
    expect(
      computeProvinceNavalCombineActionState(
        game: game,
        humanPlayerId: human,
        displayId: port,
        draftOrders: const Orders(),
        showsFullNavalIntel: false,
        isSeaZoneContext: false,
        canMutateViaUi: true,
      ).show,
      isFalse,
    );
    expect(
      computeProvinceNavalCombineActionState(
        game: game,
        humanPlayerId: human,
        displayId: port,
        draftOrders: const Orders(),
        showsFullNavalIntel: true,
        isSeaZoneContext: false,
        canMutateViaUi: false,
      ).show,
      isFalse,
    );
  });
}
