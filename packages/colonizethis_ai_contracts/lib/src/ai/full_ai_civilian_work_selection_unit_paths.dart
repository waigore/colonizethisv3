import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

import '../constants.dart';
import 'full_ai_civilian_work_selection.dart' show FullAiCivilianWorkIdle;
import 'full_ai_civilian_work_selection_build_purchase.dart';
import 'full_ai_civilian_work_selection_engineer.dart';
import 'full_ai_civilian_work_selection_explore_prospect.dart';
import 'full_ai_civilian_work_selection_rail.dart';
import 'full_ai_civilian_work_selection_shared.dart';
import 'full_ai_civilian_work_selection_spy.dart';
import 'full_ai_civilian_work_selection_upgrade_town.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_snapshot.dart';

// Per-unit civilian-work path selection: the Builder / Merchant / Explorer /
// lexicographic appenders and the per-unit dispatcher that routes each unit's
// candidate set to the right path. Split out of
// full_ai_civilian_work_selection.dart by concern to keep each library file
// small.

void _appendBuilderPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required Game game,
  required String playerId,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
  Set<String> feedstockExtractionResourceIds = const <String>{},
  Set<String> growthStageFabricFeedstockResourceIds = const <String>{},
  Set<String> growthStageInfraFeedstockResourceIds = const <String>{},
  ConnectivityDevSnapshot? connectivityDev,
}) {
  final chosen =
      bestBuilderRow(
        w,
        game,
        playerId: playerId,
        feedstockExtractionResourceIds: feedstockExtractionResourceIds,
        growthStageFabricFeedstockResourceIds:
            growthStageFabricFeedstockResourceIds,
        growthStageInfraFeedstockResourceIds:
            growthStageInfraFeedstockResourceIds,
        connectivityDev: connectivityDev,
      ) ??
      pickLexicographic(w);
  if (chosen != null) {
    workOrders.add(chosen);
    return;
  }
  if (unit == null) return;
  idleEvents.add(
    FullAiCivilianWorkIdle(
      unitId: unit.id,
      unitType: unit.type,
      reason: 'no_suggestions',
    ),
  );
}

void _appendMerchantPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required Game game,
  required DiplomacyFactionMembership factionMembership,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
}) {
  final chosen =
      bestPurchaseLandRow(w, game, factionMembership) ?? pickLexicographic(w);
  if (chosen != null) {
    workOrders.add(chosen);
    return;
  }
  if (unit == null) return;
  idleEvents.add(
    FullAiCivilianWorkIdle(
      unitId: unit.id,
      unitType: unit.type,
      reason: 'no_suggestions',
    ),
  );
}

bool _explorerOnlySuggestions(List<WorkOrder> w) {
  if (w.isEmpty) return false;
  return w.every(
    (o) => o.target == kWorkTargetExplore || o.target == kWorkTargetProspect,
  );
}

void _appendExplorerPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required Game game,
  required PlayerView view,
  required String playerId,
  Map<String, TileMapResult>? tileMapByRegion,
  required DiplomacyFactionMembership factionMembership,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
  Set<String> feedstockExtractionResourceIds = const <String>{},
}) {
  final c = w
      .where(
        (o) =>
            o.target == kWorkTargetExplore || o.target == kWorkTargetProspect,
      )
      .toList();
  if (c.isEmpty) {
    if (unit == null) return;
    idleEvents.add(
      FullAiCivilianWorkIdle(
        unitId: unit.id,
        unitType: unit.type,
        reason: 'no_suggestions',
      ),
    );
    return;
  }
  final chosen = pickExplorerCandidateSet(
    c,
    game,
    view,
    playerId,
    tileMapByRegion,
    factionMembership,
    feedstockExtractionResourceIds: feedstockExtractionResourceIds,
  );
  if (chosen != null) {
    workOrders.add(chosen);
    return;
  }
  if (unit == null) return;
  idleEvents.add(
    FullAiCivilianWorkIdle(
      unitId: unit.id,
      unitType: unit.type,
      reason: 'no_suggestions',
    ),
  );
}

void _appendLexicographicPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
}) {
  if (w.isEmpty) {
    if (unit == null) return;
    idleEvents.add(
      FullAiCivilianWorkIdle(
        unitId: unit.id,
        unitType: unit.type,
        reason: 'no_suggestions',
      ),
    );
    return;
  }
  final chosen = pickLexicographic(w);
  if (chosen == null) return;
  workOrders.add(chosen);
}

void appendSelectionForUnitId({
  required String unitId,
  required Map<String, List<WorkOrder>> byUnit,
  required PlayerView view,
  required Game game,
  Map<String, TileMapResult>? tileMapByRegion,
  required DiplomacyFactionMembership factionMembership,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
  Set<String> feedstockExtractionResourceIds = const <String>{},
  Set<String> growthStageFabricFeedstockResourceIds = const <String>{},
  Set<String> growthStageInfraFeedstockResourceIds = const <String>{},
  OwFeedstockReservation reservation = OwFeedstockReservation.none,
  bool spyDevelopPhase = false,
  ConnectivityDevSnapshot? connectivityDev,
}) {
  final W = List<WorkOrder>.from(byUnit[unitId] ?? const <WorkOrder>[]);
  sortWorkOrdersLex(W);
  final unit = view.ownUnitsById[unitId];

  if (unit != null &&
      (unit.currentWork != null || !civilianWorkCapableType(unit.type))) {
    return;
  }

  // Refs #2847 § H8-extraction: a reserved Old World feedstock unit keeps only
  // its Old World candidates so it is not routed to higher-scoring New World
  // colonial work, staying available for the Old World feedstock prospect /
  // build_improvement the feedstock score boosts then select.
  if (reservation.reserves(unitId)) {
    dropNewWorldWorkOrders(W);
  }

  final isExplorerCase = unit != null && isExplorerUnit(unit.type);
  final orphanExplorerScoring =
      unit == null && W.isNotEmpty && _explorerOnlySuggestions(W);

  if (isExplorerCase || orphanExplorerScoring) {
    _appendExplorerPathResult(
      unit: unit,
      w: W,
      game: game,
      view: view,
      playerId: view.playerId,
      tileMapByRegion: tileMapByRegion,
      factionMembership: factionMembership,
      workOrders: workOrders,
      idleEvents: idleEvents,
      feedstockExtractionResourceIds: feedstockExtractionResourceIds,
    );
    return;
  }

  if (unit != null && unit.type == kUnitTypeBuilder) {
    _appendBuilderPathResult(
      unit: unit,
      w: W,
      game: game,
      playerId: view.playerId,
      workOrders: workOrders,
      idleEvents: idleEvents,
      feedstockExtractionResourceIds: feedstockExtractionResourceIds,
      growthStageFabricFeedstockResourceIds:
          growthStageFabricFeedstockResourceIds,
      growthStageInfraFeedstockResourceIds:
          growthStageInfraFeedstockResourceIds,
      connectivityDev: connectivityDev,
    );
    return;
  }

  if (unit != null && unit.type == kUnitTypeRailBuilder) {
    appendRailBuilderPathResult(
      unit: unit,
      w: W,
      game: game,
      playerId: view.playerId,
      workOrders: workOrders,
      idleEvents: idleEvents,
      connectivityDev: connectivityDev,
    );
    return;
  }

  if (unit != null && unit.type == kUnitTypeEngineer) {
    appendEngineerPathResult(
      unit: unit,
      w: W,
      game: game,
      playerId: view.playerId,
      workOrders: workOrders,
      idleEvents: idleEvents,
      connectivityDev: connectivityDev,
    );
    return;
  }

  if (unit != null && isSpyUnit(unit.type)) {
    appendSpyPathResult(
      unit: unit,
      w: W,
      game: game,
      playerId: view.playerId,
      spyDevelopPhase: spyDevelopPhase,
      workOrders: workOrders,
      idleEvents: idleEvents,
    );
    return;
  }

  if (unit != null && isMerchantUnit(unit.type)) {
    _appendMerchantPathResult(
      unit: unit,
      w: W,
      game: game,
      factionMembership: factionMembership,
      workOrders: workOrders,
      idleEvents: idleEvents,
    );
    return;
  }

  _appendLexicographicPathResult(
    unit: unit,
    w: W,
    workOrders: workOrders,
    idleEvents: idleEvents,
  );
}
