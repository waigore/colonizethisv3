// Visual goldens for province overlay Economic Extraction / Available
// condensed lines (MAP20001 / Refs #4002, #4064).
//
// SPEC: SPEC/ui/province-economic-extraction-available.md § Acceptance criteria.

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart' show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart' show Orders;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'province_overlay_extraction_available_golden_cases.dart';
import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: Extraction partial brackets and Available counts (Refs #4002)',
    (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(600, 1000));
      configureGoldenView(
        tester,
        physicalSize: const Size(600, 1000),
        devicePixelRatio: 1.0,
      );

      const boundaryKey = ValueKey<String>(
        'province_overlay_extraction_available_partial_golden',
      );

      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);

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
              humanPlayerId: humanId,
              playerView: playerView,
              draftOrders: const Orders(),
              omniscientDetail: true,
              extractionSnapshot: partialBracketExtractionSnapshot(humanId),
              availableByCommodity: sampleExtractionGoldenAvailable,
            ),
          ),
        ),
      );
      await pumpForGolden(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Extraction'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.textContaining('1 (5)'), findsOneWidget);
      expect(find.textContaining('5 Iron'), findsOneWidget);
      expect(find.textContaining('3 Grain'), findsOneWidget);
      expect(find.textContaining('2 Timber'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/province_overlay_extraction_available_partial.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: Extraction capital grain bonus annotation (Refs #4064)',
    (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(600, 1000));
      configureGoldenView(
        tester,
        physicalSize: const Size(600, 1000),
        devicePixelRatio: 1.0,
      );

      const boundaryKey = ValueKey<String>(
        'province_overlay_extraction_capital_bonus_golden',
      );

      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);

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
              humanPlayerId: humanId,
              playerView: playerView,
              draftOrders: const Orders(),
              omniscientDetail: true,
              extractionSnapshot: capitalBonusExtractionSnapshot(humanId),
              availableByCommodity: sampleExtractionGoldenAvailable,
            ),
          ),
        ),
      );
      await pumpForGolden(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Extraction'), findsOneWidget);
      expect(
        find.textContaining('incl. +2 capital grain bonus'),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/province_overlay_extraction_capital_bonus.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: Extraction multi-commodity narrow wrap without ellipsis (Refs #4002)',
    (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(600, 1000));
      configureGoldenView(
        tester,
        physicalSize: const Size(600, 1000),
        devicePixelRatio: 1.0,
      );

      const boundaryKey = ValueKey<String>(
        'province_overlay_extraction_available_wrap_golden',
      );

      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);

      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          child: SizedBox(
            width: 160,
            height: 900,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: provinceId,
              selectedTileKey: null,
              humanPlayerId: humanId,
              playerView: playerView,
              draftOrders: const Orders(),
              omniscientDetail: true,
              extractionSnapshot: multiCommodityExtractionSnapshot(humanId),
            ),
          ),
        ),
      );
      await pumpForGolden(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Extraction'), findsOneWidget);
      expect(find.textContaining('2 Grain'), findsOneWidget);
      expect(find.textContaining('2 Copper'), findsOneWidget);
      final ellipsized = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.overflow == TextOverflow.ellipsis);
      expect(ellipsized, isEmpty);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/province_overlay_extraction_available_wrap.png',
        ),
      );
    },
  );
}
