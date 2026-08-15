/// Copy model for the MAP10001 owner/sight hover readout.
///
/// SPEC: `SPEC/ui/map-widget.md` § Hover (Refs #4406).
library;

import 'package:colonizethis_app/features/game/flame/controls/map_tile_sight.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_sections_political.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Presentational lines for [MapTileHoverReadout].
class MapTileHoverReadoutCopy {
  const MapTileHoverReadoutCopy({
    required this.placeLine,
    required this.identityLine,
    required this.sightLine,
    this.warpLine,
  });

  final String placeLine;
  final String identityLine;
  final String sightLine;
  final String? warpLine;

  /// Concatenated semantics (place, identity, sight, optional warp).
  String get semanticsSummary {
    final parts = <String>[placeLine, identityLine, sightLine];
    final warp = warpLine;
    if (warp != null && warp.isNotEmpty) {
      parts.add(warp);
    }
    return parts.join('. ');
  }
}

/// Builds hover copy for [tileKey], or null when the cell cannot be resolved.
MapTileHoverReadoutCopy? tryMapTileHoverReadoutCopy({
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String tileKey,
}) {
  final cell = cellViewDataForMapTileKey(region, tileKey);
  if (cell == null) {
    return null;
  }
  final sightLine = l10n.provinceOverlay_sight(
    mapTileSightPhrase(l10n, cell.visibility),
  );
  if (cell.isSea) {
    final prefixed = '${region.regionId}|${cell.regionCellId}';
    final seaName =
        region.seaZoneDisplayNameByPrefixedId[prefixed] ?? cell.regionCellId;
    final isWarp = region.warpMarkers.any(
      (m) => m.seaZoneId == cell.regionCellId,
    );
    return MapTileHoverReadoutCopy(
      placeLine: l10n.mapHover_place(seaName),
      identityLine: l10n.mapHover_seaZoneIdentity,
      sightLine: sightLine,
      warpLine: isWarp ? l10n.mapHover_warpPassage : null,
    );
  }
  final placeName = cell.provinceDisplayName ?? cell.regionCellId;
  final ownerName = ownerNameForProvinceOverlay(
    l10n,
    game,
    cell.ownerFactionId,
  );
  return MapTileHoverReadoutCopy(
    placeLine: l10n.mapHover_place(placeName),
    identityLine: l10n.provinceOverlay_owner(ownerName),
    sightLine: sightLine,
  );
}
