// Confirms the in-game shell chrome Widgetbook stories for issue #2861 S12
// (catalog_part3.dart, catalog_part5.dart, catalog_part7.dart) are wired into
// the catalog and that each story builder mounts a dark editorial-monocle
// widget tree without throwing. Directories are tested through the public
// `*Directories` getters so the test fails if a folder or use case is
// removed or renamed.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/exit_confirm_dialog.dart';
import 'package:colonizethis_app/features/game/flame/game_map_corner_controls.dart';
import 'package:colonizethis_app/features/game/flame/game_map_empire_left_rail.dart';
import 'package:colonizethis_app/features/game/flame/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/features/game/flame/game_region_minimap.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/features/game/flame/game_side_menu.dart';
import 'package:colonizethis_app/features/game/flame/victory_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/game_map_options_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/game_map_players_bar.dart';
import 'package:colonizethis_app/features/game/widgets/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/game_top_bar.dart';
import 'package:colonizethis_app/features/game/widgets/player_turn_event_feed.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';
import 'support/widgetbook_test_harness.dart';

/// Locates the single use-case with [useCaseName] inside the
/// [WidgetbookFolder] whose name matches [folderName], failing with a
/// readable matcher message if the folder or use case is missing.
WidgetbookUseCase findWidgetbookUseCase(
  List<WidgetbookNode> directories, {
  required String folderName,
  required String useCaseName,
}) {
  final folder = directories
      .whereType<WidgetbookFolder>()
      .firstWhere(
        (folder) => folder.name == folderName,
        orElse: () =>
            fail('Missing Widgetbook folder: $folderName (got: $directories)'),
      );
  final List<WidgetbookNode> children = folder.children ?? const [];
  final useCase = children
      .whereType<WidgetbookUseCase>()
      .firstWhere(
        (uc) => uc.name == useCaseName,
        orElse: () => fail(
          'Missing use case "$useCaseName" in folder "$folderName" '
          '(got: ${children.map((c) => c.name).toList()})',
        ),
      );
  return useCase;
}

void main() {
  suppressLogsForTests();

  group('In-game shell chrome Widgetbook stories (Refs #2861 S12)', () {
    testWidgets(
      'Game Top Bar folder exposes default + disabled + observe variants',
      (WidgetTester tester) async {
        final defaultStory = findWidgetbookUseCase(
          gameTopBarDirectories,
          folderName: 'Game Top Bar',
          useCaseName: 'Default — hamburger + Next turn enabled',
        );
        final disabledStory = findWidgetbookUseCase(
          gameTopBarDirectories,
          folderName: 'Game Top Bar',
          useCaseName: 'Next turn disabled — turn resolution in progress',
        );
        final observeStory = findWidgetbookUseCase(
          gameTopBarDirectories,
          folderName: 'Game Top Bar',
          useCaseName: 'Observe banner — observe-mode label',
        );

        for (final story in <WidgetbookUseCase>[
          defaultStory,
          disabledStory,
          observeStory,
        ]) {
          await tester.pumpWidget(story.builder(tester.element(find.byType(View))));
          await tester.pump();
          expect(find.byType(GameTopBar), findsOneWidget);
        }
      },
    );

    testWidgets(
      'Game Top Bar disabled variant renders the bar with the muted button',
      (WidgetTester tester) async {
        final disabledStory = findWidgetbookUseCase(
          gameTopBarDirectories,
          folderName: 'Game Top Bar',
          useCaseName: 'Next turn disabled — turn resolution in progress',
        );
        await tester.pumpWidget(
          disabledStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();

        final GameTopBar bar = tester.widget<GameTopBar>(
          find.byType(GameTopBar),
        );
        expect(bar.nextTurnEnabled, isFalse);
      },
    );

    testWidgets(
      'Game Tab Bar folder exposes default, region + delta + news variants',
      (WidgetTester tester) async {
        const useCaseNames = <String>[
          'Default — Old World active, no delta',
          'New World active',
          'Positive treasury delta (green)',
          'Negative treasury delta (red)',
          'News toggle — unread badge',
          'News toggle — feed open (no badge)',
        ];

        for (final name in useCaseNames) {
          final story = findWidgetbookUseCase(
            gameTabBarDirectories,
            folderName: 'Game Tab Bar',
            useCaseName: name,
          );
          await tester.pumpWidget(
            story.builder(tester.element(find.byType(View))),
          );
          await tester.pump();
          expect(find.byType(GameTabBar), findsOneWidget);
          expect(
            find.byType(PlayerTurnEventsFeedToggleButton),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets(
      'Game Map Corner Controls folder exposes default + disabled variant',
      (WidgetTester tester) async {
        final defaultStory = findWidgetbookUseCase(
          gameMapCornerControlsDirectories,
          folderName: 'Game Map Corner Controls',
          useCaseName: 'Default — all three buttons enabled',
        );
        final disabledStory = findWidgetbookUseCase(
          gameMapCornerControlsDirectories,
          folderName: 'Game Map Corner Controls',
          useCaseName: 'Home-to-capital disabled (no human capital)',
        );

        await tester.pumpWidget(
          defaultStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        expect(find.byType(GameMapCornerControls), findsOneWidget);
        final defaultControls = tester.widget<GameMapCornerControls>(
          find.byType(GameMapCornerControls),
        );
        expect(defaultControls.homeToCapitalEnabled, isTrue);
        expect(defaultControls.narrow, isFalse);

        await tester.pumpWidget(
          disabledStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        final disabledControls = tester.widget<GameMapCornerControls>(
          find.byType(GameMapCornerControls),
        );
        expect(disabledControls.homeToCapitalEnabled, isFalse);
        expect(disabledControls.narrow, isFalse);
      },
    );

    testWidgets(
      'Game Map Corner Controls folder exposes narrow variant '
      '(Refs #2870 S9)',
      (WidgetTester tester) async {
        final narrowStory = findWidgetbookUseCase(
          gameMapCornerControlsDirectories,
          folderName: 'Game Map Corner Controls',
          useCaseName: 'Narrow (360 dp) — 24 × 24 dp buttons, 2 dp gap',
        );
        await tester.pumpWidget(
          narrowStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        final narrowControls = tester.widget<GameMapCornerControls>(
          find.byType(GameMapCornerControls),
        );
        expect(
          narrowControls.narrow,
          isTrue,
          reason:
              'Narrow variant must construct GameMapCornerControls with '
              'narrow: true so the 24 × 24 dp / 2 dp gap rule applies.',
        );
        expect(
          narrowControls.homeToCapitalEnabled,
          isTrue,
          reason:
              'Narrow story exercises the active state (all three buttons '
              'enabled) at the narrow measurements.',
        );
      },
    );

    testWidgets(
      'Game Map Options Dialog folder exposes defaults + all-on + all-off variants',
      (WidgetTester tester) async {
        const useCaseNames = <String>[
          'Defaults — overlay on, ownership off, names on',
          'All toggles on',
          'All toggles off',
        ];
        for (final name in useCaseNames) {
          final story = findWidgetbookUseCase(
            gameMapOptionsDialogDirectories,
            folderName: 'Game Map Options Dialog',
            useCaseName: name,
          );
          await tester.pumpWidget(
            story.builder(tester.element(find.byType(View))),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.byType(GameMapOptionsDialog), findsOneWidget);
        }
      },
    );

    testWidgets(
      'Player Turn Event Feed Card folder exposes populated + empty variants',
      (WidgetTester tester) async {
        final populatedStory = findWidgetbookUseCase(
          playerTurnEventFeedCardDirectories,
          folderName: 'Player Turn Event Feed Card',
          useCaseName: 'Populated — three entries (top entry tappable)',
        );
        final emptyStory = findWidgetbookUseCase(
          playerTurnEventFeedCardDirectories,
          folderName: 'Player Turn Event Feed Card',
          useCaseName: 'Empty — no events this turn',
        );

        await tester.pumpWidget(
          populatedStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        final populatedCard = tester.widget<PlayerTurnEventFeedCard>(
          find.byType(PlayerTurnEventFeedCard),
        );
        expect(populatedCard.entries.length, 3);
        expect(populatedCard.narrow, isFalse);

        await tester.pumpWidget(
          emptyStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        final emptyCard = tester.widget<PlayerTurnEventFeedCard>(
          find.byType(PlayerTurnEventFeedCard),
        );
        expect(emptyCard.entries, isEmpty);
        expect(emptyCard.narrow, isFalse);
      },
    );

    testWidgets(
      'Player Turn Event Feed Card folder exposes narrow variants '
      '(Refs #2870 S3)',
      (WidgetTester tester) async {
        const narrowUseCaseNames = <String>[
          'Narrow (360 dp) — populated, clamp(180, 50vw, 260)',
          'Narrow (460 dp) — populated, 50vw mid-range',
          'Narrow (599 dp) — empty, clamp upper bound (260 dp)',
        ];
        for (final name in narrowUseCaseNames) {
          final story = findWidgetbookUseCase(
            playerTurnEventFeedCardDirectories,
            folderName: 'Player Turn Event Feed Card',
            useCaseName: name,
          );
          await tester.pumpWidget(
            story.builder(tester.element(find.byType(View))),
          );
          await tester.pump();
          final card = tester.widget<PlayerTurnEventFeedCard>(
            find.byType(PlayerTurnEventFeedCard),
          );
          expect(
            card.narrow,
            isTrue,
            reason:
                'Narrow variant "$name" must construct the card with '
                'narrow: true so the clamp(180, 50vw, 260) rule applies.',
          );
        }
      },
    );

    testWidgets(
      'Game Map Empire Left Rail folder exposes wide, debug-console, and narrow variants',
      (WidgetTester tester) async {
        const wideUseCaseName = 'Wide — six core empire buttons with tooltips';
        const debugConsoleUseCaseName =
            'Wide — debug console enabled (7 icons)';
        const narrowUseCaseName =
            'Narrow (360 dp) — 26 × 26 dp buttons, tooltips suppressed';

        final wideStory = findWidgetbookUseCase(
          gameMapEmpireLeftRailDirectories,
          folderName: 'Game Map Empire Left Rail',
          useCaseName: wideUseCaseName,
        );
        final debugConsoleStory = findWidgetbookUseCase(
          gameMapEmpireLeftRailDirectories,
          folderName: 'Game Map Empire Left Rail',
          useCaseName: debugConsoleUseCaseName,
        );
        final narrowStory = findWidgetbookUseCase(
          gameMapEmpireLeftRailDirectories,
          folderName: 'Game Map Empire Left Rail',
          useCaseName: narrowUseCaseName,
        );

        await tester.pumpWidget(
          wideStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        final wideRail = tester.widget<GameMapEmpireLeftRail>(
          find.byType(GameMapEmpireLeftRail),
        );
        expect(wideRail.narrow, isFalse);
        expect(find.byType(Tooltip), findsWidgets);

        await tester.pumpWidget(
          debugConsoleStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        expect(find.byType(GameMapEmpireLeftRail), findsOneWidget);

        await tester.pumpWidget(
          narrowStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        final narrowRail = tester.widget<GameMapEmpireLeftRail>(
          find.byType(GameMapEmpireLeftRail),
        );
        expect(
          narrowRail.narrow,
          isTrue,
          reason:
              'Narrow story must construct the rail with narrow: true so '
              'the 26 × 26 dp measurements and Tooltip suppression apply.',
        );
      },
    );

    testWidgets(
      'Region Minimap folder exposes visible, hidden, and narrow variants',
      (WidgetTester tester) async {
        const visibleUseCaseName =
            'Visible — wide chrome with viewport rectangle';
        const hiddenUseCaseName = 'Hidden — toggle-only (zoom + show button)';
        const narrowUseCaseName = 'Narrow — 90 × 70 dp grid (issue #2870 S3)';

        final visibleStory = findWidgetbookUseCase(
          gameRegionMinimapDirectories,
          folderName: 'Region Minimap',
          useCaseName: visibleUseCaseName,
        );
        final hiddenStory = findWidgetbookUseCase(
          gameRegionMinimapDirectories,
          folderName: 'Region Minimap',
          useCaseName: hiddenUseCaseName,
        );
        final narrowStory = findWidgetbookUseCase(
          gameRegionMinimapDirectories,
          folderName: 'Region Minimap',
          useCaseName: narrowUseCaseName,
        );

        await tester.pumpWidget(
          visibleStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        final visibleMinimap = tester.widget<GameRegionMinimap>(
          find.byType(GameRegionMinimap),
        );
        expect(visibleMinimap.narrow, isFalse);
        expect(visibleMinimap.viewportSnapshot, isNotNull);

        await tester.pumpWidget(
          hiddenStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        expect(find.byType(GameRegionMinimap), findsOneWidget);

        await tester.pumpWidget(
          narrowStory.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        final narrowMinimap = tester.widget<GameRegionMinimap>(
          find.byType(GameRegionMinimap),
        );
        expect(
          narrowMinimap.narrow,
          isTrue,
          reason:
              'Narrow story must construct the minimap with narrow: true so '
              'the 90 × 70 dp bounding box from mobile-adaptation.md applies.',
        );
      },
    );

    testWidgets(
      'Game Map Province Side Panel folder exposes open + closed variants',
      (WidgetTester tester) async {
        const useCaseNames = <String>[
          'Open — wide layout panel visible',
          'Closed — panel collapsed',
        ];

        for (final name in useCaseNames) {
          final story = findWidgetbookUseCase(
            gameMapProvinceDetailSidePanelDirectories,
            folderName: 'Game Map Province Side Panel',
            useCaseName: name,
          );
          await tester.pumpWidget(
            story.builder(tester.element(find.byType(View))),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.byType(GameMapProvinceDetailSidePanel), findsOneWidget);
        }
      },
    );

    testWidgets(
      'Players Bar folder exposes wide-layout chip column (S12 story 6)',
      (WidgetTester tester) async {
        final story = findWidgetbookUseCase(
          playersBarDirectories,
          folderName: 'Players Bar',
          useCaseName: 'Default — debug game (wide)',
        );
        await tester.pumpWidget(
          story.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        expect(find.byType(GameMapPlayersBar), findsOneWidget);
      },
    );

    testWidgets(
      'Game Screen folder exposes wide integrated layout (S12 story 7)',
      (WidgetTester tester) async {
        final story = findWidgetbookUseCase(
          gameScreenDirectories,
          folderName: 'Game Screen',
          useCaseName: 'Default — no victory',
        );
        await tester.pumpWidget(
          story.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(GameScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Game Side Menu folder exposes open + closed variants (S12 story 8)',
      (WidgetTester tester) async {
        const useCaseNames = <String>['Default — open', 'Closed'];

        for (final name in useCaseNames) {
          final story = findWidgetbookUseCase(
            gameSideMenuDirectories,
            folderName: 'Game Side Menu',
            useCaseName: name,
          );
          await tester.pumpWidget(
            story.builder(tester.element(find.byType(View))),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.byType(GameSideMenu), findsOneWidget);
        }
      },
    );

    testWidgets(
      'Victory folder exposes full scrim overlay (S12 story 12)',
      (WidgetTester tester) async {
        final story = findWidgetbookUseCase(
          victoryUiDirectories,
          folderName: 'Victory',
          useCaseName: 'Victory overlay — full scrim',
        );
        await tester.pumpWidget(
          story.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
        expect(find.byType(VictoryOverlay), findsOneWidget);
      },
    );

    testWidgets(
      'Exit Confirm Dialog folder exposes default variant (S12 story 13)',
      (WidgetTester tester) async {
        final story = findWidgetbookUseCase(
          exitConfirmDialogDirectories,
          folderName: 'Exit Confirm Dialog',
          useCaseName: 'Default — danger Exit + brass Cancel',
        );
        await tester.pumpWidget(
          story.builder(tester.element(find.byType(View))),
        );
        await tester.pump();
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

        for (final (folder, useCase) in folderUseCases) {
          final allDirectories = <WidgetbookNode>[
            ...gameTopBarDirectories,
            ...gameTabBarDirectories,
            ...gameMapCornerControlsDirectories,
            ...gameMapEmpireLeftRailDirectories,
            ...gameRegionMinimapDirectories,
            ...gameMapProvinceDetailSidePanelDirectories,
            ...playerTurnEventFeedCardDirectories,
          ];
          final story = findWidgetbookUseCase(
            allDirectories,
            folderName: folder,
            useCaseName: useCase,
          );
          // Reset to a barebones tree before each story so Riverpod
          // ProviderScopes used by different stories don't reuse the
          // same element (which would otherwise hit
          // `Tried to change the number of overrides` per Riverpod
          // `ProviderContainer.updateOverrides`).
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await tester.pumpWidget(
            story.builder(tester.element(find.byType(View))),
          );
          await tester.pump();
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
