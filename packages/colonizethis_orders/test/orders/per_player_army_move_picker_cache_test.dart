import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_army_move_picker_fixtures.dart';

void _runRefreshMatchesPickerAndHelpers() {
  final game = armyMovePickerGameTwoNeighborsWithNw(id: 'g_army_cache');
  final topology = armyMovePickerTopologyFourProvinces();
  final army = armyMovePickerFieldArmy(game).copyWith(
    regimentUnitIds: const ['u_field'],
  );
  final indexed = Game(
    id: game.id,
    worldState: WorldState(
      turnState: game.worldState.turnState,
      oldWorld: RegionData(
        provinces: game.worldState.oldWorld.provinces,
        units: [
          Unit(
            id: 'u_field',
            type: 'musketeers',
            ownerId: armyMovePickerGp,
            locationProvinceId: army.stationedProvinceId,
          ),
        ],
      ),
      newWorld: game.worldState.newWorld,
      armies: [
        army,
        const Army(
          id: 'home_skip',
          ownerId: armyMovePickerGp,
          regionId: 'oldWorld',
          stationedProvinceId: armyMovePickerCap,
          regimentUnitIds: ['u_home'],
          isHomeArmy: true,
        ),
      ],
    ),
    players: game.players,
  );

  final direct = armyMovePickerDestinations(
    game: indexed,
    topology: topology,
    playerId: armyMovePickerGp,
    army: army,
    currentOrders: const Orders(),
  );
  final view = buildPlayerView(indexed, topology, armyMovePickerGp);
  final cache = PerPlayerArmyMovePickerCache();
  cache.refresh(
    ArmyMovePickerSnapshot(
      game: indexed,
      playerId: armyMovePickerGp,
      playerView: view,
      topology: topology,
      currentOrders: const Orders(),
    ),
  );

  expect(
    cache.destinationsForArmy(armyMovePickerGp, army.id),
    direct,
  );
  expect(
    cache.destinationsForArmy(armyMovePickerGp, 'home_skip'),
    isEmpty,
  );
  expect(
    cache.stationedFieldArmyIdsInProvince(
      armyMovePickerGp,
      army.stationedProvinceId,
      indexed,
    ),
    [army.id],
  );
  for (final dest in direct) {
    expect(
      cache.armyIdsThatCanReach(armyMovePickerGp, dest.fullProvinceId),
      contains(army.id),
    );
  }
}

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'PerPlayerArmyMovePickerCache',
    [
      rs(
        'refresh matches picker and helpers',
        _runRefreshMatchesPickerAndHelpers,
        '#4350',
      ),
    ],
    runRunnableScenario,
  );
}
