// Shared remaining work handler fixtures (Refs #3949 wave 3).

import 'package:colonizethis_orders/src/orders/orders_application_context.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/work_order_handler.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

const remainingWorkHandlersOw = 'oldWorld';
const remainingWorkHandlersProvinceId = '$remainingWorkHandlersOw|P1';
const remainingWorkHandlersTileKey = '$remainingWorkHandlersOw|P1|0|0';

BuildWorkState remainingWorkHandlersBuildState({
  required Game game,
  required Map<String, Unit> oldWorldUnits,
}) {
  return BuildWorkState(
    game: game,
    buildOrders: const {},
    workOrders: const {},
    work: WorkOrderState(
      unitsById: (oldWorld: oldWorldUnits, newWorld: const {}),
      tileState: game.worldState.tileState,
      visibilityByTile: const {},
      portsByProvinceSeaboard: const {},
      purchasedTilesByTileKey: const {},
      oldProvinces: List<Province>.from(game.worldState.oldWorld.provinces),
      newProvinces: const [],
    ),
  );
}

WorkOrderExecutionContext remainingWorkHandlersContext({
  required Game game,
  required Map<String, Unit> oldWorldUnits,
}) {
  return WorkOrderExecutionContext(
    state: remainingWorkHandlersBuildState(
      game: game,
      oldWorldUnits: oldWorldUnits,
    ),
    player: game.players.single,
  );
}

Game remainingWorkHandlersCounterSpyGame(Unit spy) {
  return TestFixtures.minimalGame(
    oldWorld: RegionData(
      provinces: [
        Province(
          id: remainingWorkHandlersProvinceId,
          regionId: remainingWorkHandlersOw,
          ownerId: 'p1',
        ),
      ],
      units: [spy],
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
}

Game remainingWorkHandlersProspectGame(Unit explorer) {
  return TestFixtures.minimalGame(
    oldWorld: RegionData(
      provinces: [
        Province(
          id: remainingWorkHandlersProvinceId,
          regionId: remainingWorkHandlersOw,
          ownerId: 'p1',
        ),
      ],
      units: [explorer],
    ),
    resourceByTileKey: const {remainingWorkHandlersTileKey: 'grain'},
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
}
