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

/// Available work targets per civilian unit (unitId → allowed target ids).
///
/// **SPEC/program/order-suggestions.md** and **orders.md**: derived entirely from
/// [suggestWorkOrders] in `colonizethis_logic` (including dev-exclusive tile
/// reservations). The app does not compute exclusivity itself.
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
  return {
    for (final e in byUnitId.entries) e.key: e.value.toSet().toList(),
  };
});

/// Tile keys reserved for the human player’s Builder/Engineer/Merchant
/// exclusivity (in-progress work + pending dev-exclusive work orders).
///
/// **SPEC/program/order-suggestions.md** § Dev-exclusive tile reservations.
/// Exposed for UI/diagnostics; availability for assignment still flows from
/// [availableWorkTargetsProvider] and [getValidWorkOrderTileKeysWithVisibility].
final devExclusiveReservedWorkTileKeysProvider = Provider<Set<String>>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return {};

  final orders = ref.watch(currentOrdersProvider);
  final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  return devExclusiveReservedTileKeysForPlayer(game, orders, humanPlayerId);
});

/// Set of game ids for which the game-start intro dialogue has been shown.
/// SPEC/ai/dialogue-management.md § First dialogue emission point.
final gameIdsWithIntroShownProvider =
    StateProvider<Set<String>>((ref) => {});

/// When non-null, turn resolution is suspended; user must accept/reject overtures.
/// SPEC/program/dialogue-system.md, SPEC/ai/dialogue-management.md.
final pendingOverturesProvider =
    StateProvider<List<OvertureOffer>?>((ref) => null);
