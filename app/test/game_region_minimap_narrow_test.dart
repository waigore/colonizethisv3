// Narrow-layout sizing contract for [GameRegionMinimap] (issue #2870 S3).
//
// Pins:
//   - The 90 × 70 dp narrow bounding box defined in
//     `SPEC/ui/mobile-adaptation.md` § In-game shell and the
//     `.minimap-panel @media (max-width:600px)` rule in
//     `SPEC/ui/mockups/GAME10001-game-screen.html`.
//   - The aspect-preserving fit (width-limited when `aspect >= 90/70`,
//     height-limited otherwise) documented in
//     `SPEC/ui/empire-overview.md` § Narrow minimap measurements.
//   - The wide-layout regression guard: when `narrow: false`, the inner
//     grid keeps the pre-#2870 baseline (longer side capped at
//     `GameRegionMinimap.defaultMaxExtent` = 132 dp).
//
// Pure-compute tests use the `@visibleForTesting` `computeMapSize`
// static so the SPEC math can be pinned without pumping the full
// minimap widget tree (which carries asset, theme, and gesture
// dependencies already covered by `game_region_minimap_widget_test`).

import 'dart:convert';

import 'package:colonizethis_app/features/game/flame/game_region_minimap.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show kRegionMinimapCustomPaintKey;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _kRegionMinimapIconAssetPath =
    'assets/icons/32/ui_icon_region_minimap.png';

ByteData _oneByOnePngByteData() {
  final bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  return ByteData.sublistView(Uint8List.fromList(bytes));
}

final class _MinimapTestAssetBundle extends CachingAssetBundle {
  _MinimapTestAssetBundle(this._parent);

  final AssetBundle _parent;

  @override
  Future<ByteData> load(String key) async {
    if (key == _kRegionMinimapIconAssetPath) {
      return _oneByOnePngByteData();
    }
    return _parent.load(key);
  }
}

Widget _minimapTestShell(Widget child) {
  return ProviderScope(
    child: DefaultAssetBundle(
      bundle: _MinimapTestAssetBundle(rootBundle),
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

RegionMapViewData _region({
  required String regionId,
  required int w,
  required int h,
}) {
  const cellSize = 24;
  final cells = <CellViewData>[
    for (var y = 0; y < h; y++)
      for (var x = 0; x < w; x++)
        CellViewData(
          x: x,
          y: y,
          regionCellId: 'c$x$y',
          isSea: false,
          terrainType: TerrainType.plains,
          visibility: TileVisibility.visible,
        ),
  ];
  return RegionMapViewData(
    regionId: regionId,
    width: w,
    height: h,
    cellSize: cellSize,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {TerrainType.plains: (100, 150, 80)},
  );
}

/// Aspect ratio at which the 90 × 70 narrow box switches from
/// height-limited to width-limited fit (boundary case).
const double _kNarrowBoxAspect =
    GameRegionMinimap.narrowMaxWidth / GameRegionMinimap.narrowMaxHeight;

void main() {
  suppressLogsForTests();

  group('GameRegionMinimap.computeMapSize narrow contract (Refs #2870 S3)', () {
    test('square region (aspect 1.0) under narrow fits height-limited 70 × 70', () {
      final size = GameRegionMinimap.computeMapSize(aspect: 1.0, narrow: true);
      expect(size.width, closeTo(GameRegionMinimap.narrowMaxHeight, 1e-9));
      expect(size.height, closeTo(GameRegionMinimap.narrowMaxHeight, 1e-9));
      expect(size.width, lessThanOrEqualTo(GameRegionMinimap.narrowMaxWidth));
      expect(size.height, lessThanOrEqualTo(GameRegionMinimap.narrowMaxHeight));
    });

    test('wide region (aspect 2.0) under narrow fits width-limited at 90', () {
      final size = GameRegionMinimap.computeMapSize(aspect: 2.0, narrow: true);
      expect(size.width, closeTo(GameRegionMinimap.narrowMaxWidth, 1e-9));
      expect(
        size.height,
        closeTo(GameRegionMinimap.narrowMaxWidth / 2.0, 1e-9),
      );
      expect(size.height, lessThanOrEqualTo(GameRegionMinimap.narrowMaxHeight));
    });

    test('tall region (aspect 0.5) under narrow fits height-limited at 70', () {
      final size = GameRegionMinimap.computeMapSize(aspect: 0.5, narrow: true);
      expect(size.height, closeTo(GameRegionMinimap.narrowMaxHeight, 1e-9));
      expect(
        size.width,
        closeTo(GameRegionMinimap.narrowMaxHeight * 0.5, 1e-9),
      );
      expect(size.width, lessThanOrEqualTo(GameRegionMinimap.narrowMaxWidth));
    });

    test('boundary aspect (90/70) maps both axes to the narrow caps', () {
      final size = GameRegionMinimap.computeMapSize(
        aspect: _kNarrowBoxAspect,
        narrow: true,
      );
      expect(size.width, closeTo(GameRegionMinimap.narrowMaxWidth, 1e-9));
      expect(size.height, closeTo(GameRegionMinimap.narrowMaxHeight, 1e-9));
    });

    test(
      'very wide region (aspect 4.0) never exceeds 90 dp width or 70 dp height',
      () {
        final size = GameRegionMinimap.computeMapSize(
          aspect: 4.0,
          narrow: true,
        );
        expect(size.width, lessThanOrEqualTo(GameRegionMinimap.narrowMaxWidth));
        expect(
          size.height,
          lessThanOrEqualTo(GameRegionMinimap.narrowMaxHeight),
        );
        expect(size.width, closeTo(GameRegionMinimap.narrowMaxWidth, 1e-9));
        expect(
          size.height,
          closeTo(GameRegionMinimap.narrowMaxWidth / 4.0, 1e-9),
        );
      },
    );
  });

  group(
    'GameRegionMinimap.computeMapSize wide regression baseline (narrow: false)',
    () {
      test('square region keeps pre-#2870 132 × 132 sizing', () {
        final size = GameRegionMinimap.computeMapSize(
          aspect: 1.0,
          narrow: false,
        );
        expect(size.width, closeTo(GameRegionMinimap.defaultMaxExtent, 1e-9));
        expect(size.height, closeTo(GameRegionMinimap.defaultMaxExtent, 1e-9));
      });

      test('wide region (aspect 2.0) keeps 132 wide × 66 tall sizing', () {
        final size = GameRegionMinimap.computeMapSize(
          aspect: 2.0,
          narrow: false,
        );
        expect(size.width, closeTo(GameRegionMinimap.defaultMaxExtent, 1e-9));
        expect(
          size.height,
          closeTo(GameRegionMinimap.defaultMaxExtent / 2.0, 1e-9),
        );
      });

      test('tall region (aspect 0.5) keeps 66 wide × 132 tall sizing', () {
        final size = GameRegionMinimap.computeMapSize(
          aspect: 0.5,
          narrow: false,
        );
        expect(
          size.width,
          closeTo(GameRegionMinimap.defaultMaxExtent * 0.5, 1e-9),
        );
        expect(size.height, closeTo(GameRegionMinimap.defaultMaxExtent, 1e-9));
      });
    },
  );

  testWidgets(
    'narrow widget tree: CustomPaint grid box fits within 90 × 70 dp',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final region = _region(regionId: 'minimapNarrowBox', w: 4, h: 4);

      await tester.pumpWidget(
        _minimapTestShell(
          GameRegionMinimap(
            region: region,
            viewportSnapshot: null,
            bus: bus,
            cellSizePx: 24,
            narrow: true,
          ),
        ),
      );
      await tester.pump();

      final paintSize = tester.getSize(find.byKey(kRegionMinimapCustomPaintKey));
      expect(
        paintSize.width,
        lessThanOrEqualTo(GameRegionMinimap.narrowMaxWidth + 1e-6),
      );
      expect(
        paintSize.height,
        lessThanOrEqualTo(GameRegionMinimap.narrowMaxHeight + 1e-6),
      );
      // Square region aspect 1.0 → fit is height-limited at 70 × 70.
      expect(
        paintSize.width,
        closeTo(GameRegionMinimap.narrowMaxHeight, 1e-6),
      );
      expect(
        paintSize.height,
        closeTo(GameRegionMinimap.narrowMaxHeight, 1e-6),
      );
    },
  );

  testWidgets(
    'wide widget tree (default narrow: false) keeps 132 × 132 CustomPaint box',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final region = _region(regionId: 'minimapWideBox', w: 4, h: 4);

      await tester.pumpWidget(
        _minimapTestShell(
          GameRegionMinimap(
            region: region,
            viewportSnapshot: null,
            bus: bus,
            cellSizePx: 24,
          ),
        ),
      );
      await tester.pump();

      final paintSize = tester.getSize(find.byKey(kRegionMinimapCustomPaintKey));
      expect(
        paintSize.width,
        closeTo(GameRegionMinimap.defaultMaxExtent, 1e-6),
      );
      expect(
        paintSize.height,
        closeTo(GameRegionMinimap.defaultMaxExtent, 1e-6),
      );
    },
  );
}
