import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_service_provider.dart';

/// List of saved game ids. Refreshed by reading from GameService.
final gameListIdsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(gameServiceProvider);
  return service.listGameIds();
});

/// Currently loaded game, if any. Updated on load and after next turn.
final currentGameProvider = StateProvider<Game?>((ref) => null);

/// Current-turn orders for the human player (work orders, move orders, etc.).
/// Updated when the player assigns/cancels work in the civilian panel; passed to nextTurn and reset after resolution.
final currentOrdersProvider = StateProvider<Orders>((ref) => const Orders());

/// Computes available work targets for each civilian unit at turn start.
/// Returns a map from unitId to list of work targets that have at least one valid tile.
final availableWorkTargetsProvider = Provider<Map<String, List<String>>>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return {};

  final orders = ref.watch(currentOrdersProvider);
  final service = ref.watch(gameServiceProvider);
  final mapData = service.getMapData(game.id);
  final topology = mapData?.combinedTopology ?? const MapTopology();

  final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  final view = buildPlayerView(game, topology, humanPlayerId);

  final suggestions = suggestWorkOrders(view, game, topology, orders);

  final byUnitId = <String, List<String>>{};
  for (final order in suggestions) {
    byUnitId.putIfAbsent(order.unitId, () => []).add(order.target);
  }
  for (final list in byUnitId.values) {
    list.toSet().toList();
  }
  return byUnitId;
});
