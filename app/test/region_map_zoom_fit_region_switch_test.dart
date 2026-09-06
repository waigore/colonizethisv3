import 'package:colonizethis_app/features/game/flame/caches/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map_viewport_snapshot.dart';
import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_app/features/game/flame/caches/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_region_map_test_support.dart';
import 'region_map_zoom_fit_support.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await terrainTilesetCache.load();
    await transportOverlayTilesetCache.load();
    await resourceIconCache.load();
    await civilianIconCache.load();
    await townIconCache.load();
    await provinceLabelIconCache.load();
  });

  testWidgets(
    'CtRegionMap preserves global zoom multiplier across region switches',
    (WidgetTester tester) async {
      final oldWorld = ctRegionMapTestOldWorldRegion();
      final newWorld = ctRegionMapTestNewWorldRegion();
      final bus = AppEventBus.create();
      RegionMapViewportSnapshot? snap;
      var activeRegion = oldWorld;
      var controlledZoomMultiplier = 1.0;

      await tester.pumpWidget(
        ctRegionMapTestHarness(
          region: activeRegion,
          scaffoldBody: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: SizedBox(
                  width: 400,
                  height: 320,
                  child: CtRegionMap(
                    region: activeRegion,
                    cellSizePx: activeRegion.cellSize.toDouble(),
                    visibilityMode: CtMapVisibilityMode.full,
                    bus: bus,
                    zoomMultiplier: controlledZoomMultiplier,
                    onViewportSnapshotChanged: (s) {
                      snap = s;
                      controlledZoomMultiplier = s.zoomMultiplier;
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      await pumpUntilCtRegionMapFitBaseline(tester, () => snap);

      bus.emit(
        RequestRegionMapSetZoomMultiplierEvent(
          regionId: oldWorld.regionId,
          zoomMultiplier: 2.0,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final zoomBeforeSwitch = snap!.zoomMultiplier;
      expect(zoomBeforeSwitch, closeTo(2.0, 0.08));

      await tester.pumpWidget(
        ctRegionMapTestHarness(
          region: newWorld,
          scaffoldBody: StatefulBuilder(
            builder: (context, setState) {
              activeRegion = newWorld;
              return Center(
                child: SizedBox(
                  width: 400,
                  height: 320,
                  child: CtRegionMap(
                    region: activeRegion,
                    cellSizePx: activeRegion.cellSize.toDouble(),
                    visibilityMode: CtMapVisibilityMode.full,
                    bus: bus,
                    zoomMultiplier: controlledZoomMultiplier,
                    onViewportSnapshotChanged: (s) {
                      snap = s;
                      controlledZoomMultiplier = s.zoomMultiplier;
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(snap, isNotNull);
      expect(snap!.regionId, newWorld.regionId);
      expect(snap!.zoomMultiplier, closeTo(zoomBeforeSwitch, 0.1));

      bus.dispose();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
