// Confirms the in-game shell chrome Widgetbook stories for issue #2861 S12
// (catalog_part3.dart, catalog_part5.dart, catalog_part7.dart) are wired into
// the catalog and that each story builder mounts a dark editorial-monocle
// widget tree without throwing. Directories are tested through the public
// `*Directories` getters so the test fails if a folder or use case is
// removed or renamed.

import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/flame/minimap/minimap.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/game_map_options_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/shell/players_bar_toggle_button.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'widgetbook_in_game_shell_chrome_test_support.dart';

void main() {
  suppressLogsForTests();

  group('In-game shell chrome Widgetbook stories (Refs #2861 S12)', () {
    testWidgets(
      'Game Top Bar folder exposes default + disabled + observe variants',
      (WidgetTester tester) async {
        await expectWidgetbookStoriesMount(
          tester,
          gameTopBarDirectories,
          folder: 'Game Top Bar',
          useCases: const [
            'Default — hamburger + Next turn enabled',
            'Next turn disabled — turn resolution in progress',
            'Observe banner — observe-mode label',
          ],
          widgetType: GameTopBar,
        );
      },
    );

    testWidgets(
      'Game Top Bar disabled variant renders the bar with the muted button',
      (WidgetTester tester) async {
        final bar = await pumpWidgetbookStoryAs<GameTopBar>(
          tester,
          gameTopBarDirectories,
          folder: 'Game Top Bar',
          useCase: 'Next turn disabled — turn resolution in progress',
        );
        expect(bar.nextTurnEnabled, isFalse);
      },
    );

    testWidgets(
      'Game Tab Bar folder exposes default, region + delta + news variants',
      (WidgetTester tester) async {
        for (final name in const [
          'Default — Old World active, no delta',
          'New World active',
          'Positive treasury delta (green)',
          'Negative treasury delta (red)',
          'News toggle — unread badge',
          'News toggle — feed open (no badge)',
          'Players bar toggle — on (active accent)',
          'Players bar toggle — off (dim)',
        ]) {
          await pumpWidgetbookStory(
            tester,
            gameTabBarDirectories,
            folder: 'Game Tab Bar',
            useCase: name,
          );
          expect(find.byType(GameTabBar), findsOneWidget);
          expect(find.byType(PlayersBarToggleButton), findsOneWidget);
          expect(find.byType(PlayerTurnEventsFeedToggleButton), findsOneWidget);
        }
      },
    );

    testWidgets(
      'Players Bar Toggle folder exposes on and off chrome variants',
      (WidgetTester tester) async {
        await expectWidgetbookStoriesMount(
          tester,
          playersBarToggleDirectories,
          folder: 'Players Bar Toggle',
          useCases: const ['On — accent glyph + border', 'Off — dim glyph'],
          widgetType: PlayersBarToggleButton,
        );
      },
    );

    testWidgets(
      'Game Map Corner Controls folder exposes default + disabled variant',
      (WidgetTester tester) async {
        final enabled = await pumpWidgetbookStoryAs<GameMapCornerControls>(
          tester,
          gameMapCornerControlsDirectories,
          folder: 'Game Map Corner Controls',
          useCase: 'Default — all three buttons enabled',
        );
        expect(enabled.homeToCapitalEnabled, isTrue);
        expect(enabled.narrow, isFalse);

        final disabled = await pumpWidgetbookStoryAs<GameMapCornerControls>(
          tester,
          gameMapCornerControlsDirectories,
          folder: 'Game Map Corner Controls',
          useCase: 'Home-to-capital disabled (no human capital)',
        );
        expect(disabled.homeToCapitalEnabled, isFalse);
        expect(disabled.narrow, isFalse);
      },
    );

    testWidgets('Game Map Corner Controls folder exposes narrow variant '
        '(Refs #2870 S9)', (WidgetTester tester) async {
      final narrow = await pumpWidgetbookStoryAs<GameMapCornerControls>(
        tester,
        gameMapCornerControlsDirectories,
        folder: 'Game Map Corner Controls',
        useCase: 'Narrow (360 dp) — 24 × 24 dp buttons, 2 dp gap',
      );
      expect(narrow.narrow, isTrue);
      expect(narrow.homeToCapitalEnabled, isTrue);
    });

    testWidgets(
      'Game Map Options Dialog folder exposes defaults + all-on + all-off variants',
      (WidgetTester tester) async {
        await expectWidgetbookStoriesMount(
          tester,
          gameMapOptionsDialogDirectories,
          folder: 'Game Map Options Dialog',
          useCases: const [
            'Defaults — overlay on, ownership off, names on',
            'All toggles on',
            'All toggles off',
            'Improvements without resources',
            'Roads disabled when improvements off',
          ],
          widgetType: GameMapOptionsDialog,
          extra: const Duration(milliseconds: 200),
        );
      },
    );

    testWidgets(
      'Player Turn Event Feed Card folder exposes populated + empty variants',
      (WidgetTester tester) async {
        final populated = await pumpWidgetbookStoryAs<PlayerTurnEventFeedCard>(
          tester,
          playerTurnEventFeedCardDirectories,
          folder: 'Player Turn Event Feed Card',
          useCase: 'Populated — three entries (top entry tappable)',
        );
        expect(populated.entries.length, 3);
        expect(populated.narrow, isFalse);

        final empty = await pumpWidgetbookStoryAs<PlayerTurnEventFeedCard>(
          tester,
          playerTurnEventFeedCardDirectories,
          folder: 'Player Turn Event Feed Card',
          useCase: 'Empty — no events this turn',
        );
        expect(empty.entries, isEmpty);
        expect(empty.narrow, isFalse);
      },
    );

    testWidgets(
      'Player Turn Event Feed Card folder exposes market summary variants '
      '(Refs #4270)',
      (WidgetTester tester) async {
        final market = await pumpWidgetbookStoryAs<PlayerTurnEventFeedCard>(
          tester,
          playerTurnEventFeedCardDirectories,
          folder: 'Player Turn Event Feed Card',
          useCase: 'Market summary — tappable link to Deal Book',
        );
        expect(market.entries.length, 1);
        expect(market.entries.first.linkAffordance, isTrue);
        expect(
          market.entries.first.text,
          'Market: bought £240 · sold £160 · 2 orders carried',
        );

        final combined = await pumpWidgetbookStoryAs<PlayerTurnEventFeedCard>(
          tester,
          playerTurnEventFeedCardDirectories,
          folder: 'Player Turn Event Feed Card',
          useCase: 'Market + overseas profit — separate rows',
        );
        expect(combined.entries.length, 2);
        expect(combined.entries.map((entry) => entry.text).toList(), [
          'Overseas profit credited: £120 from 2 rival purchase(s). '
              'Tap to open Deal Book.',
          'Market: bought £240 · sold £160',
        ]);
      },
    );

    testWidgets('Player Turn Event Feed Card folder exposes narrow variants '
        '(Refs #2870 S3)', (WidgetTester tester) async {
      for (final name in const [
        'Narrow (360 dp) — populated, clamp(180, 50vw, 260)',
        'Narrow (460 dp) — populated, 50vw mid-range',
        'Narrow (599 dp) — empty, clamp upper bound (260 dp)',
      ]) {
        final card = await pumpWidgetbookStoryAs<PlayerTurnEventFeedCard>(
          tester,
          playerTurnEventFeedCardDirectories,
          folder: 'Player Turn Event Feed Card',
          useCase: name,
        );
        expect(card.narrow, isTrue, reason: name);
      }
    });

    testWidgets(
      'Game Map Empire Left Rail folder exposes wide, debug-console, and narrow variants',
      (WidgetTester tester) async {
        final wide = await pumpWidgetbookStoryAs<GameMapEmpireLeftRail>(
          tester,
          gameMapEmpireLeftRailDirectories,
          folder: 'Game Map Empire Left Rail',
          useCase: 'Wide — six core empire buttons with tooltips',
        );
        expect(wide.narrow, isFalse);
        expect(find.byType(Tooltip), findsWidgets);

        await pumpWidgetbookStory(
          tester,
          gameMapEmpireLeftRailDirectories,
          folder: 'Game Map Empire Left Rail',
          useCase: 'Wide — debug console enabled (7 icons)',
        );
        expect(find.byType(GameMapEmpireLeftRail), findsOneWidget);

        final narrow = await pumpWidgetbookStoryAs<GameMapEmpireLeftRail>(
          tester,
          gameMapEmpireLeftRailDirectories,
          folder: 'Game Map Empire Left Rail',
          useCase: 'Narrow (360 dp) — 26 × 26 dp buttons, tooltips suppressed',
        );
        expect(narrow.narrow, isTrue);
      },
    );

    testWidgets(
      'Region Minimap folder exposes visible, hidden, and narrow variants',
      (WidgetTester tester) async {
        final visible = await pumpWidgetbookStoryAs<GameRegionMinimap>(
          tester,
          gameRegionMinimapDirectories,
          folder: 'Region Minimap',
          useCase: 'Visible — wide chrome with viewport rectangle',
        );
        expect(visible.narrow, isFalse);
        expect(visible.viewportSnapshot, isNotNull);

        await pumpWidgetbookStory(
          tester,
          gameRegionMinimapDirectories,
          folder: 'Region Minimap',
          useCase: 'Hidden — toggle-only (zoom + show button)',
        );
        expect(find.byType(GameRegionMinimap), findsOneWidget);

        final narrow = await pumpWidgetbookStoryAs<GameRegionMinimap>(
          tester,
          gameRegionMinimapDirectories,
          folder: 'Region Minimap',
          useCase: 'Narrow — 90 × 70 dp grid (issue #2870 S3)',
        );
        expect(narrow.narrow, isTrue);
      },
    );
  });
}
