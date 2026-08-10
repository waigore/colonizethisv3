import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../../widgets/production/commodity_ui_helpers.dart';
import '../../widgets/unit_orders/move_army_invasion_intel.dart';
import '../../widgets/unit_orders/move_army_invasion_intel_labels.dart';

String militaryCounselBriefForReason(
  AppLocalizations l10n,
  MilitaryCounselReasonKey key,
) {
  return switch (key) {
    MilitaryCounselReasonKey.affordableTrain =>
      l10n.militaryCounsel_reason_affordableTrain_brief,
    MilitaryCounselReasonKey.atWarInvasion =>
      l10n.militaryCounsel_reason_atWarInvasion_brief,
    MilitaryCounselReasonKey.declareWarInvasion =>
      l10n.militaryCounsel_reason_declareWarInvasion_brief,
  };
}

String militaryCounselTitleForRecommendation(
  AppLocalizations l10n,
  MilitaryCounselRecommendation recommendation,
) {
  return switch (recommendation.kind) {
    MilitaryCounselRecommendationKind.trainUnit =>
      militaryCounselTrainTitle(l10n, recommendation),
    MilitaryCounselRecommendationKind.invade =>
      militaryCounselInvadeTitle(l10n, recommendation),
  };
}

String militaryCounselTrainTitle(
  AppLocalizations l10n,
  MilitaryCounselRecommendation recommendation,
) {
  final unitType = recommendation.unitType;
  final count = recommendation.count ?? 0;
  if (unitType == null || count <= 0) {
    return l10n.militaryCounsel_title_train;
  }
  return l10n.militaryCounsel_title_trainUnit(
    militaryCounselUnitDisplayName(unitType),
    count,
  );
}

String militaryCounselInvadeTitle(
  AppLocalizations l10n,
  MilitaryCounselRecommendation recommendation,
) {
  final province =
      recommendation.destinationProvinceLabel ??
      recommendation.destinationProvinceId ??
      '';
  final armyId = recommendation.armyId ?? '';
  if (armyId.isEmpty || province.isEmpty) {
    return l10n.militaryCounsel_title_invade;
  }
  return l10n.militaryCounsel_title_invadeArmy(armyId, province);
}

String militaryCounselUnitDisplayName(String unitType) {
  final category = buildUnitCategoryForUnitType(unitType);
  return switch (category) {
    BuildUnitCategory.military => regimentTypeDisplayName(unitType),
    BuildUnitCategory.naval => shipTypeDisplayName(unitType),
    BuildUnitCategory.civilian || BuildUnitCategory.unknown => unitType,
  };
}

String militaryCounselCostSummary(
  AppLocalizations l10n,
  MilitaryCounselRecommendation recommendation,
) {
  final snapshot = recommendation.costSnapshot;
  final count = recommendation.count ?? 1;
  if (snapshot == null) return '';
  final materialParts = <String>[
    for (final entry in snapshot.materialCosts.entries)
      '${commodityDisplayName(l10n, entry.key)} × ${entry.value * count}',
  ];
  final materials = materialParts.isEmpty
      ? l10n.militaryCounsel_cost_noMaterials
      : materialParts.join(', ');
  final peasants = snapshot.peasantCost * count;
  return l10n.militaryCounsel_costSummary(
    snapshot.treasuryCost * count,
    materials,
    peasants,
  );
}

String militaryCounselOwnerLabel(
  AppLocalizations l10n,
  Game game,
  MilitaryCounselRecommendation recommendation,
) {
  final ownerId = recommendation.ownerFactionId;
  if (ownerId == null || ownerId.isEmpty) {
    return l10n.moveArmy_groupUnowned;
  }
  return game.factionDisplayNameById(ownerId) ?? ownerId;
}

List<String> militaryCounselInvasionIntelLines(
  AppLocalizations l10n,
  MilitaryCounselInvasionIntelSummary? intel,
) {
  if (intel == null) return const [];
  if (intel.intelLevel == MilitaryCounselInvasionIntelLevel.unknown) {
    return [l10n.moveArmy_defendersUnknown];
  }
  final moveSummary = MoveArmyInvasionIntelSummary(
    intelLevel: MoveArmyInvasionIntelLevel.full,
    defenderCombatCapableCount: intel.defenderCombatCapableCount,
    fortLevel: intel.fortLevel,
  );
  return moveArmyInvasionIntelSummaryLines(l10n, moveSummary);
}
