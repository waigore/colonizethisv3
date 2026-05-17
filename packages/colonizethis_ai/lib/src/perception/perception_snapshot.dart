import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'perception_snapshot_builders.dart';
import 'summary_models.dart';

export 'summary_models.dart';

final _log = packageLogger();

/// World snapshot for AI: threats, opportunities, economy, relations.
/// Built only from [PlayerView]; used by goal manager and domain planners.
class AIWorldSnapshot {
  const AIWorldSnapshot({
    required this.playerId,
    required this.threats,
    required this.opportunities,
    required this.conquest,
    this.colonial = const ColonialSummary(),
    required this.economy,
    required this.relations,
  });

  final String playerId;
  final ThreatSummary threats;
  final OpportunitySummary opportunities;
  final ConquestSummary conquest;
  final ColonialSummary colonial;
  final EconomySummary economy;

  /// Relation state keyed by other faction id (war, peace, etc.).
  final Map<String, DiplomacyRelation> relations;

  /// Builds snapshot from [view]. Deterministic: same view -> same snapshot.
  static AIWorldSnapshot fromPlayerView(
    PlayerView view, {
    MapTopology? topology,
  }) {
    final threats = buildThreatSummary(view, topology);
    final opportunities = buildOpportunitySummary(view, topology);
    final conquest = buildConquestSummary(view, topology, threats, opportunities);
    final colonial = buildColonialSummary(view, topology, threats, opportunities);
    final economy = buildEconomySummary(view);
    final snapshot = AIWorldSnapshot(
      playerId: view.playerId,
      threats: threats,
      opportunities: opportunities,
      conquest: conquest,
      colonial: colonial,
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
      'nwInvadableCount=${snapshot.colonial.invadableNewWorldProvinceIdsSorted.length} '
      'workerCount=${snapshot.economy.workerCount} '
      'treasury=${snapshot.economy.treasury} '
      'ownProvinceCount=${snapshot.economy.ownProvinceCount} '
      'relationsKeys=${snapshot.relations.keys.toList()}',
    );
    return snapshot;
  }
}
