// Shared seed-42 overlay shell for MAP20001 tile-path pins (Refs #3656, #4642).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'map_view_fixture.dart';
import 'province_overlay_test_harness.dart';

final seed42MapViewForOverlayPaths = loadSeed42MapViewData();

Widget buildProvinceSeaZoneOverlayPathShell({
  required Game game,
  required RegionMapViewData region,
  required String displayId,
  required String humanPlayerId,
  String? selectedTileKey,
  VoidCallback? onClose,
}) {
  final playerView = buildPlayerView(
    game,
    seed42MapViewForOverlayPaths.combinedTopology,
    humanPlayerId,
  );
  return buildProvinceOverlayDarkThemeShell(
    game: game,
    region: region,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    onClose: onClose,
  );
}

({int x, int y}) overlayTileCoordsFromKey(String tileKey) {
  final parts = tileKey.split('|');
  final xPart = parts.length > 2 ? parts[2] : '';
  final yPart = parts.length > 3 ? parts[3] : '';
  final x = int.tryParse(xPart) ?? -1;
  final y = int.tryParse(yPart) ?? -1;
  return (x: x, y: y);
}

({String provinceId, String? selectedTileKey, ({int x, int y}) coords})
firstRevealedLandOverlaySelection({
  required Game game,
  required RegionMapViewData region,
}) {
  final landCell = region.cells.firstWhere(
    (c) => !c.isSea && c.visibility != TileVisibility.unrevealed,
  );
  final provinceId = '${region.regionId}|${landCell.regionCellId}';
  final possibleTiles =
      game.worldState.tileKeysByRegionAndProvince[region
          .regionId]?[provinceId] ??
      const <String>[];
  String? selectedTileKey;
  ({int x, int y}) coords = (x: -1, y: -1);
  for (final tk in possibleTiles) {
    final c = overlayTileCoordsFromKey(tk);
    if (c.x < 0 || c.x >= region.width || c.y < 0 || c.y >= region.height) {
      continue;
    }
    final cell = region.cellAt(c.x, c.y);
    if (cell.visibility != TileVisibility.unrevealed) {
      selectedTileKey = tk;
      coords = c;
      break;
    }
  }
  return (
    provinceId: provinceId,
    selectedTileKey: selectedTileKey,
    coords: coords,
  );
}
