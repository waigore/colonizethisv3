import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';

import 'ct_region_map_test_support.dart';

void main() {
  suppressLogsForTests();

  group('Town icon cache', () {
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
