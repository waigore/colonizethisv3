// Visual goldens + silhouette/mid-tone pins for NW plains plantation tiles
// (Refs #3961 AC5/AC6).
// SPEC/ui/layered-terrain-rendering.md § Plains resource variants (L1).

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';

import 'ct_region_map_test_support.dart';

/// PIL field mid-tones from SPEC/ui/layered-terrain-rendering.md.
const _plantationFieldMidTones = <String, (int, int, int)>{
  'tile_plains_sugar_cane': (124, 179, 66),
  'tile_plains_tobacco': (128, 108, 42),
  'tile_plains_cotton': (214, 208, 178),
  'tile_plains_spices': (196, 98, 42),
};

const _owPlainsKeys = <String>[
  'tile_plains_grain',
  'tile_plains_meat',
  'tile_plains_horses',
];

const _plantationKeys = <String>[
  'tile_plains_sugar_cane',
  'tile_plains_tobacco',
  'tile_plains_cotton',
  'tile_plains_spices',
];

bool _isFieldHighlight(int r, int g, int b, int a) {
  if (a < 16) return false;
  return g > r + 8 && g > b + 8 && g >= 55 && r >= 40;
}

Future<ui.Image> _decodePngFile(File file) async {
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<ByteData> _rawRgba(ui.Image image) async {
  final bd = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  expect(bd, isNotNull);
  return bd!;
}

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

  group('Plains plantation terrain goldens (Refs #3961)', () {
    RegionMapViewData plainsResourceStripRegion() {
      const resources = <String>[
        'grain',
        'meat',
        'horses',
        'sugarCane',
        'tobacco',
        'cotton',
        'spices',
      ];
      return RegionMapViewData(
        regionId: 'plainsPlantationGolden',
        width: resources.length,
        height: 1,
        cellSize: 64,
        cells: [
          for (var i = 0; i < resources.length; i++)
            CellViewData(
              x: i,
              y: 0,
              regionCellId: 'p$i',
              isSea: false,
              terrainType: TerrainType.plains,
              resourceId: resources[i],
              provinceDisplayName: 'P$i',
            ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        townMarkers: const [],
        factionColors: const {},
        greatPowerFactionIds: const {},
        terrainColors: const {TerrainType.plains: (120, 160, 90)},
        warpMarkers: const [],
      );
    }

    testWidgets(
      'map strip: OW + plantation plains variants at tile scale '
      '(AC5/AC6; Refs #3961)',
      (WidgetTester tester) async {
        const cellPx = 64.0;
        const width = 7 * cellPx;
        const height = cellPx;
        final region = plainsResourceStripRegion();

        await tester.binding.setSurfaceSize(const Size(width, height));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ctRegionMapTestHarness(
            region: region,
            width: width,
            height: height,
            cellSizePx: cellPx,
            visibilityMode: CtMapVisibilityMode.full,
            showPoliticalOverlay: false,
            showProvinceOverlay: false,
            showProvinceNamesLayer: false,
            // terrainOnly still paints L1 plains resource overlays;
            // omits commodity icon layer so the golden pins decals.
            baseLayerDisplayMode: BaseLayerDisplayMode.terrainOnly,
            useScaffold: false,
            repaintBoundaryKey: const ValueKey(
              'plains_plantation_terrain_strip_golden',
            ),
          ),
        );

        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        await expectLater(
          find.byKey(const ValueKey('plains_plantation_terrain_strip_golden')),
          matchesGoldenFile(
            'goldens/plains_plantation_terrain_strip_64.png',
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );

    test(
      'plantation PNGs share alpha silhouette and distinct field mid-tones '
      '(AC5; Refs #3961)',
      () async {
        final repoRoot = Directory.current.path.endsWith('/app')
            ? Directory.current.parent.path
            : Directory.current.path;
        final terrainDir = Directory(
          '$repoRoot/app/assets/images/terrain',
        );
        final baseFile = File(
          '$repoRoot/pytool/assets/terrain/tile_plains_plantation_base.png',
        );
        expect(baseFile.existsSync(), isTrue);

        final baseImage = await _decodePngFile(baseFile);
        addTearDown(baseImage.dispose);
        final baseBytes = await _rawRgba(baseImage);
        expect(baseImage.width, 64);
        expect(baseImage.height, 64);

        final meanRgbByKey = <String, (double, double, double)>{};

        for (final key in _plantationKeys) {
          final file = File('${terrainDir.path}/$key.png');
          expect(file.existsSync(), isTrue, reason: 'missing $key.png');
          final image = await _decodePngFile(file);
          addTearDown(image.dispose);
          expect(image.width, baseImage.width);
          expect(image.height, baseImage.height);
          final bytes = await _rawRgba(image);

          var alphaMismatches = 0;
          var fieldCount = 0;
          var sumR = 0.0;
          var sumG = 0.0;
          var sumB = 0.0;
          final pixelCount = image.width * image.height;
          for (var i = 0; i < pixelCount; i++) {
            final o = i * 4;
            final aBase = baseBytes.getUint8(o + 3);
            final aVar = bytes.getUint8(o + 3);
            if (aBase != aVar) alphaMismatches++;

            final r = bytes.getUint8(o);
            final g = bytes.getUint8(o + 1);
            final b = bytes.getUint8(o + 2);
            final a = aVar;
            // After recolour, field pixels are no longer yellow-green; sample
            // using the base mask so we measure the recoloured crop region.
            final br = baseBytes.getUint8(o);
            final bg = baseBytes.getUint8(o + 1);
            final bb = baseBytes.getUint8(o + 2);
            if (_isFieldHighlight(br, bg, bb, aBase)) {
              fieldCount++;
              sumR += r;
              sumG += g;
              sumB += b;
              expect(a, aBase);
            }
          }
          expect(
            alphaMismatches,
            0,
            reason: '$key alpha must match plantation base silhouette',
          );
          expect(fieldCount, greaterThan(100), reason: '$key field mask');
          meanRgbByKey[key] = (
            sumR / fieldCount,
            sumG / fieldCount,
            sumB / fieldCount,
          );

          final target = _plantationFieldMidTones[key]!;
          final mean = meanRgbByKey[key]!;
          // Mean of luminance-scaled field pixels stays near the SPEC mid-tone.
          expect(
            (mean.$1 - target.$1).abs(),
            lessThan(55),
            reason: '$key mean R near ${target.$1}',
          );
          expect(
            (mean.$2 - target.$2).abs(),
            lessThan(55),
            reason: '$key mean G near ${target.$2}',
          );
          expect(
            (mean.$3 - target.$3).abs(),
            lessThan(55),
            reason: '$key mean B near ${target.$3}',
          );
        }

        // Each plantation mean is farther from the other three than a small
        // epsilon — colours are visually distinct.
        for (final a in _plantationKeys) {
          for (final b in _plantationKeys) {
            if (a == b) continue;
            final ma = meanRgbByKey[a]!;
            final mb = meanRgbByKey[b]!;
            final dist = math.sqrt(
              math.pow(ma.$1 - mb.$1, 2) +
                  math.pow(ma.$2 - mb.$2, 2) +
                  math.pow(ma.$3 - mb.$3, 2),
            );
            expect(
              dist,
              greaterThan(25),
              reason: '$a vs $b field means must differ',
            );
          }
        }
      },
    );

    test(
      'OW plains variants remain distinct class peers for plantation strip '
      '(AC6 negative: plantation keys load alongside OW; Refs #3961)',
      () {
        for (final key in [..._owPlainsKeys, ..._plantationKeys]) {
          expect(
            terrainTilesetCache.getStandaloneTileByKey(key),
            isNotNull,
            reason: 'required plains variant $key',
          );
        }
      },
    );
  });
}
