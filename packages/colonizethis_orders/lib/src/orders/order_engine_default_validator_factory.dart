import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'order_resolution_context.dart';
import 'validator_bundle.dart';

OrderValidators defaultOrderValidatorFactory(
  Game game,
  Player player,
  String playerId,
  OrderResolutionContext resolution,
  MapTopology topology,
  List<DiplomaticOrder> diplomaticOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  Set<String> civilianDraftMoveUnitIds,
  Set<String> devExclusiveTiles,
  Stockpile stockpile,
  int treasury,
  DiplomacyFactionMembership factionMembership,
  WorkerPool workerPool,
) {
  return createOrderValidators(
    game: game,
    player: player,
    playerId: playerId,
    resolution: resolution,
    topology: topology,
    diplomaticOrders: diplomaticOrders,
    tileMapByRegion: tileMapByRegion,
    civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
    devExclusiveTiles: devExclusiveTiles,
    stockpile: stockpile,
    treasury: treasury,
    factionMembership: factionMembership,
    workerPool: workerPool,
  );
}
