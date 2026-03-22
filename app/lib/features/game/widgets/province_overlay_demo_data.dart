// Demo Game and region data for ProvinceSeaZoneDetailOverlay Widgetbook and tests.
// Uses debug init result (generated map + initialized game). SPEC/ui/map-widget.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/widgets/debug_init_game.dart';

/// Demo region for overlay (Old World from debug init result).
RegionMapViewData get demoRegionForOverlay =>
    getDebugInitGameResult().mapViewData.oldWorld;

/// Demo game for overlay (from debug init result; matches demoRegionForOverlay).
Game get demoGameForOverlay => getDebugInitGameResult().game;

/// [PlayerView] for the first player in [demoGameForOverlay] (fog-aware overlay).
PlayerView get demoHumanPlayerViewForOverlay {
  final result = getDebugInitGameResult();
  return buildPlayerView(
    result.game,
    result.combinedTopology,
    result.game.players.first.id,
  );
}

/// First land province prefixed id in Old World (for overlay story selectedId).
String get sampleProvinceIdForOverlay {
  final region = getDebugInitGameResult().mapViewData.oldWorld;
  for (final cell in region.cells) {
    if (!cell.isSea) {
      return '${region.regionId}|${cell.regionCellId}';
    }
  }
  return '${region.regionId}|p1';
}

/// First sea zone prefixed id in Old World (for overlay story selectedId).
String get sampleSeaZoneIdForOverlay {
  final region = getDebugInitGameResult().mapViewData.oldWorld;
  for (final cell in region.cells) {
    if (cell.isSea) {
      return '${region.regionId}|${cell.regionCellId}';
    }
  }
  return '${region.regionId}|s1';
}
