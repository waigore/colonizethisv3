import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'order_resolution_context.dart';

/// Resolved [PlayerView] / unit-map / diplomatic prefix for one
/// [IncrementalCandidateValidator] construction (Refs #4508).
///
/// When the caller already built [resolution] for this suggestion pass, pass
/// it to skip embedded `buildPlayerView` and unit-map scans (Refs #2394,
/// #2836; `SPEC/program/order-suggestions.md` § Throughput bounds). The
/// shared instance must be built from the **same** inputs as the validator;
/// behavior is undefined otherwise.
({
  PlayerView view,
  Map<String, Unit> unitsById,
  List<DiplomaticOrder> diplomaticOrders,
})
resolveIncrementalCandidateValidatorPass({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  OrderResolutionContext? resolution,
}) {
  final ctx =
      resolution ??
      buildOrderResolutionContext(
        game: game,
        topology: topology,
        playerId: playerId,
      );
  assert(
    ctx.view.playerId == playerId,
    'OrderResolutionContext view playerId must match validator playerId',
  );
  return (
    view: ctx.view,
    unitsById: ctx.unitsById,
    diplomaticOrders:
        basePrefix.diplomaticOrdersByPlayerId[playerId] ??
        const <DiplomaticOrder>[],
  );
}
