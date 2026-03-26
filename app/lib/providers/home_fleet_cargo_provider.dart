import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_service_provider.dart';
import 'games_provider.dart';

class HomeFleetCargoSummary {
  const HomeFleetCargoSummary({required this.used, required this.capacity});

  final int used;
  final int capacity;
}

final homeFleetCargoSummaryProvider = Provider<HomeFleetCargoSummary>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) {
    return const HomeFleetCargoSummary(used: 0, capacity: 0);
  }

  final humanPlayer =
      game.players.where((p) => p.isHuman).firstOrNull ?? game.players.first;
  final playerId = humanPlayer.id;

  final service = ref.watch(gameServiceProvider);
  final mapData = service.getMapData(game.id);
  final tileMaps = mapData?.tileMapByRegion;
  if (tileMaps == null || tileMaps.isEmpty) {
    return HomeFleetCargoSummary(
      used: 0,
      capacity: _homeFleetCapacity(game, playerId),
    );
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
  final overseas = extraction[playerId]?.overseas ?? const <CommodityId, int>{};
  final used = overseas.values.fold<int>(0, (sum, value) => sum + value);

  return HomeFleetCargoSummary(
    used: used,
    capacity: _homeFleetCapacity(game, playerId),
  );
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
