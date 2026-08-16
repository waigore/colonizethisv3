/// Builds [StagedDecreeReview] from the human slice of [Orders].
/// SPEC: SPEC/ui/components/staged-decree-review.md
library;

import 'package:colonizethis_app/features/game/turn_resolution/staged_decree_review.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_order_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/panels/tree_builders/fleet_mission_label.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_panel_labels.dart';
import 'package:colonizethis_app/widgets/commodity_display_name.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Human-player draft review. Research rows require a tech id and funding
/// other than [ResearchFundingLevel.none]. Idle Spies and empty seats are
/// never synthesized.
StagedDecreeReview buildStagedDecreeReview({
  required Orders orders,
  required String humanPlayerId,
  required AppLocalizations l10n,
  Game? game,
}) {
  final families = <StagedDecreeFamilyGroup>[
    _workFamily(orders, humanPlayerId, l10n, game),
    _relocateFamily(orders, humanPlayerId, l10n, game),
    _armyFamily(orders, humanPlayerId, l10n, game),
    _fleetFamily(orders, humanPlayerId, l10n, game),
    _trainFamily(orders, humanPlayerId, l10n),
    _labourFamily(orders, humanPlayerId, l10n),
    _diplomacyFamily(orders, humanPlayerId, l10n, game),
    _tradeFamily(orders, humanPlayerId, l10n),
    _researchFamily(orders, humanPlayerId, l10n),
  ].where((g) => g.rows.isNotEmpty).toList();
  if (families.isEmpty) {
    return StagedDecreeReview.empty;
  }
  return StagedDecreeReview(families: families);
}

StagedDecreeFamilyGroup _workFamily(
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
            _unitTypeLabel(
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

StagedDecreeFamilyGroup _relocateFamily(
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
            _unitTypeLabel(
              game,
              list[i].unitId,
              l10n.game_nextTurnConfirm_familySpyRelocate,
            ),
            _placeFromTileKey(game, list[i].destinationTileKey),
          ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup _armyFamily(
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
            _armyLabel(game, list[i].armyId, l10n),
            _provinceLabel(game, list[i].destinationProvinceId),
          ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup _fleetFamily(
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
          _fleetLabel(moves[i].fleetId, humanPlayerId, l10n),
          _navalMovePlace(game, moves[i]),
        ),
      ),
    for (var i = 0; i < missions.length; i++)
      StagedDecreeRow(
        id: 'naval-mission-$i-${missions[i].fleetId}',
        label: l10n.game_nextTurnConfirm_rowFleetMission(
          _fleetLabel(missions[i].fleetId, humanPlayerId, l10n),
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

StagedDecreeFamilyGroup _trainFamily(
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

StagedDecreeFamilyGroup _labourFamily(
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
                  _tierName(l10n, list[i].targetTier),
                )
              : l10n.production_labourTrainTier(
                  _tierName(l10n, list[i].targetTier),
                ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup _diplomacyFamily(
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
            _factionLabel(game, list[i].targetFactionId),
          ),
        ),
    ],
  );
}

StagedDecreeFamilyGroup _tradeFamily(
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

StagedDecreeFamilyGroup _researchFamily(
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
            _fundingLabel(l10n, listed[i].funding),
          ),
        ),
    ],
  );
}

String _tierName(AppLocalizations l10n, WorkerTier tier) {
  return switch (tier) {
    WorkerTier.peasant => l10n.production_workers_peasants,
    WorkerTier.apprentice => l10n.production_workers_apprentices,
    WorkerTier.journeyman => l10n.production_workers_journeymen,
    WorkerTier.master => l10n.production_workers_masters,
  };
}

String _fundingLabel(AppLocalizations l10n, ResearchFundingLevel level) {
  return switch (level) {
    ResearchFundingLevel.none => l10n.technologyPanel_fundingNone,
    ResearchFundingLevel.low => l10n.technologyPanel_fundingLow,
    ResearchFundingLevel.medium => l10n.technologyPanel_fundingMedium,
    ResearchFundingLevel.high => l10n.technologyPanel_fundingHigh,
    ResearchFundingLevel.maximum => l10n.technologyPanel_fundingMaximum,
  };
}

String _unitTypeLabel(Game? game, String unitId, String fallback) {
  if (game == null) return fallback;
  for (final unit in game.worldState.oldWorld.units) {
    if (unit.id == unitId) return unit.type;
  }
  for (final unit in game.worldState.newWorld.units) {
    if (unit.id == unitId) return unit.type;
  }
  return fallback;
}

String _armyLabel(Game? game, String armyId, AppLocalizations l10n) {
  if (game != null) {
    for (final army in game.worldState.armies) {
      if (army.id == armyId) {
        return army.isHomeArmy
            ? l10n.military_units_homeArmy
            : l10n.military_units_army(army.id);
      }
    }
  }
  return l10n.military_units_army(armyId);
}

String _fleetLabel(
  String fleetId,
  String humanPlayerId,
  AppLocalizations l10n,
) {
  if (fleetId == homeFleetIdFor(humanPlayerId)) {
    return l10n.naval_homeFleetLabel;
  }
  return l10n.naval_fleetLabel(fleetId);
}

String _factionLabel(Game? game, String factionId) {
  if (game == null) return factionId;
  for (final p in game.players) {
    if (p.id == factionId) return p.displayName;
  }
  for (final m in game.minorNations) {
    if (m.id == factionId) return m.displayName ?? factionId;
  }
  for (final t in game.tribes) {
    if (t.id == factionId) return t.displayName ?? factionId;
  }
  return factionId;
}

String _provinceLabel(Game? game, String prefixedId) {
  if (game == null) return prefixedId;
  final province = _provinceByPrefixedId(game, prefixedId);
  final name = province?.displayName;
  if (name != null && name.isNotEmpty) return name;
  return prefixedId;
}

Province? _provinceByPrefixedId(Game game, String prefixedId) {
  final regionId = ProvinceId.regionIdFrom(prefixedId);
  final region = regionId == kNewWorldRegionId
      ? game.worldState.newWorld
      : game.worldState.oldWorld;
  for (final p in region.provinces) {
    if (p.id == prefixedId) return p;
  }
  return null;
}

String _placeFromTileKey(Game? game, String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 2) return tileKey;
  return _provinceLabel(game, '${parts[0]}|${parts[1]}');
}

String _navalMovePlace(Game? game, NavalMoveOrder order) {
  final port = order.destinationPortProvinceId;
  if (port != null && port.isNotEmpty) {
    return _provinceLabel(game, port);
  }
  final sea = order.destinationSeaZoneId;
  if (sea == null || sea.isEmpty) return '';
  final named = game?.worldState.seaZoneDisplayNameById[sea];
  if (named != null && named.isNotEmpty) return named;
  return sea;
}
