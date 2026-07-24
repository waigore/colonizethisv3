import 'package:colonizethis_map/colonizethis_map.dart';

import '../../../../providers/map_province_panel_provider.dart'
    show displayProvinceOrSeaIdFromTileKey;

/// Resolves the overlay `displayId` from a selected tile key.
///
/// Returns the empty string when [tileKey] is `null`/empty or no province or
/// sea id can be derived — the canonical "nothing to show" sentinel both hosts
/// already relied on. Behavior is unchanged from the previously duplicated
/// inline expression.
String resolveProvinceDetailDisplayId({
  required RegionMapViewData region,
  required String? tileKey,
}) {
  if (tileKey == null || tileKey.isEmpty) {
    return '';
  }
  return (provinceDetailDisplayIdForPortHarborMapTile(
            region: region,
            tileKey: tileKey,
          ) ??
          displayProvinceOrSeaIdFromTileKey(tileKey)) ??
      '';
}
