// Confirms the in-game shell chrome Widgetbook stories for issue #2861 S12
// (catalog_part3.dart, catalog_part5.dart, catalog_part7.dart) are wired into
// the catalog and that each story builder mounts a dark editorial-monocle
// widget tree without throwing. Directories are tested through the public
// `*Directories` getters so the test fails if a folder or use case is
// removed or renamed.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/overlays/exit_confirm_dialog.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/features/game/flame/minimap/minimap.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
import 'package:colonizethis_app/features/game/flame/overlays/victory_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/game_map_options_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_map_players_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/players_bar_toggle_button.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';
import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpStory(
    WidgetTester tester,
    List<WidgetbookNode> directories, {
    required String folder,
    required String useCase,
    Duration? extra,
    bool resetTree = false,
  }) async {
    if (resetTree) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    final story = findWidgetbookUseCase(
      directories,
      folderName: folder,
      useCaseName: useCase,
    );
    await tester.pumpWidget(
      story.builder(tester.element(find.byType(View))),
    );
    await tester.pump();
    if (extra != null) {
      await tester.pump(extra);
    }
  }

  Future<T> pumpStoryAs<T extends Widget>(
    WidgetTester tester,
    List<WidgetbookNode> directories, {
    required String folder,
    required String useCase,
    Duration? extra,
  }) async {
    await pumpStory(
      tester,
      directories,
      folder: folder,
      useCase: useCase,
      extra: extra,
    );
    return tester.widget<T>(find.byType(T));
  }

  Future<void> expectStoriesMount(
    WidgetTester tester,
    List<WidgetbookNode> directories, {
    required String folder,
    required List<String> useCases,
    required Type widgetType,
    Duration? extra,
  }) async {
    for (final name in useCases) {
      await pumpStory(
        tester,
        directories,
        folder: folder,
        useCase: name,
        extra: extra,
      );
      expect(find.byType(widgetType), findsOneWidget);
    }
  }

  group('In-game shell chrome Widgetbook stories (Refs #2861 S12)', () {
    testWidgets(
      'Game Top Bar folder exposes default + disabled + observe variants',
      (WidgetTester tester) async {
        await expectStoriesMount(
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
        final bar = await pumpStoryAs<GameTopBar>(
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
          await pumpStory(
            tester,
            gameTabBarDirectories,
            folder: 'Game Tab Bar',
            useCase: name,
          );
          expect(find.byType(GameTabBar), findsOneWidget);
          expect(find.byType(PlayersBarToggleButton), findsOneWidget);
          expect(
            find.byType(PlayerTurnEventsFeedToggleButton),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets(
      'Players Bar Toggle folder exposes on and off chrome variants',
      (WidgetTester tester) async {
        await expectStoriesMount(
          tester,
          playersBarToggleDirectories,
          folder: 'Players Bar Toggle',
          useCases: const [
            'On — accent glyph + border',
            'Off — dim glyph',
          ],
          widgetType: PlayersBarToggleButton,
        );
      },
    );

    testWidgets(
      'Game Map Corner Controls folder exposes default + disabled variant',
      (WidgetTester tester) async {
        final enabled = await pumpStoryAs<GameMapCornerControls>(
          tester,
          gameMapCornerControlsDirectories,
          folder: 'Game Map Corner Controls',
          useCase: 'Default — all three buttons enabled',
        );
        expect(enabled.homeToCapitalEnabled, isTrue);
        expect(enabled.narrow, isFalse);

        final disabled = await pumpStoryAs<GameMapCornerControls>(
          tester,
          gameMapCornerControlsDirectories,
          folder: 'Game Map Corner Controls',
          useCase: 'Home-to-capital disabled (no human capital)',
        );
        expect(disabled.homeToCapitalEnabled, isFalse);
        expect(disabled.narrow, isFalse);
      },
    );

    testWidgets(
      'Game Map Corner Controls folder exposes narrow variant '
      '(Refs #2870 S9)',
      (WidgetTester tester) async {
        final narrow = await pumpStoryAs<GameMapCornerControls>(
          tester,
          gameMapCornerControlsDirectories,
          folder: 'Game Map Corner Controls',
          useCase: 'Narrow (360 dp) — 24 × 24 dp buttons, 2 dp gap',
        );
        expect(narrow.narrow, isTrue);
        expect(narrow.homeToCapitalEnabled, isTrue);
      },
    );

    testWidgets(
      'Game Map Options Dialog folder exposes defaults + all-on + all-off variants',
      (WidgetTester tester) async {
        await expectStoriesMount(
          tester,
          gameMapOptionsDialogDirectories,
          folder: 'Game Map Options Dialog',
          useCases: const [
            'Defaults — overlay on, ownership off, names on',
            'All toggles on',
            'All toggles off',
          ],
          widgetType: GameMapOptionsDialog,
          extra: const Duration(milliseconds: 200),
        );
      },
    );

    testWidgets(
      'Player Turn Event Feed Card folder exposes populated + empty variants',
      (WidgetTester tester) async {
        final populated = await pumpStoryAs<PlayerTurnEventFeedCard>(
          tester,
          playerTurnEventFeedCardDirectories,
          folder: 'Player Turn Event Feed Card',
          useCase: 'Populated — three entries (top entry tappable)',
        );
        expect(populated.entries.length, 3);
        expect(populated.narrow, isFalse);

        final empty = await pumpStoryAs<PlayerTurnEventFeedCard>(
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
      'Player Turn Event Feed Card folder exposes narrow variants '
      '(Refs #2870 S3)',
      (WidgetTester tester) async {
        for (final name in const [
          'Narrow (360 dp) — populated, clamp(180, 50vw, 260)',
          'Narrow (460 dp) — populated, 50vw mid-range',
          'Narrow (599 dp) — empty, clamp upper bound (260 dp)',
        ]) {
          final card = await pumpStoryAs<PlayerTurnEventFeedCard>(
            tester,
            playerTurnEventFeedCardDirectories,
            folder: 'Player Turn Event Feed Card',
            useCase: name,
          );
          expect(card.narrow, isTrue, reason: name);
        }
      },
    );

    testWidgets(
      'Game Map Empire Left Rail folder exposes wide, debug-console, and narrow variants',
      (WidgetTester tester) async {
        final wide = await pumpStoryAs<GameMapEmpireLeftRail>(
          tester,
          gameMapEmpireLeftRailDirectories,
          folder: 'Game Map Empire Left Rail',
          useCase: 'Wide — six core empire buttons with tooltips',
        );
        expect(wide.narrow, isFalse);
        expect(find.byType(Tooltip), findsWidgets);

        await pumpStory(
          tester,
          gameMapEmpireLeftRailDirectories,
          folder: 'Game Map Empire Left Rail',
          useCase: 'Wide — debug console enabled (7 icons)',
        );
        expect(find.byType(GameMapEmpireLeftRail), findsOneWidget);

        final narrow = await pumpStoryAs<GameMapEmpireLeftRail>(
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
        final visible = await pumpStoryAs<GameRegionMinimap>(
          tester,
          gameRegionMinimapDirectories,
          folder: 'Region Minimap',
          useCase: 'Visible — wide chrome with viewport rectangle',
        );
        expect(visible.narrow, isFalse);
        expect(visible.viewportSnapshot, isNotNull);

        await pumpStory(
          tester,
          gameRegionMinimapDirectories,
          folder: 'Region Minimap',
          useCase: 'Hidden — toggle-only (zoom + show button)',
        );
        expect(find.byType(GameRegionMinimap), findsOneWidget);

        final narrow = await pumpStoryAs<GameRegionMinimap>(
          tester,
          gameRegionMinimapDirectories,
          folder: 'Region Minimap',
          useCase: 'Narrow — 90 × 70 dp grid (issue #2870 S3)',
        );
        expect(narrow.narrow, isTrue);
      },
    );

    testWidgets(
      'Game Map Province Side Panel folder exposes open + closed variants',
      (WidgetTester tester) async {
        await expectStoriesMount(
          tester,
          gameMapProvinceDetailSidePanelDirectories,
          folder: 'Game Map Province Side Panel',
          useCases: const [
            'Open — wide layout panel visible',
            'Closed — panel collapsed',
          ],
          widgetType: GameMapProvinceDetailSidePanel,
          extra: const Duration(milliseconds: 100),
        );
      },
    );

    testWidgets(
      'Players Bar folder exposes wide-layout chip column (S12 story 6)',
      (WidgetTester tester) async {
        await expectStoriesMount(
          tester,
          playersBarDirectories,
          folder: 'Players Bar',
          useCases: const [
            'Default — debug game (wide)',
            'Human GP highlighted — power scores',
            'Narrow — embedded below feed anchor',
          ],
          widgetType: GameMapPlayersBar,
        );
      },
    );

    testWidgets(
      'Game Screen folder exposes wide integrated layout (S12 story 7)',
      (WidgetTester tester) async {
        await pumpStory(
          tester,
          gameScreenDirectories,
          folder: 'Game Screen',
          useCase: 'Default — no victory',
          extra: const Duration(milliseconds: 200),
        );
        expect(find.byType(GameScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Game Side Menu folder exposes open + closed variants (S12 story 8)',
      (WidgetTester tester) async {
        await expectStoriesMount(
          tester,
          gameSideMenuDirectories,
          folder: 'Game Side Menu',
          useCases: const ['Default — open', 'Closed'],
          widgetType: GameSideMenu,
          extra: const Duration(milliseconds: 250),
        );
      },
    );

    testWidgets(
      'Victory folder exposes full scrim overlay (S12 story 12)',
      (WidgetTester tester) async {
        await pumpStory(
          tester,
          victoryUiDirectories,
          folder: 'Victory',
          useCase: 'Victory overlay — full scrim',
        );
        expect(find.byType(VictoryOverlay), findsOneWidget);
      },
    );

    testWidgets(
      'Exit Confirm Dialog folder exposes default variant (S12 story 13)',
      (WidgetTester tester) async {
        await pumpStory(
          tester,
          exitConfirmDialogDirectories,
          folder: 'Exit Confirm Dialog',
          useCase: 'Default — danger Exit + brass Cancel',
        );
        expect(find.byType(ExitConfirmDialog), findsOneWidget);
      },
    );

    testWidgets(
      'all new in-game shell chrome story frames apply the editorial-monocle scaffold colour',
      (WidgetTester tester) async {
        // Sanity-check that the shared story frame in catalog_part7 paints
        // the canonical dark `--bg-deep` token under the chrome (not the
        // default light Material scaffold), satisfying the "dark theme"
        // qualifier in issue #2861 S12. Use one frame per folder so we
        // catch regressions if a frame helper drifts.
        const folderUseCases = <(String, String)>[
          ('Game Top Bar', 'Default — hamburger + Next turn enabled'),
          ('Game Tab Bar', 'Default — Old World active, no delta'),
          (
            'Game Map Corner Controls',
            'Default — all three buttons enabled',
          ),
          (
            'Game Map Empire Left Rail',
            'Wide — six core empire buttons with tooltips',
          ),
          ('Region Minimap', 'Visible — wide chrome with viewport rectangle'),
          (
            'Game Map Province Side Panel',
            'Open — wide layout panel visible',
          ),
          (
            'Player Turn Event Feed Card',
            'Populated — three entries (top entry tappable)',
          ),
        ];
        final allDirectories = <WidgetbookNode>[
          ...gameTopBarDirectories,
          ...gameTabBarDirectories,
          ...gameMapCornerControlsDirectories,
          ...gameMapEmpireLeftRailDirectories,
          ...gameRegionMinimapDirectories,
          ...gameMapProvinceDetailSidePanelDirectories,
          ...playerTurnEventFeedCardDirectories,
        ];

        for (final (folder, useCase) in folderUseCases) {
          // Reset to a barebones tree before each story so Riverpod
          // ProviderScopes used by different stories don't reuse the
          // same element (which would otherwise hit
          // `Tried to change the number of overrides` per Riverpod
          // `ProviderContainer.updateOverrides`).
          await pumpStory(
            tester,
            allDirectories,
            folder: folder,
            useCase: useCase,
            resetTree: true,
          );
          final Scaffold scaffold = tester.widget<Scaffold>(
            find.byType(Scaffold).first,
          );
          expect(
            scaffold.backgroundColor,
            EditorialMonoclePalette.bgDeep,
            reason: 'folder=$folder useCase=$useCase',
          );
        }
      },
    );
  });
}
