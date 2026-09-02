/// Family mappers for [buildStagedDecreeReview].
library;

import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review_labels.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_order_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/panels/tree_builders/fleet_mission_label.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_panel_labels.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export 'staged_decree_review_builder_trade_research.dart';

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
    count: list.length,
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
    count: list.length,
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
    count: list.length,
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
    count: rows.length,
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
    count: list.length,
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
    count: list.length,
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
    count: list.length,
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
