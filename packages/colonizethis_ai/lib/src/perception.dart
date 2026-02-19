import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

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

  /// Builds snapshot from [view]. Deterministic: same view → same snapshot.
  static AIWorldSnapshot fromPlayerView(PlayerView view) {
    final threats = _buildThreatSummary(view);
    final opportunities = _buildOpportunitySummary(view);
    final economy = _buildEconomySummary(view);
    return AIWorldSnapshot(
      playerId: view.playerId,
      threats: threats,
      opportunities: opportunities,
      economy: economy,
      relations: Map<String, DiplomacyRelation>.from(view.diplomacyByOtherId),
    );
  }

  static ThreatSummary _buildThreatSummary(PlayerView view) {
    final atWarWith = <String>[];
    for (final e in view.diplomacyByOtherId.entries) {
      final rel = e.value;
      if (rel.state == RelationState.atWar) {
        atWarWith.add(e.key);
      }
    }
    // Neighbor hostility and capital threat would need topology + visibility;
    // stub for now.
    return ThreatSummary(atWarWith: atWarWith);
  }

  static OpportunitySummary _buildOpportunitySummary(PlayerView view) {
    int unclaimed = 0;
    for (final p in view.provincesById.values) {
      if (p.ownerId == null || p.ownerId!.isEmpty) unclaimed++;
    }
    return OpportunitySummary(unclaimedProvinces: unclaimed);
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
