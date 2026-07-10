// Shared order-effects projector seam scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const oepsRegionId = 'oldWorld';

final oepsTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: oepsRegionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game oepsGameWithPlayer(Player player) => Game(
  id: 'g',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
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
    newWorld: const RegionData(),
  ),
  players: [player],
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
