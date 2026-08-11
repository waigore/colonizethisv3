import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_effects_projector.dart';
import 'order_engine_validation.dart';
import 'order_resolution_context.dart';
import 'order_validation_result.dart';
import 'order_validator_factory.dart';
import 'orders_application_context.dart' show copyUnitsById;
import 'unit_type_helpers.dart';

/// Full-pass validation setup and phase run for [OrderEngine].
/// Extracted from `order_engine.dart` (Refs #4317 Slice B).
List<OrderValidationResult> runOrderEnginePlayerValidation({
  required OrderValidatorFactory validatorFactory,
  required OrderEffectsProjector? projector,
  required Orders stagedOrders,
  required Game game,
  required String playerId,
  required MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final player = game.playerById(playerId);
  if (player == null) return <OrderValidationResult>[];

  final view = buildPlayerView(game, topology, playerId);

  final moves = stagedOrders.moveOrdersByPlayerId[playerId] ?? [];
  final armyMoves = stagedOrders.armyMoveOrdersByPlayerId[playerId] ?? [];
  final recruitWorkers =
      stagedOrders.recruitWorkerOrdersByPlayerId[playerId] ?? [];
  final builds = stagedOrders.buildUnitOrdersByPlayerId[playerId] ?? [];
  final works = stagedOrders.workOrdersByPlayerId[playerId] ?? [];
  final diplomatic = stagedOrders.diplomaticOrdersByPlayerId[playerId] ?? [];
  final navals = stagedOrders.navalMoveOrdersByPlayerId[playerId] ?? [];
  final missions = stagedOrders.navalMissionOrdersByPlayerId[playerId] ?? [];
  final tradeOrders = stagedOrders.tradeOrdersByPlayerId[playerId] ?? [];

  final unitsById = copyUnitsById(game.worldState.allUnitsById);

  final resolution = orderResolutionContextFromView(
    view,
    game,
    unitsById: unitsById,
  );

  final devExclusiveTiles = devExclusiveTilesFromWorld(
    game.worldState,
    playerId,
  );

  final civilianDraftMoveUnitIds = <String>{};
  for (final m in moves) {
    final u = unitsById[m.unitId];
    if (u != null && u.tileKey != null && u.tileKey!.isNotEmpty) {
      civilianDraftMoveUnitIds.add(m.unitId);
    }
  }

  final factionMembership = DiplomacyFactionMembership.from(game);

  final armiesById = <String, Army>{
    for (final a in game.worldState.armies) a.id: a,
  };

  final state = OrderValidationRunState(
    results: <OrderValidationResult>[],
    stockpile: player.stockpile,
    treasury: player.treasury,
    workerPool: player.workerPool,
  );

  runOrderValidationPhases(
    validatorFactory: validatorFactory,
    projector: projector,
    stagedOrdersSnapshot: stagedOrders,
    state: state,
    game: game,
    player: player,
    playerId: playerId,
    resolution: resolution,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    diplomatic: diplomatic,
    civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
    devExclusiveTiles: devExclusiveTiles,
    factionMembership: factionMembership,
    armiesById: armiesById,
    moves: moves,
    armyMoves: armyMoves,
    recruitWorkers: recruitWorkers,
    builds: builds,
    works: works,
    navals: navals,
    missions: missions,
    tradeOrders: tradeOrders,
  );
  return state.results;
}
