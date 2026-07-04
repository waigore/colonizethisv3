// Pins level- and style-aware town map icons and townDevelopmentLevel floor (Refs #3870).

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';

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
    for (final style in kTownIconStyles) {
      test('$style opaque pixels and max height increase 1→4', () async {
        final opaqueCounts = <int>[];
        final maxHeights = <int>[];
        for (final level in kTownDevelopmentLevels) {
          final path = townIconCache.assetPath('town_${style}_$level');
          final data = await rootBundle.load(path);
          final image = await _decodePng(data.buffer.asUint8List());
          expect(image.width, 64);
          expect(image.height, 64);
          final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          image.dispose();
          expect(pixels, isNotNull);
          var opaque = 0;
          var maxRow = -1;
          for (var y = 0; y < 64; y++) {
            for (var x = 0; x < 64; x++) {
              final i = (y * 64 + x) * 4;
              if (pixels!.getUint8(i + 3) > 0) {
                opaque++;
                maxRow = y;
              }
            }
          }
          opaqueCounts.add(opaque);
          maxHeights.add(maxRow + 1);
        }
        for (var i = 0; i < 3; i++) {
          expect(opaqueCounts[i], lessThan(opaqueCounts[i + 1]));
          expect(maxHeights[i], lessThan(maxHeights[i + 1]));
        }
      });
    }
  });
}

Future<ui.Image> _decodePng(Uint8List bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, completer.complete);
  return completer.future;
}
