/// Military counsel recommendation DTOs and reason keys.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

enum MilitaryCounselReasonKey {
  affordableTrain,
  atWarInvasion,
  declareWarInvasion,
}

enum MilitaryCounselRecommendationKind {
  trainUnit,
  invade,
}

enum MilitaryCounselInvasionIntelLevel {
  unknown,
  full,
}

/// Fog-respecting defender summary for invade recommendations (DLG20001 parity).
final class MilitaryCounselInvasionIntelSummary {
  const MilitaryCounselInvasionIntelSummary({
    required this.intelLevel,
    this.defenderCombatCapableCount,
    this.fortLevel,
  });

  final MilitaryCounselInvasionIntelLevel intelLevel;
  final int? defenderCombatCapableCount;
  final int? fortLevel;

  bool get unopposed =>
      intelLevel == MilitaryCounselInvasionIntelLevel.full &&
      defenderCombatCapableCount == 0;
}

/// Treasury, material, and peasant costs for one train recommendation.
final class MilitaryCounselBuildCostSnapshot {
  const MilitaryCounselBuildCostSnapshot({
    required this.treasuryCost,
    required this.materialCosts,
    required this.peasantCost,
  });

  final int treasuryCost;
  final Map<CommodityId, int> materialCosts;

  /// `1` when the unit type consumes a peasant; otherwise `0`.
  final int peasantCost;
}

/// One ranked military counsel recommendation (≤3 per turn).
final class MilitaryCounselRecommendation {
  const MilitaryCounselRecommendation({
    required this.recommendationId,
    required this.kind,
    required this.rankScore,
    required this.briefReasonKey,
    required this.detailReasonKeys,
    required this.isHighlight,
    this.unitType,
    this.count,
    this.costSnapshot,
    this.armyId,
    this.destinationProvinceId,
    this.destinationProvinceLabel,
    this.ownerFactionId,
    this.requiresDeclareWar,
    this.invasionIntel,
  });

  final String recommendationId;
  final MilitaryCounselRecommendationKind kind;
  final double rankScore;
  final MilitaryCounselReasonKey briefReasonKey;
  final List<MilitaryCounselReasonKey> detailReasonKeys;
  final bool isHighlight;
  final String? unitType;
  final int? count;
  final MilitaryCounselBuildCostSnapshot? costSnapshot;
  final String? armyId;
  final String? destinationProvinceId;
  final String? destinationProvinceLabel;
  final String? ownerFactionId;
  final bool? requiresDeclareWar;
  final MilitaryCounselInvasionIntelSummary? invasionIntel;
}
