// Widget goldens for MAP10001 improvement headroom marks (#4408).
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/improvement_headroom_mark_story.dart';

import 'ct_region_map_test_support.dart';

Future<void> _pumpMarkGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required RegionMapViewData region,
  bool showImprovements = true,
  bool playerConstrained = false,
  PlayerView? playerView,
}) async {
  await tester.pumpWidget(
    ctRegionMapTestHarness(
      region: region,
      width: 72,
      height: 72,
      cellSizePx: 64,
      visibilityMode: playerConstrained
          ? CtMapVisibilityMode.playerConstrained
          : CtMapVisibilityMode.full,
      playerViewForResources: playerConstrained
          ? (playerView ?? improvementHeadroomHiddenMineralView)
          : null,
      showPoliticalOverlay: false,
      showProvinceOverlay: false,
      showProvinceNamesLayer: false,
      showCapitalLinkDisconnectedHighlight: false,
      baseLayerDisplayMode: showImprovements
          ? BaseLayerDisplayMode.terrainAndResourcesImprovementLabels
          : BaseLayerDisplayMode.terrainAndResources,
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

  testWidgets('golden: at-cap muted 1 of 1', (tester) async {
    const boundaryKey = ValueKey<String>('improvement_mark_at_cap');
    await _pumpMarkGolden(
      tester,
      boundaryKey: boundaryKey,
      region: improvementHeadroomMarkRegion(
        improvementLevel: 1,
        improvementTechCap: 1,
      ),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/improvement_headroom_mark_at_cap.png'),
    );
  });

  testWidgets('golden: has-headroom 1 of 2', (tester) async {
    const boundaryKey = ValueKey<String>('improvement_mark_headroom');
    await _pumpMarkGolden(
      tester,
      boundaryKey: boundaryKey,
      region: improvementHeadroomMarkRegion(
        improvementLevel: 1,
        improvementTechCap: 2,
      ),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/improvement_headroom_mark_headroom.png'),
    );
  });

  testWidgets('golden: foreign level-only', (tester) async {
    const boundaryKey = ValueKey<String>('improvement_mark_foreign');
    await _pumpMarkGolden(
      tester,
      boundaryKey: boundaryKey,
      region: improvementHeadroomMarkRegion(
        improvementLevel: 2,
        ownerFactionId: 'gp2',
      ),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/improvement_headroom_mark_foreign.png'),
    );
  });

  testWidgets('golden: owned hidden-resource level-only', (tester) async {
    const boundaryKey = ValueKey<String>('improvement_mark_hidden');
    await _pumpMarkGolden(
      tester,
      boundaryKey: boundaryKey,
      region: improvementHeadroomMarkRegion(
        improvementLevel: 2,
        improvementTechCap: 3,
        resourceId: 'gold',
      ),
      playerConstrained: true,
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile(
        'goldens/improvement_headroom_mark_hidden_resource.png',
      ),
    );
  });

  testWidgets('golden: unimproved unmarked', (tester) async {
    const boundaryKey = ValueKey<String>('improvement_mark_unimproved');
    await _pumpMarkGolden(
      tester,
      boundaryKey: boundaryKey,
      region: improvementHeadroomMarkRegion(
        improvementLevel: 0,
        improvementTechCap: 1,
      ),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/improvement_headroom_mark_unimproved.png'),
    );
  });

  testWidgets('golden: unrevealed hidden', (tester) async {
    const boundaryKey = ValueKey<String>('improvement_mark_unrevealed');
    await _pumpMarkGolden(
      tester,
      boundaryKey: boundaryKey,
      region: improvementHeadroomMarkRegion(
        improvementLevel: 2,
        improvementTechCap: 2,
        visibility: TileVisibility.unrevealed,
      ),
      playerConstrained: true,
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/improvement_headroom_mark_unrevealed.png'),
    );
  });

  testWidgets('golden: improvements off', (tester) async {
    const boundaryKey = ValueKey<String>('improvement_mark_off');
    await _pumpMarkGolden(
      tester,
      boundaryKey: boundaryKey,
      region: improvementHeadroomMarkRegion(
        improvementLevel: 1,
        improvementTechCap: 1,
      ),
      showImprovements: false,
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/improvement_headroom_mark_off.png'),
    );
  });
}
