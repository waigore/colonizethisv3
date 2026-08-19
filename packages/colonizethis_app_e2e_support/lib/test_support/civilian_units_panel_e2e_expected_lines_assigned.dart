// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Expected plain-text lines for CivilianUnitsPanel (bottom sheet). Mirrors
// app/lib/features/game/widgets/units/civilian/civilian_units_panel.dart for e2e.
// If drift fails tests, align this file with the panel widget.


import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/region_labels.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';


const Map<String, String> workTargetLabels = {
  kWorkTargetExplore: 'Explore',
  kWorkTargetProspect: 'Prospect',
  kWorkTargetBuildImprovement: 'Build improvement',
  kWorkTargetUpgradeTown: 'Upgrade town',
  kWorkTargetBuildRoad: 'Build road',
  kWorkTargetBuildPort: 'Build port',
  kWorkTargetBuildFort: 'Build fort',
  kWorkTargetBuildRail: 'Build rail',
  kWorkTargetCounterSpy: 'Counter-espionage',
  kWorkTargetPurchaseLand: 'Purchase land',
};

// Sort/partition helpers live in `civilian_units_sort.dart` (public). This
// file delegates to them to keep e2e expectations aligned with the panel
// rendering. Refs #2575.

class PendingAssignedResolution {
  const PendingAssignedResolution({
    required this.mainLine,
    required this.totalTurns,
    this.materialCosts,
    this.treasuryAmount,
  });

  final String mainLine;
  final int totalTurns;
  final Map<String, int>? materialCosts;
  final int? treasuryAmount;
}

PendingAssignedResolution resolvePendingAssignedResolution(
  Game game,
  Unit unit,
  WorkOrder order,
  Map<String, String> provinceNames,
) {
  final workLabel = workTargetLabels[order.target] ?? order.target;
  final regionId = Unit.regionIdFromTileKey(order.targetTileKey);
  final provinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
  var location = '';
  if (regionId != null && provinceId != null) {
    final name =
        provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
    location = ' (${regionDisplayLabel(regionId)} — $name)';
  }
  final base = '$workLabel$location';
  final totalTurns = previewTotalTurnsForPendingWorkOrder(
    game: game,
    unit: unit,
    order: order,
  );

  if (order.target == kWorkTargetPurchaseLand) {
    final resourceId = game.worldState.resourceByTileKey[order.targetTileKey];
    if (resourceId != null && resourceId.isNotEmpty) {
      return PendingAssignedResolution(
        mainLine: base,
        totalTurns: totalTurns,
        treasuryAmount: purchaseLandCost(resourceId),
      );
    }
    return PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
  }
  if (order.target == kWorkTargetCounterSpy) {
    return PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
  }

  final targetProvinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
  final province = targetProvinceId != null
      ? game.worldState.tryGetProvince(targetProvinceId)
      : null;

  final improvementLevel = order.target == kWorkTargetBuildImprovement
      ? game.worldState.tileState.improvementLevel(order.targetTileKey)
      : 0;
  final fortLevel = province?.fortLevel ?? 0;
  final roadLevel = game.worldState.tileState.roadLevel(order.targetTileKey);

  final costMap = WorkOrderCostCalculator(game).calculateCost(
    order.target,
    order.targetTileKey,
    improvementLevel: improvementLevel,
    fortLevel: fortLevel,
    roadLevel: roadLevel,
  );
  if (costMap != null && costMap.isNotEmpty) {
    return PendingAssignedResolution(
      mainLine: base,
      totalTurns: totalTurns,
      materialCosts: costMap,
    );
  }
  return PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
}

List<MapEntry<String, int>> sortedMaterialCostEntries(Map<String, int> m) {
  return m.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
}

WorkOrder? pendingWorkOrder(Unit unit, Orders currentOrders, String humanId) {
  final list = currentOrders.workOrdersByPlayerId[humanId] ?? const [];
  for (final o in list) {
    if (o.unitId == unit.id) return o;
  }
  return null;
}

bool hasPending(Unit unit, Orders currentOrders, String humanId) =>
    pendingWorkOrder(unit, currentOrders, humanId) != null;

bool isIdleNoPending(Unit unit, Orders currentOrders, String humanId) =>
    unit.status == UnitStatus.idle &&
    unit.currentWork == null &&
    !hasPending(unit, currentOrders, humanId);

bool hasWork(Unit unit, Orders currentOrders, String humanId) =>
    unit.currentWork != null || hasPending(unit, currentOrders, humanId);

String assignedToLabelNonPending(
  Unit unit,
  Map<String, String> provinceNames,
  AppLocalizations l10n,
) {
  if (unit.status != UnitStatus.working || unit.currentWork == null) {
    return '—';
  }
  final cw = unit.currentWork!;
  final workLabel = workTargetLabels[cw.workTarget] ?? cw.workTarget;
  final regionId = Unit.regionIdFromTileKey(cw.tileKey);
  final provinceId = Unit.provinceIdFromTileKey(cw.tileKey);
  var location = '';
  if (regionId != null && provinceId != null) {
    final name =
        provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
    location = ' (${regionDisplayLabel(regionId)} — $name)';
  }
  final progress = cw.totalTurns > 0
      ? l10n.civilian_units_turnProgress(
          cw.remainingTurns.toString(),
          cw.totalTurns.toString(),
        )
      : l10n.civilian_units_turns(
          cw.remainingTurns <= 0 ? 1 : cw.remainingTurns,
        );
  return '$workLabel$location — $progress';
}

void addAssignedLines(
  List<String> out,
  Game game,
  Unit unit,
  Orders currentOrders,
  String humanId,
  Map<String, String> provinceNames,
  AppLocalizations l10n,
) {
  final pending = pendingWorkOrder(unit, currentOrders, humanId);
  if (pending != null) {
    final r = resolvePendingAssignedResolution(
      game,
      unit,
      pending,
      provinceNames,
    );
    final turns = l10n.civilian_units_turns(r.totalTurns);
    out.add(l10n.civilian_units_assignedTo('${r.mainLine} — $turns'));
    if (r.materialCosts != null && r.materialCosts!.isNotEmpty) {
      for (final e in sortedMaterialCostEntries(r.materialCosts!)) {
        out.add(e.value.toString());
      }
    }
    if (r.treasuryAmount != null) {
      out.add(l10n.trainUnits_treasury(r.treasuryAmount!.toString()));
    }
    return;
  }
  out.add(
    l10n.civilian_units_assignedTo(
      assignedToLabelNonPending(unit, provinceNames, l10n),
    ),
  );
}
