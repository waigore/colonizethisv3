// Visual golden for province overlay Economic section Town production row
// (MAP20001). AC#14: ResourceIcon + quantity for projected bonus commodities.
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md § Economic / Town production.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';

import 'golden_capture_harness.dart';
import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: Economic Town production row shows ResourceIcon and quantity '
    '(Refs #3872 AC#14)',
    (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(600, 1000));
      configureGoldenView(
        tester,
        physicalSize: const Size(600, 1000),
        devicePixelRatio: 1.0,
      );

      const boundaryKey = ValueKey<String>(
        'province_overlay_town_production_golden',
      );

      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final bonusByCommodity = {
        CommodityCatalog.lumber.id: 1,
        CommodityCatalog.fabric.id: 1,
      };

      final humanPlayerId = game.players.first.id;
      final playerView =
          buildPlayerView(game, const MapTopology(), humanPlayerId);

      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          child: SizedBox(
            width: 460,
            height: 900,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: provinceId,
              selectedTileKey: null,
              humanPlayerId: humanPlayerId,
              playerView: playerView,
              draftOrders: const Orders(),
              townProductionBonusByCommodity: bonusByCommodity,
            ),
          ),
        ),
      );
      await pumpForGolden(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Town production'), findsOneWidget);
      expect(find.byType(ResourceIcon), findsNWidgets(2));
      expect(find.text('+1'), findsNWidgets(2));

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/province_overlay_town_production.png',
        ),
      );
    },
  );
}
