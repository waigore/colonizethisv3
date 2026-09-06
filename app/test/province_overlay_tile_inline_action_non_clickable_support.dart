// Helpers for Tile inline-action non-clickable pins (Refs #4734 Slice D).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/widgets/ct_icon_action.dart';

import 'province_overlay_test_harness.dart';

Widget overlayWithInlineActions({
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  VoidCallback? onExploreWithExplorerTap,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  VoidCallback? onProspectWithExplorerTap,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
  bool buildImprovementActionHasMatchingUnits = false,
  VoidCallback? onBuildImprovementTap,
}) {
  return buildProvinceOverlayDarkThemeShell(
    game: demoGameForOverlay,
    displayId: sampleProvinceIdForOverlay,
    selectedTileKey: sampleTileKeyForProvinceOverlay,
    showExploreActionIcon: showExploreActionIcon,
    exploreActionEnabled: exploreActionEnabled,
    onExploreWithExplorerTap: onExploreWithExplorerTap,
    showProspectActionIcon: showProspectActionIcon,
    prospectActionEnabled: prospectActionEnabled,
    onProspectWithExplorerTap: onProspectWithExplorerTap,
    showBuildImprovementActionIcon: showBuildImprovementActionIcon,
    buildImprovementActionEnabled: buildImprovementActionEnabled,
    buildImprovementActionHasMatchingUnits:
        buildImprovementActionHasMatchingUnits,
    onBuildImprovementTap: onBuildImprovementTap,
  );
}

CtIconAction iconActionByTooltip(WidgetTester tester, String tooltip) {
  return tester.widget<CtIconAction>(
    find.byWidgetPredicate(
      (widget) => widget is CtIconAction && widget.tooltip == tooltip,
    ),
  );
}

CtIconAction buildImprovementIconAction(WidgetTester tester) {
  return tester.widget<CtIconAction>(
    find.byWidgetPredicate(
      (widget) => widget is CtIconAction && widget.icon == Icons.handyman,
    ),
  );
}
