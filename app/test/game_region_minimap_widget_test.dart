import 'dart:convert';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/game_region_minimap.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show
        kRegionMinimapCustomPaintKey,
        kRegionMinimapGestureKey,
        kRegionMinimapToggleKey,
        kRegionMinimapZoomSliderKey;
import 'package:colonizethis_app/features/game/flame/region_map_viewport_snapshot.dart'
    show RegionMapViewportSnapshot, kRegionMapZoomMultiplierMax;
import 'package:colonizethis_app/features/game/flame/region_minimap_math.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Same path as [StrictAssetIcon] in [GameRegionMinimap] toggle.
const _kRegionMinimapIconAssetPath =
    'assets/icons/32/ui_icon_region_minimap.png';

ByteData _oneByOnePngByteData() {
  final bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  return ByteData.sublistView(Uint8List.fromList(bytes));
}

/// Supplies a tiny PNG for the minimap toggle so tests do not require the real
/// asset file on disk (CI still uses the real bundle).
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

RegionMapViewData _tinyRegion({required String regionId}) {
  const w = 4;
  const h = 4;
  const cellSize = 24;
  final cells = <CellViewData>[];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      cells.add(
        CellViewData(
          x: x,
          y: y,
          regionCellId: 'c$x$y',
          isSea: false,
          terrainType: TerrainType.plains,
          visibility: x == 0 && y == 0
              ? TileVisibility.unrevealed
              : TileVisibility.visible,
        ),
      );
    }
  }
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

void main() {
  suppressLogsForTests();

  testWidgets('tap center emits RequestRegionMapCameraCenterWorldEvent', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    final centers = <RequestRegionMapCameraCenterWorldEvent>[];
    final sub = bus.on<RequestRegionMapCameraCenterWorldEvent>().listen(
      centers.add,
    );
    addTearDown(() async {
      await sub.cancel();
      bus.dispose();
    });

    final region = _tinyRegion(regionId: 'minimapTapRegion');
    const cellSizePx = 24.0;
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;

    await tester.pumpWidget(
      _minimapTestShell(
        GameRegionMinimap(
          region: region,
          viewportSnapshot: null,
          bus: bus,
          cellSizePx: cellSizePx,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(kRegionMinimapGestureKey));
    await tester.pump();

    expect(centers, hasLength(1));
    final e = centers.single;
    expect(e.regionId, region.regionId);
    // Default tap hits widget center; map is square 132×132 for 4×4 aspect-1 region.
    const minimapLogical = 132.0;
    final expected = minimapLocalToWorldCenter(
      localOnMinimap: const Offset(minimapLogical / 2, minimapLogical / 2),
      minimapSize: const Size(minimapLogical, minimapLogical),
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    expect(e.worldCenterX, closeTo(expected.dx, 1e-6));
    expect(e.worldCenterY, closeTo(expected.dy, 1e-6));
  });

  testWidgets('tap top-left emits world origin (clamped mapping)', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    final centers = <RequestRegionMapCameraCenterWorldEvent>[];
    final sub = bus.on<RequestRegionMapCameraCenterWorldEvent>().listen(
      centers.add,
    );
    addTearDown(() async {
      await sub.cancel();
      bus.dispose();
    });

    final region = _tinyRegion(regionId: 'minimapCornerRegion');
    const cellSizePx = 24.0;
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;

    await tester.pumpWidget(
      _minimapTestShell(
        GameRegionMinimap(
          region: region,
          viewportSnapshot: null,
          bus: bus,
          cellSizePx: cellSizePx,
        ),
      ),
    );
    await tester.pump();

    final topLeft = tester.getTopLeft(find.byKey(kRegionMinimapGestureKey));
    await tester.tapAt(topLeft + const Offset(2, 2));
    await tester.pump();

    expect(centers, hasLength(1));
    final e = centers.single;
    expect(e.regionId, region.regionId);
    final expected = minimapLocalToWorldCenter(
      localOnMinimap: const Offset(2, 2),
      minimapSize: const Size(132, 132),
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    expect(e.worldCenterX, closeTo(expected.dx, 1e-6));
    expect(e.worldCenterY, closeTo(expected.dy, 1e-6));
  });

  testWidgets('pan gesture sums to minimapDeltaToWorldDelta', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    final pans = <RequestRegionMapCameraPanWorldDeltaEvent>[];
    final sub = bus.on<RequestRegionMapCameraPanWorldDeltaEvent>().listen(
      pans.add,
    );
    addTearDown(() async {
      await sub.cancel();
      bus.dispose();
    });

    final region = _tinyRegion(regionId: 'minimapPanRegion');
    const cellSizePx = 24.0;
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;

    await tester.pumpWidget(
      _minimapTestShell(
        GameRegionMinimap(
          region: region,
          viewportSnapshot: null,
          bus: bus,
          cellSizePx: cellSizePx,
        ),
      ),
    );
    await tester.pump();

    const dragLogical = Offset(24, -16);
    await tester.drag(
      find.byKey(kRegionMinimapGestureKey),
      dragLogical,
      touchSlopX: 0,
      touchSlopY: 0,
    );
    await tester.pump();

    expect(pans, isNotEmpty);
    var sumDx = 0.0;
    var sumDy = 0.0;
    for (final p in pans) {
      expect(p.regionId, region.regionId);
      sumDx += p.worldDx;
      sumDy += p.worldDy;
    }
    final expected = minimapDeltaToWorldDelta(
      minimapDelta: dragLogical,
      minimapSize: const Size(132, 132),
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    expect(sumDx, closeTo(expected.dx, 0.02));
    expect(sumDy, closeTo(expected.dy, 0.02));
  });

  testWidgets(
    'matching viewport snapshot shows slider value from zoomMultiplier',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final region = _tinyRegion(regionId: 'minimapZoomRegion');
      const cellSizePx = 24.0;
      final mw = region.width * cellSizePx;
      final mh = region.height * cellSizePx;
      final snap = RegionMapViewportSnapshot(
        regionId: 'minimapZoomRegion',
        cellSizePx: cellSizePx,
        mapWidthWorld: mw,
        mapHeightWorld: mh,
        cameraCenterX: 48,
        cameraCenterY: 48,
        zoom: 2.0,
        fitMapZoom: 1.0,
        viewportWidthLogical: 400,
        viewportHeightLogical: 400,
      );

      await tester.pumpWidget(
        _minimapTestShell(
          GameRegionMinimap(
            region: region,
            viewportSnapshot: snap,
            bus: bus,
            cellSizePx: cellSizePx,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('200%'), findsOneWidget);
      final slider = tester.widget<CtSlider>(
        find.byKey(kRegionMinimapZoomSliderKey),
      );
      expect(slider.value, closeTo(2.0, 1e-9));
    },
  );

  testWidgets('slider onChanged emits RequestRegionMapSetZoomMultiplierEvent', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    final zooms = <RequestRegionMapSetZoomMultiplierEvent>[];
    final sub = bus.on<RequestRegionMapSetZoomMultiplierEvent>().listen(
      zooms.add,
    );
    addTearDown(() async {
      await sub.cancel();
      bus.dispose();
    });

    final region = _tinyRegion(regionId: 'minimapSliderEmitRegion');
    const cellSizePx = 24.0;
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;
    final snap = RegionMapViewportSnapshot(
      regionId: 'minimapSliderEmitRegion',
      cellSizePx: cellSizePx,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
      cameraCenterX: 48,
      cameraCenterY: 48,
      zoom: 1.0,
      fitMapZoom: 1.0,
      viewportWidthLogical: 400,
      viewportHeightLogical: 400,
    );

    await tester.pumpWidget(
      _minimapTestShell(
        GameRegionMinimap(
          region: region,
          viewportSnapshot: snap,
          bus: bus,
          cellSizePx: cellSizePx,
        ),
      ),
    );
    await tester.pump();

    final sliderFinder = find.byKey(kRegionMinimapZoomSliderKey);
    final track = tester.getRect(sliderFinder);
    await tester.tapAt(
      Offset(track.left + track.width * 0.75, track.top + track.height / 2),
    );
    await tester.pump();

    expect(zooms, isNotEmpty);
    final last = zooms.last;
    expect(last.regionId, region.regionId);
    expect(last.zoomMultiplier, greaterThan(1.0));
    expect(last.zoomMultiplier, lessThanOrEqualTo(kRegionMapZoomMultiplierMax));
  });

  testWidgets(
    'sequential taps on zoom track emit multiple RequestRegionMapSetZoomMultiplierEvent',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final zooms = <RequestRegionMapSetZoomMultiplierEvent>[];
      final sub = bus.on<RequestRegionMapSetZoomMultiplierEvent>().listen(
        zooms.add,
      );
      addTearDown(() async {
        await sub.cancel();
        bus.dispose();
      });

      final region = _tinyRegion(regionId: 'minimapMultiTapZoomRegion');
      const cellSizePx = 24.0;
      final mw = region.width * cellSizePx;
      final mh = region.height * cellSizePx;
      final snap = RegionMapViewportSnapshot(
        regionId: 'minimapMultiTapZoomRegion',
        cellSizePx: cellSizePx,
        mapWidthWorld: mw,
        mapHeightWorld: mh,
        cameraCenterX: 48,
        cameraCenterY: 48,
        zoom: 1.0,
        fitMapZoom: 1.0,
        viewportWidthLogical: 400,
        viewportHeightLogical: 400,
      );

      await tester.pumpWidget(
        _minimapTestShell(
          GameRegionMinimap(
            region: region,
            viewportSnapshot: snap,
            bus: bus,
            cellSizePx: cellSizePx,
          ),
        ),
      );
      await tester.pump();

      final box = tester.getRect(find.byKey(kRegionMinimapZoomSliderKey));
      final y = box.center.dy;
      await tester.tapAt(Offset(box.left + 4, y));
      await tester.pump();
      await tester.tapAt(Offset(box.center.dx, y));
      await tester.pump();
      await tester.tapAt(Offset(box.right - 6, y));
      await tester.pump();

      expect(zooms.length, greaterThan(1));
      expect(zooms.every((e) => e.regionId == region.regionId), isTrue);
    },
  );

  testWidgets('toggle hides gesture target but keeps slider row', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

    final region = _tinyRegion(regionId: 'minimapToggleRegion');

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

    expect(find.byKey(kRegionMinimapGestureKey), findsOneWidget);
    await tester.tap(find.byKey(kRegionMinimapToggleKey));
    await tester.pump();

    expect(find.byKey(kRegionMinimapGestureKey), findsNothing);
    expect(find.byKey(kRegionMinimapZoomSliderKey), findsOneWidget);
  });

  group('dark editorial-monocle chrome (Refs #2861 S5)', () {
    testWidgets(
      'panel ancestor decoration uses --bg-deep fill + --border outline',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        final region = _tinyRegion(regionId: 'minimapChromePanelRegion');

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

        final paintCtx = tester.element(
          find.byKey(kRegionMinimapCustomPaintKey),
        );
        DecoratedBox? panel;
        paintCtx.visitAncestorElements((element) {
          final widget = element.widget;
          if (widget is DecoratedBox) {
            final deco = widget.decoration;
            if (deco is BoxDecoration &&
                deco.color == EditorialMonoclePalette.bgDeep) {
              panel = widget;
              return false;
            }
          }
          return true;
        });
        expect(
          panel,
          isNotNull,
          reason: 'expected --bg-deep DecoratedBox ancestor',
        );
        final deco = panel!.decoration as BoxDecoration;
        expect(deco.color, EditorialMonoclePalette.bgDeep);
        final border = deco.border! as Border;
        expect(border.top.color, EditorialMonoclePalette.border);
        expect(border.bottom.color, EditorialMonoclePalette.border);
        expect(border.left.color, EditorialMonoclePalette.border);
        expect(border.right.color, EditorialMonoclePalette.border);
        expect(border.top.width, 1);
      },
    );

    testWidgets(
      'no Material under minimap paints with white or black background',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        final region = _tinyRegion(regionId: 'minimapChromeNoLightThemeRegion');

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

        final materials = tester.widgetList<Material>(
          find.descendant(
            of: find.byType(GameRegionMinimap),
            matching: find.byType(Material),
          ),
        );
        for (final m in materials) {
          expect(
            m.color,
            isNot(equals(Colors.white)),
            reason: 'Material.color must not be Colors.white inside minimap',
          );
          expect(
            m.color,
            isNot(equals(Colors.black)),
            reason: 'Material.color must not be Colors.black inside minimap',
          );
        }
      },
    );

    testWidgets('no Material design buttons paint inside minimap', (
      WidgetTester tester,
    ) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      final region = _tinyRegion(regionId: 'minimapNoMaterialButtons');

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

      expect(
        find.descendant(
          of: find.byType(GameRegionMinimap),
          matching: find.byType(ElevatedButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(GameRegionMinimap),
          matching: find.byType(OutlinedButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(GameRegionMinimap),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(GameRegionMinimap),
          matching: find.byType(IconButton),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'toggle default state paints --bg-deep + --border + accent-dim glyph tint',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        final region = _tinyRegion(regionId: 'minimapToggleDarkChrome');

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

        final toggle = find.byKey(kRegionMinimapToggleKey);
        expect(toggle, findsOneWidget);

        final animated = tester.widget<AnimatedContainer>(
          find.descendant(of: toggle, matching: find.byType(AnimatedContainer)),
        );
        final deco = animated.decoration! as BoxDecoration;
        expect(deco.color, EditorialMonoclePalette.bgDeep);
        final border = deco.border! as Border;
        expect(border.top.color, EditorialMonoclePalette.border);
        expect(border.top.width, 1);

        final colorFiltered = tester.widget<ColorFiltered>(
          find.descendant(of: toggle, matching: find.byType(ColorFiltered)),
        );
        final filter = ColorFilter.mode(
          EditorialMonoclePalette.accentDim,
          BlendMode.srcIn,
        );
        expect(colorFiltered.colorFilter, filter);

        final icon = tester.widget<StrictAssetIcon>(
          find.descendant(of: toggle, matching: find.byType(StrictAssetIcon)),
        );
        expect(icon.width, 20);
        expect(icon.height, 20);
      },
    );

    testWidgets(
      'hover transitions toggle glyph tint to accent-bright + outline to accent-dim',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);

        final region = _tinyRegion(regionId: 'minimapToggleHoverChrome');

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

        final toggleFinder = find.byKey(kRegionMinimapToggleKey);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(toggleFinder));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final animated = tester.widget<AnimatedContainer>(
          find.descendant(
            of: toggleFinder,
            matching: find.byType(AnimatedContainer),
          ),
        );
        final deco = animated.decoration! as BoxDecoration;
        final border = deco.border! as Border;
        expect(border.top.color, EditorialMonoclePalette.accentDim);

        final colorFiltered = tester.widget<ColorFiltered>(
          find.descendant(
            of: toggleFinder,
            matching: find.byType(ColorFiltered),
          ),
        );
        final filter = ColorFilter.mode(
          EditorialMonoclePalette.accentBright,
          BlendMode.srcIn,
        );
        expect(colorFiltered.colorFilter, filter);
      },
    );

    testWidgets(
      'panel padding does not affect minimap gesture local coordinates',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final centers = <RequestRegionMapCameraCenterWorldEvent>[];
        final sub = bus.on<RequestRegionMapCameraCenterWorldEvent>().listen(
          centers.add,
        );
        addTearDown(() async {
          await sub.cancel();
          bus.dispose();
        });

        final region = _tinyRegion(regionId: 'minimapPanelPaddingRegion');
        const cellSizePx = 24.0;
        final mw = region.width * cellSizePx;
        final mh = region.height * cellSizePx;

        await tester.pumpWidget(
          _minimapTestShell(
            GameRegionMinimap(
              region: region,
              viewportSnapshot: null,
              bus: bus,
              cellSizePx: cellSizePx,
            ),
          ),
        );
        await tester.pump();

        final gestureBox = tester.getSize(find.byKey(kRegionMinimapGestureKey));
        expect(gestureBox.width, 132);
        expect(gestureBox.height, 132);

        final topLeft = tester.getTopLeft(find.byKey(kRegionMinimapGestureKey));
        await tester.tapAt(topLeft + const Offset(2, 2));
        await tester.pump();

        expect(centers, hasLength(1));
        final expected = minimapLocalToWorldCenter(
          localOnMinimap: const Offset(2, 2),
          minimapSize: const Size(132, 132),
          mapWidthWorld: mw,
          mapHeightWorld: mh,
        );
        expect(centers.single.worldCenterX, closeTo(expected.dx, 1e-6));
        expect(centers.single.worldCenterY, closeTo(expected.dy, 1e-6));
      },
    );
  });
}
