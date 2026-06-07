import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart';

/// Per-player resolved indexes for order suggestion and incremental validation.
///
/// Built once per suggestion pass and threaded through probe helpers so
/// candidate loops do not repeat [buildPlayerView] or unit-map scans.
/// SPEC/program/order-suggestions.md § Throughput bounds; Refs #2836 AC 3.
typedef OrderResolutionContext = ({
  PlayerView view,
  Map<String, Unit> unitsById,
  Map<String, Province> provinceById,
});

/// Builds [OrderResolutionContext] for [playerId], reusing optional [view] /
/// [unitsById] when the caller already computed them for this pass.
OrderResolutionContext buildOrderResolutionContext({
  required Game game,
  required MapTopology topology,
  required String playerId,
  PlayerView? view,
  Map<String, Unit>? unitsById,
}) {
  final effectiveView = view ?? buildPlayerView(game, topology, playerId);
  assert(
    effectiveView.playerId == playerId,
    'shared PlayerView playerId must match playerId',
  );
  return (
    view: effectiveView,
    unitsById: unitsById ?? game.worldState.allUnitsById,
    provinceById: effectiveView.provincesById,
  );
}

/// When [view] is already the pass snapshot, builds context without rescanning
/// provinces (province map aliases [PlayerView.provincesById]).
OrderResolutionContext orderResolutionContextFromView(
  PlayerView view,
  Game game, {
  Map<String, Unit>? unitsById,
}) {
  return (
    view: view,
    unitsById: unitsById ?? game.worldState.allUnitsById,
    provinceById: view.provincesById,
  );
}
