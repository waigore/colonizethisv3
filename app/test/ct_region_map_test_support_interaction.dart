import 'dart:ui' as ui;

import 'package:colonizethis_models/colonizethis_models.dart'
    show AppEvent, AppEventBus;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

Finder ctRegionMapFinder() => find.byType(CtRegionMap);

Future<void> tapCtRegionMap(WidgetTester tester) async {
  await tester.tap(ctRegionMapFinder());
  await tester.pump();
}

Future<void> tapCtRegionMapSecondary(WidgetTester tester) async {
  await tester.tap(ctRegionMapFinder(), buttons: kSecondaryButton);
  await tester.pump();
}

Offset ctRegionMapCenter(WidgetTester tester) {
  final box = tester.element(ctRegionMapFinder()).renderObject! as RenderBox;
  return box.localToGlobal(box.size.center(Offset.zero));
}

Future<void> scrollCtRegionMap(WidgetTester tester, double dy) async {
  await tester.sendEventToBinding(
    PointerScrollEvent(
      position: ctRegionMapCenter(tester),
      scrollDelta: Offset(0, dy),
    ),
  );
  await tester.pump();
}

(AppEventBus, List<T>) ctRegionMapBusCapture<T extends AppEvent>() {
  final bus = AppEventBus.create();
  final events = <T>[];
  final sub = bus.on<T>().listen(events.add);
  addTearDown(() {
    sub.cancel();
    bus.dispose();
  });
  return (bus, events);
}

Future<void> preloadCtRegionMapRoadAssets() async {
  await terrainTilesetCache.load();
  await transportOverlayTilesetCache.load();
  await resourceIconCache.load();
}

Future<int> countLoadedCtRegionMapResourceIconAssets() async {
  var loaded = 0;
  for (final resourceId in kResourceIconIds) {
    final path = 'assets/icons/64/ui_icon_com_$resourceId.png';
    try {
      final data = await rootBundle.load(path);
      if (data.lengthInBytes > 0) loaded++;
    } catch (_) {}
  }
  return loaded;
}

/// Gold-star silhouette checks for the capital map icon (Refs #4021 densify).
Future<void> expectCapitalStarSilhouette(ByteData data) async {
  expect(data.lengthInBytes, greaterThan(0));
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
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
      if (r >= 150 && g >= 110 && b <= 120 && r >= g) goldCount++;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }

  expect(opaqueCount, greaterThan(20));
  expect(goldCount / opaqueCount, greaterThan(0.20));
  final boxWidth = (maxX - minX + 1).toDouble();
  final boxHeight = (maxY - minY + 1).toDouble();
  expect(boxWidth, greaterThan(6));
  expect(boxHeight, greaterThan(6));
  expect(opaqueCount / (boxWidth * boxHeight), lessThan(0.75));

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
}
