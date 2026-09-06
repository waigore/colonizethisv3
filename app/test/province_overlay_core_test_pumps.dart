// Pump helpers for ProvinceSeaZoneDetailOverlay core pins (Refs #4305).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleSeaZoneIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'app_shell_harness.dart';
import 'province_overlay_core_test_region_helpers.dart';
import 'widget_test_assets.dart';

Future<void> pumpProvinceOverlay(
  WidgetTester tester, {
  required String displayId,
  String? selectedTileKey,
  Game? game,
  RegionMapViewData? region,
  void Function(String?)? onHighlightTile,
  VoidCallback? onClose,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  VoidCallback? onProspectWithExplorerTap,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  VoidCallback? onExploreWithExplorerTap,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
  bool buildImprovementActionHasMatchingUnits = false,
  VoidCallback? onBuildImprovementTap,
  Size? mediaQuerySize,
  bool settle = true,
}) async {
  final g = game ?? demoGameForOverlay;
  await tester.pumpWidget(
    buildAppShell(
      viewport: mediaQuerySize,
      child: Scaffold(
        body: ProvinceSeaZoneDetailOverlay(
          game: g,
          region: region ?? demoRegionForOverlay,
          displayId: displayId,
          selectedTileKey: selectedTileKey,
          humanPlayerId: g.players.first.id,
          playerView: demoHumanPlayerViewForOverlay,
          onHighlightTile: onHighlightTile,
          onClose: onClose,
          civilianInlineActions: provinceOverlayInlineActions(
            explore: (
              showIcon: showExploreActionIcon,
              enabled: exploreActionEnabled,
              hasMatchingUnits: exploreActionEnabled,
            ),
            prospect: (
              showIcon: showProspectActionIcon,
              enabled: prospectActionEnabled,
              hasMatchingUnits: prospectActionEnabled,
            ),
            buildImprovement: (
              showIcon: showBuildImprovementActionIcon,
              enabled: buildImprovementActionEnabled,
              hasMatchingUnits: buildImprovementActionHasMatchingUnits,
            ),
          ),
          inlineActionCallbacks: (
            onExploreWithExplorerTap: onExploreWithExplorerTap,
            onProspectWithExplorerTap: onProspectWithExplorerTap,
            onBuildImprovementTap: onBuildImprovementTap,
            onBuildRoadTap: null,
            onBuildFortTap: null,
            onBuildPortTap: null,
            onBuildRailroadTap: null,
            onPurchaseLandTap: null,
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> pumpProvinceOverlayDemo(
  WidgetTester tester, {
  VoidCallback? onClose,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  VoidCallback? onProspectWithExplorerTap,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  VoidCallback? onExploreWithExplorerTap,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
  bool buildImprovementActionHasMatchingUnits = false,
  VoidCallback? onBuildImprovementTap,
  Size? mediaQuerySize,
  Game? game,
  RegionMapViewData? region,
}) {
  return pumpProvinceOverlay(
    tester,
    displayId: sampleProvinceIdForOverlay,
    selectedTileKey: sampleTileKeyForProvinceOverlay,
    onClose: onClose,
    showProspectActionIcon: showProspectActionIcon,
    prospectActionEnabled: prospectActionEnabled,
    onProspectWithExplorerTap: onProspectWithExplorerTap,
    showExploreActionIcon: showExploreActionIcon,
    exploreActionEnabled: exploreActionEnabled,
    onExploreWithExplorerTap: onExploreWithExplorerTap,
    showBuildImprovementActionIcon: showBuildImprovementActionIcon,
    buildImprovementActionEnabled: buildImprovementActionEnabled,
    buildImprovementActionHasMatchingUnits:
        buildImprovementActionHasMatchingUnits,
    onBuildImprovementTap: onBuildImprovementTap,
    mediaQuerySize: mediaQuerySize,
    game: game,
    region: region,
  );
}

Future<void> pumpNamedSeaZoneOverlay(
  WidgetTester tester, {
  RegionMapViewData? region,
}) async {
  await installNinePatchAssetMock();
  await pumpProvinceOverlay(
    tester,
    displayId: sampleSeaZoneIdForOverlay,
    game: namedSeaZoneOverlayGame(),
    region: region,
  );
}
