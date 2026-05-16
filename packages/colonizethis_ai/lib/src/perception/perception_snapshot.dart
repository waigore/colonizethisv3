import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'perception_topology.dart';

final _log = packageLogger();

/// Summary of threats (e.g. hostile neighbors, weak borders).
class ThreatSummary {
  const ThreatSummary({
    this.atWarWith = const [],
    this.neighborProvincesHostile = 0,
    this.capitalThreatened = false,
  });

  final List<String> atWarWith;
  final int neighborProvincesHostile;
  final bool capitalThreatened;
}

/// Summary of opportunities (e.g. weak targets, rich provinces).
class OpportunitySummary {
  const OpportunitySummary({
    this.weakNeighbors = const [],
    this.richUnexploitedProvinces = 0,
    this.unclaimedProvinces = 0,
  });

  final List<String> weakNeighbors;
  final int richUnexploitedProvinces;
  final int unclaimedProvinces;
}

/// Victory-pace and invasion targets from PlayerView. SPEC/ai/ai-architecture.md.
class ConquestSummary {
  const ConquestSummary({
    this.oldWorldProvincesOwned = 0,
    this.provincesToVictory = kMilitaryVictoryOldWorldProvinceThreshold,
    this.invadableProvinceIdsSorted = const [],
    this.preferredConquestTargetFactionIdsSorted = const [],
  });

  final int oldWorldProvincesOwned;
  final int provincesToVictory;
  final List<String> invadableProvinceIdsSorted;
  final List<String> preferredConquestTargetFactionIdsSorted;
}

/// Economy summary from view (stockpile, workers, treasury).
class EconomySummary {
  const EconomySummary({
    this.workerCount = 0,
    this.treasury = 0,
    this.ownProvinceCount = 0,
  });

  final int workerCount;
  final int treasury;
  final int ownProvinceCount;
}

/// World snapshot for AI: threats, opportunities, economy, relations.
/// Built only from [PlayerView]; used by goal manager and domain planners.
class AIWorldSnapshot {
  const AIWorldSnapshot({
    required this.playerId,
    required this.threats,
    required this.opportunities,
    required this.conquest,
    required this.economy,
    required this.relations,
  });

  final String playerId;
  final ThreatSummary threats;
  final OpportunitySummary opportunities;
  final ConquestSummary conquest;
  final EconomySummary economy;

  /// Relation state keyed by other faction id (war, peace, etc.).
  final Map<String, DiplomacyRelation> relations;

  /// Builds snapshot from [view]. Deterministic: same view -> same snapshot.
  static AIWorldSnapshot fromPlayerView(
    PlayerView view, {
    MapTopology? topology,
  }) {
    final threats = _buildThreatSummary(view, topology);
    final opportunities = _buildOpportunitySummary(view, topology);
    final conquest = _buildConquestSummary(view, topology, threats, opportunities);
    final economy = _buildEconomySummary(view);
    final snapshot = AIWorldSnapshot(
      playerId: view.playerId,
      threats: threats,
      opportunities: opportunities,
      conquest: conquest,
      economy: economy,
      relations: Map<String, DiplomacyRelation>.from(view.diplomacyByOtherId),
    );
    _log.d(
      'snapshot playerId=${snapshot.playerId} '
      'atWarWith=${snapshot.threats.atWarWith} '
      'neighborProvincesHostile=${snapshot.threats.neighborProvincesHostile} '
      'capitalThreatened=${snapshot.threats.capitalThreatened} '
      'weakNeighbors=${snapshot.opportunities.weakNeighbors} '
      'richUnexploitedProvinces=${snapshot.opportunities.richUnexploitedProvinces} '
      'unclaimedProvinces=${snapshot.opportunities.unclaimedProvinces} '
      'oldWorldProvincesOwned=${snapshot.conquest.oldWorldProvincesOwned} '
      'provincesToVictory=${snapshot.conquest.provincesToVictory} '
      'invadableCount=${snapshot.conquest.invadableProvinceIdsSorted.length} '
      'workerCount=${snapshot.economy.workerCount} '
      'treasury=${snapshot.economy.treasury} '
      'ownProvinceCount=${snapshot.economy.ownProvinceCount} '
      'relationsKeys=${snapshot.relations.keys.toList()}',
    );
    return snapshot;
  }

  static ThreatSummary _buildThreatSummary(
    PlayerView view,
    MapTopology? topology,
  ) {
    final atWarWith = <String>[];
    for (final e in view.diplomacyByOtherId.entries) {
      final rel = e.value;
      if (rel.state == RelationState.atWar) {
        atWarWith.add(e.key);
      }
    }
    if (topology == null) {
      return ThreatSummary(atWarWith: atWarWith);
    }
    final ownedIds = <String>{};
    for (final p in view.provincesById.entries) {
      if (p.value.ownerId == view.playerId) ownedIds.add(p.key);
    }
    var neighborProvincesHostile = 0;
    final neighborProvinceIds = neighborProvinceIdsFromTopology(
      topology,
      ownedIds,
      view,
    );
    for (final neighborFullId in neighborProvinceIds) {
      final prov = view.provincesById[neighborFullId];
      if (prov == null) continue;
      final ownerId = prov.ownerId;
      if (ownerId == null || ownerId.isEmpty || ownerId == view.playerId)
        continue;
      final rel = view.diplomacyByOtherId[ownerId];
      if (rel != null && rel.state == RelationState.atWar) {
        neighborProvincesHostile++;
      }
    }
    var capitalThreatened = false;
    final capitalId = view.player.capitalProvinceId;
    if (capitalId != null &&
        capitalId.isNotEmpty &&
        ownedIds.contains(capitalId)) {
      final capitalNeighbors = neighborProvinceIdsFromTopology(topology, {
        capitalId,
      }, view);
      for (final neighborFullId in capitalNeighbors) {
        final prov = view.provincesById[neighborFullId];
        if (prov == null) continue;
        final ownerId = prov.ownerId;
        if (ownerId == null || ownerId.isEmpty || ownerId == view.playerId) {
          continue;
        }
        final rel = view.diplomacyByOtherId[ownerId];
        if (rel != null && rel.state == RelationState.atWar) {
          capitalThreatened = true;
          break;
        }
      }
    }
    return ThreatSummary(
      atWarWith: atWarWith,
      neighborProvincesHostile: neighborProvincesHostile,
      capitalThreatened: capitalThreatened,
    );
  }

  static OpportunitySummary _buildOpportunitySummary(
    PlayerView view,
    MapTopology? topology,
  ) {
    var unclaimed = 0;
    var richUnexploited = 0;
    for (final p in view.provincesById.values) {
      if (p.ownerId == null || p.ownerId!.isEmpty) {
        unclaimed++;
        richUnexploited++;
      } else if (p.ownerId != view.playerId && p.townDevelopmentLevel > 0) {
        richUnexploited++;
      }
    }
    final weakNeighbors = topology == null
        ? <String>[]
        : _weakNeighborOwnerIds(view, topology);
    return OpportunitySummary(
      weakNeighbors: weakNeighbors,
      richUnexploitedProvinces: richUnexploited,
      unclaimedProvinces: unclaimed,
    );
  }

  static List<String> _weakNeighborOwnerIds(
    PlayerView view,
    MapTopology topology,
  ) {
    final ownedIds = <String>{};
    for (final p in view.provincesById.entries) {
      if (p.value.ownerId == view.playerId) ownedIds.add(p.key);
    }
    final neighborIds = neighborProvinceIdsFromTopology(
      topology,
      ownedIds,
      view,
    );
    final weakNeighbors = <String>[];
    for (final fid in neighborIds) {
      final prov = view.provincesById[fid];
      if (prov == null) continue;
      final ownerId = prov.ownerId;
      if (ownerId == null || ownerId.isEmpty || ownerId == view.playerId) {
        continue;
      }
      if (!weakNeighbors.contains(ownerId)) weakNeighbors.add(ownerId);
    }
    return weakNeighbors;
  }

  static ConquestSummary _buildConquestSummary(
    PlayerView view,
    MapTopology? topology,
    ThreatSummary threats,
    OpportunitySummary opportunities,
  ) {
    var oldWorldOwned = 0;
    for (final p in view.provincesById.entries) {
      if (p.value.ownerId != view.playerId) continue;
      if (ProvinceId.regionIdFrom(p.key) != kOldWorldRegionId) continue;
      oldWorldOwned++;
    }
    final provincesToVictory =
        provincesToVictoryFromOldWorldOwned(oldWorldOwned);
    final invadable = topology == null
        ? <String>[]
        : _invadableOldWorldProvinceIds(view, topology);
    final preferredTargets = <String>{
      ...threats.atWarWith,
      ...opportunities.weakNeighbors,
    }.toList()
      ..sort();
    return ConquestSummary(
      oldWorldProvincesOwned: oldWorldOwned,
      provincesToVictory: provincesToVictory,
      invadableProvinceIdsSorted: invadable,
      preferredConquestTargetFactionIdsSorted: preferredTargets,
    );
  }

  static List<String> _invadableOldWorldProvinceIds(
    PlayerView view,
    MapTopology topology,
  ) {
    final anchorProvinces = <String>{};
    for (final p in view.provincesById.entries) {
      if (p.value.ownerId == view.playerId) {
        anchorProvinces.add(p.key);
      }
    }
    for (final u in view.ownUnits) {
      final loc = u.locationProvinceId;
      if (loc.isNotEmpty) anchorProvinces.add(loc);
    }
    final neighbors = neighborProvinceIdsFromTopology(
      topology,
      anchorProvinces,
      view,
    );
    final invadable = <String>[];
    for (final fullId in neighbors) {
      if (ProvinceId.regionIdFrom(fullId) != kOldWorldRegionId) continue;
      final prov = view.provincesById[fullId];
      if (prov == null) continue;
      final ownerId = prov.ownerId;
      if (ownerId == null || ownerId.isEmpty || ownerId == view.playerId) {
        continue;
      }
      invadable.add(fullId);
    }
    invadable.sort();
    return invadable;
  }

  static EconomySummary _buildEconomySummary(PlayerView view) {
    final p = view.player;
    final workerCount = p.workerPool.totalWorkers;
    final treasury = p.treasury;
    var ownCount = 0;
    for (final prov in view.provincesById.values) {
      if (prov.ownerId == view.playerId) ownCount++;
    }
    return EconomySummary(
      workerCount: workerCount,
      treasury: treasury,
      ownProvinceCount: ownCount,
    );
  }
}
