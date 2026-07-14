// Shared order-effects projector seam scenario fixtures (Refs #3949 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const oepsRegionId = 'oldWorld';

// dart format off
final oepsTopology = const MapTopology(
  nodes: [
    TopologyNode(id: 'P1', regionId: oepsRegionId, type: TopologyNodeType.province),
  ],
  edges: [],
);
// dart format on

Game oepsGameWithPlayer(Player player) => ordersOwRegionGame(
  id: 'g',
  players: [player],
  oldWorld: RegionData(
    provinces: [
      Province(
        id: '$oepsRegionId|P1',
        regionId: oepsRegionId,
        ownerId: player.id,
      ),
    ],
    units: const [],
  ),
);

int oepsFakeProjectorInvocations = 0;

void oepsResetFakeProjectorInvocations() => oepsFakeProjectorInvocations = 0;

ProjectedEffects oepsFakeProjector({
  required Game game,
  required Orders orders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required String playerId,
  List<AssignedRecipe> defaultAssignments = const [],
}) {
  oepsFakeProjectorInvocations++;
  return const ProjectedEffects(workerCount: 99, treasuryDelta: -42);
}

OrderEngine oepsEngineWithFakeProjector() =>
    OrderEngine(projector: oepsFakeProjector);

OrderEngine oepsEngineWithoutProjector() => OrderEngine();

Player oepsBasicPlayer({String id = 'p1'}) =>
    Player(id: id, displayName: id.toUpperCase(), isHuman: true);

Player oepsGpWithTimberStockpile({String id = 'gp1', int timber = 10}) =>
    Player(
      id: id,
      displayName: id.toUpperCase(),
      isHuman: true,
      stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: timber}),
    );
