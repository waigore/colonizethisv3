import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
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

/// First deterministic candidate entry tile in [destProvinceFullId] for bundled
/// civilian relocation (authoritative province tile list, sorted).
String? firstBundledEntryTileKeyInProvince({
  required Game game,
  required String destProvinceFullId,
}) {
  final regionId = ProvinceId.regionIdFrom(destProvinceFullId);
  final tiles = List<String>.from(
    game.worldState.tileKeysByRegionAndProvince[regionId]?[destProvinceFullId] ??
        const <String>[],
  )..sort();
  var n = 0;
  for (final tk in tiles) {
    if (n++ >= kBundledWorkTileScanCap) break;
    return tk;
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

bool hasAtLeastOneBundledEntryTileInProvince({
  required Game game,
  required String destProvinceFullId,
}) =>
    firstBundledEntryTileKeyInProvince(
      game: game,
      destProvinceFullId: destProvinceFullId,
    ) !=
    null;

OrderValidationResult validateCivilianBundledWorkMoveLeg({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Unit unit,
  required WorkOrder order,
  required PlayerView view,
  required Map<String, Unit> unitsById,
  required List<DiplomaticOrder> diplomaticOrders,
}) {
  if (!civilianBundledWorkNeedsProvinceMoveLeg(game, unit, order)) {
    return OrderValidationResult.accepted();
  }
  final destFull = executionProvinceFullIdFromWorkOrder(game, order);
  if (destFull == null) {
    return OrderValidationResult.rejected(kReasonBundledWorkMoveLegInvalid);
  }
  const moveValidator = MoveValidator();
  final moveRes = moveValidator.validate(
    MoveOrder(unitId: unit.id, destinationProvinceId: destFull),
    game,
    playerId,
    unitsById,
    diplomaticOrders,
    view,
    topology,
    previousRejected: false,
  );
  if (!moveRes.isAccepted) {
    return OrderValidationResult.rejected(kReasonBundledWorkMoveLegInvalid);
  }
  if (order.target == kWorkTargetExplore) {
    if (!hasAtLeastOneBundledEntryTileInProvince(
      game: game,
      destProvinceFullId: destFull,
    )) {
      return OrderValidationResult.rejected(kReasonNoValidEntryLandTile);
    }
  }
  return OrderValidationResult.accepted();
}
