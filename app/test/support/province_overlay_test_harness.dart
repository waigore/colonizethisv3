// Shared editorial-monocle pump shell for ProvinceSeaZoneDetailOverlay dark-token
// pins. Refs #3847.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

/// Returns a province id (`regionId|localId`) owned by [ownerId] in the demo
/// Old World. Province ids in the debug-init game are already prefixed.
String ownedProvinceIdInOldWorld({
  required Game game,
  required String ownerId,
}) {
  for (final province in game.worldState.oldWorld.provinces) {
    if (province.ownerId == ownerId) {
      return province.id;
    }
  }
  fail(
    'Test setup: no province in oldWorld is owned by "$ownerId"; '
    'cannot construct a human-owned province for overlay pins.',
  );
}

/// Extracts `regionId|localProvinceId` from a full tile key.
String provinceIdFromTileKey(String tileKey) {
  final parts = tileKey.split('|');
  return '${parts[0]}|${parts[1]}';
}

/// Lightweight [PlayerView] for demo-overlay pins (Refs #3656).
PlayerView demoOverlayPlayerView(Game game) {
  return buildPlayerView(game, const MapTopology(), game.players.first.id);
}

/// Returns [base] with [roadLevel] applied to [tileKey] in tile state.
Game gameWithRoadLevelOnTile({
  required Game base,
  required String tileKey,
  required int roadLevel,
}) {
  final ws = base.worldState;
  final tileState = ws.tileState.setRoadLevel(tileKey, roadLevel);
  return base.copyWith(worldState: ws.copyWith(tileState: tileState));
}

/// Builds a [MaterialApp] shell mounting [ProvinceSeaZoneDetailOverlay] under
/// `AppThemes.editorialMonocle` for dark-token widget tests.
Widget buildProvinceOverlayDarkThemeShell({
  required Game game,
  required String displayId,
  RegionMapViewData? region,
  String? selectedTileKey,
  String? humanPlayerId,
  PlayerView? playerView,
  Orders draftOrders = const Orders(),
  double? shellWidth,
  VoidCallback? onClose,
  void Function(String? tileKey)? onHighlightTile,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  VoidCallback? onProspectWithExplorerTap,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  VoidCallback? onExploreWithExplorerTap,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
  VoidCallback? onBuildImprovementTap,
  bool omniscientDetail = false,
}) {
  final overlay = ProvinceSeaZoneDetailOverlay(
    game: game,
    region: region ?? demoRegionForOverlay,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    humanPlayerId: humanPlayerId ?? game.players.first.id,
    playerView: playerView ?? demoHumanPlayerViewForOverlay,
    draftOrders: draftOrders,
    onClose: onClose,
    onHighlightTile: onHighlightTile,
    showProspectActionIcon: showProspectActionIcon,
    prospectActionEnabled: prospectActionEnabled,
    onProspectWithExplorerTap: onProspectWithExplorerTap,
    showExploreActionIcon: showExploreActionIcon,
    exploreActionEnabled: exploreActionEnabled,
    onExploreWithExplorerTap: onExploreWithExplorerTap,
    showBuildImprovementActionIcon: showBuildImprovementActionIcon,
    buildImprovementActionEnabled: buildImprovementActionEnabled,
    onBuildImprovementTap: onBuildImprovementTap,
    omniscientDetail: omniscientDetail,
  );
  final body = shellWidth != null
      ? SizedBox(width: shellWidth, child: overlay)
      : overlay;
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(body: body),
  );
}

/// Pumps [buildProvinceOverlayDarkThemeShell] and flushes the first layout pass.
Future<void> pumpProvinceOverlayAtDarkTheme(
  WidgetTester tester, {
  required Game game,
  required String displayId,
  RegionMapViewData? region,
  String? selectedTileKey,
  String? humanPlayerId,
  PlayerView? playerView,
  Orders draftOrders = const Orders(),
  double? shellWidth,
  VoidCallback? onClose,
  void Function(String? tileKey)? onHighlightTile,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  VoidCallback? onProspectWithExplorerTap,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  VoidCallback? onExploreWithExplorerTap,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
  VoidCallback? onBuildImprovementTap,
  bool omniscientDetail = false,
}) async {
  await tester.pumpWidget(
    buildProvinceOverlayDarkThemeShell(
      game: game,
      displayId: displayId,
      region: region,
      selectedTileKey: selectedTileKey,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      draftOrders: draftOrders,
      shellWidth: shellWidth,
      onClose: onClose,
      onHighlightTile: onHighlightTile,
      showProspectActionIcon: showProspectActionIcon,
      prospectActionEnabled: prospectActionEnabled,
      onProspectWithExplorerTap: onProspectWithExplorerTap,
      showExploreActionIcon: showExploreActionIcon,
      exploreActionEnabled: exploreActionEnabled,
      onExploreWithExplorerTap: onExploreWithExplorerTap,
      showBuildImprovementActionIcon: showBuildImprovementActionIcon,
      buildImprovementActionEnabled: buildImprovementActionEnabled,
      onBuildImprovementTap: onBuildImprovementTap,
      omniscientDetail: omniscientDetail,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// Overlay with the demo fixture player view and a revealed sample land tile.
Widget buildProvinceOverlayWithRevealedDemoTile({int roadLevel = 0}) {
  final base = demoGameForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;
  final game = roadLevel == 0
      ? base
      : gameWithRoadLevelOnTile(
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
  final humanPlayerId = base.players.first.id;
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
