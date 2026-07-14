import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';

import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        extractionIndicatorDisplaySizePx,
        extractionIndicatorRectsForIconRect,
        resolveProvinceLabelIconIds,
        resolveProvinceLabelPresenceIconIds,
        resolveSeaZoneLabelPrefixIconIds,
        shouldEllipsizeProvinceLabelText,
        shouldShowExtractionUnitIndicators,
        shouldApplyFogToFeatureOverlay,
        shouldApplyFogToInteriorPlainsVariantBase,
        shouldApplyFogToInteriorPlainsVariantOverlay,
        shouldApplyFogToLandBase,
        shouldWrapProvinceLabelPresenceIcons;
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

import 'ct_region_map_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'land-base fog application skips feature terrains to prevent double darkening',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(
          shouldApplyFogToLandBase(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            tileVisibility: TileVisibility.fogged,
            terrain: TerrainType.plains,
          ),
          isTrue,
          reason: 'Fogged plains should darken in land-base pass',
        );
        expect(
          shouldApplyFogToLandBase(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            tileVisibility: TileVisibility.fogged,
            terrain: TerrainType.desert,
          ),
          isTrue,
          reason: 'Fogged desert should darken in land-base pass',
        );
        expect(
          shouldApplyFogToLandBase(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            tileVisibility: TileVisibility.fogged,
            terrain: TerrainType.swamp,
          ),
          isFalse,
          reason: 'Fogged feature tiles darken in overlay pass only',
        );
        expect(
          shouldApplyFogToFeatureOverlay(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            tileVisibility: TileVisibility.fogged,
            terrain: TerrainType.swamp,
          ),
          isTrue,
          reason: 'Fogged feature tiles should darken in overlay pass',
        );
        expect(
          shouldApplyFogToLandBase(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            tileVisibility: TileVisibility.fogged,
            terrain: TerrainType.hardwoodForest,
          ),
          isFalse,
        );
        expect(
          shouldApplyFogToFeatureOverlay(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            tileVisibility: TileVisibility.fogged,
            terrain: TerrainType.hardwoodForest,
          ),
          isTrue,
        );
        expect(
          shouldApplyFogToFeatureOverlay(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            tileVisibility: TileVisibility.fogged,
            terrain: TerrainType.plains,
          ),
          isFalse,
          reason: 'Fogged non-feature tiles darken in land-base pass only',
        );
        expect(
          shouldApplyFogToLandBase(
            visibilityMode: CtMapVisibilityMode.full,
            tileVisibility: TileVisibility.fogged,
            terrain: TerrainType.plains,
          ),
          isFalse,
          reason: 'Full visibility mode must not apply fog',
        );
        expect(
          shouldApplyFogToFeatureOverlay(
            visibilityMode: CtMapVisibilityMode.full,
            tileVisibility: TileVisibility.fogged,
            terrain: TerrainType.swamp,
          ),
          isFalse,
          reason: 'Full visibility mode must not apply fog',
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'fogged interior plains variants apply fog exactly once on overlay pass',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(
          shouldApplyFogToInteriorPlainsVariantBase(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            tileVisibility: TileVisibility.fogged,
          ),
          isFalse,
          reason:
              'Variant base must remain un-fogged to avoid double darkening',
        );
        expect(
          shouldApplyFogToInteriorPlainsVariantOverlay(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            tileVisibility: TileVisibility.fogged,
          ),
          isTrue,
          reason: 'Variant overlay is the single fog attenuation pass',
        );
        expect(
          shouldApplyFogToInteriorPlainsVariantBase(
            visibilityMode: CtMapVisibilityMode.full,
            tileVisibility: TileVisibility.fogged,
          ),
          isFalse,
        );
        expect(
          shouldApplyFogToInteriorPlainsVariantOverlay(
            visibilityMode: CtMapVisibilityMode.full,
            tileVisibility: TileVisibility.fogged,
          ),
          isFalse,
        );
        expect(
          shouldApplyFogToInteriorPlainsVariantOverlay(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            tileVisibility: TileVisibility.visible,
          ),
          isFalse,
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'required civilian map icon assets exist and are non-empty',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        for (final slug in kCivilianIconSlugs) {
          final colorPath = 'assets/icons/64/ui_icon_civ_$slug.png';
          final colorData = await rootBundle.load(colorPath);
          expect(
            colorData.lengthInBytes,
            greaterThan(0),
            reason: 'Civilian icon $colorPath is empty',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'throws StateError when playerConstrained without playerViewForResources',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  height: 320,
                  child: CtRegionMap(
                    region: region,
                    visibilityMode: CtMapVisibilityMode.playerConstrained,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isA<StateError>());
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'required province/sea label icon assets exist and are non-empty',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        for (final iconId in kProvinceLabelIconIds) {
          final path = 'assets/icons/64/ui_icon_$iconId.png';
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Province label icon $path is empty',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'capital star icon asset resembles a gold star silhouette',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          final data = await rootBundle.load(
            'assets/icons/64/ui_icon_map_capital_star.png',
          );
          await expectCapitalStarSilhouette(data);
        });
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'province presence icon resolver enforces intel gate, zero suppression, and class order',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(
          resolveProvinceLabelPresenceIconIds(null),
          isEmpty,
          reason: 'Null presence should suppress all icons',
        );
        expect(
          resolveProvinceLabelPresenceIconIds(
            const ProvinceUnitPresenceView(
              civilianCount: 1,
              regimentCount: 1,
              shipCount: 1,
              intelVisible: false,
            ),
          ),
          isEmpty,
          reason: 'Hidden intel should suppress all icons',
        );
        expect(
          resolveProvinceLabelPresenceIconIds(
            const ProvinceUnitPresenceView(
              civilianCount: 1,
              regimentCount: 2,
              shipCount: 3,
              intelVisible: true,
            ),
          ),
          const [
            'map_presence_civilian',
            'map_presence_regiment',
            'map_presence_ship',
          ],
        );
        expect(
          resolveProvinceLabelPresenceIconIds(
            const ProvinceUnitPresenceView(
              civilianCount: 0,
              regimentCount: 4,
              shipCount: 0,
              intelVisible: true,
            ),
          ),
          const ['map_presence_regiment'],
          reason: 'Only >0 classes should render',
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'province label icon resolver prepends capital icon before presence icons',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(
          resolveProvinceLabelIconIds(isCapital: true, presence: null),
          const ['map_capital_star'],
        );
        expect(
          resolveProvinceLabelIconIds(
            isCapital: true,
            presence: const ProvinceUnitPresenceView(
              civilianCount: 1,
              regimentCount: 2,
              shipCount: 3,
              intelVisible: true,
            ),
          ),
          const [
            'map_capital_star',
            'map_presence_civilian',
            'map_presence_regiment',
            'map_presence_ship',
          ],
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'sea-zone label prefix icon resolver emits warp icon only for warp zones',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(resolveSeaZoneLabelPrefixIconIds(isWarpZone: false), isEmpty);
        expect(resolveSeaZoneLabelPrefixIconIds(isWarpZone: true), const [
          'map_warp_zone',
        ]);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'capital province labels disable ellipsis while non-capitals retain ellipsis',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(shouldEllipsizeProvinceLabelText(isCapital: true), isFalse);
        expect(shouldEllipsizeProvinceLabelText(isCapital: false), isTrue);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'presence icon wrap helper moves icons to second line only when width is insufficient',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(
          shouldWrapProvinceLabelPresenceIcons(textWidthPx: 20, iconCount: 0),
          isFalse,
        );
        expect(
          shouldWrapProvinceLabelPresenceIcons(textWidthPx: 60, iconCount: 2),
          isFalse,
          reason: 'Content fits one line',
        );
        expect(
          shouldWrapProvinceLabelPresenceIcons(textWidthPx: 110, iconCount: 3),
          isTrue,
          reason: 'Content should wrap to second line when too wide',
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'didUpdateWidget refreshes map region presence data after rebuild',
      (WidgetTester tester) async {
        final base = ctRegionMapTestOldWorldRegion();
        final localProvinceId = base.cells
            .firstWhere((c) => !c.isSea)
            .regionCellId;
        final fullProvinceId = '${base.regionId}|$localProvinceId';

        final initial = ctRegionMapWithPresence(
          base: base,
          fullProvinceId: fullProvinceId,
          civilianCount: 0,
          regimentCount: 0,
          shipCount: 0,
          intelVisible: true,
        );
        final refreshed = ctRegionMapWithPresence(
          base: base,
          fullProvinceId: fullProvinceId,
          civilianCount: 1,
          regimentCount: 1,
          shipCount: 1,
          intelVisible: true,
        );

        await tester.pumpWidget(ctRegionMapTestHarness(region: initial));
        await tester.pump();

        final gameWidgetFinder = find.byWidgetPredicate(
          (w) => w.runtimeType.toString().startsWith('GameWidget<'),
        );
        expect(gameWidgetFinder, findsOneWidget);
        final beforeRegion =
            (tester.widget(gameWidgetFinder) as dynamic).game.region
                as RegionMapViewData;
        final beforePresence =
            beforeRegion.provinceUnitPresenceByProvinceId[fullProvinceId]!;
        expect(beforePresence.civilianCount, 0);
        expect(beforePresence.regimentCount, 0);
        expect(beforePresence.shipCount, 0);

        await tester.pumpWidget(ctRegionMapTestHarness(region: refreshed));
        await tester.pump();

        final afterPresence =
            ((tester.widget(gameWidgetFinder) as dynamic).game.region
                    as RegionMapViewData)
                .provinceUnitPresenceByProvinceId[fullProvinceId]!;
        expect(afterPresence.civilianCount, 1);
        expect(afterPresence.regimentCount, 1);
        expect(afterPresence.shipCount, 1);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'required transport overlay atlas/spec assets are present in test bundle',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await expectCtRegionMapAssetsNonEmpty(
          ctRegionMapTransportOverlayAssetPaths,
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'required Wang tileset asset files are present in test asset bundle',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await expectCtRegionMapAssetsNonEmpty([
          ...ctRegionMapWangPngAssetPaths,
          ...ctRegionMapWangJsonAssetPaths,
        ]);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'required canonical and variant L2 overlay PNGs exist in bundle',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await expectCtRegionMapAssetsNonEmpty(ctRegionMapL2OverlayAssetPaths);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'loads required Wang tilesets before rendering map',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
        });

        expect(terrainTilesetCache.isLoaded, isTrue);
        expect(terrainTilesetCache.getSeaPlainsTileset(), isNotNull);
        expect(terrainTilesetCache.getSeaDesertTileset(), isNotNull);
        expect(terrainTilesetCache.getPlainsDesertTileset(), isNotNull);

        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'canonical L2 default overlays are findable by terrain type',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
        });

        for (final t in [
          TerrainType.hardwoodForest,
          TerrainType.scrubForest,
          TerrainType.hills,
          TerrainType.mountain,
          TerrainType.swamp,
        ]) {
          expect(terrainTilesetCache.getStandaloneTile(t), isNotNull);
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'terrain situations resolve to findable canonical defaults',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
        });

        final keys = <String>[
          for (final id in [
            'grain',
            'meat',
            'horses',
            'sugarCane',
            'tobacco',
            'cotton',
            'spices',
          ])
            terrainVariantTileKey(terrain: TerrainType.plains, resourceId: id)!,
          featureOverlayTileKey(
            terrain: TerrainType.hardwoodForest,
            resourceId: 'furs',
          ),
          featureOverlayTileKey(
            terrain: TerrainType.hardwoodForest,
            resourceId: null,
          ),
          featureOverlayTileKey(
            terrain: TerrainType.scrubForest,
            resourceId: null,
          ),
          featureOverlayTileKey(
            terrain: TerrainType.hills,
            resourceId: 'iron',
            improvementLevel: 0,
          ),
          featureOverlayTileKey(
            terrain: TerrainType.hills,
            resourceId: null,
            improvementLevel: 0,
          ),
          featureOverlayTileKey(
            terrain: TerrainType.mountain,
            resourceId: 'gold',
          ),
          featureOverlayTileKey(terrain: TerrainType.swamp, resourceId: 'tin'),
        ];

        for (final key in keys) {
          expect(
            terrainTilesetCache.getStandaloneTileByKey(key),
            isNotNull,
            reason: 'Overlay key $key should be available in cache',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
    testWidgets(
      'builds without throwing for old world region',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        // Do a single pump; CtRegionMap embeds a Flame GameWidget which
        // does not naturally settle for pumpAndSettle.
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      // GameWidget + Flame may keep the frame "dirty"; avoid long timeouts.
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'applies non-default visibility and political overlay flags',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            showPoliticalOverlay: false,
            showProvinceOverlay: false,
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            playerViewForResources: ctRegionMapTestPlayerView,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'honors province overlay visibility flag without throwing',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();

        // Province overlay on.
        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, showProvinceOverlay: true),
        );
        await tester.pump();
        expect(find.byType(CtRegionMap), findsOneWidget);

        // Province overlay off.
        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, showProvinceOverlay: false),
        );
        await tester.pump();
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'honors province ownership tint flag without throwing',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            showProvinceOwnershipTint: true,
          ),
        );
        await tester.pump();
        expect(find.byType(CtRegionMap), findsOneWidget);

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            showProvinceOwnershipTint: false,
          ),
        );
        await tester.pump();
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'builds with each base layer display mode (SPEC/ui/map-widget.md § Base layer display mode)',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        for (final mode in BaseLayerDisplayMode.values) {
          await tester.pumpWidget(
            ctRegionMapTestHarness(region: region, baseLayerDisplayMode: mode),
          );
          await tester.pump();
          expect(find.byType(CtRegionMap), findsOneWidget);
        }
        // Omitted baseLayerDisplayMode defaults to full letters
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'extraction indicator visibility follows base-layer resource visibility mode',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(
          shouldShowExtractionUnitIndicators(
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainOnly,
          ),
          isFalse,
        );
        expect(
          shouldShowExtractionUnitIndicators(
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
          ),
          isTrue,
        );
        expect(
          shouldShowExtractionUnitIndicators(
            baseLayerDisplayMode:
                BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
          ),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'extraction indicator stack layout advances right with overlap',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

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
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'extraction indicator size is at least resource icon display size',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        expect(extractionIndicatorDisplaySizePx(16), greaterThanOrEqualTo(16));
        expect(extractionIndicatorDisplaySizePx(24), greaterThanOrEqualTo(24));
        expect(extractionIndicatorDisplaySizePx(64), equals(64));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'responds to +/- keyboard shortcuts for zoom',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        // Give the Focus widget a chance to attach.
        await tester.tap(mapFinder);
        await tester.pump();

        // Zoom in.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.equal);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.equal);
        await tester.pump();

        // Zoom out.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.minus);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.minus);
        await tester.pump();

        expect(mapFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );
  });
}
