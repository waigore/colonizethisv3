// Demo Game and region data for ProvinceSeaZoneDetailOverlay Widgetbook and tests.
// Uses committed seed-42 fixtures (Refs #3656, #3847). SPEC/ui/map-widget.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/test_support/seed42_fixture_loader.dart';

Game? _cachedDemoGame;
InitGameMapViewData? _cachedDemoMapView;

InitGameMapViewData get _demoMapView =>
    _cachedDemoMapView ??= loadSeed42MapViewData();

Game get _demoGame => _cachedDemoGame ??= loadSeed42Game();

/// Demo region for overlay (Old World from seed-42 map-view fixture).
RegionMapViewData get demoRegionForOverlay => _demoMapView.oldWorld;

/// Demo game for overlay (matches [demoRegionForOverlay]).
Game get demoGameForOverlay => _demoGame;

/// [PlayerView] for the first player in [demoGameForOverlay] (fog-aware overlay).
PlayerView get demoHumanPlayerViewForOverlay {
  return buildPlayerView(
    _demoGame,
    _demoMapView.combinedTopology,
    _demoGame.players.first.id,
  );
}

/// First land province prefixed id in Old World (for overlay story selectedId).
String get sampleProvinceIdForOverlay {
  final region = _demoMapView.oldWorld;
  for (final cell in region.cells) {
    if (!cell.isSea) {
      return '${region.regionId}|${cell.regionCellId}';
    }
  }
  return '${region.regionId}|p1';
}

/// A full tile key in [sampleProvinceIdForOverlay] for Tile section demos/tests.
String get sampleTileKeyForProvinceOverlay {
  final game = _demoGame;
  final region = _demoMapView.oldWorld;
  final provinceId = sampleProvinceIdForOverlay;
  final tiles =
      game.worldState.tileKeysByRegionAndProvince[region.regionId]?[provinceId];
  if (tiles != null && tiles.isNotEmpty) {
    return tiles.first;
  }
  final cell = region.cells.firstWhere((c) => !c.isSea);
  return '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
}

/// First sea zone prefixed id in Old World (for overlay story selectedId).
String get sampleSeaZoneIdForOverlay {
  final region = _demoMapView.oldWorld;
  for (final cell in region.cells) {
    if (cell.isSea) {
      return '${region.regionId}|${cell.regionCellId}';
    }
  }
  return '${region.regionId}|s1';
}
