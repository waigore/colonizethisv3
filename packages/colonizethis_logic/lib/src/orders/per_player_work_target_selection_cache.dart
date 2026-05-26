import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import 'incremental_candidate_validator.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_work_tile_keys.dart';

/// Inputs for populating per-player work-target tile selection caches.
///
/// SPEC/program/order-suggestions.md — cache contract; Refs #2277 (worker reuse).
class WorkTargetSelectionSnapshot {
  const WorkTargetSelectionSnapshot({
    required this.game,
    required this.playerId,
    required this.playerView,
    required this.topology,
    required this.currentOrders,
    required this.tileMapByRegion,
    this.sharedCandidateValidator,
    this.playerOwnedProvinceIds,
  });

  final Game game;
  final String playerId;
  final PlayerView playerView;
  final MapTopology topology;
  final Orders currentOrders;
  final Map<String, TileMapResult>? tileMapByRegion;

  /// Prefixed province ids owned by [playerId]. When set on a snapshot passed to
  /// [PerPlayerWorkTargetSelectionCache.refresh], population reuses this set
  /// instead of rescanning [allProvinces] per unit × work target (Refs #2394).
  final Set<String>? playerOwnedProvinceIds;

  /// When non-null on the **output** snapshot passed to population strategies,
  /// all default population paths reuse this instance instead of rebuilding
  /// [IncrementalCandidateValidator.forPlayer] per work target (Refs #2394).
  ///
  /// Callers may also set this on the **input** snapshot passed to [refresh];
  /// when set, [refresh] reuses that validator instead of constructing one
  /// (must match the same `(game, topology, playerId, currentOrders, …)` tuple).
  final IncrementalCandidateValidator? sharedCandidateValidator;
}

typedef WorkTargetSelectionPopulationStrategy =
    Set<String> Function(WorkTargetSelectionSnapshot snapshot);

/// Per-player cache for deterministic work-target tile selection (UI + workers).
///
/// Population delegates to [getValidWorkOrderTileKeysWithVisibility] and shared
/// work-target tables. Callers own instance lifetime and [refresh] boundaries.
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

  /// Reuses [WorkTargetSelectionSnapshot.sharedCandidateValidator] when set;
  /// otherwise builds one and pays [DiplomacyFactionMembership.from] only on
  /// that path (Refs #2394 — avoid redundant membership scans per strategy).
  static IncrementalCandidateValidator _sharedOrBuildValidator(
    WorkTargetSelectionSnapshot s,
  ) {
    final existing = s.sharedCandidateValidator;
    if (existing != null) {
      return existing;
    }
    return buildIncrementalCandidateValidator(
      game: s.game,
      topology: s.topology,
      playerId: s.playerId,
      baseOrders: s.currentOrders,
      tileMapByRegion: s.tileMapByRegion,
      view: s.playerView,
      unitsById: s.game.worldState.allUnitsById,
      factionMembership: DiplomacyFactionMembership.from(s.game),
    );
  }

  void refresh(WorkTargetSelectionSnapshot snapshot) {
    final sharedValidator = _sharedOrBuildValidator(snapshot);
    final playerOwnedProvinceIds =
        snapshot.playerOwnedProvinceIds ??
        <String>{
          for (final e in snapshot.playerView.provincesById.entries)
            if (e.value.ownerId == snapshot.playerId) e.key,
        };
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

  static final Map<String, WorkTargetSelectionPopulationStrategy>
  _defaultStrategies = {
    kWorkTargetExplore: _populateExploreTargets,
    kWorkTargetStealTech: _populateStealTechTargets,
    kWorkTargetCounterSpy: _populateCounterSpyTargets,
    kWorkTargetPurchaseLand: _populatePurchaseLandTargets,
    kWorkTargetProspect: _populateProspectTargets,
    kWorkTargetBuildImprovement: _populateBuildImprovementTargets,
    kWorkTargetUpgradeTown: _populateUpgradeTownTargets,
    kWorkTargetBuildRoad: _populateBuildRoadTargets,
    kWorkTargetBuildPort: _populateBuildPortTargets,
    kWorkTargetBuildFort: _populateBuildFortTargets,
    kWorkTargetBuildRail: _populateBuildRailTargets,
  };

  static Set<String> _populateExploreTargets(WorkTargetSelectionSnapshot s) {
    return _populateMergedValidForTarget(s, kWorkTargetExplore);
  }

  static Set<String> _populateStealTechTargets(WorkTargetSelectionSnapshot s) {
    return _populateMergedValidForTarget(s, kWorkTargetStealTech);
  }

  static Set<String> _populateCounterSpyTargets(WorkTargetSelectionSnapshot s) {
    return _populateMergedValidForTarget(s, kWorkTargetCounterSpy);
  }

  static Set<String> _populatePurchaseLandTargets(
    WorkTargetSelectionSnapshot s,
  ) {
    return _populateMergedValidForTarget(s, kWorkTargetPurchaseLand);
  }

  /// Per-unit union of `getValidWorkOrderTileKeysWithVisibility` (same as
  /// `explore` cache population).
  static Set<String> _populateMergedValidForTarget(
    WorkTargetSelectionSnapshot s,
    String workTarget,
  ) {
    final sharedValidator = _sharedOrBuildValidator(s);
    final merged = <String>{};
    for (final unit in _humanCivilianUnits(s.game, s.playerId)) {
      final supportsTarget =
          workOrderTargetsByUnitType[unit.type]?.contains(workTarget) ?? false;
      if (!supportsTarget) {
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
        sharedCandidateValidator: sharedValidator,
        playerOwnedProvinceIds: s.playerOwnedProvinceIds,
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

  static Set<String> _populateProspectTargets(WorkTargetSelectionSnapshot s) {
    return _populateIdleNoPendingTargets(s, kWorkTargetProspect);
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
    final sharedValidator = _sharedOrBuildValidator(s);
    final pendingWorkUnitIds = <String>{
      for (final w
          in s.currentOrders.workOrdersByPlayerId[s.playerId] ??
              const <WorkOrder>[])
        w.unitId,
    };
    final merged = <String>{};
    for (final unit in _humanCivilianUnits(s.game, s.playerId)) {
      final supportsTarget =
          workOrderTargetsByUnitType[unit.type]?.contains(workTarget) ?? false;
      if (!supportsTarget) {
        continue;
      }
      final isIdleNow = unit.status == UnitStatus.idle;
      if (!isIdleNow || unit.currentWork != null) {
        continue;
      }
      if (pendingWorkUnitIds.contains(unit.id)) {
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
        sharedCandidateValidator: sharedValidator,
        playerOwnedProvinceIds: s.playerOwnedProvinceIds,
      );
      merged.addAll(valid);
    }
    return merged;
  }

  static Iterable<Unit> _humanCivilianUnits(Game game, String playerId) sync* {
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
}
