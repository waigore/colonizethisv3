/// Shared MAP10001 / MAP20001 sight phrases from [TileVisibility].
///
/// SPEC: `SPEC/ui/map-widget.md` § Hover; `SPEC/ui/province-sea-zone-detail-overlay.md`.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

/// Looks up [region] cell for a full map tile key `regionId|localId|x|y`.
CellViewData? cellViewDataForMapTileKey(
  RegionMapViewData region,
  String tileKey,
) {
  final parts = tileKey.split('|');
  if (parts.length < 4) {
    return null;
  }
  if (parts[0] != region.regionId) {
    return null;
  }
  final x = int.tryParse(parts[2]);
  final y = int.tryParse(parts[3]);
  if (x == null || y == null) {
    return null;
  }
  if (x < 0 || y < 0 || x >= region.width || y >= region.height) {
    return null;
  }
  final index = y * region.width + x;
  if (index < 0 || index >= region.cells.length) {
    return null;
  }
  return region.cellAt(x, y);
}

/// Player-facing sight phrase for [visibility] (never raw enum text).
String mapTileSightPhrase(AppLocalizations l10n, TileVisibility visibility) {
  return switch (visibility) {
    TileVisibility.visible => l10n.mapSight_fullyVisible,
    TileVisibility.fogged => l10n.mapSight_foggedTerrainOnly,
    TileVisibility.unrevealed => l10n.mapSight_unknownNoIntel,
  };
}

/// Sight phrase for [selectedTileKey] in [region], or null when unresolved.
String? mapTileSightPhraseForSelectedTile({
  required AppLocalizations l10n,
  required RegionMapViewData region,
  required String? selectedTileKey,
}) {
  if (selectedTileKey == null || selectedTileKey.isEmpty) {
    return null;
  }
  final cell = cellViewDataForMapTileKey(region, selectedTileKey);
  if (cell == null) {
    return null;
  }
  return mapTileSightPhrase(l10n, cell.visibility);
}
