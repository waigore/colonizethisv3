import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/ai_api.dart';

final _log = packageLogger();

// Perception: PlayerView → AIWorldSnapshot. SPEC/ai/ai-architecture.md.
// All data derived from PlayerView only; no hidden state.

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
    required this.economy,
    required this.relations,
  });

  final String playerId;
  final ThreatSummary threats;
  final OpportunitySummary opportunities;
  final EconomySummary economy;

  /// Relation state keyed by other faction id (war, peace, etc.).
  final Map<String, DiplomacyRelation> relations;

  /// Builds snapshot from [view]. When [topology] is provided, computes
  /// neighborProvincesHostile, capitalThreatened, weakNeighbors, and
  /// richUnexploitedProvinces from view + topology. Deterministic: same view → same snapshot.
  static AIWorldSnapshot fromPlayerView(
    PlayerView view, {
    MapTopology? topology,
  }) {
    final threats = _buildThreatSummary(view, topology);
    final opportunities = _buildOpportunitySummary(view, topology);
    final economy = _buildEconomySummary(view);
    final snapshot = AIWorldSnapshot(
      playerId: view.playerId,
      threats: threats,
      opportunities: opportunities,
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
    int neighborProvincesHostile = 0;
    final neighborProvinceIds = _neighborProvinceIdsFromTopology(
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
    bool capitalThreatened = false;
    final capitalId = view.player.capitalProvinceId;
    if (capitalId != null &&
        capitalId.isNotEmpty &&
        ownedIds.contains(capitalId)) {
      final capitalNeighbors = _neighborProvinceIdsFromTopology(topology, {
        capitalId,
      }, view);
      for (final neighborFullId in capitalNeighbors) {
        final prov = view.provincesById[neighborFullId];
        if (prov == null) continue;
        final ownerId = prov.ownerId;
        if (ownerId == null || ownerId.isEmpty || ownerId == view.playerId)
          continue;
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

  /// Returns full province ids of provinces adjacent to [ownedFullIds] per [topology].
  static Set<String> _neighborProvinceIdsFromTopology(
    MapTopology topology,
    Set<String> ownedFullIds,
    PlayerView view,
  ) {
    final nodesByRegion = _topologyNodesByRegionId(topology);
    final out = <String>{};
    for (final fullId in ownedFullIds) {
      final regionId = ProvinceId.regionIdFrom(fullId);
      final localId = ProvinceId.localIdFrom(fullId);
      final nodesInRegion = nodesByRegion[regionId];
      if (nodesInRegion == null) continue;
      for (final edge in topology.edges) {
        final neighborLocalId = _otherEndOfEdge(edge, localId);
        if (neighborLocalId == null) continue;
        final neighborNode = nodesInRegion[neighborLocalId];
        if (neighborNode == null ||
            neighborNode.type != TopologyNodeType.province) {
          continue;
        }
        final neighborFullId = ProvinceId.full(
          neighborNode.regionId,
          neighborNode.id,
        );
        if (!ownedFullIds.contains(neighborFullId)) out.add(neighborFullId);
      }
    }
    return out;
  }

  static Map<String, Map<String, TopologyNode>> _topologyNodesByRegionId(
    MapTopology topology,
  ) {
    final byRegion = <String, Map<String, TopologyNode>>{};
    for (final n in topology.nodes) {
      byRegion.putIfAbsent(n.regionId, () => <String, TopologyNode>{})[n.id] =
          n;
    }
    return byRegion;
  }

  static String? _otherEndOfEdge(TopologyEdge edge, String localId) {
    if (edge.id1 == localId) return edge.id2;
    if (edge.id2 == localId) return edge.id1;
    return null;
  }

  static OpportunitySummary _buildOpportunitySummary(
    PlayerView view,
    MapTopology? topology,
  ) {
    int unclaimed = 0;
    int richUnexploited = 0;
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
    final neighborIds = _neighborProvinceIdsFromTopology(
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

  static EconomySummary _buildEconomySummary(PlayerView view) {
    final p = view.player;
    final workerCount = p.workerPool.totalWorkers;
    final treasury = p.treasury;
    int ownCount = 0;
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
