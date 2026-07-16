import 'dart:convert';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/minimap/minimap.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show
        kRegionMinimapCustomPaintKey,
        kRegionMinimapGestureKey,
        kRegionMinimapToggleKey,
        kRegionMinimapZoomSliderKey;
import 'package:colonizethis_app/features/game/flame/region_map/region_map_viewport_snapshot.dart'
    show RegionMapViewportSnapshot, kRegionMapZoomMultiplierMax;
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';

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
  // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
  return buildAppShell(
    shellWrapper: (app) => DefaultAssetBundle(
      bundle: _MinimapTestAssetBundle(rootBundle),
      child: app,
    ),
    child: Scaffold(body: Center(child: child)),
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

class _MinimapBus {
  _MinimapBus() : bus = AppEventBus.create();
  final AppEventBus bus;
  void disposeLater() => addTearDown(bus.dispose);
}

/// Binds [bus] to collect [E] events and dispose both on tear-down.
List<E> _captureBusEvents<E extends AppEvent>(AppEventBus bus) {
  final events = <E>[];
  final sub = bus.on<E>().listen(events.add);
  addTearDown(() async {
    await sub.cancel();
    bus.dispose();
  });
  return events;
}

(double mw, double mh) _worldDims(
  RegionMapViewData region, {
  double cellSizePx = 24,
}) => (region.width * cellSizePx, region.height * cellSizePx);

Future<RegionMapViewData> _pumpTinyMinimap(
  WidgetTester tester, {
  required String regionId,
  required AppEventBus bus,
  RegionMapViewportSnapshot? viewportSnapshot,
  double cellSizePx = 24,
}) async {
  final region = _tinyRegion(regionId: regionId);
  await tester.pumpWidget(
    _minimapTestShell(
      GameRegionMinimap(
        region: region,
        viewportSnapshot: viewportSnapshot,
        bus: bus,
        cellSizePx: cellSizePx,
      ),
    ),
  );
  await tester.pump();
  return region;
}

RegionMapViewportSnapshot _snapFor(
  RegionMapViewData region, {
  required double zoom,
}) {
  const cellSizePx = 24.0;
  final (mw, mh) = _worldDims(region, cellSizePx: cellSizePx);
  return RegionMapViewportSnapshot(
    regionId: region.regionId,
    cellSizePx: cellSizePx,
    mapWidthWorld: mw,
    mapHeightWorld: mh,
    cameraCenterX: 48,
    cameraCenterY: 48,
    zoom: zoom,
    fitMapZoom: 1.0,
    viewportWidthLogical: 400,
    viewportHeightLogical: 400,
  );
}

void _expectBorderColor(BoxDecoration deco, Color color, {double width = 1}) {
  final border = deco.border! as Border;
  expect(border.top.color, color);
  expect(border.bottom.color, color);
  expect(border.left.color, color);
  expect(border.right.color, color);
  expect(border.top.width, width);
}

ColorFilter _accentFilter(Color color) =>
    ColorFilter.mode(color, BlendMode.srcIn);

Future<void> _tapZoomTrack(
  WidgetTester tester, {
  required double fractionFromLeft,
}) async {
  final track = tester.getRect(find.byKey(kRegionMinimapZoomSliderKey));
  await tester.tapAt(
    Offset(track.left + track.width * fractionFromLeft, track.center.dy),
  );
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  testWidgets('tap center/top-left emit RequestRegionMapCameraCenterWorldEvent', (
    WidgetTester tester,
  ) async {
    // Default tap hits widget center; map is square 132×132 for 4×4 aspect-1 region.
    const minimapLogical = 132.0;
    for (final case_
        in <
          ({
            String regionId,
            Future<void> Function(WidgetTester t) tap,
            Offset local,
          })
        >[
          (
            regionId: 'minimapTapRegion',
            tap: (t) => t.tap(find.byKey(kRegionMinimapGestureKey)),
            local: const Offset(minimapLogical / 2, minimapLogical / 2),
          ),
          (
            regionId: 'minimapCornerRegion',
            tap: (t) async {
              final topLeft = t.getTopLeft(
                find.byKey(kRegionMinimapGestureKey),
              );
              await t.tapAt(topLeft + const Offset(2, 2));
            },
            local: const Offset(2, 2),
          ),
        ]) {
      final bus = AppEventBus.create();
      final centers = _captureBusEvents<RequestRegionMapCameraCenterWorldEvent>(
        bus,
      );
      final region = await _pumpTinyMinimap(
        tester,
        regionId: case_.regionId,
        bus: bus,
      );
      final (mw, mh) = _worldDims(region);
      await case_.tap(tester);
      await tester.pump();
      expect(centers, hasLength(1));
      final e = centers.single;
      expect(e.regionId, region.regionId);
      final expected = minimapLocalToWorldCenter(
        localOnMinimap: case_.local,
        minimapSize: const Size(minimapLogical, minimapLogical),
        mapWidthWorld: mw,
        mapHeightWorld: mh,
      );
      expect(e.worldCenterX, closeTo(expected.dx, 1e-6));
      expect(e.worldCenterY, closeTo(expected.dy, 1e-6));
    }
  });

  testWidgets('pan gesture sums to minimapDeltaToWorldDelta', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    final pans = _captureBusEvents<RequestRegionMapCameraPanWorldDeltaEvent>(
      bus,
    );
    final region = await _pumpTinyMinimap(
      tester,
      regionId: 'minimapPanRegion',
      bus: bus,
    );
    final (mw, mh) = _worldDims(region);

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
      final mb = _MinimapBus()..disposeLater();
      final region = _tinyRegion(regionId: 'minimapZoomRegion');
      await _pumpTinyMinimap(
        tester,
        regionId: 'minimapZoomRegion',
        bus: mb.bus,
        viewportSnapshot: _snapFor(region, zoom: 2.0),
      );

      expect(find.text('200%'), findsOneWidget);
      final slider = tester.widget<CtSlider>(
        find.byKey(kRegionMinimapZoomSliderKey),
      );
      expect(slider.value, closeTo(2.0, 1e-9));
    },
  );

  testWidgets(
    'zoom slider emits RequestRegionMapSetZoomMultiplierEvent (single + multi tap)',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final zooms = _captureBusEvents<RequestRegionMapSetZoomMultiplierEvent>(
        bus,
      );
      final region = _tinyRegion(regionId: 'minimapSliderEmitRegion');
      await _pumpTinyMinimap(
        tester,
        regionId: 'minimapSliderEmitRegion',
        bus: bus,
        viewportSnapshot: _snapFor(region, zoom: 1.0),
      );

      await _tapZoomTrack(tester, fractionFromLeft: 0.75);
      expect(zooms, isNotEmpty);
      expect(zooms.last.regionId, region.regionId);
      expect(zooms.last.zoomMultiplier, greaterThan(1.0));
      expect(
        zooms.last.zoomMultiplier,
        lessThanOrEqualTo(kRegionMapZoomMultiplierMax),
      );

      final beforeMulti = zooms.length;
      final box = tester.getRect(find.byKey(kRegionMinimapZoomSliderKey));
      final y = box.center.dy;
      for (final x in <double>[box.left + 4, box.center.dx, box.right - 6]) {
        await tester.tapAt(Offset(x, y));
        await tester.pump();
      }
      expect(zooms.length, greaterThan(beforeMulti));
      expect(zooms.every((e) => e.regionId == region.regionId), isTrue);
    },
  );

  testWidgets('toggle hides gesture target but keeps slider row', (
    WidgetTester tester,
  ) async {
    final mb = _MinimapBus()..disposeLater();
    await _pumpTinyMinimap(
      tester,
      regionId: 'minimapToggleRegion',
      bus: mb.bus,
    );

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
        final mb = _MinimapBus()..disposeLater();
        await _pumpTinyMinimap(
          tester,
          regionId: 'minimapChromePanelRegion',
          bus: mb.bus,
        );

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
        _expectBorderColor(deco, EditorialMonoclePalette.border);
      },
    );

    testWidgets(
      'no light-theme Material chrome or Material design buttons inside minimap',
      (WidgetTester tester) async {
        final mb = _MinimapBus()..disposeLater();
        await _pumpTinyMinimap(
          tester,
          regionId: 'minimapChromeNoLightThemeRegion',
          bus: mb.bus,
        );

        for (final m in tester.widgetList<Material>(
          find.descendant(
            of: find.byType(GameRegionMinimap),
            matching: find.byType(Material),
          ),
        )) {
          expect(m.color, isNot(equals(Colors.white)));
          expect(m.color, isNot(equals(Colors.black)));
        }
        for (final type in const <Type>[
          ElevatedButton,
          OutlinedButton,
          FilledButton,
          IconButton,
        ]) {
          expect(
            find.descendant(
              of: find.byType(GameRegionMinimap),
              matching: find.byType(type),
            ),
            findsNothing,
          );
        }
      },
    );

    testWidgets(
      'toggle default and hover paint editorial-monocle glyph/outline tokens',
      (WidgetTester tester) async {
        final mb = _MinimapBus()..disposeLater();
        await _pumpTinyMinimap(
          tester,
          regionId: 'minimapToggleDarkChrome',
          bus: mb.bus,
        );

        final toggle = find.byKey(kRegionMinimapToggleKey);
        expect(toggle, findsOneWidget);

        AnimatedContainer animatedOf(Finder root) =>
            tester.widget<AnimatedContainer>(
              find.descendant(
                of: root,
                matching: find.byType(AnimatedContainer),
              ),
            );
        ColorFiltered filterOf(Finder root) => tester.widget<ColorFiltered>(
          find.descendant(of: root, matching: find.byType(ColorFiltered)),
        );

        final defaultDeco = animatedOf(toggle).decoration! as BoxDecoration;
        expect(defaultDeco.color, EditorialMonoclePalette.bgDeep);
        _expectBorderColor(defaultDeco, EditorialMonoclePalette.border);
        expect(
          filterOf(toggle).colorFilter,
          _accentFilter(EditorialMonoclePalette.accentDim),
        );
        final icon = tester.widget<StrictAssetIcon>(
          find.descendant(of: toggle, matching: find.byType(StrictAssetIcon)),
        );
        expect(icon.width, 20);
        expect(icon.height, 20);

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(toggle));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final hoverDeco = animatedOf(toggle).decoration! as BoxDecoration;
        expect(
          (hoverDeco.border! as Border).top.color,
          EditorialMonoclePalette.accentDim,
        );
        expect(
          filterOf(toggle).colorFilter,
          _accentFilter(EditorialMonoclePalette.accentBright),
        );
      },
    );

    testWidgets(
      'panel padding does not affect minimap gesture local coordinates',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final centers =
            _captureBusEvents<RequestRegionMapCameraCenterWorldEvent>(bus);
        final region = await _pumpTinyMinimap(
          tester,
          regionId: 'minimapPanelPaddingRegion',
          bus: bus,
        );
        final (mw, mh) = _worldDims(region);

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
