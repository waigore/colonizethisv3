import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/shell_player_context.dart';
import 'game_service_provider.dart';
import 'game_summary_support.dart';
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
  return computeGameSummary<HomeFleetCargoSummary>(
    game: ref.watch(currentGameProvider),
    shell: ref.watch(shellPlayerContextProvider),
    orders: ref.watch(currentOrdersProvider),
    gameService: ref.watch(gameServiceProvider),
    whenNoGame: const HomeFleetCargoSummary(used: 0, capacity: 0),
    notDefined: (shell) => shell.cargoNotDefined,
    whenNotDefined: () =>
        const HomeFleetCargoSummary(used: 0, capacity: 0, notDefined: true),
    log: _homeFleetCargoLog,
    compute: (context) {
      final game = context.game;
      final capacity = _homeFleetCapacity(game, context.playerId);
      // Some widget tests mount game UI without initializing Hive-backed
      // services; fall back to 0 used with the known capacity in that case.
      if (!context.hasMapData) {
        return HomeFleetCargoSummary(used: 0, capacity: capacity);
      }

      final connectivity = resolveConnectivity(
        game: game,
        tileMapByRegion: context.tileMapByRegion!,
        topology: context.topology,
      );
      final extraction = computeExtraction(
        game: game,
        tileMapByRegion: context.tileMapByRegion!,
        connectivityResult: connectivity,
        techCapForPlayer: (id) {
          final player = game.playerById(id);
          return extractionCapForUnlocked(player?.techUnlocked);
        },
      );
      final overseas =
          extraction[context.playerId]?.overseas ?? const <CommodityId, int>{};
      final used = overseas.values.fold<int>(0, (sum, value) => sum + value);

      return HomeFleetCargoSummary(used: used, capacity: capacity);
    },
    onError: (game, playerId) => HomeFleetCargoSummary(
      used: 0,
      capacity: _homeFleetCapacity(game, playerId),
      isCargoUsedReliable: false,
    ),
  );
});

int _homeFleetCapacity(Game game, String playerId) {
  final homeFleetId = homeFleetIdFor(playerId);
  final candidate = game.fleetById(homeFleetId);
  final homeFleet = candidate != null && candidate.ownerId == playerId
      ? candidate
      : null;
  if (homeFleet == null) {
    return 0;
  }
  var capacity = 0;
  for (final shipTypeId in homeFleet.shipTypeIds) {
    capacity += NavalStatsCatalog.get(shipTypeId).cargoHold;
  }
  return capacity;
}
