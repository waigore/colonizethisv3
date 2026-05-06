import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import 'order_suggestion_build_research.dart';

/// Per-unit work-target availability for UI pre-assign gating (Refs #2133).
///
/// Populated via [getValidWorkOrderTileKeysWithVisibility] per allowed target;
/// short-circuits when the unit already has pending draft work.
class AvailableWorkTargetsForUnit {
  const AvailableWorkTargetsForUnit({
    required this.unitId,
    required this.assignable,
    this.blockedReason,
    required this.validTileKeysByTarget,
  });

  final String unitId;
  final bool assignable;
  final String? blockedReason;

  /// Non-empty valid tile sets per work target id (e.g. `explore`, `prospect`).
  final Map<String, Set<String>> validTileKeysByTarget;

  /// Deterministic target ids the shell may enable for Assign (non-empty sets).
  List<String> enabledWorkTargetIds() {
    if (!assignable) return const [];
    final out = validTileKeysByTarget.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList()
      ..sort();
    return out;
  }
}

bool _unitHasPendingDraftWorkOrder(
  String playerId,
  Orders orders,
  String unitId,
) {
  final list = orders.workOrdersByPlayerId[playerId] ?? const [];
  return list.any((o) => o.unitId == unitId);
}

/// Selected-unit availability for civilian work assignment UI (Refs #2133).
///
/// Scopes computation to [unitId] only; does not enumerate other units.
/// When [workTargetFilter] is non-null, only that target is evaluated (must be
/// allowed for the unit type).
AvailableWorkTargetsForUnit getAvailableWorkTargetsForUnit({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String unitId,
  Map<String, TileMapResult>? tileMapByRegion,
  String? workTargetFilter,
}) {
  final playerId = view.playerId;
  final unit = allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.id == unitId).firstOrNull;
  if (unit == null || unit.ownerId != playerId) {
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      blockedReason: 'unit_not_found',
      validTileKeysByTarget: const {},
    );
  }
  if (unit.currentWork != null) {
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      blockedReason: 'current_work',
      validTileKeysByTarget: const {},
    );
  }
  if (_unitHasPendingDraftWorkOrder(playerId, currentOrders, unitId)) {
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      blockedReason: 'pending_draft_work',
      validTileKeysByTarget: const {},
    );
  }

  final isExplorer = isExplorerUnit(unit.type);
  final isWorker = isCivilianWorkerUnit(unit.type);
  final isSpy = isSpyUnit(unit.type);
  final isMerchant = isMerchantUnit(unit.type);
  if (!isExplorer && !isWorker && !isSpy && !isMerchant) {
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      blockedReason: 'not_applicable',
      validTileKeysByTarget: const {},
    );
  }

  final allowed = workOrderTargetsByUnitType[unit.type];
  if (allowed == null || allowed.isEmpty) {
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      blockedReason: 'no_targets',
      validTileKeysByTarget: const {},
    );
  }

  final Iterable<String> targetsToScan;
  if (workTargetFilter != null) {
    if (!allowed.contains(workTargetFilter)) {
      return AvailableWorkTargetsForUnit(
        unitId: unitId,
        assignable: false,
        blockedReason: 'target_not_allowed',
        validTileKeysByTarget: const {},
      );
    }
    targetsToScan = [workTargetFilter];
  } else {
    targetsToScan = allowed;
  }

  final map = <String, Set<String>>{};
  for (final target in targetsToScan) {
    final tiles = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: view,
      unitId: unitId,
      workTarget: target,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
    );
    map[target] = tiles;
  }

  final assignable = map.values.any((s) => s.isNotEmpty);
  return AvailableWorkTargetsForUnit(
    unitId: unitId,
    assignable: assignable,
    blockedReason: assignable ? null : 'no_valid_tile',
    validTileKeysByTarget: map,
  );
}
