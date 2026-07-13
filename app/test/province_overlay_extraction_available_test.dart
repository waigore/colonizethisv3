import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ProvinceImprovableCommodityCount, buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'Extraction and Available appear above Town production (Refs #4002)',
    (tester) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);

      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: provinceId,
        region: demoRegionForOverlay,
        humanPlayerId: humanId,
        playerView: playerView,
        omniscientDetail: true,
        extractionSnapshot: ProvinceExtractionSnapshot(
          ownerId: humanId,
          byCommodity: {
            'grain': const ProvinceExtractionCommodityTotals(
              effective: 1,
              full: 5,
              tileKeys: ['oldWorld|p1|0|0'],
            ),
            'iron': const ProvinceExtractionCommodityTotals(
              effective: 5,
              full: 5,
              tileKeys: ['oldWorld|p1|1|0'],
            ),
          },
        ),
        availableByCommodity: const {
          'grain': ProvinceImprovableCommodityCount(
            count: 3,
            tileKeys: ['oldWorld|p1|0|0', 'oldWorld|p1|2|0'],
          ),
          'timber': ProvinceImprovableCommodityCount(
            count: 2,
            tileKeys: ['oldWorld|p1|0|1'],
          ),
        },
      );

      expect(find.text('Extraction'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Town production'), findsOneWidget);
      expect(find.textContaining('1 (5)'), findsOneWidget);
      expect(find.textContaining('5 Iron'), findsOneWidget);
      expect(find.textContaining('3 Grain'), findsOneWidget);
      expect(find.textContaining('2 Timber'), findsOneWidget);

      final extractionY = tester.getTopLeft(find.text('Extraction')).dy;
      final availableY = tester.getTopLeft(find.text('Available')).dy;
      final townY = tester.getTopLeft(find.text('Town production')).dy;
      expect(extractionY, lessThan(availableY));
      expect(availableY, lessThan(townY));
    },
  );

  testWidgets(
    'empty Extraction/Available show dash placeholders (Refs #4002)',
    (tester) async {
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;
      final provinceId = ownedProvinceIdInOldWorld(
        game: game,
        ownerId: humanId,
      );
      final playerView = buildPlayerView(game, const MapTopology(), humanId);

      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: game,
        displayId: provinceId,
        region: demoRegionForOverlay,
        humanPlayerId: humanId,
        playerView: playerView,
        omniscientDetail: true,
      );

      expect(find.text('Extraction'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    },
  );

  test(
    'setSecondaryHighlights stores multi keys and clears single (Refs #4002)',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(mapProvincePanelProvider.notifier);
      n.reportMapTileTapped('r1|p1|0|0');
      n.setSecondaryHighlights(['r1|p1|1|0', 'r1|p1|2|0']);
      var state = container.read(mapProvincePanelProvider);
      expect(state.secondaryHighlightTileKey, isNull);
      expect(state.secondaryHighlightTileKeys, {'r1|p1|1|0', 'r1|p1|2|0'});

      n.setSecondaryHighlight('r1|p1|3|0');
      state = container.read(mapProvincePanelProvider);
      expect(state.secondaryHighlightTileKey, 'r1|p1|3|0');
      expect(state.secondaryHighlightTileKeys, isNull);
    },
  );
}
