// Expected plain-text lines for CivilianUnitsPanel (bottom sheet). Mirrors
// app/lib/features/game/widgets/civilian_units_panel.dart for e2e.
// If drift fails tests, align this file with the panel widget.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_sort.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_region_label.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

const Map<String, String> _workTargetLabels = {
  kWorkTargetExplore: 'Explore',
  kWorkTargetProspect: 'Prospect',
  kWorkTargetBuildImprovement: 'Build improvement',
  kWorkTargetUpgradeTown: 'Upgrade town',
  kWorkTargetBuildRoad: 'Build road',
  kWorkTargetBuildPort: 'Build port',
  kWorkTargetBuildFort: 'Build fort',
  kWorkTargetBuildRail: 'Build rail',
  kWorkTargetStealTech: 'Steal tech',
  kWorkTargetCounterSpy: 'Counter spy',
  kWorkTargetPurchaseLand: 'Purchase land',
};

// Sort/partition helpers live in `civilian_units_sort.dart` (public). This
// file delegates to them to keep e2e expectations aligned with the panel
// rendering. Refs #2575.

class _PendingAssignedResolution {
  const _PendingAssignedResolution({
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

_PendingAssignedResolution _resolvePendingAssignedResolution(
  Game game,
  Unit unit,
  WorkOrder order,
  Map<String, String> provinceNames,
) {
  final workLabel = _workTargetLabels[order.target] ?? order.target;
  final regionId = Unit.regionIdFromTileKey(order.targetTileKey);
  final provinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
  var location = '';
  if (regionId != null && provinceId != null) {
    final name =
        provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
    location = ' (${unitsPanelRegionLabel(regionId)} — $name)';
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
      return _PendingAssignedResolution(
        mainLine: base,
        totalTurns: totalTurns,
        treasuryAmount: purchaseLandCost(resourceId),
      );
    }
    return _PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
  }
  if (order.target == kWorkTargetStealTech ||
      order.target == kWorkTargetCounterSpy) {
    return _PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
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
    return _PendingAssignedResolution(
      mainLine: base,
      totalTurns: totalTurns,
      materialCosts: costMap,
    );
  }
  return _PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
}

List<MapEntry<String, int>> _sortedMaterialCostEntries(Map<String, int> m) {
  return m.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
}

WorkOrder? _pendingWorkOrder(Unit unit, Orders currentOrders, String humanId) {
  final list = currentOrders.workOrdersByPlayerId[humanId] ?? const [];
  for (final o in list) {
    if (o.unitId == unit.id) return o;
  }
  return null;
}

bool _hasPending(Unit unit, Orders currentOrders, String humanId) =>
    _pendingWorkOrder(unit, currentOrders, humanId) != null;

bool _isIdleNoPending(Unit unit, Orders currentOrders, String humanId) =>
    unit.status == UnitStatus.idle &&
    unit.currentWork == null &&
    !_hasPending(unit, currentOrders, humanId);

bool _hasWork(Unit unit, Orders currentOrders, String humanId) =>
    unit.currentWork != null || _hasPending(unit, currentOrders, humanId);

String _locationLabel(
  String? projectedTileKey,
  Map<String, String> provinceNames,
) {
  final regionId = Unit.regionIdFromTileKey(projectedTileKey);
  final provinceId = Unit.provinceIdFromTileKey(projectedTileKey);
  if (regionId == null || provinceId == null) return '—';
  final prefixed = '$regionId|$provinceId';
  final name = provinceNames[prefixed] ?? prefixed;
  final regionLabel = unitsPanelRegionLabel(regionId);
  return '$regionLabel — $name';
}

String _assignedToLabelNonPending(
  Unit unit,
  Map<String, String> provinceNames,
  AppLocalizations l10n,
) {
  if (unit.status != UnitStatus.working || unit.currentWork == null) {
    return '—';
  }
  final cw = unit.currentWork!;
  final workLabel = _workTargetLabels[cw.workTarget] ?? cw.workTarget;
  final regionId = Unit.regionIdFromTileKey(cw.tileKey);
  final provinceId = Unit.provinceIdFromTileKey(cw.tileKey);
  var location = '';
  if (regionId != null && provinceId != null) {
    final name =
        provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
    location = ' (${unitsPanelRegionLabel(regionId)} — $name)';
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

void _addAssignedLines(
  List<String> out,
  Game game,
  Unit unit,
  Orders currentOrders,
  String humanId,
  Map<String, String> provinceNames,
  AppLocalizations l10n,
) {
  final pending = _pendingWorkOrder(unit, currentOrders, humanId);
  if (pending != null) {
    final r = _resolvePendingAssignedResolution(
      game,
      unit,
      pending,
      provinceNames,
    );
    final turns = l10n.civilian_units_turns(r.totalTurns);
    out.add(l10n.civilian_units_assignedTo('${r.mainLine} — $turns'));
    if (r.materialCosts != null && r.materialCosts!.isNotEmpty) {
      for (final e in _sortedMaterialCostEntries(r.materialCosts!)) {
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
      _assignedToLabelNonPending(unit, provinceNames, l10n),
    ),
  );
}

void _addUnitRowTexts({
  required List<String> out,
  required Game game,
  required Unit unit,
  required String humanPlayerId,
  required Orders currentOrders,
  required Map<String, String> provinceNames,
  required AppLocalizations l10n,
  required bool isTileScope,
  required String? resolvedSelectedUnitId,
  required String? projectedTileKey,
}) {
  final statusLabel = switch (unit.status) {
    UnitStatus.idle => l10n.province_unitStatus_idle,
    UnitStatus.working => l10n.province_unitStatus_working,
  };
  final showActions = !isTileScope || resolvedSelectedUnitId == unit.id;

  out.add(unit.type);
  if (showActions) {
    if (_isIdleNoPending(unit, currentOrders, humanPlayerId)) {
      out.add(l10n.civilian_units_assign);
    }
    if (_hasWork(unit, currentOrders, humanPlayerId)) {
      out.add(l10n.common_cancel);
    }
  }
  out.add(l10n.civilian_units_status(statusLabel));
  out.add(
    l10n.civilian_units_location(
      _locationLabel(projectedTileKey, provinceNames),
    ),
  );
  _addAssignedLines(
    out,
    game,
    unit,
    currentOrders,
    humanPlayerId,
    provinceNames,
    l10n,
  );
}

/// In-order [Text.data] strings for [CivilianUnitsPanel] preorder traversal.
List<String> civilianUnitsPanelExpectedTexts(
  CtE2eCivilianPanelSnapshot snap,
  AppLocalizations l10n,
) {
  final game = snap.game;
  final humanPlayerId = snap.humanPlayerId;
  final provinceNames = provinceNamesByPrefixedId(game);
  final ow = civilianUnitsInRegion(
    game.worldState.oldWorld.units,
    humanPlayerId,
    provinceNames,
    snap.currentOrders,
  );
  final nw = civilianUnitsInRegion(
    game.worldState.newWorld.units,
    humanPlayerId,
    provinceNames,
    snap.currentOrders,
  );
  final scopeTileKey = snap.tileScopeTileKey;
  final tileScopeActive = scopeTileKey != null && scopeTileKey.isNotEmpty;
  var scopedOw = ow;
  var scopedNw = nw;
  if (tileScopeActive) {
    scopedOw = ow
        .where(
          (u) =>
              projectedCivilianTileKey(
                unit: u,
                playerId: humanPlayerId,
                orders: snap.currentOrders,
              ) ==
              scopeTileKey,
        )
        .toList();
    scopedNw = nw
        .where(
          (u) =>
              projectedCivilianTileKey(
                unit: u,
                playerId: humanPlayerId,
                orders: snap.currentOrders,
              ) ==
              scopeTileKey,
        )
        .toList();
  }
  final allScoped = <Unit>[...scopedOw, ...scopedNw];
  final resolvedSelected =
      snap.resolvedSelectedUnitId ??
      (allScoped.isNotEmpty ? allScoped.first.id : null);

  final out = <String>[];
  out.add(
    tileScopeActive
        ? l10n.civilian_units_title_tile
        : l10n.civilian_units_title,
  );
  if (tileScopeActive) {
    out.add(l10n.civilian_units_tile);
  }
  out.add(l10n.common_train);

  final hasAny = scopedOw.isNotEmpty || scopedNw.isNotEmpty;
  if (!hasAny) {
    out.add(l10n.civilian_units_empty);
    return out;
  }

  if (scopedOw.isNotEmpty) {
    out.add(unitsPanelRegionLabel('oldWorld'));
    for (final u in scopedOw) {
      _addUnitRowTexts(
        out: out,
        game: game,
        unit: u,
        humanPlayerId: humanPlayerId,
        currentOrders: snap.currentOrders,
        provinceNames: provinceNames,
        l10n: l10n,
        isTileScope: tileScopeActive,
        resolvedSelectedUnitId: resolvedSelected,
        projectedTileKey: projectedCivilianTileKey(
          unit: u,
          playerId: humanPlayerId,
          orders: snap.currentOrders,
        ),
      );
    }
  }
  if (scopedNw.isNotEmpty) {
    out.add(unitsPanelRegionLabel('newWorld'));
    for (final u in scopedNw) {
      _addUnitRowTexts(
        out: out,
        game: game,
        unit: u,
        humanPlayerId: humanPlayerId,
        currentOrders: snap.currentOrders,
        provinceNames: provinceNames,
        l10n: l10n,
        isTileScope: tileScopeActive,
        resolvedSelectedUnitId: resolvedSelected,
        projectedTileKey: projectedCivilianTileKey(
          unit: u,
          playerId: humanPlayerId,
          orders: snap.currentOrders,
        ),
      );
    }
  }
  return out;
}
