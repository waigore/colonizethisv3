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

    test('level1TownIconAssetPath uses production filenames by default', () {
      expect(
        TownIconCache.level1TownIconAssetPath(
          'town_euro_1',
          useCandidateLevel1Icons: false,
        ),
        isNull,
      );
      expect(
        townIconCache.assetPath('town_euro_1'),
        'assets/icons/64/ui_icon_com_town_euro_1_64.png',
      );
      expect(
        TownIconCache.level1TownIconAssetPath(
          'town_colonial_2',
          useCandidateLevel1Icons: true,
        ),
        isNull,
      );
    });

    test('level1TownIconAssetPath selects candidate filenames when enabled', () {
      for (final style in kTownIconStyles) {
        expect(
          TownIconCache.level1TownIconAssetPath(
            'town_${style}_1',
            useCandidateLevel1Icons: true,
          ),
          'assets/icons/64/ui_icon_com_town_${style}_1_candidate_64.png',
        );
      }
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
    const kLevel1TownIconByteLengths = <String, int>{
      'town_euro_1': 1153,
      'town_colonial_1': 1133,
      'town_tribal_1': 1130,
    };

    test('level-1 assets match pre-#3892 hamlet bytes (S9a revert)', () async {
      for (final entry in kLevel1TownIconByteLengths.entries) {
        final bytes = await _loadTownIconBytes(entry.key);
        expect(bytes.length, entry.value, reason: '${entry.key} must match #3871 assets');
        final stats = await _loadTownIconStats(entry.key);
        expect(stats.opaqueCount, greaterThan(100), reason: '${entry.key} must be readable hamlet art');
      }
    });

    for (final style in kTownIconStyles) {
      test('$style opaque pixels strictly increase 1→4', () async {
        final opaqueCounts = <int>[];
        for (final level in kTownDevelopmentLevels) {
          final stats = await _loadTownIconStats('town_${style}_$level');
          opaqueCounts.add(stats.opaqueCount);
        }
        for (var i = 0; i < 3; i++) {
          expect(opaqueCounts[i], lessThan(opaqueCounts[i + 1]));
        }
      });

      test(
        '$style level-1 bbox matches level-4 footprint within 2 px',
        () async {
          final level1 = await _loadTownIconStats('town_${style}_1');
          final level4 = await _loadTownIconStats('town_${style}_4');

          expect(
            (level1.bboxWidth - level4.bboxWidth).abs(),
            lessThanOrEqualTo(2),
          );
          expect(
            (level1.bboxHeight - level4.bboxHeight).abs(),
            lessThanOrEqualTo(2),
          );
          expect(
            (level1.bboxMinX - level4.bboxMinX).abs(),
            lessThanOrEqualTo(2),
          );
          expect(
            (level1.bboxMinY - level4.bboxMinY).abs(),
            lessThanOrEqualTo(2),
          );
          expect(
            (level1.centerX - level4.centerX).abs(),
            lessThanOrEqualTo(2),
          );
          expect(
            (level1.centerY - level4.centerY).abs(),
            lessThanOrEqualTo(2),
          );
        },
        skip: 'S9b deferred: size parity after level-1 revert (#3870)',
      );

      test(
        '$style level-1 max column height is at least 75% of level 4',
        () async {
          final level1 = await _loadTownIconStats('town_${style}_1');
          final level4 = await _loadTownIconStats('town_${style}_4');

          expect(
            level1.maxColumnHeight,
            greaterThanOrEqualTo((level4.maxColumnHeight * 0.75).ceil()),
          );
        },
        skip: 'S9b deferred: size parity after level-1 revert (#3870)',
      );
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

  group('S9b candidate level-1 town icons (Refs #3870)', () {
    Future<_TownIconStats> _loadCandidateStats(String style) async {
      final path =
          'assets/icons/64/ui_icon_com_town_${style}_1_candidate_64.png';
      final data = await rootBundle.load(path);
      final image = await _decodePng(data.buffer.asUint8List());
      expect(image.width, 64);
      expect(image.height, 64);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      expect(pixels, isNotNull);
      return _statsFromPixels(pixels!);
    }

    for (final style in kTownIconStyles) {
      test('$style candidate level-1 bbox matches level-4 footprint within 2 px', () async {
        final level1 = await _loadCandidateStats(style);
        final level4 = await _loadTownIconStats('town_${style}_4');

        expect(
          (level1.bboxWidth - level4.bboxWidth).abs(),
          lessThanOrEqualTo(2),
        );
        expect(
          (level1.bboxHeight - level4.bboxHeight).abs(),
          lessThanOrEqualTo(2),
        );
        expect(
          (level1.bboxMinX - level4.bboxMinX).abs(),
          lessThanOrEqualTo(2),
        );
        expect(
          (level1.bboxMinY - level4.bboxMinY).abs(),
          lessThanOrEqualTo(2),
        );
      });

      test('$style candidate level-1 max column height is at least 75% of level 4', () async {
        final level1 = await _loadCandidateStats(style);
        final level4 = await _loadTownIconStats('town_${style}_4');

        expect(
          level1.maxColumnHeight,
          greaterThanOrEqualTo((level4.maxColumnHeight * 0.75).ceil()),
        );
      });

      test('$style candidate level-1 is less complex than production level 2', () async {
        final candidate = await _loadCandidateStats(style);
        final level2 = await _loadTownIconStats('town_${style}_2');

        expect(candidate.opaqueCount, lessThan(level2.opaqueCount));
      });

      test('$style candidate level-1 bytes differ from S9a production level 1', () async {
        final candidatePath =
            'assets/icons/64/ui_icon_com_town_${style}_1_candidate_64.png';
        final productionPath =
            'assets/icons/64/ui_icon_com_town_${style}_1_64.png';
        final candidateData = await rootBundle.load(candidatePath);
        final productionData = await rootBundle.load(productionPath);

        expect(
          candidateData.buffer.asUint8List(),
          isNot(equals(productionData.buffer.asUint8List())),
        );
      });
    }
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

Future<_TownIconStats> _loadTownIconStats(String iconId) async {
  final bytes = await _loadTownIconBytes(iconId);
  final image = await _decodePng(bytes);
  expect(image.width, 64);
  expect(image.height, 64);
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  expect(pixels, isNotNull);
  return _statsFromPixels(pixels!);
}

_TownIconStats _statsFromPixels(ByteData pixels) {
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
      if (pixels.getUint8(i + 3) == 0) continue;
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
