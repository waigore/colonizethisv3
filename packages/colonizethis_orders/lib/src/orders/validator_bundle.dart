import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'order_resolution_context.dart';
import 'order_validators.dart';

/// Treasury available for build validation after pending riches cash-in.
int projectedTreasuryForBuildValidation({
  required Game game,
  required Stockpile stockpile,
  required int treasury,
}) =>
    treasury +
    pendingRichesTreasuryDelta(
      stockpile: stockpile,
      richesCashMultiplier: game.richesCashMultiplier,
    );

/// Shared recruit-worker validator construction for full-pass and incremental
/// probe paths (Refs #3877).
RecruitWorkerOrderValidator createProjectedRecruitWorkerValidator({
  required Player player,
  required Stockpile stockpile,
  required int treasury,
  required WorkerPool workerPool,
}) =>
    RecruitWorkerOrderValidator.withProjectedEconomy(
      player: player,
      stockpile: stockpile,
      treasury: treasury,
      workerPool: workerPool,
    );

/// Shared build validator construction for full-pass and incremental probe
/// paths (Refs #3877).
BuildOrderValidator createProjectedBuildValidator({
  required Game game,
  required Player player,
  required Stockpile stockpile,
  required int treasury,
  required WorkerPool workerPool,
}) =>
    BuildOrderValidator.withProjectedEconomy(
      game: game,
      player: player,
      stockpile: stockpile,
      treasury: projectedTreasuryForBuildValidation(
        game: game,
        stockpile: stockpile,
        treasury: treasury,
      ),
      workerPool: workerPool,
    );

/// Shared diplomatic validator construction for full-pass and incremental
/// probe paths (Refs #3877).
DiplomaticOrderValidator createProjectedDiplomaticValidator({
  required Game game,
  required String playerId,
  required int initialTreasury,
  required DiplomacyFactionMembership factionMembership,
}) =>
    DiplomaticOrderValidator(
      game: game,
      playerId: playerId,
      initialTreasury: initialTreasury,
      factionMembership: factionMembership,
    );

/// Validators for a single full-pass player order validation slice, built with
/// aligned work-order context and economy state (Refs #2391 AC6,
/// SPEC/program/order-engine.md).
class OrderValidators {
  const OrderValidators({
    required this.moveValidator,
    required this.armyMoveValidator,
    required this.recruitWorkerValidator,
    required this.buildValidator,
    required this.workValidator,
    required this.diplomaticValidator,
    required this.navalValidator,
  });

  final MoveValidator moveValidator;
  final ArmyMoveValidator armyMoveValidator;
  final RecruitWorkerOrderValidator recruitWorkerValidator;
  final BuildOrderValidator buildValidator;
  final WorkOrderValidator workValidator;
  final DiplomaticOrderValidator diplomaticValidator;
  final NavalOrderValidator navalValidator;
}

/// Shared [WorkOrderValidationContext] construction for [OrderEngine] and
/// [IncrementalCandidateValidator] so probe and full-pass paths stay aligned.
///
/// [resolution] threads the canonical [OrderResolutionContext] record
/// (`view` + `unitsById` + `provinceById`) so the per-pass snapshot built
/// by the engine entry-point flows through one shared record instead of
/// two free-standing parameters (Refs #2836 AC 3).
WorkOrderValidationContext buildWorkOrderValidationContext({
  required Game game,
  required Player player,
  required String playerId,
  required OrderResolutionContext resolution,
  required Set<String> devExclusiveTiles,
  required Map<String, TileMapResult>? tileMapByRegion,
  required Set<String> civilianDraftMoveUnitIds,
  required List<DiplomaticOrder> diplomaticOrders,
  required MapTopology topology,
  DiplomacyFactionMembership? factionMembership,
}) {
  return WorkOrderValidationContext(
    game: game,
    player: player,
    playerId: playerId,
    view: resolution.view,
    unitsById: resolution.unitsById,
    devExclusiveTiles: devExclusiveTiles,
    tileMapByRegion: tileMapByRegion,
    civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
    diplomaticOrders: diplomaticOrders,
    topology: topology,
    factionMembership: factionMembership,
  );
}

/// Single [WorkOrderValidator] aligned with [createOrderValidators] without
/// constructing the full [OrderValidators] bundle (Refs #2391 AC6,
/// SPEC/program/order-engine.md — incremental work probes stay lean).
///
/// [resolution] threads the canonical [OrderResolutionContext] (`view` +
/// `unitsById` + `provinceById`) so the work-order probe layer reuses the
/// same pass snapshot the engine entry-point already built (Refs #2836
/// AC 3). The internal call to [buildWorkOrderValidationContext] forwards
/// the record verbatim.
WorkOrderValidator createWorkOrderValidator({
  required Game game,
  required Player player,
  required String playerId,
  required OrderResolutionContext resolution,
  required MapTopology topology,
  required List<DiplomaticOrder> diplomaticOrders,
  required Map<String, TileMapResult>? tileMapByRegion,
  required Set<String> civilianDraftMoveUnitIds,
  required Set<String> devExclusiveTiles,
  required Stockpile stockpile,
  required int treasury,
  required DiplomacyFactionMembership factionMembership,
  Set<String> initialSeenUnitIds = const <String>{},
}) {
  final workContext = buildWorkOrderValidationContext(
    game: game,
    player: player,
    playerId: playerId,
    resolution: resolution,
    devExclusiveTiles: devExclusiveTiles,
    tileMapByRegion: tileMapByRegion,
    civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
    diplomaticOrders: diplomaticOrders,
    topology: topology,
    factionMembership: factionMembership,
  );
  return WorkOrderValidator(
    context: workContext,
    stockpile: stockpile,
    treasury: treasury,
    initialSeenUnitIds: initialSeenUnitIds,
  );
}

/// Factory for the default validator bundle used by [OrderEngine] and for
/// economy projection inside incremental candidate validation.
///
/// [resolution] threads the canonical [OrderResolutionContext] record
/// (`view` + `unitsById` + `provinceById`) built once by the engine entry
/// point so the bundle factory does not reconstruct `view` or rescan the
/// world for unit / province indexes (Refs #2836 AC 3;
/// SPEC/program/logic-validator-units-params.md). The work-validator
/// branch forwards the record verbatim into [createWorkOrderValidator].
///
/// [workerPool] is the projected worker pool state after any previously
/// accepted `RecruitWorkerOrder`s in the same validation pass (peasant
/// reservation ledger, SPEC/game/workers-and-population.md § Peasant
/// reservation). Pass `player.workerPool` when no recruit orders are in
/// scope.
OrderValidators createOrderValidators({
  required Game game,
  required Player player,
  required String playerId,
  required OrderResolutionContext resolution,
  required MapTopology topology,
  required List<DiplomaticOrder> diplomaticOrders,
  required Map<String, TileMapResult>? tileMapByRegion,
  required Set<String> civilianDraftMoveUnitIds,
  required Set<String> devExclusiveTiles,
  required Stockpile stockpile,
  required int treasury,
  required DiplomacyFactionMembership factionMembership,
  WorkerPool? workerPool,
}) {
  final projectedWorkerPool = workerPool ?? player.workerPool;
  return OrderValidators(
    moveValidator: const MoveValidator(),
    armyMoveValidator: const ArmyMoveValidator(),
    recruitWorkerValidator: createProjectedRecruitWorkerValidator(
      player: player,
      stockpile: stockpile,
      treasury: treasury,
      workerPool: projectedWorkerPool,
    ),
    buildValidator: createProjectedBuildValidator(
      game: game,
      player: player,
      stockpile: stockpile,
      treasury: treasury,
      workerPool: projectedWorkerPool,
    ),
    workValidator: createWorkOrderValidator(
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
    ),
    diplomaticValidator: createProjectedDiplomaticValidator(
      game: game,
      playerId: playerId,
      initialTreasury: treasury,
      factionMembership: factionMembership,
    ),
    navalValidator: NavalOrderValidator(
      game: game,
      topology: topology,
      playerId: playerId,
    ),
  );
}
