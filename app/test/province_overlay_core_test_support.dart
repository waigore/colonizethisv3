// Shared pumps and region helpers for ProvinceSeaZoneDetailOverlay core pins.
// Refs #4305 Slice D densify.

export 'province_overlay_core_test_pumps.dart';
export 'province_overlay_core_test_region_helpers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoHumanPlayerViewForOverlay, demoRegionForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';

import 'app_shell_harness.dart';

void expectProvinceOverlayMaxHeight(double maxHeight) {
  expect(
    find.byWidgetPredicate(
      (w) => w is ConstrainedBox && w.constraints.maxHeight == maxHeight,
    ),
    findsAtLeastNWidgets(1),
  );
}

Widget mapBesideOverlayHost({
  required Widget map,
  Widget? overlay,
  bool expandMap = true,
  double mapWidth = 400,
  double mapHeight = 320,
}) {
  return buildAppShell(
    child: Scaffold(
      body: Row(
        children: [
          if (expandMap)
            Expanded(child: map)
          else
            SizedBox(width: mapWidth, height: mapHeight, child: map),
          if (overlay != null) SizedBox(width: 320, child: overlay),
        ],
      ),
    ),
  );
}

ProvinceSeaZoneDetailOverlay demoProvinceOverlay({
  required String displayId,
  required String? selectedTileKey,
  required VoidCallback onClose,
}) {
  final g = demoGameForOverlay;
  return ProvinceSeaZoneDetailOverlay(
    game: g,
    region: demoRegionForOverlay,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    humanPlayerId: g.players.first.id,
    playerView: demoHumanPlayerViewForOverlay,
    onClose: onClose,
  );
}

void expectProvinceOverlayTexts(Iterable<String> texts) {
  for (final text in texts) {
    expect(find.text(text), findsOneWidget);
  }
}
