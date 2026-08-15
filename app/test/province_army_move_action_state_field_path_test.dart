// Pins field-army overlay path over Home Army detach when cache can serve
// (issue #4407 AC 7).

import 'package:colonizethis_app/features/game/flame/map_state/province_army_move_action_state.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_army_move_home_army.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'province_army_move_action_state_support.dart';

void main() {
  suppressLogsForTests();

  const human = kArmyMoveActionHumanId;
  const owned = kArmyMoveActionOwnedId;
  const foreign = kArmyMoveActionForeignId;

  const home = Army(
    id: 'home',
    ownerId: human,
    regionId: 'oldWorld',
    stationedProvinceId: owned,
    regimentUnitIds: ['r_home'],
    isHomeArmy: true,
  );
  const field = Army(
    id: 'field',
    ownerId: human,
    regionId: 'oldWorld',
    stationedProvinceId: owned,
    regimentUnitIds: ['r_field'],
  );
  final units = [
    Unit(
      id: 'r_home',
      type: 'pikemen',
      ownerId: human,
      locationProvinceId: owned,
    ),
    Unit(
      id: 'r_field',
      type: 'musketeers',
      ownerId: human,
      locationProvinceId: owned,
    ),
  ];

  PerPlayerArmyMovePickerCache refreshedCache(Game game) {
    final topology = armyMoveActionTopology();
    final cache = PerPlayerArmyMovePickerCache()
      ..refresh(
        ArmyMovePickerSnapshot(
          game: game,
          playerId: human,
          playerView: buildPlayerView(game, topology, human),
          topology: topology,
          currentOrders: const Orders(),
        ),
      );
    return cache;
  }

  test('capital Move keeps field ids when cache has destinations', () {
    final game = armyMoveActionPickerReadyGame(
      armies: const [home, field],
      units: units,
    );
    final cache = refreshedCache(game);
    expect(cache.stationedFieldArmyIdsWithDestinations(human, owned, game), [
      'field',
    ]);
    final state = computeProvinceArmyMoveActionState(
      game: game,
      humanPlayerId: human,
      provinceId: owned,
      topology: armyMoveActionTopology(),
      armyMovePickerCache: cache,
      showsFullMilitaryIntel: true,
      isSeaZoneContext: false,
    );
    expect(state.moveEnabled, isTrue);
    expect(state.eligibleMoveArmyIds, ['field']);
    expect(
      usesHomeArmyDetachFlow(
        enabled: state.moveEnabled,
        eligibleArmyIds: state.eligibleMoveArmyIds,
      ),
      isFalse,
    );
  });

  test('Invade keeps field ids when a field army can reach', () {
    final game = armyMoveActionPickerReadyGame(
      armies: const [home, field],
      units: units,
      atWar: true,
    );
    final cache = refreshedCache(game);
    expect(cache.armyIdsThatCanReach(human, foreign), contains('field'));
    final state = computeProvinceArmyMoveActionState(
      game: game,
      humanPlayerId: human,
      provinceId: foreign,
      topology: armyMoveActionTopology(),
      armyMovePickerCache: cache,
      showsFullMilitaryIntel: true,
      isSeaZoneContext: false,
    );
    expect(state.invadeEnabled, isTrue);
    expect(state.eligibleInvadeArmyIds, ['field']);
    expect(
      usesHomeArmyDetachFlow(
        enabled: state.invadeEnabled,
        eligibleArmyIds: state.eligibleInvadeArmyIds,
      ),
      isFalse,
    );
  });
}
