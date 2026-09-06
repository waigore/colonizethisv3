import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        extractionIndicatorDisplaySizePx,
        extractionIndicatorRectsForIconRect,
        shouldShowExtractionUnitIndicators;
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

import 'ct_region_map_test_support.dart';

Future<void> _pumpBlank(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget) — overlays & assets', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'required transport / Wang / L2 overlay assets are present in test bundle',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        await expectCtRegionMapAssetsNonEmpty([
          ...ctRegionMapTransportOverlayAssetPaths,
          ...ctRegionMapWangPngAssetPaths,
          ...ctRegionMapWangJsonAssetPaths,
          ...ctRegionMapL2OverlayAssetPaths,
        ]);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'Wang tilesets load for map; L2 defaults and terrain overlays resolve',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
        });
        expect(terrainTilesetCache.isLoaded, isTrue);
        expect(terrainTilesetCache.getSeaPlainsTileset(), isNotNull);
        expect(terrainTilesetCache.getSeaDesertTileset(), isNotNull);
        expect(terrainTilesetCache.getPlainsDesertTileset(), isNotNull);

        await pumpCtRegionMapTest(tester);
        expect(find.byType(CtRegionMap), findsOneWidget);

        for (final t in [
          TerrainType.hardwoodForest,
          TerrainType.scrubForest,
          TerrainType.hills,
          TerrainType.mountain,
          TerrainType.swamp,
        ]) {
          expect(terrainTilesetCache.getStandaloneTile(t), isNotNull);
        }
        final keys = <String>[
          for (final id in const [
            'grain',
            'meat',
            'horses',
            'sugarCane',
            'tobacco',
            'cotton',
            'spices',
          ])
            terrainVariantTileKey(terrain: TerrainType.plains, resourceId: id)!,
          for (final args in <(TerrainType, String?, int?)>[
            (TerrainType.hardwoodForest, 'furs', null),
            (TerrainType.hardwoodForest, null, null),
            (TerrainType.scrubForest, null, null),
            (TerrainType.hills, 'iron', 0),
            (TerrainType.hills, null, 0),
            (TerrainType.mountain, 'gold', null),
            (TerrainType.swamp, 'tin', null),
          ])
            featureOverlayTileKey(
              terrain: args.$1,
              resourceId: args.$2,
              improvementLevel: args.$3,
            ),
        ];
        for (final key in keys) {
          expect(
            terrainTilesetCache.getStandaloneTileByKey(key),
            isNotNull,
            reason: 'Overlay key $key should be available in cache',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'builds for OW region across visibility, overlay, tint, and base-layer modes',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        void expectMap() => expect(find.byType(CtRegionMap), findsOneWidget);

        await pumpCtRegionMapTest(tester);
        expectMap();

        await pumpCtRegionMapTest(
          tester,
          showPoliticalOverlay: false,
          showProvinceOverlay: false,
          visibilityMode: CtMapVisibilityMode.playerConstrained,
          playerConstrained: true,
        );
        expectMap();

        for (final cfg in [
          (overlay: true, tint: false),
          (overlay: false, tint: false),
          (overlay: true, tint: true),
        ]) {
          await pumpCtRegionMapTest(
            tester,
            region: region,
            showProvinceOverlay: cfg.overlay,
            showProvinceOwnershipTint: cfg.tint,
          );
          expectMap();
        }

        for (final mode in BaseLayerDisplayMode.values) {
          await pumpCtRegionMapTest(tester, baseLayerDisplayMode: mode);
          expectMap();
        }
        await pumpCtRegionMapTest(tester);
        expectMap();
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'extraction indicator visibility, stack layout, and display size',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        for (final case_ in <({MapBaseLayerFlags flags, bool show})>[
          (flags: MapBaseLayerFlags.terrainOnly, show: false),
          (flags: MapBaseLayerFlags.resourcesOnly, show: true),
          (flags: MapBaseLayerFlags.resourcesAndImprovements, show: true),
          (flags: MapBaseLayerFlags.fullDetail, show: true),
        ]) {
          expect(
            shouldShowExtractionUnitIndicators(flags: case_.flags),
            case_.show,
          );
        }
        final rects = extractionIndicatorRectsForIconRect(
          iconRect: const Rect.fromLTWH(10, 20, 64, 64),
          units: 3,
        );
        expect(rects, hasLength(3));
        expect(rects[1].left, greaterThan(rects[0].left));
        expect(rects[2].left, greaterThan(rects[1].left));
        expect(rects[0].top, equals(rects[1].top));
        expect(rects[1].top, equals(rects[2].top));
        expect(rects[1].left, lessThan(rects[0].right));
        for (final size in <double>[16, 24]) {
          expect(
            extractionIndicatorDisplaySizePx(size),
            greaterThanOrEqualTo(size),
          );
        }
        expect(extractionIndicatorDisplaySizePx(64), equals(64));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'responds to +/- keyboard shortcuts for zoom',
      (WidgetTester tester) async {
        await pumpCtRegionMapTest(tester);
        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);
        await tester.tap(mapFinder);
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.equal);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.equal);
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.minus);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.minus);
        await tester.pump();
        expect(mapFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );
  });
}
