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

void _expectLandFog({
  required CtMapVisibilityMode visibilityMode,
  required TerrainType terrain,
  required bool landBase,
  required bool featureOverlay,
  String? reason,
}) {
  expect(
    shouldApplyFogToLandBase(
      visibilityMode: visibilityMode,
      tileVisibility: TileVisibility.fogged,
      terrain: terrain,
    ),
    landBase,
    reason: reason,
  );
  expect(
    shouldApplyFogToFeatureOverlay(
      visibilityMode: visibilityMode,
      tileVisibility: TileVisibility.fogged,
      terrain: terrain,
    ),
    featureOverlay,
    reason: reason,
  );
}

Future<void> _pumpBlank(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

Future<void> _pumpOwMap(
  WidgetTester tester, {
  RegionMapViewData? region,
  bool showPoliticalOverlay = true,
  bool showProvinceOverlay = true,
  bool showProvinceOwnershipTint = false,
  CtMapVisibilityMode visibilityMode = CtMapVisibilityMode.full,
  BaseLayerDisplayMode? baseLayerDisplayMode,
  bool playerConstrained = false,
}) async {
  await tester.pumpWidget(
    ctRegionMapTestHarness(
      region: region ?? ctRegionMapTestOldWorldRegion(),
      showPoliticalOverlay: showPoliticalOverlay,
      showProvinceOverlay: showProvinceOverlay,
      showProvinceOwnershipTint: showProvinceOwnershipTint,
      visibilityMode: visibilityMode,
      baseLayerDisplayMode: baseLayerDisplayMode,
      playerViewForResources: playerConstrained
          ? ctRegionMapTestPlayerView
          : null,
    ),
  );
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'land-base fog application skips feature terrains to prevent double darkening',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        const constrained = CtMapVisibilityMode.playerConstrained;
        _expectLandFog(
          visibilityMode: constrained,
          terrain: TerrainType.plains,
          landBase: true,
          featureOverlay: false,
          reason: 'Fogged plains darken in land-base only',
        );
        _expectLandFog(
          visibilityMode: constrained,
          terrain: TerrainType.desert,
          landBase: true,
          featureOverlay: false,
          reason: 'Fogged desert darkens in land-base only',
        );
        _expectLandFog(
          visibilityMode: constrained,
          terrain: TerrainType.swamp,
          landBase: false,
          featureOverlay: true,
          reason: 'Fogged feature tiles darken in overlay pass only',
        );
        _expectLandFog(
          visibilityMode: constrained,
          terrain: TerrainType.hardwoodForest,
          landBase: false,
          featureOverlay: true,
        );
        _expectLandFog(
          visibilityMode: CtMapVisibilityMode.full,
          terrain: TerrainType.plains,
          landBase: false,
          featureOverlay: false,
          reason: 'Full visibility mode must not apply fog',
        );
        _expectLandFog(
          visibilityMode: CtMapVisibilityMode.full,
          terrain: TerrainType.swamp,
          landBase: false,
          featureOverlay: false,
          reason: 'Full visibility mode must not apply fog',
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'fogged interior plains variants apply fog exactly once on overlay pass',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        for (final case_
            in <
              ({
                CtMapVisibilityMode mode,
                TileVisibility visibility,
                bool base,
                bool overlay,
              })
            >[
              (
                mode: CtMapVisibilityMode.playerConstrained,
                visibility: TileVisibility.fogged,
                base: false,
                overlay: true,
              ),
              (
                mode: CtMapVisibilityMode.full,
                visibility: TileVisibility.fogged,
                base: false,
                overlay: false,
              ),
              (
                mode: CtMapVisibilityMode.playerConstrained,
                visibility: TileVisibility.visible,
                base: false,
                overlay: false,
              ),
            ]) {
          expect(
            shouldApplyFogToInteriorPlainsVariantBase(
              visibilityMode: case_.mode,
              tileVisibility: case_.visibility,
            ),
            case_.base,
            reason:
                'Variant base must remain un-fogged to avoid double darkening',
          );
          expect(
            shouldApplyFogToInteriorPlainsVariantOverlay(
              visibilityMode: case_.mode,
              tileVisibility: case_.visibility,
            ),
            case_.overlay,
            reason: 'Variant overlay is the single fog attenuation pass',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'required civilian and province/sea label icon assets exist and are non-empty',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        for (final slug in kCivilianIconSlugs) {
          final colorPath = 'assets/icons/64/ui_icon_civ_$slug.png';
          final colorData = await rootBundle.load(colorPath);
          expect(
            colorData.lengthInBytes,
            greaterThan(0),
            reason: 'Civilian icon $colorPath is empty',
          );
        }
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
        await _pumpBlank(tester);
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
      'province/sea label helpers: presence gate, capital prepend, warp, ellipsis, wrap',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        const allPresence = ProvinceUnitPresenceView(
          civilianCount: 1,
          regimentCount: 2,
          shipCount: 3,
          intelVisible: true,
        );
        const allIcons = [
          'map_presence_civilian',
          'map_presence_regiment',
          'map_presence_ship',
        ];
        for (final case_ in <
          ({ProvinceUnitPresenceView? presence, List<String> icons, String? reason})
        >[
          (presence: null, icons: const [], reason: 'Null presence should suppress all icons'),
          (
            presence: const ProvinceUnitPresenceView(
              civilianCount: 1,
              regimentCount: 1,
              shipCount: 1,
              intelVisible: false,
            ),
            icons: const [],
            reason: 'Hidden intel should suppress all icons',
          ),
          (presence: allPresence, icons: allIcons, reason: null),
          (
            presence: const ProvinceUnitPresenceView(
              civilianCount: 0,
              regimentCount: 4,
              shipCount: 0,
              intelVisible: true,
            ),
            icons: const ['map_presence_regiment'],
            reason: 'Only >0 classes should render',
          ),
        ]) {
          expect(
            resolveProvinceLabelPresenceIconIds(case_.presence),
            case_.icons,
            reason: case_.reason,
          );
        }
        expect(
          resolveProvinceLabelIconIds(isCapital: true, presence: null),
          const ['map_capital_star'],
        );
        expect(
          resolveProvinceLabelIconIds(isCapital: true, presence: allPresence),
          ['map_capital_star', ...allIcons],
        );
        expect(resolveSeaZoneLabelPrefixIconIds(isWarpZone: false), isEmpty);
        expect(
          resolveSeaZoneLabelPrefixIconIds(isWarpZone: true),
          const ['map_warp_zone'],
        );
        expect(shouldEllipsizeProvinceLabelText(isCapital: true), isFalse);
        expect(shouldEllipsizeProvinceLabelText(isCapital: false), isTrue);
        for (final case_ in <
          ({double width, int icons, bool wrap, String? reason})
        >[
          (width: 20, icons: 0, wrap: false, reason: null),
          (width: 60, icons: 2, wrap: false, reason: 'Content fits one line'),
          (
            width: 110,
            icons: 3,
            wrap: true,
            reason: 'Content should wrap to second line when too wide',
          ),
        ]) {
          expect(
            shouldWrapProvinceLabelPresenceIcons(
              textWidthPx: case_.width,
              iconCount: case_.icons,
            ),
            case_.wrap,
            reason: case_.reason,
          );
        }
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
      'loads required Wang tilesets before rendering map',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await terrainTilesetCache.load();
        });

        expect(terrainTilesetCache.isLoaded, isTrue);
        expect(terrainTilesetCache.getSeaPlainsTileset(), isNotNull);
        expect(terrainTilesetCache.getSeaDesertTileset(), isNotNull);
        expect(terrainTilesetCache.getPlainsDesertTileset(), isNotNull);

        await _pumpOwMap(tester);
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'canonical L2 defaults and terrain situations resolve in tileset cache',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
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
        await _pumpOwMap(tester);
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      // GameWidget + Flame may keep the frame "dirty"; avoid long timeouts.
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'applies non-default visibility and political overlay flags',
      (WidgetTester tester) async {
        await _pumpOwMap(
          tester,
          showPoliticalOverlay: false,
          showProvinceOverlay: false,
          visibilityMode: CtMapVisibilityMode.playerConstrained,
          playerConstrained: true,
        );
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'honors province overlay and ownership tint flags without throwing',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        for (final cfg in [
          (overlay: true, tint: false),
          (overlay: false, tint: false),
          (overlay: true, tint: true),
          (overlay: false, tint: false),
        ]) {
          await _pumpOwMap(
            tester,
            region: region,
            showProvinceOverlay: cfg.overlay,
            showProvinceOwnershipTint: cfg.tint,
          );
          expect(find.byType(CtRegionMap), findsOneWidget);
        }
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'builds with each base layer display mode (SPEC/ui/map-widget.md § Base layer display mode)',
      (WidgetTester tester) async {
        for (final mode in BaseLayerDisplayMode.values) {
          await _pumpOwMap(tester, baseLayerDisplayMode: mode);
          expect(find.byType(CtRegionMap), findsOneWidget);
        }
        await _pumpOwMap(tester);
        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'extraction indicator visibility, stack layout, and display size',
      (WidgetTester tester) async {
        await _pumpBlank(tester);
        for (final case_ in <({BaseLayerDisplayMode mode, bool show})>[
          (mode: BaseLayerDisplayMode.terrainOnly, show: false),
          (mode: BaseLayerDisplayMode.terrainAndResources, show: true),
          (
            mode: BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
            show: true,
          ),
        ]) {
          expect(
            shouldShowExtractionUnitIndicators(
              baseLayerDisplayMode: case_.mode,
            ),
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
        await _pumpOwMap(tester);
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
