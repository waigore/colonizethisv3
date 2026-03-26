import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
class CurrentOrdersNotifier extends Notifier<Orders> {
  CurrentOrdersNotifier([this._initial = const Orders()]);

  final Orders _initial;

  @override
  Orders build() => _initial;

  void replaceAll(Orders next) {
    state = next;
  }

  void clear() {
    state = const Orders();
  }
}

final currentOrdersProvider = NotifierProvider<CurrentOrdersNotifier, Orders>(
  CurrentOrdersNotifier.new,
);

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

  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    orders,
    tileMapByRegion: mapData?.tileMapByRegion,
  );

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
class GameIdsWithIntroShownNotifier extends Notifier<Set<String>> {
  GameIdsWithIntroShownNotifier([this._initial = const <String>{}]);

  final Set<String> _initial;

  @override
  Set<String> build() => _initial;

  void markShown(String gameId) {
    state = {...state, gameId};
  }
}

final gameIdsWithIntroShownProvider =
    NotifierProvider<GameIdsWithIntroShownNotifier, Set<String>>(
      GameIdsWithIntroShownNotifier.new,
    );

/// When non-null, turn resolution is suspended; user must accept/reject overtures.
/// SPEC/program/dialogue-system.md, SPEC/ai/dialogue-management.md.
class PendingOverturesNotifier extends Notifier<List<OvertureOffer>?> {
  PendingOverturesNotifier([this._initial]);

  final List<OvertureOffer>? _initial;

  @override
  List<OvertureOffer>? build() => _initial;

  void setPending(List<OvertureOffer>? overtures) {
    state = overtures;
  }

  void clear() {
    state = null;
  }
}

final pendingOverturesProvider =
    NotifierProvider<PendingOverturesNotifier, List<OvertureOffer>?>(
      PendingOverturesNotifier.new,
    );
