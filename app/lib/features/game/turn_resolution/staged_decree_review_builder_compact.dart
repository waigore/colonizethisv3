/// Compact family counts for [buildStagedDecreeReview] (no row labels).
library;

import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

StagedDecreeFamilyGroup? stagedDecreeWorkFamilyCompact(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final count =
      (orders.workOrdersByPlayerId[humanPlayerId] ?? const <WorkOrder>[])
          .length;
  if (count == 0) return null;
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.civilianWork,
    familyLabel: l10n.game_nextTurnConfirm_familyCivilianWork,
    count: count,
  );
}

StagedDecreeFamilyGroup? stagedDecreeRelocateFamilyCompact(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final count =
      (orders.moveOrdersByPlayerId[humanPlayerId] ?? const <MoveOrder>[])
          .length;
  if (count == 0) return null;
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.spyRelocate,
    familyLabel: l10n.game_nextTurnConfirm_familySpyRelocate,
    count: count,
  );
}

StagedDecreeFamilyGroup? stagedDecreeArmyFamilyCompact(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final count =
      (orders.armyMoveOrdersByPlayerId[humanPlayerId] ??
              const <ArmyMoveOrder>[])
          .length;
  if (count == 0) return null;
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.armyMoves,
    familyLabel: l10n.game_nextTurnConfirm_familyArmyMoves,
    count: count,
  );
}

StagedDecreeFamilyGroup? stagedDecreeFleetFamilyCompact(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final moves =
      orders.navalMoveOrdersByPlayerId[humanPlayerId] ??
      const <NavalMoveOrder>[];
  final missions =
      orders.navalMissionOrdersByPlayerId[humanPlayerId] ??
      const <NavalMissionOrder>[];
  final count = moves.length + missions.length;
  if (count == 0) return null;
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.fleet,
    familyLabel: l10n.game_nextTurnConfirm_familyFleet,
    count: count,
  );
}

StagedDecreeFamilyGroup? stagedDecreeTrainFamilyCompact(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final count =
      (orders.buildUnitOrdersByPlayerId[humanPlayerId] ??
              const <BuildUnitOrder>[])
          .length;
  if (count == 0) return null;
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.trainingBuilds,
    familyLabel: l10n.game_nextTurnConfirm_familyTraining,
    count: count,
  );
}

StagedDecreeFamilyGroup? stagedDecreeLabourFamilyCompact(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final count =
      (orders.recruitWorkerOrdersByPlayerId[humanPlayerId] ??
              const <RecruitWorkerOrder>[])
          .length;
  if (count == 0) return null;
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.labourRecruit,
    familyLabel: l10n.game_nextTurnConfirm_familyLabour,
    count: count,
  );
}

StagedDecreeFamilyGroup? stagedDecreeDiplomacyFamilyCompact(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final count =
      (orders.diplomaticOrdersByPlayerId[humanPlayerId] ??
              const <DiplomaticOrder>[])
          .length;
  if (count == 0) return null;
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.diplomacy,
    familyLabel: l10n.game_nextTurnConfirm_familyDiplomacy,
    count: count,
  );
}

StagedDecreeFamilyGroup? stagedDecreeTradeFamilyCompact(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final count =
      (orders.tradeOrdersByPlayerId[humanPlayerId] ?? const <TradeOrder>[])
          .length;
  if (count == 0) return null;
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.trade,
    familyLabel: l10n.game_nextTurnConfirm_familyTrade,
    count: count,
  );
}

StagedDecreeFamilyGroup? stagedDecreeResearchFamilyCompact(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final raw =
      orders.researchOrdersByPlayerId[humanPlayerId] ?? const <ResearchOrder>[];
  final count = raw
      .where(
        (o) => o.techId.isNotEmpty && o.funding != ResearchFundingLevel.none,
      )
      .length;
  if (count == 0) return null;
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.research,
    familyLabel: l10n.game_nextTurnConfirm_familyResearch,
    count: count,
  );
}
