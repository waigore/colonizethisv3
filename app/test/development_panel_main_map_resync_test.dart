// Post-assign shell map draft projection after GAME80001 pop (Refs #4687 AC6).

import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/human_draft_projected_region_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/shell_main_map_pause_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';

const _tileB = 'oldWorld|p1|1|0';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox(suiteId: 'main_map_resync');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets(
    'assigning work in GAME80001 reflects on shell draft projection after pop (Refs #4687 AC6)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final ordersNotifier = CurrentOrdersNotifier(const Orders());
      final mapData = DevelopmentPanelMapGameService.goldenMapData();
      final mapView = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: mapData.tileMapByRegion,
        topologyByRegion: mapData.topologyByRegion,
        cellSize: 8,
      );

      final container = ProviderContainer(
        overrides: [
          mapViewDataProvider.overrideWith((ref) => mapView),
          ...developmentPanelProjectionProviderOverrides(
            game,
            ordersNotifier: ordersNotifier,
          ),
        ],
      );
      addTearDown(container.dispose);

      final initial = container.read(humanDraftProjectedRegionProvider('oldWorld'));
      expect(initial, isNotNull);
      expect(
        initial!.civilianTileMarkers.any(
          (m) => m.tileKey == _tileB && m.representativeIsAssigned,
        ),
        isFalse,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: DevelopmentScreen(
              game: game,
              humanPlayerId: kPanelTestHumanPlayerId,
            ),
          ),
        ),
      );
      await pumpDevelopmentPanelReady(tester);
      expect(container.read(shellMainMapPauseHoldProvider), 1);

      ordersNotifier.state = Orders(
        workOrdersByPlayerId: {
          kPanelTestHumanPlayerId: const [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: _tileB,
            ),
          ],
        },
      );
      await tester.pump();

      final whileOpen = container.read(humanDraftProjectedRegionProvider('oldWorld'));
      expect(whileOpen, isNotNull);
      expect(
        whileOpen!.civilianTileMarkers.any(
          (m) => m.tileKey == _tileB && m.representativeIsAssigned,
        ),
        isTrue,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SizedBox.shrink()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(container.read(shellMainMapPauseHoldProvider), 0);

      final afterPop = container.read(humanDraftProjectedRegionProvider('oldWorld'));
      expect(afterPop, isNotNull);
      final assignedMarker = afterPop!.civilianTileMarkers
          .where((m) => m.tileKey == _tileB && m.representativeIsAssigned)
          .toList();
      expect(assignedMarker, hasLength(1));
      expect(assignedMarker.single.unitIds, contains('b1'));
    },
  );

  testWidgets(
    'live GameMapArea stays draft-synced after GAME80001 assign and pop (Refs #4687 AC6)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final ordersNotifier = CurrentOrdersNotifier(const Orders());
      final mapData = DevelopmentPanelMapGameService.goldenMapData();
      final mapView = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: mapData.tileMapByRegion,
        topologyByRegion: mapData.topologyByRegion,
        cellSize: 8,
      );

      final container = ProviderContainer(
        overrides: [
          mapViewDataProvider.overrideWith((ref) => mapView),
          ...developmentPanelProjectionProviderOverrides(
            game,
            ordersNotifier: ordersNotifier,
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SizedBox(
              width: 900,
              height: 700,
              child: GameMapArea(game: game, mapViewData: mapView),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Stack(
              children: [
                SizedBox(
                  width: 900,
                  height: 700,
                  child: GameMapArea(game: game, mapViewData: mapView),
                ),
                DevelopmentScreen(
                  game: game,
                  humanPlayerId: kPanelTestHumanPlayerId,
                ),
              ],
            ),
          ),
        ),
      );
      await pumpDevelopmentPanelReady(tester);
      expect(container.read(shellMainMapPauseHoldProvider), 1);

      ordersNotifier.state = Orders(
        workOrdersByPlayerId: {
          kPanelTestHumanPlayerId: const [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: _tileB,
            ),
          ],
        },
      );
      await tester.pump();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SizedBox(
              width: 900,
              height: 700,
              child: GameMapArea(game: game, mapViewData: mapView),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(container.read(shellMainMapPauseHoldProvider), 0);

      final projected =
          container.read(humanDraftProjectedRegionProvider('oldWorld'));
      expect(projected, isNotNull);
      expect(
        projected!.civilianTileMarkers.any(
          (m) => m.tileKey == _tileB && m.representativeIsAssigned,
        ),
        isTrue,
      );
    },
  );
}
