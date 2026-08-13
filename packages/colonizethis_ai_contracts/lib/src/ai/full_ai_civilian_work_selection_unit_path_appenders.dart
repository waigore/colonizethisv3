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

// Per-unit civilian-work path appenders for Full AI selection (Refs #4368 Slice B).
// Split from unit_paths.dart by concern.

void appendBuilderPathResult({
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

void appendMerchantPathResult({
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

bool explorerOnlySuggestions(List<WorkOrder> w) {
  if (w.isEmpty) return false;
  return w.every(
    (o) => o.target == kWorkTargetExplore || o.target == kWorkTargetProspect,
  );
}

void appendExplorerPathResult({
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

void appendLexicographicPathResult({
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
