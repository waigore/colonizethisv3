import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/widgets/shell/shell_player_context.dart';
import 'game_service_provider.dart';
import 'games_provider_current_game.dart';

/// Sorted work target ids for one civilian unit that have ≥1 valid tile
/// (selected-unit availability). SPEC/program/order-suggestions.md (Refs #2133).
///
/// The app must not use broad [suggestWorkOrders] for per-unit Assign hot paths.
final availableWorkTargetIdsForUnitProvider =
    Provider.family<List<String>, String>((ref, unitId) {
      final game = ref.watch(currentGameProvider);
      if (game == null) return const [];

      final orders = ref.watch(currentOrdersProvider);
      final service = ref.watch(gameServiceProvider);
      final mapData = service.getMapData(game.id);
      final topology = mapData?.combinedTopology ?? const MapTopology();

      final shell = ref.read(shellPlayerContextProvider);
      final humanPlayerId =
          shell.panelPlayerId ?? resolveShellPanelPlayerId(shell, game);
      final view = buildPlayerView(game, topology, humanPlayerId);

      return getAvailableWorkTargetsForUnit(
        view: view,
        game: game,
        topology: topology,
        currentOrders: orders,
        unitId: unitId,
        tileMapByRegion: mapData?.tileMapByRegion,
      ).availableWorkTargetIdsSorted();
    });

/// Tile keys reserved for the human player's Builder/Engineer/Merchant
/// exclusivity (in-progress work + pending dev-exclusive work orders).
///
/// **SPEC/program/order-suggestions.md** § Dev-exclusive tile reservations.
/// Exposed for UI/diagnostics; availability for assignment still flows from
/// [availableWorkTargetIdsForUnitProvider] and
/// [getValidWorkOrderTileKeysWithVisibility].
final devExclusiveReservedWorkTileKeysProvider = Provider<Set<String>>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return {};

  final orders = ref.watch(currentOrdersProvider);
  final shell = ref.read(shellPlayerContextProvider);
  final humanPlayerId =
      shell.panelPlayerId ?? resolveShellPanelPlayerId(shell, game);
  return devExclusiveReservedTileKeysForPlayer(game, orders, humanPlayerId);
});
