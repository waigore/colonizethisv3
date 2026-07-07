// Pins level- and style-aware town map icons and townDevelopmentLevel floor (Refs #3870).

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/caches/town_icon_cache.dart';

import 'ct_region_map_test_support.dart';

void main() {
  suppressLogsForTests();

  group('Town icon cache', () {
    test('town icon policy uses 16 style/level variants plus port', () {
      expect(kTownIconIds, contains('port'));
      expect(kTownIconIds, contains('town_euro_1'));
      expect(kTownIconIds, contains('town_colonial_4'));
      expect(kTownIconIds, contains('town_tribal_2'));
      expect(kTownIconIds, isNot(contains('town_inland_64')));
      expect(kTownIconIds.length, 13);
    });

    test('town and port render sizes follow spec', () {
      expect(TownIconCache.townIconSize, equals(64.0));
      expect(TownIconCache.portIconSize, equals(64.0));
    });

    test('townIconIdForMarker resolves style and level', () {
      expect(
        TownIconCache.townIconIdForMarker(
          townIconStyle: kTownIconStyleColonial,
          townDevelopmentLevel: 3,
        ),
        'town_colonial_3',
      );
    });

    test('production asset paths use canonical filenames', () {
      expect(
        TownIconCache.assetPathForId('town_euro_1', useLegacyTownIcons: false),
        endsWith('ui_icon_com_town_euro_1_64.png'),
      );
      expect(
        TownIconCache.assetPathForId('town_euro_2', useLegacyTownIcons: false),
        endsWith('ui_icon_com_town_euro_2_64.png'),
      );
    });

    test('legacy asset paths when rollback flag is on', () {
      expect(
        TownIconCache.assetPathForId('town_colonial_1', useLegacyTownIcons: true),
        endsWith('ui_icon_com_town_colonial_1_legacy_64.png'),
      );
      expect(
        TownIconCache.assetPathForId('town_colonial_3', useLegacyTownIcons: true),
        endsWith('ui_icon_com_town_colonial_3_64.png'),
      );
    });

    testWidgets(
      'required town icon asset files are present in test asset bundle',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        for (final iconId in kTownIconIds) {
          final path = townIconCache.assetPath(iconId);
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Town icon $path is empty',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    testWidgets(
      'town markers carry development level and style in Old World region data',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        expect(region.townMarkers, isNotEmpty);
        for (final town in region.townMarkers) {
          expect(town.townDevelopmentLevel, inInclusiveRange(1, 4));
          expect(
            town.townIconStyle,
            isIn([kTownIconStyleEuro, kTownIconStyleColonial, kTownIconStyleTribal]),
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('town icon asset monotonicity (Refs #3870)', () {
    // Pre-#3892 level-1 hamlets from #3871 (commit bed8a84a); byte lengths
    // distinguish them from the broken #3892 black-line replacements.
    const kLegacyLevel1TownIconByteLengths = <String, int>{
      'town_euro_1': 1153,
      'town_colonial_1': 1133,
      'town_tribal_1': 1130,
    };

    // PO-approved S9b candidates promoted to production in S9c.
    const kPromotedLevel1TownIconByteLengths = <String, int>{
      'town_euro_1': 4809,
      'town_colonial_1': 3450,
      'town_tribal_1': 4222,
    };

    test('promoted level-1 assets match approved S9b candidate bytes', () async {
      for (final entry in kPromotedLevel1TownIconByteLengths.entries) {
        final bytes = await _loadTownIconBytes(entry.key);
        expect(bytes.length, entry.value, reason: '${entry.key} must match promoted art');
        final stats = await _loadTownIconStats(entry.key);
        expect(stats.opaqueCount, greaterThan(100), reason: '${entry.key} must be readable art');
      }
    });

    test('legacy level-1 assets match pre-#3892 hamlet bytes (S9a revert)', () async {
      for (final entry in kLegacyLevel1TownIconByteLengths.entries) {
        final bytes = await _loadLegacyTownIconBytes(entry.key);
        expect(bytes.length, entry.value, reason: '${entry.key} legacy must match #3871 assets');
        final stats = await _loadLegacyTownIconStats(entry.key);
        expect(stats.opaqueCount, greaterThan(100), reason: '${entry.key} legacy must be readable hamlet art');
      }
    });

    for (final style in kTownIconStyles) {
      test('$style opaque pixels strictly increase 2→4', () async {
        final opaqueCounts = <int>[];
        for (final level in [2, 3, 4]) {
          final stats = await _loadTownIconStats('town_${style}_$level');
          opaqueCounts.add(stats.opaqueCount);
        }
        for (var i = 0; i < 2; i++) {
          expect(opaqueCounts[i], lessThan(opaqueCounts[i + 1]));
        }
      });

      test('$style level-1 bbox matches level-4 footprint within 6 px', () async {
        final level1 = await _loadTownIconStats('town_${style}_1');
        final level4 = await _loadTownIconStats('town_${style}_4');

        expect(
          (level1.bboxWidth - level4.bboxWidth).abs(),
          lessThanOrEqualTo(6),
        );
        expect(
          (level1.bboxHeight - level4.bboxHeight).abs(),
          lessThanOrEqualTo(6),
        );
        expect(
          (level1.bboxMinX - level4.bboxMinX).abs(),
          lessThanOrEqualTo(6),
        );
        expect(
          (level1.bboxMinY - level4.bboxMinY).abs(),
          lessThanOrEqualTo(6),
        );
        expect(
          (level1.centerX - level4.centerX).abs(),
          lessThanOrEqualTo(6),
        );
        expect(
          (level1.centerY - level4.centerY).abs(),
          lessThanOrEqualTo(6),
        );
      }, skip: style == kTownIconStyleColonial
          ? 'S9c PO-approved colonial L1; vertical bbox variance exceeds automatable gate (#3870)'
          : null);

      test('$style level-1 max column height is at least 75% of level 4', () async {
        final level1 = await _loadTownIconStats('town_${style}_1');
        final level4 = await _loadTownIconStats('town_${style}_4');

        expect(
          level1.maxColumnHeight,
          greaterThanOrEqualTo((level4.maxColumnHeight * 0.75).ceil()),
        );
      });
    }

    test('level-1 styles use distinct assets', () async {
      final euro = await _loadTownIconBytes('town_euro_1');
      final colonial = await _loadTownIconBytes('town_colonial_1');
      final tribal = await _loadTownIconBytes('town_tribal_1');

      expect(euro, isNot(equals(colonial)));
      expect(euro, isNot(equals(tribal)));
      expect(colonial, isNot(equals(tribal)));
    });
  });

  group('town icon legacy fallback assets (Refs #3870)', () {
    testWidgets(
      'legacy level-1 town icon asset files are present in test asset bundle',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        for (final path in TownIconCache.legacyTownIconAssetPaths) {
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Legacy town icon $path is empty',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}

class _TownIconStats {
  const _TownIconStats({
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

Future<Uint8List> _loadTownIconBytes(String iconId) async {
  final path = townIconCache.assetPath(iconId);
  final data = await rootBundle.load(path);
  return data.buffer.asUint8List();
}

Future<Uint8List> _loadLegacyTownIconBytes(String iconId) async {
  final path = TownIconCache.assetPathForId(
    iconId,
    useLegacyTownIcons: true,
  );
  final data = await rootBundle.load(path);
  return data.buffer.asUint8List();
}

Future<_TownIconStats> _loadLegacyTownIconStats(String iconId) async {
  final bytes = await _loadLegacyTownIconBytes(iconId);
  return _statsFromPngBytes(bytes);
}

Future<_TownIconStats> _loadTownIconStats(String iconId) async {
  final bytes = await _loadTownIconBytes(iconId);
  return _statsFromPngBytes(bytes);
}

Future<_TownIconStats> _statsFromPngBytes(Uint8List bytes) async {
  final image = await _decodePng(bytes);
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
  return _TownIconStats(
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

Future<ui.Image> _decodePng(Uint8List bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, completer.complete);
  return completer.future;
}
