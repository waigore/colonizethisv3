// Widget goldens for the Victory panel (GAME70001) visual acceptance criteria
// (Refs #4165). Pixel baselines live under `app/test/goldens/` and are asserted
// with `matchesGoldenFile`, following the committed golden harness pattern
// (`technology_slots_panel_parity_goldens_test.dart`,
// `diplomacy_panel_goldens_test.dart`): keyed `RepaintBoundary`, deterministic
// fixtures, and `AppThemes.editorialMonocle` dark-theme chrome.
//
// Golden mapping:
//  - AC-2  conditions block (31 OW military threshold + calendar copy;
//         infinite-mode bypass variant)
//  - AC-3  GP standings sorted by OW count with human row emphasis
//  - AC-4  expandable power-score breakdown (expanded row)
//  - AC-7  end-state banners (military victory, calendar declared winner, tie)
//  - AC-12 wide side-by-side layout (standings + minimap)
//  - AC-14–AC-16 annotated minimap (province names, capital border, towns)
//
// SPEC: SPEC/ui/victory-panel.md § Acceptance criteria.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_political_minimap.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_body.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_keys.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'golden_capture_harness.dart';
import 'panel_fixtures/core.dart';
import 'victory_panel_test_support.dart';
import 'widget_test_pumps.dart';

const Size _kVictoryDesktopViewport = Size(900, 760);

late Box<dynamic> _victoryGoldenGamesBox;

RegionMapViewData _sampleOldWorldRegion() => sampleVictoryAnnotatedOldWorldRegion();

Game _standingsGoldenGame() {
  return buildPanelTestGame(
    players: [
      panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
      const Player(id: 'gp2', displayName: 'France', isHuman: false),
    ],
    oldWorldProvinces: const [
      Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
      Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp1'),
      Province(id: 'oldWorld|p3', regionId: 'oldWorld', ownerId: 'gp2'),
    ],
  );
}

Widget _victoryBodyHost({
  required Game game,
  required Size viewport,
}) {
  return SizedBox(
    width: viewport.width,
    height: viewport.height,
    child: SingleChildScrollView(
      child: VictoryScreenBody(
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
      ),
    ),
  );
}

Future<void> _pumpVictoryBodyGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  Size viewport = _kVictoryDesktopViewport,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: viewport,
    includeLocalizations: true,
    wrapInProviderScope: true,
    center: false,
    child: _victoryBodyHost(game: game, viewport: viewport),
  );
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    _victoryGoldenGamesBox = await openVictoryPanelTestHiveBox();
  });

  tearDownAll(() async {
    await _victoryGoldenGamesBox.close();
  });

  testWidgets(
    'golden: conditions and GP standings default (Refs #4165 AC-2/AC-3)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPanelDefaultGolden');
      await _pumpVictoryBodyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: _standingsGoldenGame(),
      );

      expect(find.byKey(VictoryScreenKeys.conditionsSectionKey), findsOneWidget);
      expect(find.byKey(VictoryScreenKeys.standingsSectionKey), findsOneWidget);
      expect(find.textContaining('31 or more Old World provinces'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_panel_default.png'),
      );
    },
  );

  testWidgets(
    'golden: infinite-mode conditions variant (Refs #4165 AC-2)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPanelInfiniteGolden');
      await _pumpVictoryBodyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: _standingsGoldenGame().copyWith(infiniteMode: true),
      );

      expect(find.byKey(VictoryScreenKeys.conditionsSectionKey), findsOneWidget);
      expect(find.textContaining('Infinite mode is on'), findsOneWidget);
      expect(
        find.textContaining('calendar halt is bypassed'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_panel_infinite_mode.png'),
      );
    },
  );

  testWidgets(
    'golden: expanded power-score breakdown (Refs #4165 AC-4)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPanelExpandedGolden');
      await _pumpVictoryBodyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: _standingsGoldenGame(),
      );

      await tester.tap(find.byKey(VictoryScreenKeys.standingExpandKey('gp1')));
      await pumpSyncFrames(tester);

      expect(
        find.byKey(VictoryScreenKeys.powerBreakdownKey('gp1')),
        findsOneWidget,
      );
      expect(
        find.textContaining('not the military victory meter'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_panel_expanded_power.png'),
      );
    },
  );

  testWidgets(
    'golden: military victory end-state banner (Refs #4165 AC-7)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPanelMilitaryEndGolden');
      final game = _standingsGoldenGame().copyWith(
        victory: const VictoryState(
          winnerPlayerId: 'gp1',
          type: VictoryType.military,
          turnNumber: 42,
        ),
      );
      await _pumpVictoryBodyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
      );

      expect(find.byKey(VictoryScreenKeys.endStateBannerKey), findsOneWidget);
      expect(
        find.textContaining('Military victory: England won on turn 42'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_panel_military_end.png'),
      );
    },
  );

  testWidgets(
    'golden: calendar halt declared-winner banner (Refs #4165 AC-7)',
    (WidgetTester tester) async {
      const boundaryKey =
          ValueKey<String>('victoryPanelCalendarWinnerGolden');
      final game = buildPanelTestGame(
        players: [
          panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
          const Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|p3', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|p4', regionId: 'oldWorld', ownerId: 'gp2'),
        ],
      ).copyWith(calendarCampaignHalted: true);
      await _pumpVictoryBodyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
      );

      expect(find.byKey(VictoryScreenKeys.endStateBannerKey), findsOneWidget);
      expect(
        find.textContaining('Declared winner by power score: England'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_panel_calendar_winner.png'),
      );
    },
  );

  testWidgets(
    'golden: calendar halt tie banner (Refs #4165 AC-7)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPanelCalendarTieGolden');
      final game = buildPanelTestGame(
        players: [
          panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
          const Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
        ],
      ).copyWith(calendarCampaignHalted: true);
      await _pumpVictoryBodyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
      );

      expect(find.byKey(VictoryScreenKeys.endStateBannerKey), findsOneWidget);
      expect(find.textContaining('no declared winner'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_panel_calendar_tie.png'),
      );
    },
  );

  testWidgets(
    'golden: wide side-by-side standings and minimap (Refs #4165 AC-12)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPanelWideLayoutGolden');
      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(kNarrowBreakpoint, 700),
        includeLocalizations: true,
        wrapInProviderScope: true,
        center: false,
        overrides: [
          gameServiceProvider.overrideWith(
            (ref) => VictoryPanelMapGameService(
              _victoryGoldenGamesBox,
              GameSaveAdapter(),
            ),
          ),
        ],
        child: SizedBox(
          width: kNarrowBreakpoint,
          height: 700,
          child: VictoryScreenBody(
            game: buildVictoryPanelMapTestGame(),
            humanPlayerId: kPanelTestHumanPlayerId,
          ),
        ),
      );

      expect(find.byKey(VictoryScreenKeys.standingsMinimapWideRowKey), findsOneWidget);
      expect(find.byKey(VictoryScreenKeys.politicalMinimapSectionKey), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_panel_wide_layout.png'),
      );
    },
  );

  testWidgets(
    'golden: political minimap ownership colours (Refs #4165 AC-5/AC-14–AC-16)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPoliticalMinimapGolden');
      final game = buildPanelTestGame(
        players: [
          panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
          const Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            ownerId: 'gp2',
            originalOwnerId: 'gp1',
            displayName: 'Yorkshire',
          ),
        ],
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 400),
        includeLocalizations: true,
        wrapInProviderScope: true,
        center: false,
        child: SizedBox(
          width: 360,
          height: 400,
          child: VictoryPoliticalMinimap(
            game: game,
            region: _sampleOldWorldRegion(),
          ),
        ),
      );

      expect(
        find.byKey(VictoryScreenKeys.politicalMinimapPaintKey),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_political_minimap.png'),
      );
    },
  );

  testWidgets(
    'golden: political minimap capture inspect line (Refs #4165 AC-6)',
    (WidgetTester tester) async {
      const boundaryKey =
          ValueKey<String>('victoryPoliticalMinimapInspectGolden');
      final game = buildPanelTestGame(
        players: [
          panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
          const Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            ownerId: 'gp2',
            originalOwnerId: 'gp1',
            displayName: 'Yorkshire',
          ),
        ],
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 440),
        includeLocalizations: true,
        wrapInProviderScope: true,
        center: false,
        child: SizedBox(
          width: 360,
          height: 440,
          child: VictoryPoliticalMinimap(
            game: game,
            region: _sampleOldWorldRegion(),
          ),
        ),
      );

      final gesture = find.byKey(VictoryScreenKeys.politicalMinimapGestureKey);
      final topLeft = tester.getTopLeft(gesture);
      final size = tester.getSize(gesture);
      await tester.tapAt(
        topLeft + Offset(size.width * 0.75, size.height * 0.75),
      );
      await pumpSyncFrames(tester);

      expect(
        find.byKey(VictoryScreenKeys.politicalMinimapInspectKey),
        findsOneWidget,
      );
      expect(find.textContaining('captured from England'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_political_minimap_inspect.png'),
      );
    },
  );
}
