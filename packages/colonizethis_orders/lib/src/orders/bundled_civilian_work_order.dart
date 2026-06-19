import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_work_constants.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'order_resolution_context.dart';
import 'order_validation_result.dart';
import 'validators/move_validator.dart';

/// Draft validation: same civilian cannot queue [MoveOrder] and [WorkOrder] one turn.
/// SPEC/program/orders.md (Refs #1869).
const String kReasonCivilianMoveXorWorkOrder = 'civilian_move_xor_work_order';

/// Bundled implicit move leg failed [MoveValidator] or entry-tile existence.
const String kReasonBundledWorkMoveLegInvalid = 'bundled_work_move_leg_invalid';

/// No land tile found in destination province within scan cap (bundled entry).
const String kReasonNoValidEntryLandTile = 'no_valid_entry_land_tile';

/// Maximum tiles scanned for bundled entry existence / “explore still useful”.
const int kBundledWorkTileScanCap = 256;

List<String> _sortedBundledEntryTileKeysInProvince(
  Game game,
  String destProvinceFullId,
) {
  final regionId = ProvinceId.regionIdFrom(destProvinceFullId);
  final tiles = List<String>.from(
    game.worldState.tileKeysForProvince(regionId, destProvinceFullId) ??
        const <String>[],
  )..sort();
  return tiles;
}

String? executionProvinceFullIdFromWorkOrder(Game game, WorkOrder o) {
  final pid = Unit.provinceIdFromTileKey(o.targetTileKey);
  if (pid == null) return null;
  try {
    return resolveToFullProvinceId(game.worldState, pid);
  } on StateError {
    return null;
  }
}

bool civilianBundledWorkNeedsProvinceMoveLeg(
  Game game,
  Unit unit,
  WorkOrder o,
) {
  if (unit.tileKey == null || unit.tileKey!.isEmpty) return false;
  // steal_tech: spy work uses target-specific validation (war/visibility, GP
  // capital rules); no implicit civilian MoveOrder-equivalent leg through
  // MoveValidator in the bundled helper (see suggestWorkOrders spy tests).
  if (o.target == kWorkTargetStealTech) {
    return false;
  }
  final dest = executionProvinceFullIdFromWorkOrder(game, o);
  if (dest == null) return false;
  final current = resolveToFullProvinceId(
    game.worldState,
    unit.locationProvinceId,
  );
  if (current == dest) return false;
  // Purchased enclave: work targets player-bought land in another power's
  // province — no implicit MoveOrder-equivalent leg (MoveValidator cannot
  // express this case). Work apply handles placement. See
  // order_engine_validate_work_build_improvement_test (Refs #1869).
  if (game.worldState.purchasedTilesByTileKey[o.targetTileKey] ==
      unit.ownerId) {
    return false;
  }
  return true;
}

/// First land tile in [destProvinceFullId] that passes [MoveValidator] for the
/// implicit bundled civilian move leg (deterministic sorted order, bounded
/// scan). Returns null when the province lists no tiles or none pass.
///
/// Suggestions, bundled work validation, and movement-phase implicit relocation
/// must use the same predicate so validation and execution agree (Refs #1916).
/// [resolution] threads the canonical [OrderResolutionContext] so the cached
/// `view` + `unitsById` are reused across the per-tile probe loop (Refs #2836
/// AC 3).
String? firstLegalBundledEntryTileKeyInProvince({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Unit unit,
  required String destProvinceFullId,
  String? preferredTargetTileKey,
  required OrderResolutionContext resolution,
  required List<DiplomaticOrder> diplomaticOrders,
}) {
  const moveValidator = MoveValidator();
  final factionMembership = DiplomacyFactionMembership.from(game);
  final regionId = ProvinceId.regionIdFrom(destProvinceFullId);

  bool isMoveAccepted(String tileKey) {
    final moveRes = moveValidator.validate(
      MoveOrder(unitId: unit.id, destinationTileKey: tileKey),
      game,
      playerId,
      resolution,
      diplomaticOrders,
      topology,
      previousRejected: false,
      factionMembership: factionMembership,
    );
    return moveRes.isAccepted;
  }

  final preferredTile = preferredTargetTileKey;
  if (preferredTile != null && preferredTile.isNotEmpty) {
    final preferredProvinceId = Unit.provinceIdFromTileKey(preferredTile);
    final preferredRegionId = Unit.regionIdFromTileKey(preferredTile);
    if (preferredProvinceId == destProvinceFullId &&
        preferredRegionId == regionId &&
        isMoveAccepted(preferredTile)) {
      return preferredTile;
    }
  }

  final tiles = _sortedBundledEntryTileKeysInProvince(game, destProvinceFullId);
  var n = 0;
  for (final tk in tiles) {
    if (n++ >= kBundledWorkTileScanCap) break;
    if (isMoveAccepted(tk)) {
      return tk;
    }
  }
  return null;
}

bool exploreProvinceStillUsefulFromAuthoritativeTiles(
  PlayerView view,
  List<String> authoritativeLandTiles,
) {
  var n = 0;
  for (final tk in authoritativeLandTiles) {
    if (n++ >= kBundledWorkTileScanCap) break;
    if (view.visibilityForTile(tk) != VisibilityLevel.fullyVisible) {
      return true;
    }
  }
  return false;
}

/// [resolution] threads the canonical [OrderResolutionContext]
/// (`view` + `unitsById`) so the per-tile probe loop reuses one shared
/// pass snapshot (Refs #2836 AC 3).
OrderValidationResult validateCivilianBundledWorkMoveLeg({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Unit unit,
  required WorkOrder order,
  required OrderResolutionContext resolution,
  required List<DiplomaticOrder> diplomaticOrders,
}) {
  if (!civilianBundledWorkNeedsProvinceMoveLeg(game, unit, order)) {
    return OrderValidationResult.accepted();
  }
  final destFull = executionProvinceFullIdFromWorkOrder(game, order);
  if (destFull == null) {
    return OrderValidationResult.rejected(kReasonBundledWorkMoveLegInvalid);
  }
  final tiles = _sortedBundledEntryTileKeysInProvince(game, destFull);
  if (tiles.isEmpty) {
    return OrderValidationResult.rejected(kReasonNoValidEntryLandTile);
  }
  final legal = firstLegalBundledEntryTileKeyInProvince(
    game: game,
    topology: topology,
    playerId: playerId,
    unit: unit,
    destProvinceFullId: destFull,
    preferredTargetTileKey: order.targetTileKey,
    resolution: resolution,
    diplomaticOrders: diplomaticOrders,
  );
  if (legal == null) {
    return OrderValidationResult.rejected(kReasonBundledWorkMoveLegInvalid);
  }
  return OrderValidationResult.accepted();
}
