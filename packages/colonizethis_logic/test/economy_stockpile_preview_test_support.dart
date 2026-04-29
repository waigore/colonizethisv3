import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void expectPhaseDeltasSumToNet({
  required Game game,
  required String playerId,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  Orders currentOrders = const Orders(),
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
    game: game,
    topology: const MapTopology(),
    playerId: playerId,
    extractedByPlayerId: extractedByPlayerId,
    currentOrders: currentOrders,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
  );
  final net = previewStockpileNetDeltaByCommodityForPlayer(
    game: game,
    topology: const MapTopology(),
    playerId: playerId,
    extractedByPlayerId: extractedByPlayerId,
    currentOrders: currentOrders,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
  );
  final keys = <String>{};
  for (final m in phases.values) {
    keys.addAll(m.keys);
  }
  keys.addAll(net.keys);
  for (final c in keys) {
    var sum = 0;
    for (final p in EconomyPreviewStockpilePhase.values) {
      sum += phases[p]?[c] ?? 0;
    }
    expect(sum, net[c] ?? 0, reason: 'commodity $c phase sum vs net');
  }
}

Game _singlePlayerGame(Player player) {
  return Game(
    id: 't',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [player],
  );
}

Game _singlePlayerWorkPreviewGame({
  required Stockpile playerStockpile,
  required List<Unit> units,
  TileMapState tileState = const TileMapState(),
}) {
  final player = Player(
    id: 'p1',
    displayName: 'A',
    isHuman: true,
    stockpile: playerStockpile,
  );
  return Game(
    id: 't',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        units: units,
        provinces: const [
          Province(
            id: 'ow|p1',
            regionId: 'oldWorld',
            ownerId: 'p1',
            fortLevel: 0,
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileState: tileState,
    ),
    players: [player],
  );
}
