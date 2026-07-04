import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_resolution_context.dart';
import 'validator_bundle.dart';

export 'validator_bundle.dart'
    show
        OrderValidators,
        createOrderValidators,
        createProjectedBuildValidator,
        createProjectedDiplomaticValidator,
        createProjectedRecruitWorkerValidator,
        createWorkOrderValidator;

/// Canonical entry for validator construction shared by full-pass
/// [runOrderValidationPhases] and incremental candidate replay (Refs #3877).
///
/// Full-pass validation supplies an [OrderValidatorFactory] (typically
/// [createOrderValidators]). Incremental probes call the per-category
/// [createProjectedRecruitWorkerValidator], [createProjectedBuildValidator],
/// [createWorkOrderValidator], and [createProjectedDiplomaticValidator]
/// factories exported here — the same helpers [createOrderValidators] uses
/// internally so both paths stay aligned.

/// Builds the per-bundle [OrderValidators] for one validation slice.
///
/// [resolution] threads the canonical [OrderResolutionContext] record
/// (`view` + `unitsById` + `provinceById`) so factories reuse the
/// per-pass snapshot the engine entry-point already built instead of
/// rebuilding the player view or unit-by-id map (Refs #2836 AC 3;
/// SPEC/program/logic-validator-units-params.md).
typedef OrderValidatorFactory =
    OrderValidators Function(
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
    );
