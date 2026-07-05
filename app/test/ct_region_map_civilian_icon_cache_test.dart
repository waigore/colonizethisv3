import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('CivilianIconCache', () {
    testWidgets('required civilian icon assets exist and are non-empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      for (final slug in kCivilianIconSlugs) {
        final colorPath = 'assets/icons/64/ui_icon_civ_$slug.png';
        final colorData = await rootBundle.load(colorPath);
        expect(
          colorData.lengthInBytes,
          greaterThan(0),
          reason: 'Asset $colorPath is empty',
        );
      }
    });

    testWidgets('color civilian icons preserve transparent pixels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      for (final slug in kCivilianIconSlugs) {
        final colorPath = 'assets/icons/64/ui_icon_civ_$slug.png';
        var hasTransparentPixel = false;
        await tester.runAsync(() async {
          final data = await rootBundle.load(colorPath);
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
          reason: 'Civilian icon $colorPath must keep transparent background',
        );
      }
    });

    testWidgets('civilian type mapping is deterministic and normalized', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      expect(kCivilianTypeToIconSlug['builder'], 'builder');
      expect(kCivilianTypeToIconSlug['engineer'], 'engineer');
      expect(kCivilianTypeToIconSlug['rail builder'], 'rail_builder');
      expect(kCivilianTypeToIconSlug['rail_builder'], 'rail_builder');
      expect(kCivilianTypeToIconSlug['railbuilder'], 'rail_builder');
      expect(kCivilianTypeToIconSlug['explorer'], 'explorer');
      expect(kCivilianTypeToIconSlug['merchant'], 'merchant');
      expect(kCivilianTypeToIconSlug['spy'], 'spy');
      expect(kCivilianTypeToIconSlug['unknown'], isNull);

      // Unknown type lookup is always null when no icon mapping exists.
      expect(
        civilianIconCache.getIcon(
          unitType: 'UnknownCivilian',
          grayscale: false,
        ),
        isNull,
      );
    });
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
