import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_resolver.dart';
import '../world/player_view.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_helpers.dart';
import 'order_suggestion_work_tile_keys.dart';

/// Per-unit civilian work availability for UI (Refs #2133).
/// SPEC/program/order-suggestions.md § Selected-unit availability.
class AvailableWorkTargetsForUnit {
  const AvailableWorkTargetsForUnit({
    required this.unitId,
    required this.assignable,
    required this.validTileKeysByTarget,
    this.blockedReason,
  });

  final String unitId;

  /// True when the unit may receive a new draft work order this turn
  /// (idle, no pending draft work, and at least one allowed target has a valid tile).
  final bool assignable;

  /// When [assignable] is false, a stable token for diagnostics (not user-facing).
  final String? blockedReason;

  /// Non-empty value sets per work target id (only targets with ≥1 valid tile).
  final Map<String, Set<String>> validTileKeysByTarget;

  /// Sorted work target ids that have at least one valid tile (Assign menu wiring).
  List<String> availableWorkTargetIdsSorted() {
    if (validTileKeysByTarget.isEmpty) return const [];
    final keys =
        validTileKeysByTarget.entries
            .where((e) => e.value.isNotEmpty)
            .map((e) => e.key)
            .toList()
          ..sort();
    return keys;
  }
}

/// Selected-unit civilian work availability for the human shell (Refs #2133).
///
/// Does not enumerate broad per-player [suggestWorkOrders] candidate rows.
/// When [workTargetFilter] is non-null, only that target is evaluated.
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
  Unit? unit;
  for (final u in view.ownUnits) {
    if (u.id == unitId) {
      unit = u;
      break;
    }
  }
  if (unit == null) {
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      validTileKeysByTarget: const {},
      blockedReason: 'unit_not_in_player_view',
    );
  }
  if (unit.currentWork != null) {
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      validTileKeysByTarget: const {},
      blockedReason: 'unit_has_current_work',
    );
  }
  if (playerHasPendingWorkOrderForUnit(currentOrders, playerId, unitId)) {
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      validTileKeysByTarget: const {},
      blockedReason: 'pending_draft_work_order',
    );
  }

  final allowed = workOrderTargetsByUnitType[unit.type];
  if (allowed == null || allowed.isEmpty) {
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      validTileKeysByTarget: const {},
      blockedReason: 'no_work_targets_for_unit_type',
    );
  }

  final factionMembership = DiplomacyFactionMembership.from(game);
  final playerOwnedProvinceIds = <String>{
    for (final e in view.provincesById.entries)
      if (e.value.ownerId == playerId) e.key,
  };
  final sharedValidator = buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
    factionMembership: factionMembership,
  );
  final byTarget = <String, Set<String>>{};
  for (final target in allowed) {
    if (workTargetFilter != null && target != workTargetFilter) continue;
    final tiles = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: view,
      unitId: unitId,
      workTarget: target,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      sharedCandidateValidator: sharedValidator,
      playerOwnedProvinceIds: playerOwnedProvinceIds,
    );
    if (tiles.isNotEmpty) {
      byTarget[target] = tiles;
    }
  }

  final assignable = byTarget.values.any((s) => s.isNotEmpty);
  return AvailableWorkTargetsForUnit(
    unitId: unitId,
    assignable: assignable,
    validTileKeysByTarget: byTarget,
    blockedReason: assignable ? null : 'no_valid_work_targets',
  );
}
