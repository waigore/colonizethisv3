import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Old World region id for two-province integration setups in turn tests.
const turnTestOldWorldRegionId = 'oldWorld';

/// Two adjacent Old World provinces connected by a topology edge.
MapTopology twoAdjacentOldWorldProvinceTopology({
  String id1 = 'P1',
  String id2 = 'P2',
  String regionId = turnTestOldWorldRegionId,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: id1,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: id2,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: id1, id2: id2)],
  );
}

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
    ),
  );
}
