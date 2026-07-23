import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export 'movement_civilian_apply.dart'
    show applyCivilianTileMoveOrdersToWorldRegions;
export 'movement_validation.dart'
    show isValidLandMove, isValidLandMoveInRegion, neighborProvinceIdsInRegion;

/// Movement validation and application.
/// SPEC/program/movement.md

/// Legacy hook: civilian [MoveOrder] application uses
/// [applyCivilianTileMoveOrdersToWorldRegions]. This function is a no-op for move orders.
RegionData applyMoveOrdersToRegion(
  RegionData regionData,
  MapTopology topology,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId, {
  String? regionId,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  bool Function(String playerId, String destFullProvinceId)?
  isDestinationOwnedByPlayer,
}) {
  return regionData;
}
