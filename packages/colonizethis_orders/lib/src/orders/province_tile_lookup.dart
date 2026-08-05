import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Region-aware province lookup from a canonical tile key (Refs #4258 Slice D).
///
/// Uses explicit `(regionId, localId)` resolution per SPEC/game/world-model.md.
Province? tryGetProvinceAtTileKey(WorldState world, String tileKey) {
  final regionId = Unit.regionIdFromTileKey(tileKey);
  final fullProvinceId = Unit.provinceIdFromTileKey(tileKey);
  if (regionId == null || fullProvinceId == null) return null;
  return world.tryGetProvinceByRegion(
    regionId,
    ProvinceId.localIdFrom(fullProvinceId),
  );
}
