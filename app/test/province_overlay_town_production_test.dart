// Province overlay Economic section — Town production preview rows (Refs #3872).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/resource_icon.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay;

import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay Town production (Refs #3872)', () {
    testWidgets('shows ResourceIcon and quantity for projected bonus commodities',
        (WidgetTester tester) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );

      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: provinceId,
        townProductionBonusByCommodity: {
          CommodityCatalog.lumber.id: 1,
          CommodityCatalog.fabric.id: 1,
        },
      );

      expect(find.text('Town production'), findsOneWidget);
      expect(find.byType(ResourceIcon), findsNWidgets(2));
      expect(find.text('+1'), findsNWidgets(2));
    });

    testWidgets('shows em-dash when projected bonus is empty', (
      WidgetTester tester,
    ) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );

      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: provinceId,
        townProductionBonusByCommodity: const {},
      );

      expect(find.text('Town production'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });
  });
}
