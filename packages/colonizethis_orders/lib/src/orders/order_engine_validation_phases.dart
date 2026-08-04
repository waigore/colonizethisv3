/// Per-category validation phase runners for [runOrderValidationPhases].
///
/// Split from `order_engine_validation.dart` so the orchestrator stays under
/// the wave-6 physical-line ratchet (Refs #4246).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'order_effects_projector.dart';
import 'order_resolution_context.dart';
import 'order_validation_result_append.dart';
import 'order_validator_factory.dart';
import 'order_engine_validation_state.dart';

void runMoveValidationPhase(
  OrderValidators v,
  OrderValidationRunState state,
  List<MoveOrder> moves,
  Game game,
  String playerId,
  OrderResolutionContext resolution,
  List<DiplomaticOrder> diplomatic,
  MapTopology topology,
  DiplomacyFactionMembership factionMembership,
) {
  // [resolution] is the per-pass snapshot built once in
  // [validatePlayerOrdersWithContext]; the per-move
  // [MoveValidator.validate] call reuses it directly so probes do not
  // rebuild equivalent `view` / `unitsById` maps (Refs #2836 AC 3;
  // SPEC/program/logic-validator-units-params.md).
  state.rejected = appendValidationResults(
    state.results,
    moves,
    state.rejected,
    (o, prev) => v.moveValidator.validate(
      o,
      game,
      playerId,
      resolution,
      diplomatic,
      topology,
      previousRejected: prev,
      factionMembership: factionMembership,
    ),
  );
}

void runArmyMoveValidationPhase(
  OrderValidators v,
  OrderValidationRunState state,
  List<ArmyMoveOrder> armyMoves,
  Game game,
  String playerId,
  List<DiplomaticOrder> diplomatic,
  PlayerView view,
  MapTopology topology,
  Map<String, Army> armiesById,
  DiplomacyFactionMembership factionMembership,
) {
  state.rejected = appendValidationResults(
    state.results,
    armyMoves,
    state.rejected,
    (o, prev) => v.armyMoveValidator.validate(
      o,
      game,
      playerId,
      diplomatic,
      view,
      topology,
      previousRejected: prev,
      armiesById: armiesById,
      factionMembership: factionMembership,
    ),
  );
}

void runDiplomaticValidationPhase(
  OrderValidators v,
  OrderValidationRunState state,
  List<DiplomaticOrder> diplomatic,
) {
  final afterDiplomatic =
      appendValidationResultsWithState<DiplomaticOrder, int>(
        state.results,
        diplomatic,
        state.rejected,
        state.treasury,
        (o, prev) {
          final r = v.diplomaticValidator.validate(o, previousRejected: prev);
          return (result: r.result, state: r.treasury);
        },
      );
  state.rejected = afterDiplomatic.rejected;
  state.treasury = afterDiplomatic.state;
}

void runNavalValidationPhase(
  OrderValidators v,
  OrderValidationRunState state,
  List<NavalMoveOrder> navals,
  List<NavalMissionOrder> missions,
) {
  state.rejected = appendValidationResults(
    state.results,
    navals,
    state.rejected,
    (o, prev) => v.navalValidator.validateNavalMove(o, previousRejected: prev),
  );
  state.rejected = appendValidationResults(
    state.results,
    missions,
    state.rejected,
    (o, prev) =>
        v.navalValidator.validateNavalMission(o, previousRejected: prev),
  );
}

void runTradeOrderValidationPhase(
  OrderValidationRunState state,
  Game game,
  String playerId,
  List<TradeOrder> tradeOrders,
  MapTopology topology,
  Orders stagedOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  OrderEffectsProjector? projector,
) {
  if (tradeOrders.isEmpty) return;
  if (state.rejected) {
    for (var i = 0; i < tradeOrders.length; i++) {
      state.results.add(previousInvalidOrderResult);
    }
    return;
  }
  // The projected non-bid treasury delta is a turn-layer dry-run
  // (`projectOrderEffects` calls `resolveTurnForGame`) that lives in the neutral
  // `lib/src/projections/` core module — above the `orders` domain. The engine
  // therefore receives it as an injected [OrderEffectsProjector] (Refs #3290
  // C2) and hands the resulting delta to the (economy-local) context builder,
  // keeping both `orders` free of any `projections`/`turn` import and `economy`
  // free of any `orders`/`turn` import per
  // `SPEC/program/logic-package-split-phase0.md`.
  if (projector == null) {
    throw StateError(
      'OrderEngine trade-order validation requires an injected '
      'OrderEffectsProjector; construct OrderEngine(projector: '
      'projectOrderEffects).',
    );
  }
  final projected = projector(
    game: game,
    orders: stagedOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion ?? const {},
    playerId: playerId,
  );
  final context = tradeOrderValidationContextFromGame(
    game,
    playerId,
    stagedOrders: stagedOrders,
    projectedTreasuryDelta: projected.treasuryDelta ?? 0,
  );
  final tradeResults = TradeOrderValidator.validate(
    context: context,
    proposedOrders: tradeOrders,
  );
  state.results.addAll(tradeResults);
  if (tradeResults.any((r) => !r.isAccepted)) {
    state.rejected = true;
  }
}
