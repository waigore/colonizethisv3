import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../providers/map_province_panel_provider.dart'
    show displayProvinceOrSeaIdFromTileKey;

/// Resolves a faction id to overlay copy (empty when [factionId] is null).
String resolveProvinceDetailFactionDisplayName(
  ct_models.Game game,
  String? factionId,
) =>
    factionId == null
        ? ''
        : (game.factionDisplayNameById(factionId) ?? factionId);

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
