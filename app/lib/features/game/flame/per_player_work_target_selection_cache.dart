import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

typedef WorkTargetSelectionPopulationStrategy =
    Set<String> Function(WorkTargetSelectionSnapshot snapshot);

class WorkTargetSelectionSnapshot {
  const WorkTargetSelectionSnapshot({
    required this.game,
    required this.playerId,
    required this.playerView,
    required this.topology,
    required this.currentOrders,
    required this.tileMapByRegion,
  });

  final ct_models.Game game;
  final String playerId;
  final PlayerView playerView;
  final MapTopology topology;
  final ct_models.Orders currentOrders;
  final Map<String, TileMapResult>? tileMapByRegion;
}

/// App-side, per-player cache for deterministic work-target tile selection.
class PerPlayerWorkTargetSelectionCache {
  PerPlayerWorkTargetSelectionCache({
    Map<String, WorkTargetSelectionPopulationStrategy>? strategies,
  }) : _strategies = strategies == null
           ? _defaultStrategies
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
    final nextByTarget = <String, Set<String>>{};
    for (final entry in _strategies.entries) {
      final population = entry.value(snapshot);
      final sorted = population.toList()..sort();
      nextByTarget[entry.key] = LinkedHashSet<String>.from(sorted);
    }
    _cacheByPlayerAndTarget[snapshot.playerId] = nextByTarget;
  }

  void clear() {
    _cacheByPlayerAndTarget.clear();
  }

  static final Map<String, WorkTargetSelectionPopulationStrategy>
  _defaultStrategies = {
    kWorkTargetExplore: _populateExploreTargets,
    kWorkTargetBuildImprovement: _populateBuildImprovementTargets,
    kWorkTargetUpgradeTown: _populateUpgradeTownTargets,
    kWorkTargetBuildRoad: _populateBuildRoadTargets,
    kWorkTargetBuildPort: _populateBuildPortTargets,
    kWorkTargetBuildFort: _populateBuildFortTargets,
    kWorkTargetBuildRail: _populateBuildRailTargets,
  };

  static Set<String> _populateExploreTargets(WorkTargetSelectionSnapshot s) {
    final merged = <String>{};
    for (final unit in _humanCivilianUnits(s.game, s.playerId)) {
      final supportsTarget =
          workOrderTargetsByUnitType[unit.type]?.contains(kWorkTargetExplore) ??
          false;
      if (!supportsTarget) {
        continue;
      }
      final valid = getValidWorkOrderTileKeysWithVisibility(
        game: s.game,
        topology: s.topology,
        view: s.playerView,
        unitId: unit.id,
        workTarget: kWorkTargetExplore,
        currentOrders: s.currentOrders,
        tileMapByRegion: s.tileMapByRegion,
      );
      merged.addAll(valid);
    }
    return merged;
  }

  static Set<String> _populateBuildImprovementTargets(
    WorkTargetSelectionSnapshot s,
  ) {
    return _populateIdleNoPendingTargets(s, kWorkTargetBuildImprovement);
  }

  static Set<String> _populateUpgradeTownTargets(
    WorkTargetSelectionSnapshot s,
  ) {
    return _populateIdleNoPendingTargets(s, kWorkTargetUpgradeTown);
  }

  static Set<String> _populateBuildRoadTargets(WorkTargetSelectionSnapshot s) {
    return _populateIdleNoPendingTargets(s, kWorkTargetBuildRoad);
  }

  static Set<String> _populateBuildPortTargets(WorkTargetSelectionSnapshot s) {
    return _populateIdleNoPendingTargets(s, kWorkTargetBuildPort);
  }

  static Set<String> _populateBuildFortTargets(WorkTargetSelectionSnapshot s) {
    return _populateIdleNoPendingTargets(s, kWorkTargetBuildFort);
  }

  static Set<String> _populateBuildRailTargets(WorkTargetSelectionSnapshot s) {
    return _populateIdleNoPendingTargets(s, kWorkTargetBuildRail);
  }

  static Set<String> _populateIdleNoPendingTargets(
    WorkTargetSelectionSnapshot s,
    String workTarget,
  ) {
    final merged = <String>{};
    for (final unit in _humanCivilianUnits(s.game, s.playerId)) {
      final supportsTarget =
          workOrderTargetsByUnitType[unit.type]?.contains(workTarget) ?? false;
      if (!supportsTarget) {
        continue;
      }
      final isIdleNow = unit.status == ct_models.UnitStatus.idle;
      if (!isIdleNow || unit.currentWork != null) {
        continue;
      }
      if (_hasPendingWorkOrderForUnit(
        orders: s.currentOrders,
        playerId: s.playerId,
        unitId: unit.id,
      )) {
        continue;
      }
      final valid = getValidWorkOrderTileKeysWithVisibility(
        game: s.game,
        topology: s.topology,
        view: s.playerView,
        unitId: unit.id,
        workTarget: workTarget,
        currentOrders: s.currentOrders,
        tileMapByRegion: s.tileMapByRegion,
      );
      merged.addAll(valid);
    }
    return merged;
  }

  static Iterable<ct_models.Unit> _humanCivilianUnits(
    ct_models.Game game,
    String playerId,
  ) sync* {
    for (final unit in game.worldState.oldWorld.units) {
      if (unit.ownerId == playerId) {
        yield unit;
      }
    }
    for (final unit in game.worldState.newWorld.units) {
      if (unit.ownerId == playerId) {
        yield unit;
      }
    }
  }

  static bool _hasPendingWorkOrderForUnit({
    required ct_models.Orders orders,
    required String playerId,
    required String unitId,
  }) {
    final pendingByPlayer = orders.workOrdersByPlayerId[playerId] ?? const [];
    for (final pending in pendingByPlayer) {
      if (pending.unitId == unitId) {
        return true;
      }
    }
    return false;
  }
}
