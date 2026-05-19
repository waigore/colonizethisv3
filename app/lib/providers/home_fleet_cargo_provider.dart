import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/shell_player_context.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';

final _homeFleetCargoLog = packageLogger('home_fleet_cargo');

class HomeFleetCargoSummary {
  const HomeFleetCargoSummary({
    required this.used,
    required this.capacity,
    this.isCargoUsedReliable = true,
    this.notDefined = false,
  });

  final int used;
  final int capacity;

  /// False when overseas cargo usage could not be computed (e.g. unexpected
  /// failure); [used] is then 0 and the UI should not treat it as authoritative.
  final bool isCargoUsedReliable;
  final bool notDefined;
}

final homeFleetCargoSummaryProvider = Provider<HomeFleetCargoSummary>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) {
    return const HomeFleetCargoSummary(used: 0, capacity: 0);
  }

  final shell = ref.watch(shellPlayerContextProvider);
  if (shell.cargoNotDefined) {
    return const HomeFleetCargoSummary(used: 0, capacity: 0, notDefined: true);
  }

  final playerId = shell.viewingPlayerId ?? shell.mapPlayerIdFor(game);
  final capacity = _homeFleetCapacity(game, playerId);

  // Some widget tests mount game UI without initializing Hive-backed services.
  // Keep the indicator stable by falling back to 0/known-capacity in that case.
  try {
    final service = ref.watch(gameServiceProvider);
    final mapData = service.getMapData(game.id);
    final tileMaps = mapData?.tileMapByRegion;
    if (tileMaps == null || tileMaps.isEmpty) {
      return HomeFleetCargoSummary(used: 0, capacity: capacity);
    }

    final topology = mapData?.combinedTopology ?? const MapTopology();
    final connectivity = resolveConnectivity(
      game: game,
      tileMapByRegion: tileMaps,
      topology: topology,
    );
    final extraction = computeExtraction(
      game: game,
      tileMapByRegion: tileMaps,
      connectivityResult: connectivity,
      techCapForPlayer: (id) {
        final player = game.playerById(id);
        return extractionCapForUnlocked(player?.techUnlocked);
      },
    );
    final overseas =
        extraction[playerId]?.overseas ?? const <CommodityId, int>{};
    final used = overseas.values.fold<int>(0, (sum, value) => sum + value);

    return HomeFleetCargoSummary(used: used, capacity: capacity);
  } catch (e, stackTrace) {
    _homeFleetCargoLog.w(
      'summary_failed gameId=${game.id}',
      error: e,
      stackTrace: stackTrace,
    );
    return HomeFleetCargoSummary(
      used: 0,
      capacity: capacity,
      isCargoUsedReliable: false,
    );
  }
});

int _homeFleetCapacity(Game game, String playerId) {
  final homeFleetId = homeFleetIdFor(playerId);
  final homeFleet = game.worldState.fleets
      .where((f) => f.id == homeFleetId && f.ownerId == playerId)
      .firstOrNull;
  if (homeFleet == null) {
    return 0;
  }
  var capacity = 0;
  for (final shipTypeId in homeFleet.shipTypeIds) {
    capacity += NavalStatsCatalog.get(shipTypeId).cargoHold;
  }
  return capacity;
}
