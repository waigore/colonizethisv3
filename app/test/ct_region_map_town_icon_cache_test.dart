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
    test('town icon policy uses inland + port assets only', () {
      expect(kTownIconIds.contains('town_inland_64'), isTrue);
      expect(kTownIconIds.contains('port'), isTrue);
      expect(kTownIconIds.contains('town_coastal'), isFalse);
    });

    test('town and port render sizes follow spec', () {
      expect(TownIconCache.townIconSize, equals(64.0));
      expect(TownIconCache.portIconSize, equals(32.0));
    });

    testWidgets(
      'town and port icon contracts use expected ids and sizes',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        expect(TownIconCache.townIconId, 'town_inland_64');
        expect(TownIconCache.portIconId, 'port');
        expect(TownIconCache.townIconSize, 64);
        expect(TownIconCache.portIconSize, 32);
        expect(kTownIconIds, containsAll(['town_inland_64', 'port']));
        expect(kTownIconIds, isNot(contains('town_coastal')));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'required town icon asset files are present in test asset bundle',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());

        for (final iconId in kTownIconIds) {
          final path = 'assets/icons/ui_icon_com_$iconId.png';
          final data = await rootBundle.load(path);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: 'Town icon $path is empty',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'town icon assets load successfully via rootBundle',
      (WidgetTester tester) async {
        var loadedCount = 0;
        await tester.runAsync(() async {
          for (final iconId in kTownIconIds) {
            final path = 'assets/icons/ui_icon_com_$iconId.png';
            try {
              final data = await rootBundle.load(path);
              if (data.lengthInBytes > 0) {
                loadedCount++;
              }
            } catch (e) {
              // Icon asset failed to load
            }
          }
        });

        expect(
          loadedCount,
          equals(kTownIconIds.length),
          reason:
              'Expected all ${kTownIconIds.length} town icon assets to load, but only $loadedCount loaded',
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets('town 64 icon preserves transparent background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      var hasTransparentPixel = false;
      await tester.runAsync(() async {
        final data = await rootBundle.load(
          'assets/icons/ui_icon_com_town_inland_64.png',
        );
        final image = await _decodePng(data.buffer.asUint8List());
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (pixels != null) {
          hasTransparentPixel = _hasTransparentPixel(pixels);
        }
        image.dispose();
      });
      expect(
        hasTransparentPixel,
        isTrue,
        reason:
            'Town map icon must keep transparent background so terrain stays visible around the glyph',
      );
    });

    testWidgets(
      'town markers exist in Old World region data',
      (WidgetTester tester) async {
        final region = ctRegionMapTestOldWorldRegion();
        expect(
          region.townMarkers.isNotEmpty,
          isTrue,
          reason: 'Old World region should have town markers',
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}

Future<ui.Image> _decodePng(Uint8List bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, completer.complete);
  return completer.future;
}

bool _hasTransparentPixel(ByteData pixels) {
  for (var i = 3; i < pixels.lengthInBytes; i += 4) {
    if (pixels.getUint8(i) < 255) return true;
  }
  return false;
}
