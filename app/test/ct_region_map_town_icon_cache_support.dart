// PNG stats/load helpers for ct_region_map_town_icon_cache_test.dart (Refs #4680).

import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_app/features/game/flame/caches/town_icon_cache.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Pre-#3892 level-1 hamlets from #3871 (commit bed8a84a).
const Map<String, int> kLegacyLevel1TownIconByteLengths = <String, int>{
  'town_euro_1': 1153,
  'town_colonial_1': 1133,
  'town_tribal_1': 1130,
};

// PO-approved S9b candidates promoted to production in S9c.
const Map<String, int> kPromotedLevel1TownIconByteLengths = <String, int>{
  'town_euro_1': 4809,
  'town_colonial_1': 3450,
  'town_tribal_1': 4222,
};

class TownIconStats {
  const TownIconStats({
    required this.opaqueCount,
    required this.bboxMinX,
    required this.bboxMinY,
    required this.bboxWidth,
    required this.bboxHeight,
    required this.centerX,
    required this.centerY,
    required this.maxColumnHeight,
  });

  final int opaqueCount;
  final int bboxMinX;
  final int bboxMinY;
  final int bboxWidth;
  final int bboxHeight;
  final double centerX;
  final double centerY;
  final int maxColumnHeight;
}

Future<Uint8List> loadTownIconBytes(String iconId) async {
  final path = townIconCache.assetPath(iconId);
  final data = await rootBundle.load(path);
  return data.buffer.asUint8List();
}

Future<Uint8List> loadLegacyTownIconBytes(String iconId) async {
  final path = TownIconCache.assetPathForId(
    iconId,
    useLegacyTownIcons: true,
  );
  final data = await rootBundle.load(path);
  return data.buffer.asUint8List();
}

Future<TownIconStats> loadLegacyTownIconStats(String iconId) async {
  final bytes = await loadLegacyTownIconBytes(iconId);
  return statsFromPngBytes(bytes);
}

Future<TownIconStats> loadTownIconStats(String iconId) async {
  final bytes = await loadTownIconBytes(iconId);
  return statsFromPngBytes(bytes);
}

Future<TownIconStats> statsFromPngBytes(Uint8List bytes) async {
  final image = await decodeTownIconPng(bytes);
  expect(image.width, 64);
  expect(image.height, 64);
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  expect(pixels, isNotNull);

  var opaque = 0;
  var minX = 64;
  var minY = 64;
  var maxX = -1;
  var maxY = -1;
  var maxColumnHeight = 0;
  for (var y = 0; y < 64; y++) {
    var rowOpaque = 0;
    for (var x = 0; x < 64; x++) {
      final i = (y * 64 + x) * 4;
      if (pixels!.getUint8(i + 3) == 0) continue;
      opaque++;
      rowOpaque++;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    if (rowOpaque > maxColumnHeight) {
      maxColumnHeight = rowOpaque;
    }
  }

  final width = maxX - minX + 1;
  final height = maxY - minY + 1;
  return TownIconStats(
    opaqueCount: opaque,
    bboxMinX: minX,
    bboxMinY: minY,
    bboxWidth: width,
    bboxHeight: height,
    centerX: (minX + maxX) / 2,
    centerY: (minY + maxY) / 2,
    maxColumnHeight: maxColumnHeight,
  );
}

Future<ui.Image> decodeTownIconPng(Uint8List bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, completer.complete);
  return completer.future;
}
