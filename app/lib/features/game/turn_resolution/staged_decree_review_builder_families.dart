/// Family mappers for [buildStagedDecreeReview].
library;

import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review_labels.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_order_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/panels/tree_builders/fleet_mission_label.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_panel_labels.dart';
import 'package:colonizethis_app/widgets/commodity_display_name.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

StagedDecreeFamilyGroup stagedDecreeWorkFamily(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
  Game? game,
) {
  final list =
      orders.workOrdersByPlayerId[humanPlayerId] ?? const <WorkOrder>[];
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.civilianWork,
    familyLabel: l10n.game_nextTurnConfirm_familyCivilianWork,
    rows: [
      for (var i = 0; i < list.length; i++)
        StagedDecreeRow(
          id: 'work-$i-${list[i].unitId}',
          label: l10n.game_nextTurnConfirm_rowWork(
            stagedDecreeUnitTypeLabel(
              game,
              list[i].unitId,
              l10n.game_nextTurnConfirm_familyCivilianWork,
            ),
            workOrderTargetDisplayLabel(l10n, list[i].target),
          ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup stagedDecreeRelocateFamily(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
  Game? game,
) {
  final list =
      orders.moveOrdersByPlayerId[humanPlayerId] ?? const <MoveOrder>[];
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.spyRelocate,
    familyLabel: l10n.game_nextTurnConfirm_familySpyRelocate,
    rows: [
      for (var i = 0; i < list.length; i++)
        StagedDecreeRow(
          id: 'move-$i-${list[i].unitId}',
          label: l10n.game_nextTurnConfirm_rowRelocate(
            stagedDecreeUnitTypeLabel(
              game,
              list[i].unitId,
              l10n.game_nextTurnConfirm_familySpyRelocate,
            ),
            stagedDecreePlaceFromTileKey(game, list[i].destinationTileKey),
          ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup stagedDecreeArmyFamily(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
  Game? game,
) {
  final list =
      orders.armyMoveOrdersByPlayerId[humanPlayerId] ?? const <ArmyMoveOrder>[];
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.armyMoves,
    familyLabel: l10n.game_nextTurnConfirm_familyArmyMoves,
    rows: [
      for (var i = 0; i < list.length; i++)
        StagedDecreeRow(
          id: 'army-$i-${list[i].armyId}',
          label: l10n.game_nextTurnConfirm_rowArmyMove(
            stagedDecreeArmyLabel(game, list[i].armyId, l10n),
            stagedDecreeProvinceLabel(game, list[i].destinationProvinceId),
          ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup stagedDecreeFleetFamily(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
  Game? game,
) {
  final moves =
      orders.navalMoveOrdersByPlayerId[humanPlayerId] ??
      const <NavalMoveOrder>[];
  final missions =
      orders.navalMissionOrdersByPlayerId[humanPlayerId] ??
      const <NavalMissionOrder>[];
  final rows = <StagedDecreeRow>[
    for (var i = 0; i < moves.length; i++)
      StagedDecreeRow(
        id: 'naval-move-$i-${moves[i].fleetId}',
        label: l10n.game_nextTurnConfirm_rowFleetMove(
          stagedDecreeFleetLabel(moves[i].fleetId, humanPlayerId, l10n),
          stagedDecreeNavalMovePlace(game, moves[i]),
        ),
      ),
    for (var i = 0; i < missions.length; i++)
      StagedDecreeRow(
        id: 'naval-mission-$i-${missions[i].fleetId}',
        label: l10n.game_nextTurnConfirm_rowFleetMission(
          stagedDecreeFleetLabel(missions[i].fleetId, humanPlayerId, l10n),
          fleetMissionDisplayLabel(
            fleetMissionFromOrderString(missions[i].mission),
          ),
        ),
      ),
  ];
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.fleet,
    familyLabel: l10n.game_nextTurnConfirm_familyFleet,
    rows: rows,
  );
}

StagedDecreeFamilyGroup stagedDecreeTrainFamily(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final list =
      orders.buildUnitOrdersByPlayerId[humanPlayerId] ??
      const <BuildUnitOrder>[];
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.trainingBuilds,
    familyLabel: l10n.game_nextTurnConfirm_familyTraining,
    rows: [
      for (var i = 0; i < list.length; i++)
        StagedDecreeRow(
          id: 'build-$i-${list[i].unitType}-${list[i].spawnProvinceId}',
          label: l10n.game_nextTurnConfirm_rowTrain(
            list[i].isMilitary
                ? regimentTypeDisplayLabel(l10n, list[i].unitType)
                : list[i].unitType,
          ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup stagedDecreeLabourFamily(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final list =
      orders.recruitWorkerOrdersByPlayerId[humanPlayerId] ??
      const <RecruitWorkerOrder>[];
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.labourRecruit,
    familyLabel: l10n.game_nextTurnConfirm_familyLabour,
    rows: [
      for (var i = 0; i < list.length; i++)
        StagedDecreeRow(
          id: 'recruit-$i-${list[i].targetTier.id}',
          label: list[i].targetTier == WorkerTier.peasant
              ? l10n.production_labourRecruitTier(
                  stagedDecreeTierName(l10n, list[i].targetTier),
                )
              : l10n.production_labourTrainTier(
                  stagedDecreeTierName(l10n, list[i].targetTier),
                ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup stagedDecreeDiplomacyFamily(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
  Game? game,
) {
  final list =
      orders.diplomaticOrdersByPlayerId[humanPlayerId] ??
      const <DiplomaticOrder>[];
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.diplomacy,
    familyLabel: l10n.game_nextTurnConfirm_familyDiplomacy,
    rows: [
      for (var i = 0; i < list.length; i++)
        StagedDecreeRow(
          id: 'diplo-$i-${list[i].type.name}-${list[i].targetFactionId}',
          label: l10n.game_nextTurnConfirm_rowDiplomacy(
            diplomacyActionLabel(list[i]),
            stagedDecreeFactionLabel(game, list[i].targetFactionId),
          ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup stagedDecreeTradeFamily(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final list =
      orders.tradeOrdersByPlayerId[humanPlayerId] ?? const <TradeOrder>[];
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.trade,
    familyLabel: l10n.game_nextTurnConfirm_familyTrade,
    rows: [
      for (var i = 0; i < list.length; i++)
        StagedDecreeRow(
          id: 'trade-$i-${list[i].type.name}-${list[i].commodityId}',
          label: list[i].type == TradeOrderType.bid
              ? l10n.tradeCounsel_title_bid(
                  commodityDisplayName(l10n, list[i].commodityId),
                  list[i].quantity,
                )
              : l10n.tradeCounsel_title_offer(
                  commodityDisplayName(l10n, list[i].commodityId),
                  list[i].quantity,
                ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup stagedDecreeResearchFamily(
  Orders orders,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  final raw =
      orders.researchOrdersByPlayerId[humanPlayerId] ?? const <ResearchOrder>[];
  final listed = raw
      .where(
        (o) => o.techId.isNotEmpty && o.funding != ResearchFundingLevel.none,
      )
      .toList();
  return StagedDecreeFamilyGroup(
    family: StagedDecreeFamily.research,
    familyLabel: l10n.game_nextTurnConfirm_familyResearch,
    rows: [
      for (var i = 0; i < listed.length; i++)
        StagedDecreeRow(
          id: 'research-$i-${listed[i].slotIndex}-${listed[i].techId}',
          label: l10n.game_nextTurnConfirm_rowResearch(
            techDisplayName(listed[i].techId),
            stagedDecreeFundingLabel(l10n, listed[i].funding),
          ),
        ),
    ],
  );
}
