// Confirms the in-game shell chrome Widgetbook stories for issue #2861 S12
// (catalog_part3.dart, catalog_part5.dart, catalog_part7.dart) are wired into
// the catalog and that each story builder mounts a dark editorial-monocle
// widget tree without throwing. Directories are tested through the public
// `*Directories` getters so the test fails if a folder or use case is
// removed or renamed.

import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/game_map_options_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/shell/players_bar_toggle_button.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/old_world_race_chip.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
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
      'Game Tab Bar folder exposes Old World race variants (Refs #4451)',
      (WidgetTester tester) async {
        for (final name in const [
          'Old World race — human ahead',
          'Old World race — rival ahead',
          'Old World race — players bar hidden',
          'Old World race — 320 dp rival ahead',
        ]) {
          await pumpWidgetbookStory(
            tester,
            gameTabBarDirectories,
            folder: 'Game Tab Bar',
            useCase: name,
          );
          expect(find.byType(GameTabBar), findsOneWidget);
          expect(find.byType(OldWorldRaceChip), findsOneWidget);
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
            'Resources only',
            'Improvements without resources',
            'Roads disabled when improvements off',
          ],
          widgetType: GameMapOptionsDialog,
          extra: const Duration(milliseconds: 200),
        );
      },
    );
  });
}
