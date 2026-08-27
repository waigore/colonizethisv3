// Demo-fixture shell builders for MAP20001 dark-token pins (Refs #3847).
// Split from province_overlay_test_harness.dart for repo.app_test_file_size.

import 'package:colonizethis_logic/colonizethis_logic.dart' show VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart' show TileVisibility;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;

import 'province_overlay_test_harness.dart';

/// Overlay with the demo fixture player view and a revealed sample land tile.
Widget buildProvinceOverlayWithRevealedDemoTile({int roadLevel = 0}) {
  final base = demoGameForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;
  final game = gameWithRoadLevelOnTile(
    base: base,
    tileKey: tileKey,
    roadLevel: roadLevel,
  );
  return buildProvinceOverlayDarkThemeShell(
    game: game,
    displayId: provinceIdFromTileKey(tileKey),
    selectedTileKey: tileKey,
    playerView: demoOverlayPlayerView(base),
  );
}

/// Overlay with demo fixture, full player view, and configurable road level.
Widget buildProvinceOverlayWithRoadLevelFullPlayerView({
  required int roadLevel,
}) {
  final base = demoGameForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;
  final game = gameWithRoadLevelOnTile(
    base: base,
    tileKey: tileKey,
    roadLevel: roadLevel,
  );
  return buildProvinceOverlayDarkThemeShell(
    game: game,
    displayId: provinceIdFromTileKey(tileKey),
    selectedTileKey: tileKey,
    playerView: demoOverlayPlayerView(base),
  );
}

/// Overlay with demo fixture, demo player view, and optional inline action icons.
Widget buildProvinceOverlayWithRoadLevelDemoFixture({
  required int roadLevel,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
}) {
  final base = demoGameForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;
  final game = gameWithRoadLevelOnTile(
    base: base,
    tileKey: tileKey,
    roadLevel: roadLevel,
  );
  return buildProvinceOverlayDarkThemeShell(
    game: game,
    displayId: sampleProvinceIdForOverlay,
    selectedTileKey: tileKey,
    showExploreActionIcon: showExploreActionIcon,
    exploreActionEnabled: exploreActionEnabled,
    onExploreWithExplorerTap: () {},
    showProspectActionIcon: showProspectActionIcon,
    prospectActionEnabled: prospectActionEnabled,
    onProspectWithExplorerTap: () {},
    showBuildImprovementActionIcon: showBuildImprovementActionIcon,
    buildImprovementActionEnabled: buildImprovementActionEnabled,
    onBuildImprovementTap: () {},
  );
}

/// Overlay with a province-context display id and a sea-cell selected tile.
/// Returns `null` when the demo fixture cannot supply the port-harbor case.
Widget? buildProvinceOverlayWithSeaCellAtLandProvince() {
  final base = demoGameForOverlay;
  final region = demoRegionForOverlay;
  final playerView = demoOverlayPlayerView(base);

  String? landDisplayId;
  for (final cell in region.cells) {
    if (!cell.isSea) {
      landDisplayId = '${region.regionId}|${cell.regionCellId}';
      break;
    }
  }

  String? seaTileKey;
  for (final cell in region.cells) {
    if (!cell.isSea) continue;
    if (cell.visibility == TileVisibility.unrevealed) continue;
    final candidate =
        '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
    if (playerView.visibilityForTile(candidate) != VisibilityLevel.unknown) {
      seaTileKey = candidate;
      break;
    }
  }
  if (landDisplayId == null || seaTileKey == null) return null;

  return buildProvinceOverlayDarkThemeShell(
    game: base,
    displayId: landDisplayId,
    selectedTileKey: seaTileKey,
    playerView: playerView,
  );
}

/// Searches the demo region for a revealed land tile with no resource.
({String displayId, String tileKey})? findRevealedLandTileWithoutResource() {
  final game = demoGameForOverlay;
  final region = demoRegionForOverlay;
  final playerView = demoOverlayPlayerView(game);
  final resourceByTile = game.worldState.resourceByTileKey;
  for (final cell in region.cells) {
    if (cell.isSea) continue;
    if (cell.resourceId != null) continue;
    final tk = '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
    if (resourceByTile[tk] != null) continue;
    if (playerView.visibilityForTile(tk) != VisibilityLevel.fullyVisible) {
      continue;
    }
    final displayId = '${region.regionId}|${cell.regionCellId}';
    return (displayId: displayId, tileKey: tk);
  }
  return null;
}

/// Overlay with a revealed land tile that has no visible resource.
Widget? buildProvinceOverlayWithRevealedNoResourceTile() {
  final pick = findRevealedLandTileWithoutResource();
  if (pick == null) return null;
  final game = demoGameForOverlay;
  return buildProvinceOverlayDarkThemeShell(
    game: game,
    displayId: pick.displayId,
    selectedTileKey: pick.tileKey,
    playerView: demoOverlayPlayerView(game),
  );
}
