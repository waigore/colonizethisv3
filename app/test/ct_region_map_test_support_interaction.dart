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

import 'ct_region_map_test_support_core.dart';

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
