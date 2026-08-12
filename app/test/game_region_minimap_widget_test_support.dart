// Shared pump / asset helpers for GameRegionMinimap widget tests (Refs #4305).

import 'dart:convert';

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
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

const String kRegionMinimapTestIconAssetPath =
    'assets/icons/32/ui_icon_region_minimap.png';

ByteData regionMinimapOneByOnePngByteData() {
  final bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  return ByteData.sublistView(Uint8List.fromList(bytes));
}

final class RegionMinimapTestAssetBundle extends CachingAssetBundle {
  RegionMinimapTestAssetBundle(this._parent);

  final AssetBundle _parent;

  @override
  Future<ByteData> load(String key) async {
    if (key == kRegionMinimapTestIconAssetPath) {
      return regionMinimapOneByOnePngByteData();
    }
    return _parent.load(key);
  }
}

Widget regionMinimapTestShell(Widget child) {
  return buildAppShell(
    shellWrapper: (app) => DefaultAssetBundle(
      bundle: RegionMinimapTestAssetBundle(rootBundle),
      child: app,
    ),
    child: Scaffold(body: Center(child: child)),
  );
}

RegionMapViewData regionMinimapTinyRegion({required String regionId}) {
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

class RegionMinimapTestBus {
  RegionMinimapTestBus() : bus = AppEventBus.create();
  final AppEventBus bus;
  void disposeLater() => addTearDown(bus.dispose);
}

List<E> captureRegionMinimapBusEvents<E extends AppEvent>(AppEventBus bus) {
  final events = <E>[];
  final sub = bus.on<E>().listen(events.add);
  addTearDown(() async {
    await sub.cancel();
    bus.dispose();
  });
  return events;
}

(double mw, double mh) regionMinimapWorldDims(
  RegionMapViewData region, {
  double cellSizePx = 24,
}) => (region.width * cellSizePx, region.height * cellSizePx);

Future<RegionMapViewData> pumpRegionMinimapTiny(
  WidgetTester tester, {
  required String regionId,
  required AppEventBus bus,
  RegionMapViewportSnapshot? viewportSnapshot,
  double cellSizePx = 24,
}) async {
  final region = regionMinimapTinyRegion(regionId: regionId);
  await tester.pumpWidget(
    regionMinimapTestShell(
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

RegionMapViewportSnapshot regionMinimapSnapshotFor(
  RegionMapViewData region, {
  required double zoom,
}) {
  const cellSizePx = 24.0;
  final (mw, mh) = regionMinimapWorldDims(region, cellSizePx: cellSizePx);
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

void expectRegionMinimapBorderColor(
  BoxDecoration deco,
  Color color, {
  double width = 1,
}) {
  final border = deco.border! as Border;
  expect(border.top.color, color);
  expect(border.bottom.color, color);
  expect(border.left.color, color);
  expect(border.right.color, color);
  expect(border.top.width, width);
}

ColorFilter regionMinimapAccentFilter(Color color) =>
    ColorFilter.mode(color, BlendMode.srcIn);

Future<void> tapRegionMinimapZoomTrack(
  WidgetTester tester, {
  required double fractionFromLeft,
}) async {
  final track = tester.getRect(find.byKey(kRegionMinimapZoomSliderKey));
  await tester.tapAt(
    Offset(track.left + track.width * fractionFromLeft, track.center.dy),
  );
  await tester.pump();
}

Finder get regionMinimapGestureFinder => find.byKey(kRegionMinimapGestureKey);
Finder get regionMinimapToggleFinder => find.byKey(kRegionMinimapToggleKey);
Finder get regionMinimapZoomSliderFinder => find.byKey(kRegionMinimapZoomSliderKey);
Finder get regionMinimapCustomPaintFinder =>
    find.byKey(kRegionMinimapCustomPaintKey);

double get kRegionMinimapZoomMultiplierMaxValue => kRegionMapZoomMultiplierMax;
