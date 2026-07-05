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

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';

import 'support/province_overlay_test_harness.dart';

Widget _townProductionGoldenOverlay({
  required Game game,
  required String displayId,
  required Key boundaryKey,
  required Map<String, int> townProductionBonusByCommodity,
}) {
  final humanPlayerId = game.players.first.id;
  final playerView = buildPlayerView(game, const MapTopology(), humanPlayerId);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox(
            width: 460,
            height: 900,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: displayId,
              selectedTileKey: null,
              humanPlayerId: humanPlayerId,
              playerView: playerView,
              draftOrders: const Orders(),
              townProductionBonusByCommodity: townProductionBonusByCommodity,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: Economic Town production row shows ResourceIcon and quantity '
    '(Refs #3872 AC#14)',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.reset);
      await tester.binding.setSurfaceSize(const Size(600, 1000));
      tester.view.devicePixelRatio = 1.0;

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

      await tester.pumpWidget(
        _townProductionGoldenOverlay(
          game: game,
          displayId: provinceId,
          boundaryKey: boundaryKey,
          townProductionBonusByCommodity: bonusByCommodity,
        ),
      );
      await tester.pumpAndSettle();

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
