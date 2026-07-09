// Shared fixtures for per-player work target selection cache scenarios (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

WorkTargetSelectionSnapshot ppwtscSnapshotForPlayer(String playerId) {
  return WorkTargetSelectionSnapshot(
    game: Game(
      id: 'g_$playerId',
      worldState: const WorldState(
        turnState: TurnState(
          phase: TurnPhase.orders,
          turnNumber: 1,
        ),
        oldWorld: RegionData(provinces: [], units: []),
        newWorld: RegionData(provinces: [], units: []),
      ),
      players: [
        Player(
          id: playerId,
          displayName: playerId,
          isHuman: true,
        ),
      ],
    ),
    playerId: playerId,
    playerView: PlayerView(
      playerId: playerId,
      player: Player(
        id: playerId,
        displayName: playerId,
        isHuman: true,
      ),
      ownUnitsById: const {},
      provincesById: const {},
      visibilityByTile: const {'oldWorld|p1|0|0': VisibilityLevel.fogged},
      prospectedTiles: const {},
      diplomacyByOtherId: const {},
    ),
    topology: const MapTopology(nodes: [], edges: []),
    currentOrders: const Orders(),
    tileMapByRegion: null,
  );
}
