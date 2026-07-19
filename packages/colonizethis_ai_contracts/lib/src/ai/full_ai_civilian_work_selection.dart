import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'full_ai_civilian_work_selection_build_purchase.dart';
import 'full_ai_civilian_work_selection_shared.dart';
import 'full_ai_civilian_work_selection_unit_paths.dart';
import 'package:colonizethis_orders/src/orders/feedstock_extraction_targets.dart';
import 'package:colonizethis_world/src/world/faction_membership.dart';
import 'package:colonizethis_world/src/world/player_view.dart';

/// Idle civilian (no new work) for Full AI observability.
class FullAiCivilianWorkIdle {
  const FullAiCivilianWorkIdle({
    required this.unitId,
    required this.unitType,
    required this.reason,
  });

  final String unitId;
  final String unitType;
  final String reason;
}

/// Deterministic Full AI civilian work selection from [suggestWorkOrders] output.
///
/// Normative rules: GitHub #2082; SPEC/program/order-suggestions.md (Full AI).
class FullAiCivilianWorkSelectionResult {
  const FullAiCivilianWorkSelectionResult({
    required this.workOrders,
    required this.idleEvents,
  });

  final List<WorkOrder> workOrders;
  final List<FullAiCivilianWorkIdle> idleEvents;
}

/// Selects per-unit civilian work for Full AI from [workSuggestions].
FullAiCivilianWorkSelectionResult selectFullAiCivilianWorkOrders({
  required List<WorkOrder> workSuggestions,
  required PlayerView view,
  required Game game,
  Map<String, TileMapResult>? tileMapByRegion,
  Set<String> growthStageFabricFeedstockResourceIds = const <String>{},
  Set<String> growthStageInfraFeedstockResourceIds = const <String>{},
  bool spyDevelopPhase = false,
}) {
  final byUnit = <String, List<WorkOrder>>{};
  for (final w in workSuggestions) {
    byUnit.putIfAbsent(w.unitId, () => <WorkOrder>[]).add(w);
  }
  for (final list in byUnit.values) {
    sortWorkOrdersLex(list);
  }

  final suggestionUnitIds = byUnit.keys.toList()..sort();
  final idleCivilianIds = view.ownUnits
      .where((u) => u.currentWork == null && civilianWorkCapableType(u.type))
      .map((u) => u.id)
      .toList();
  final allUnitIds = {...suggestionUnitIds, ...idleCivilianIds}.toList()
    ..sort();

  final workOrders = <WorkOrder>[];
  final idleEvents = <FullAiCivilianWorkIdle>[];
  final factionMembership = DiplomacyFactionMembership.from(game);
  final feedstockExtractionResourceIds =
      feedstockExtractionResourceIdsForPlayer(game, view.playerId);
  final reservation = resolveOwFeedstockReservation(
    view,
    game,
    feedstockExtractionResourceIds,
  );

  for (final unitId in allUnitIds) {
    appendSelectionForUnitId(
      unitId: unitId,
      byUnit: byUnit,
      view: view,
      game: game,
      tileMapByRegion: tileMapByRegion,
      factionMembership: factionMembership,
      workOrders: workOrders,
      idleEvents: idleEvents,
      feedstockExtractionResourceIds: feedstockExtractionResourceIds,
      growthStageFabricFeedstockResourceIds:
          growthStageFabricFeedstockResourceIds,
      growthStageInfraFeedstockResourceIds:
          growthStageInfraFeedstockResourceIds,
      reservation: reservation,
      spyDevelopPhase: spyDevelopPhase,
    );
  }

  workOrders.sort(compareWorkOrderLex);
  return FullAiCivilianWorkSelectionResult(
    workOrders: workOrders,
    idleEvents: idleEvents,
  );
}
