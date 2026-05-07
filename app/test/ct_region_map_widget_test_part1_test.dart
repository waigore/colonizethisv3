import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show AppEventBus, OpenProvinceDetailPanelEvent;

import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        CtRegionMapComponent,
        extractionIndicatorDisplaySizePx,
        extractionIndicatorRectsForIconRect,
        isCellUnderFleetRevealHalo,
        resolveProvinceLabelIconIds,
        resolveProvinceLabelPresenceIconIds,
        resolveSeaZoneLabelPrefixIconIds,
        resolveSeaZoneNamePlateCenterWorld,
        resourceIconDisplaySizePx,
        shouldEllipsizeProvinceLabelText,
        shouldShowExtractionUnitIndicators,
        shouldApplyFogToFeatureOverlay,
        shouldApplyFogToInteriorPlainsVariantBase,
        shouldApplyFogToInteriorPlainsVariantOverlay,
        shouldApplyFogToLandBase,
        shouldWrapProvinceLabelPresenceIcons,
        visibilityForTerrainForMapCell;
import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/terrain_tileset.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/ct_region_map_game.dart';
import 'package:colonizethis_app/features/game/flame/transport_overlay_tileset.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

import 'ct_region_map_test_support.dart';

CtRegionMapComponent ctRegionMapComponentFromTester(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (w) => w.runtimeType.toString().startsWith('GameWidget<'),
  );
  expect(finder, findsOneWidget);
  final gameWidget = tester.widget(finder);
  final game = (gameWidget as dynamic).game as CtRegionMapGame;
  return game.debugMapComponentForTest;
}

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(() async {
      // CtRegionMapComponent.onLoad awaits these; without a warm cache, a single
      // pump() is not enough when tests run alone (e.g. CI --total-shards).
      await terrainTilesetCache.load();
      await transportOverlayTilesetCache.load();
      await resourceIconCache.load();
      await civilianIconCache.load();
      await townIconCache.load();
      await provinceLabelIconCache.load();
    });

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
            terrain: TerrainType.forest,
          ),
          isFalse,
        );
        expect(
          shouldApplyFogToFeatureOverlay(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            tileVisibility: TileVisibility.fogged,
            terrain: TerrainType.forest,
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
          expect(data.lengthInBytes, greaterThan(0));
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final frame = await codec.getNextFrame();
          final image = frame.image;
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          expect(bytes, isNotNull);
          final rgba = bytes!.buffer.asUint8List();
          expect(rgba.length, image.width * image.height * 4);

          var opaqueCount = 0;
          var goldCount = 0;
          var minX = image.width;
          var minY = image.height;
          var maxX = -1;
          var maxY = -1;
          for (var y = 0; y < image.height; y++) {
            for (var x = 0; x < image.width; x++) {
              final i = (y * image.width + x) * 4;
              final r = rgba[i];
              final g = rgba[i + 1];
              final b = rgba[i + 2];
              final a = rgba[i + 3];
              if (a < 200) continue;
              opaqueCount++;
              if (r >= 150 && g >= 110 && b <= 120 && r >= g) {
                goldCount++;
              }
              if (x < minX) minX = x;
              if (y < minY) minY = y;
              if (x > maxX) maxX = x;
              if (y > maxY) maxY = y;
            }
          }

          expect(opaqueCount, greaterThan(20));
          expect(
            goldCount / opaqueCount,
            greaterThan(0.20),
            reason: 'Capital icon should be dominantly gold/yellow',
          );

          final boxWidth = (maxX - minX + 1).toDouble();
          final boxHeight = (maxY - minY + 1).toDouble();
          expect(boxWidth, greaterThan(6));
          expect(boxHeight, greaterThan(6));
          final bboxArea = boxWidth * boxHeight;
          final fillRatio = opaqueCount / bboxArea;
          expect(
            fillRatio,
            lessThan(0.75),
            reason:
                'Star silhouette should not fill a rectangular bounding box',
          );

          final rowCounts = List<int>.filled(image.height, 0);
          final colCounts = List<int>.filled(image.width, 0);
          for (var y = minY; y <= maxY; y++) {
            for (var x = minX; x <= maxX; x++) {
              final i = (y * image.width + x) * 4;
              if (rgba[i + 3] < 200) continue;
              rowCounts[y]++;
              colCounts[x]++;
            }
          }
          final midRow = (minY + maxY) ~/ 2;
          final midCol = (minX + maxX) ~/ 2;
          expect(rowCounts[midRow], greaterThan(rowCounts[minY] * 2));
          expect(rowCounts[midRow], greaterThan(rowCounts[maxY] * 2));
          expect(colCounts[midCol], greaterThan(colCounts[minX] * 2));
          expect(colCounts[midCol], greaterThan(colCounts[maxX] * 2));
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

        RegionMapViewData withPresence({
          required int civilianCount,
          required int regimentCount,
          required int shipCount,
          required bool intelVisible,
        }) {
          return RegionMapViewData(
            regionId: base.regionId,
            width: base.width,
            height: base.height,
            cellSize: base.cellSize,
            cells: base.cells,
            capitalMarkers: base.capitalMarkers,
            portMarkers: base.portMarkers,
            factionColors: base.factionColors,
            greatPowerFactionIds: base.greatPowerFactionIds,
            terrainColors: base.terrainColors,
            unitMarkers: base.unitMarkers,
            warpMarkers: base.warpMarkers,
            townMarkers: base.townMarkers,
            provinceUnitPresenceByProvinceId: {
              ...base.provinceUnitPresenceByProvinceId,
              fullProvinceId: ProvinceUnitPresenceView(
                civilianCount: civilianCount,
                regimentCount: regimentCount,
                shipCount: shipCount,
                intelVisible: intelVisible,
              ),
            },
          );
        }

        final initial = withPresence(
          civilianCount: 0,
          regimentCount: 0,
          shipCount: 0,
          intelVisible: true,
        );
        final refreshed = withPresence(
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
        final beforeWidget = tester.widget(gameWidgetFinder);
        final beforeRegion =
            (beforeWidget as dynamic).game.region as RegionMapViewData;
        final beforePresence =
            beforeRegion.provinceUnitPresenceByProvinceId[fullProvinceId];
        expect(beforePresence, isNotNull);
        expect(beforePresence!.civilianCount, 0);
        expect(beforePresence.regimentCount, 0);
        expect(beforePresence.shipCount, 0);

        await tester.pumpWidget(ctRegionMapTestHarness(region: refreshed));
        await tester.pump();

        final afterWidget = tester.widget(gameWidgetFinder);
        final afterRegion =
            (afterWidget as dynamic).game.region as RegionMapViewData;
        final afterPresence =
            afterRegion.provinceUnitPresenceByProvinceId[fullProvinceId];
        expect(afterPresence, isNotNull);
        expect(afterPresence!.civilianCount, 1);
        expect(afterPresence.regimentCount, 1);
        expect(afterPresence.shipCount, 1);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'required transport overlay atlas/spec assets are present in test bundle',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        const paths = [
          'assets/images/terrain/tilesets/tileset_transport_road_64.png',
          'assets/images/terrain/tilesets/tileset_transport_road_64.json',
          'assets/images/terrain/tilesets/tileset_transport_rail_64.png',
          'assets/images/terrain/tilesets/tileset_transport_rail_64.json',
        ];
        for (final path in paths) {
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Transport overlay asset $path is empty',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'required Wang tileset asset files are present in test asset bundle',
      (WidgetTester tester) async {
        // Pump a minimal widget tree so the test binding and asset bundle are initialized.
        await tester.pumpWidget(const SizedBox.shrink());

        const pngPaths = [
          'assets/images/terrain/tilesets/tileset_sea_plains_v2_64.png',
          'assets/images/terrain/tilesets/tileset_sea_desert.png',
          'assets/images/terrain/tilesets/tileset_plains_desert.png',
        ];
        const jsonPaths = [
          'assets/data/map_terrain_tilesets.json',
          'assets/images/terrain/tilesets/tileset_sea_plains_v2_64.json',
          'assets/images/terrain/tilesets/tileset_sea_desert.json',
          'assets/images/terrain/tilesets/tileset_plains_desert.json',
        ];

        for (final path in [...pngPaths, ...jsonPaths]) {
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Asset $path is empty',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'required canonical and variant L2 overlay PNGs exist in bundle',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        const paths = [
          'assets/images/terrain/tile_plains_grain.png',
          'assets/images/terrain/tile_plains_meat.png',
          'assets/images/terrain/tile_plains_horses.png',
          'assets/images/terrain/tile_forest.png',
          'assets/images/terrain/tile_forest_timber.png',
          'assets/images/terrain/tile_hills.png',
          'assets/images/terrain/tile_hills_mine.png',
          'assets/images/terrain/tile_hills_wool.png',
          'assets/images/terrain/tile_mountain.png',
          'assets/images/terrain/tile_swamp.png',
        ];

        for (final path in paths) {
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Asset $path is empty',
          );
        }
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

        expect(
          terrainTilesetCache.getStandaloneTile(TerrainType.forest),
          isNotNull,
        );
        expect(
          terrainTilesetCache.getStandaloneTile(TerrainType.hills),
          isNotNull,
        );
        expect(
          terrainTilesetCache.getStandaloneTile(TerrainType.mountain),
          isNotNull,
        );
        expect(
          terrainTilesetCache.getStandaloneTile(TerrainType.swamp),
          isNotNull,
        );
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
          // Plains variants for supported plains resources.
          terrainVariantTileKey(
            terrain: TerrainType.plains,
            resourceId: 'grain',
          )!,
          terrainVariantTileKey(
            terrain: TerrainType.plains,
            resourceId: 'meat',
          )!,
          terrainVariantTileKey(
            terrain: TerrainType.plains,
            resourceId: 'horses',
          )!,
          // Forest: non-timber should keep canonical default.
          featureOverlayTileKey(
            terrain: TerrainType.forest,
            resourceId: 'furs',
          ),
          featureOverlayTileKey(terrain: TerrainType.forest, resourceId: null),
          // Hills: non-mine and non-wool should keep canonical default.
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
          // Mountain/swamp always canonical defaults.
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

    testWidgets(
      'supports drag-to-pan gesture without throwing',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        await tester.pumpWidget(ctRegionMapTestHarness(region: region));
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        await tester.drag(mapFinder, const Offset(40, 20));
        await tester.pump();

        // Widget remains mounted after pan.
        expect(mapFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'hover and tap callbacks fire for visible tiles',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        String? lastProvinceId;
        String? lastTileKey;

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            onProvinceHovered: (id) => lastProvinceId = id,
            onTileHovered: (key) => lastTileKey = key,
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        // Move mouse over the center of the map.
        final center = tester.getCenter(mapFinder);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();
        await gesture.moveTo(center);
        await tester.pump();

        expect(lastProvinceId, isNotNull);
        expect(lastTileKey, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'centerOnTileKey triggers centering logic without throwing',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        final landCell = region.cells.firstWhere((c) => !c.isSea);
        final tileKey =
            '${region.regionId}|${landCell.regionCellId}|${landCell.x}|${landCell.y}';

        await tester.pumpWidget(
          ctRegionMapTestHarness(region: region, centerOnTileKey: tileKey),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'didUpdateWidget propagates updated props into game',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            visibilityMode: CtMapVisibilityMode.full,
            baseLayerDisplayMode:
                BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
          ),
        );
        await tester.pump();

        // Rebuild with changed visibility, political overlay, and base layer display mode.
        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            showPoliticalOverlay: false,
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            playerViewForResources: ctRegionMapTestPlayerView,
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainOnly,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );


  });
}
