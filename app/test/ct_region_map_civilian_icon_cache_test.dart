import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
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
        final colorPath = 'assets/icons/ui_icon_civ_$slug.png';
        final colorData = await rootBundle.load(colorPath);
        expect(
          colorData.lengthInBytes,
          greaterThan(0),
          reason: 'Asset $colorPath is empty',
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
