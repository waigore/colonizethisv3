import 'package:colonizethis_models/colonizethis_models.dart';

import 'utils/expando_index.dart';

/// Lazily built once per [Game] instance (issue #2268 AC-2); invalidated when a
/// new [Game] replaces the previous one via [Game.copyWith]. Routed through the
/// shared [ExpandoIndex] utility so all per-[Game] caches share one
/// invalidation contract (Refs #2836 AC 2).
final ExpandoIndex<Game, Map<String, Player>> _gamePlayersByIdIndex =
    ExpandoIndex<Game, Map<String, Player>>('gamePlayersById', (game) {
      final byId = <String, Player>{};
      for (final p in game.players) {
        byId.putIfAbsent(p.id, () => p);
      }
      return byId;
    });

/// GP whose [Player.capitalProvinceId] maps to each full province id (first in
/// [Game.players] list order wins on duplicates). Refs #2394 steal_tech paths.
final ExpandoIndex<Game, Map<String, String>>
_gameGpOwnerIdByCapitalProvinceIdIndex =
    ExpandoIndex<Game, Map<String, String>>(
      'gameGpOwnerIdByCapitalProvinceId',
      (game) {
        final byCap = <String, String>{};
        for (final p in game.players) {
          final cap = p.capitalProvinceId;
          if (cap != null) {
            byCap.putIfAbsent(cap, () => p.id);
          }
        }
        return byCap;
      },
    );

/// Faction id → display name for any [Game.players], [Game.minorNations], or
/// [Game.tribes] row (Refs #2575 Phase 3).
final ExpandoIndex<Game, Map<String, String>> _gameFactionDisplayNameByIdIndex =
    ExpandoIndex<Game, Map<String, String>>('gameFactionDisplayNameById', (
      game,
    ) {
      final byId = <String, String>{};
      for (final p in game.players) {
        byId.putIfAbsent(p.id, () => p.displayName);
      }
      for (final m in game.minorNations) {
        byId.putIfAbsent(m.id, () => m.displayName ?? m.id);
      }
      for (final t in game.tribes) {
        byId.putIfAbsent(t.id, () => t.displayName ?? t.id);
      }
      return byId;
    });

/// Fleet id → [Fleet] for any [WorldState.fleets] row (Refs #2575 Phase 4).
final ExpandoIndex<Game, Map<String, Fleet>> _gameFleetsByIdIndex =
    ExpandoIndex<Game, Map<String, Fleet>>('gameFleetsById', (game) {
      final byId = <String, Fleet>{};
      for (final f in game.worldState.fleets) {
        byId.putIfAbsent(f.id, () => f);
      }
      return byId;
    });

/// Safe player lookup by id. Returns null if not found.
extension GamePlayerLookup on Game {
  Player? playerById(String id) => _gamePlayersByIdIndex.get(this)[id];

  Player? otherGreatPowerAtCapitalProvince(
    String capitalProvinceId,
    String excludePlayerId,
  ) {
    final byCap = _gameGpOwnerIdByCapitalProvinceIdIndex.get(this);
    final ownerId = byCap[capitalProvinceId];
    if (ownerId == null || ownerId == excludePlayerId) {
      return null;
    }
    return playerById(ownerId);
  }

  String? factionDisplayNameById(String factionId) =>
      _gameFactionDisplayNameByIdIndex.get(this)[factionId];

  Fleet? fleetById(String id) => _gameFleetsByIdIndex.get(this)[id];
}
