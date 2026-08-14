// Widget goldens for MAP10001 capital-link disconnected hatch (#4370).
// SPEC/ui/map-widget.md § Capital-link disconnected land.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/capital_link_disconnected_highlight_story.dart';

import 'ct_region_map_test_support.dart';

Future<void> _pumpHatchGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required RegionMapViewData region,
  required Size physicalSize,
  bool showHighlight = true,
  CtMapVisibilityMode visibilityMode = CtMapVisibilityMode.full,
}) async {
  await tester.pumpWidget(
    ctRegionMapTestHarness(
      region: region,
      width: physicalSize.width,
      height: physicalSize.height,
      cellSizePx: 64,
      visibilityMode: visibilityMode,
      playerViewForResources:
          visibilityMode == CtMapVisibilityMode.playerConstrained
          ? ctRegionMapTestPlayerView
          : null,
      showPoliticalOverlay: false,
      showProvinceOverlay: false,
      showProvinceNamesLayer: false,
      showCapitalLinkDisconnectedHighlight: showHighlight,
      baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
      useScaffold: false,
      repaintBoundaryKey: boundaryKey,
    ),
  );
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await warmCtRegionMapCachesForTests();
  });

  testWidgets(
    'golden: mixed connected vs disconnected hatch on (Refs #4370)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('capital_link_hatch_mixed_golden');
      await _pumpHatchGolden(
        tester,
        boundaryKey: boundaryKey,
        region: capitalLinkDisconnectedHighlightRegion(),
        physicalSize: const Size(128, 72),
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/capital_link_hatch_mixed.png'),
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'golden: mixed tiles with highlight off (Refs #4370)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('capital_link_hatch_off_golden');
      await _pumpHatchGolden(
        tester,
        boundaryKey: boundaryKey,
        region: capitalLinkDisconnectedHighlightRegion(),
        physicalSize: const Size(128, 72),
        showHighlight: false,
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/capital_link_hatch_off.png'),
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'golden: fogged disconnected hatch (Refs #4370)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('capital_link_hatch_fogged_golden');
      await _pumpHatchGolden(
        tester,
        boundaryKey: boundaryKey,
        region: capitalLinkDisconnectedHighlightRegion(
          disconnectedVisibility: TileVisibility.fogged,
        ),
        physicalSize: const Size(128, 72),
        visibilityMode: CtMapVisibilityMode.playerConstrained,
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/capital_link_hatch_fogged.png'),
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'golden: hatch at 320 dp narrow host (Refs #4370)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('capital_link_hatch_narrow_golden');
      await _pumpHatchGolden(
        tester,
        boundaryKey: boundaryKey,
        region: capitalLinkDisconnectedHighlightRegion(),
        physicalSize: const Size(kMinViewportWidth, 120),
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/capital_link_hatch_narrow.png'),
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
