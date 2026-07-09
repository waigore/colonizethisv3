// Shared validator-bundle scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_resolution_context.dart';
import 'package:colonizethis_orders/src/orders/order_validators.dart';
import 'package:colonizethis_orders/src/orders/validator_bundle.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

typedef ValidatorBundleScenarioContext = ({
  Game game,
  Player player,
  String playerId,
  MapTopology topology,
  OrderResolutionContext resolution,
  List<DiplomaticOrder> diplomaticOrders,
  Set<String> civilianDraftMoveUnitIds,
  Set<String> devExclusiveTiles,
  Stockpile stockpile,
  int treasury,
  WorkOrderValidationContext workContext,
  OrderValidators bundle,
});

ValidatorBundleScenarioContext vbDefaultScenarioContext() {
  final game = TestFixtures.minimalGame(
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final player = game.players.single;
  const playerId = 'p1';
  final topology = MapTopology(nodes: const [], edges: const []);
  final view = buildPlayerView(game, topology, playerId);
  final unitsById = unitsByIdFromWorld(game.worldState);
  const diplomaticOrders = <DiplomaticOrder>[];
  const civilianDraftMoveUnitIds = <String>{};
  const devExclusiveTiles = <String>{};
  final stockpile = player.stockpile;
  final treasury = player.treasury;
  final resolution = orderResolutionContextFromView(
    view,
    game,
    unitsById: unitsById,
  );

  final workContext = buildWorkOrderValidationContext(
    game: game,
    player: player,
    playerId: playerId,
    resolution: resolution,
    devExclusiveTiles: devExclusiveTiles,
    tileMapByRegion: null,
    civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
    diplomaticOrders: diplomaticOrders,
    topology: topology,
  );

  final bundle = createOrderValidators(
    game: game,
    player: player,
    playerId: playerId,
    resolution: resolution,
    topology: topology,
    diplomaticOrders: diplomaticOrders,
    tileMapByRegion: null,
    civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
    devExclusiveTiles: devExclusiveTiles,
    stockpile: stockpile,
    treasury: treasury,
    factionMembership: DiplomacyFactionMembership.from(game),
  );

  return (
    game: game,
    player: player,
    playerId: playerId,
    topology: topology,
    resolution: resolution,
    diplomaticOrders: diplomaticOrders,
    civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
    devExclusiveTiles: devExclusiveTiles,
    stockpile: stockpile,
    treasury: treasury,
    workContext: workContext,
    bundle: bundle,
  );
}
