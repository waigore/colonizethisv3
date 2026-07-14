import 'package:colonizethis_models/colonizethis_models.dart';

import 'province_lookup.dart';
import 'unit_lookup.dart';

/// Prefixed ids use [ProvinceId.regionIdFrom]; otherwise resolve from [WorldState]
/// (legacy tests and fixtures may use local province ids only).
String regionIdForProvinceInWorld(WorldState ws, String provinceId) {
  if (ProvinceId.isPrefixed(provinceId)) {
    return ProvinceId.regionIdFrom(provinceId);
  }
  final region = ws.tryGetRegionIdForLegacyProvinceKey(provinceId);
  if (region == null) {
    throw StateError('Province id not found in either region: "$provinceId"');
  }
  return region;
}

/// Prefixed [Unit.locationProvinceId] uses [ProvinceId.regionIdFrom]; otherwise
/// infer region from which regional unit list contains [u].
String regionIdForUnitInWorld(WorldState ws, Unit u) {
  if (ProvinceId.isPrefixed(u.locationProvinceId)) {
    return ProvinceId.regionIdFrom(u.locationProvinceId);
  }
  final region = ws.tryGetRegionIdForUnit(u);
  if (region == null) {
    throw StateError('Military unit ${u.id} not found in world state regions');
  }
  return region;
}
