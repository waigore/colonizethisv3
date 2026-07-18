// Visual goldens for province overlay Economic Extraction / Available
// condensed lines (MAP20001 / Refs #4002, #4064).
//
// Structural behavior is pinned by `province_overlay_extraction_available_test.dart`.
// This suite adds `matchesGoldenFile` proof for the partial-bracket fixture,
// capital-grain-bonus annotation, and multi-commodity narrow wrap variant.
// SPEC: SPEC/ui/province-economic-extraction-available.md § Acceptance criteria.

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ProvinceImprovableCommodityCount, buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_capture_harness.dart';
import 'support/province_overlay_test_harness.dart';

ProvinceExtractionSnapshot _partialBracketSnapshot(String ownerId) {
  return ProvinceExtractionSnapshot(
    ownerId: ownerId,
    byCommodity: {
      'grain': const ProvinceExtractionCommodityTotals(
        effective: 1,
        full: 5,
        tileKeys: ['oldWorld|p1|0|0', 'oldWorld|p1|0|1'],
      ),
      'iron': const ProvinceExtractionCommodityTotals(
        effective: 5,
        full: 5,
        tileKeys: ['oldWorld|p1|1|0'],
      ),
    },
  );
}

const Map<String, ProvinceImprovableCommodityCount> _sampleAvailable = {
  'grain': ProvinceImprovableCommodityCount(
    count: 3,
    tileKeys: ['oldWorld|p1|0|0', 'oldWorld|p1|2|0'],
  ),
  'timber': ProvinceImprovableCommodityCount(
    count: 2,
    tileKeys: ['oldWorld|p1|0|1'],
  ),
};

ProvinceExtractionSnapshot _multiCommoditySnapshot(String ownerId) {
  return ProvinceExtractionSnapshot(
    ownerId: ownerId,
    byCommodity: {
      for (final id in const [
        'grain',
        'meat',
        'wool',
        'timber',
        'iron',
        'copper',
      ])
        id: ProvinceExtractionCommodityTotals(
          effective: 2,
          full: 2,
          tileKeys: ['oldWorld|p1|0|0'],
        ),
    },
  );
}

ProvinceExtractionSnapshot _capitalBonusSnapshot(String ownerId) {
  return ProvinceExtractionSnapshot(
    ownerId: ownerId,
    capitalGrainBonus: 2,
    byCommodity: {
      'grain': const ProvinceExtractionCommodityTotals(
        effective: 3,
        full: 7,
        tileKeys: ['oldWorld|p1|0|0', 'oldWorld|p1|0|1'],
      ),
      'iron': const ProvinceExtractionCommodityTotals(
        effective: 5,
        full: 5,
        tileKeys: ['oldWorld|p1|1|0'],
      ),
    },
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: Extraction partial brackets and Available counts '
    '(Refs #4002)',
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
              extractionSnapshot: _partialBracketSnapshot(humanId),
              availableByCommodity: _sampleAvailable,
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
              extractionSnapshot: _capitalBonusSnapshot(humanId),
              availableByCommodity: _sampleAvailable,
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
    'golden: Extraction multi-commodity narrow wrap without ellipsis '
    '(Refs #4002)',
    (WidgetTester tester) async {
      // Keep MediaQuery width above kNarrowBreakpoint so the overlay uses the
      // wide (all-sections) body; only the panel width is 160 dp so segments wrap.
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
              extractionSnapshot: _multiCommoditySnapshot(humanId),
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
