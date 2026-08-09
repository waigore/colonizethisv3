import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export 'turn_combat_test_harness.dart';
export 'turn_diplomacy_test_harness.dart';
export 'turn_economy_test_harness.dart';
export 'turn_naval_test_harness.dart';
export 'turn_test_harness_common.dart';

/// Runs [resolveTurnForGame] and returns the resolved [Game], failing on pending.
Game resolveTurnComplete({
  required Game game,
  required MapTopology topology,
  Orders orders = const Orders(),
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  TurnEventSink? eventSink,
  TurnPhase? startFromPhase,
}) {
  return requireTurnResolutionComplete(
    resolveTurnForGame(
      game: game,
      topology: topology,
      orders: orders,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      extractedByPlayerId: extractedByPlayerId,
      defaultAssignments: defaultAssignments,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
      eventSink: eventSink,
      startFromPhase: startFromPhase,
    ),
  );
}
