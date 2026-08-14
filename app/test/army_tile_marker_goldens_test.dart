// Widget goldens for MAP10001 army stack markers (#4384).
// SPEC/ui/map-widget.md § Human army markers.

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/army_tile_marker_story.dart';

import 'ct_region_map_test_support.dart';

Future<void> _pumpArmyMarkerGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required ArmyTileMarkerStoryKind kind,
}) async {
  final region = armyTileMarkerRegion(kind);
  await tester.pumpWidget(
    ctRegionMapTestHarness(
      region: region,
      width: 72,
      height: 72,
      cellSizePx: 64,
      visibilityMode: CtMapVisibilityMode.full,
      showPoliticalOverlay: false,
      showProvinceOverlay: false,
      showProvinceNamesLayer: false,
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

  group('Army stack marker goldens (#4384)', () {
    testWidgets('golden: default field army', (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('army_stack_marker_default_golden');
      await _pumpArmyMarkerGolden(
        tester,
        boundaryKey: boundaryKey,
        kind: ArmyTileMarkerStoryKind.defaultField,
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/army_stack_marker_default.png'),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('golden: stacked field armies', (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('army_stack_marker_stacked_golden');
      await _pumpArmyMarkerGolden(
        tester,
        boundaryKey: boundaryKey,
        kind: ArmyTileMarkerStoryKind.stacked,
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/army_stack_marker_stacked.png'),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets(
      'golden: grayscale pending move',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'army_stack_marker_grayscale_golden',
        );
        await _pumpArmyMarkerGolden(
          tester,
          boundaryKey: boundaryKey,
          kind: ArmyTileMarkerStoryKind.grayscale,
        );
        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/army_stack_marker_grayscale.png'),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    testWidgets('golden: Home Army only', (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'army_stack_marker_home_only_golden',
      );
      await _pumpArmyMarkerGolden(
        tester,
        boundaryKey: boundaryKey,
        kind: ArmyTileMarkerStoryKind.homeOnly,
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/army_stack_marker_home_only.png'),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('golden: empty Home Army', (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'army_stack_marker_empty_home_golden',
      );
      await _pumpArmyMarkerGolden(
        tester,
        boundaryKey: boundaryKey,
        kind: ArmyTileMarkerStoryKind.emptyHome,
      );
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/army_stack_marker_empty_home.png'),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets(
      'golden: mixed Home plus field',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>('army_stack_marker_mixed_golden');
        await _pumpArmyMarkerGolden(
          tester,
          boundaryKey: boundaryKey,
          kind: ArmyTileMarkerStoryKind.mixedHomePlusField,
        );
        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/army_stack_marker_mixed_home_field.png'),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
