import 'dart:collection';

import 'order_suggestion_pass_context.dart';
import 'work_target_selection_population.dart';

export 'work_target_selection_snapshot.dart';

/// Per-player cache for deterministic work-target tile selection (UI + workers).
///
/// Population delegates to [getValidWorkOrderTileKeysWithVisibility] and shared
/// work-target tables. Callers own instance lifetime and [refresh] boundaries.
class PerPlayerWorkTargetSelectionCache {
  PerPlayerWorkTargetSelectionCache({
    Map<String, WorkTargetSelectionPopulationStrategy>? strategies,
  }) : _strategies = strategies == null
           ? workTargetSelectionDefaultStrategies
           : Map<String, WorkTargetSelectionPopulationStrategy>.from(
               strategies,
             );

  final Map<String, WorkTargetSelectionPopulationStrategy> _strategies;
  final Map<String, Map<String, Set<String>>> _cacheByPlayerAndTarget = {};

  Set<String> get(String playerId, String workTarget) {
    final playerCache = _cacheByPlayerAndTarget[playerId];
    if (playerCache == null) {
      return const <String>{};
    }
    return playerCache[workTarget] ?? const <String>{};
  }

  bool contains(String playerId, String workTarget, String tileKey) {
    return get(playerId, workTarget).contains(tileKey);
  }

  List<String> sorted(String playerId, String workTarget) {
    final out = get(playerId, workTarget).toList()..sort();
    return out;
  }

  void refresh(WorkTargetSelectionSnapshot snapshot) {
    final sharedValidator = sharedOrBuildWorkTargetValidator(snapshot);
    final playerOwnedProvinceIds =
        snapshot.playerOwnedProvinceIds ??
        ownedProvinceIdsFromView(snapshot.playerView, snapshot.playerId);
    final snapshotForPopulation = WorkTargetSelectionSnapshot(
      game: snapshot.game,
      playerId: snapshot.playerId,
      playerView: snapshot.playerView,
      topology: snapshot.topology,
      currentOrders: snapshot.currentOrders,
      tileMapByRegion: snapshot.tileMapByRegion,
      sharedCandidateValidator: sharedValidator,
      playerOwnedProvinceIds: playerOwnedProvinceIds,
    );
    final nextByTarget = <String, Set<String>>{};
    for (final entry in _strategies.entries) {
      final population = entry.value(snapshotForPopulation);
      final sorted = population.toList()..sort();
      nextByTarget[entry.key] = LinkedHashSet<String>.from(sorted);
    }
    _cacheByPlayerAndTarget[snapshot.playerId] = nextByTarget;
  }

  void clear() {
    _cacheByPlayerAndTarget.clear();
  }
}
