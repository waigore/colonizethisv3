import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

void expectPhaseDeltasSumToNet({
  required Game game,
  required String playerId,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  Orders currentOrders = const Orders(),
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
}) {
  final inputs = economyPreviewInputs(
    extractedByPlayerId: extractedByPlayerId,
    currentOrders: currentOrders,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
  );
  final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
    game: game,
    topology: const MapTopology(),
    playerId: playerId,
    inputs: inputs,
  );
  final net = previewStockpileNetDeltaByCommodityForPlayer(
    game: game,
    topology: const MapTopology(),
    playerId: playerId,
    inputs: inputs,
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

/// Back-compat wrapper; prefer [TestFixtures.singlePlayerGame].
Game singlePlayerGame(Player player) => TestFixtures.singlePlayerGame(player);

/// Back-compat wrapper; prefer [TestFixtures.singlePlayerWorkPreviewGame].
Game singlePlayerWorkPreviewGame({
  required Stockpile playerStockpile,
  required List<Unit> units,
  TileMapState tileState = const TileMapState(),
}) => TestFixtures.singlePlayerWorkPreviewGame(
  playerStockpile: playerStockpile,
  units: units,
  tileState: tileState,
);
