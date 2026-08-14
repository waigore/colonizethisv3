// Overlay / menu Widgetbook stories for in-game shell chrome (Refs #4352).
// SPEC: issue #2861 S12 catalog folders.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/overlays/exit_confirm_dialog.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
import 'package:colonizethis_app/features/game/flame/overlays/victory_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_map_players_bar.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';
import 'widgetbook_in_game_shell_chrome_test_support.dart';

void main() {
  suppressLogsForTests();

  group('In-game shell overlay Widgetbook stories (Refs #4352)', () {
    testWidgets(
      'Game Map Province Side Panel folder exposes open + closed variants',
      (WidgetTester tester) async {
        await expectWidgetbookStoriesMount(
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
        await expectWidgetbookStoriesMount(
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
        await pumpWidgetbookStory(
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
        await expectWidgetbookStoriesMount(
          tester,
          gameSideMenuDirectories,
          folder: 'Game Side Menu',
          useCases: const ['Default — open', 'Closed'],
          widgetType: GameSideMenu,
          extra: const Duration(milliseconds: 250),
        );
      },
    );

    testWidgets('Victory folder exposes full scrim overlay (S12 story 12)', (
      WidgetTester tester,
    ) async {
      await pumpWidgetbookStory(
        tester,
        victoryUiDirectories,
        folder: 'Victory',
        useCase: 'Victory overlay — full scrim',
      );
      expect(find.byType(VictoryOverlay), findsOneWidget);
    });

    testWidgets(
      'Exit Confirm Dialog folder exposes default variant (S12 story 13)',
      (WidgetTester tester) async {
        await pumpWidgetbookStory(
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
          ('Game Map Corner Controls', 'Default — all three buttons enabled'),
          (
            'Game Map Empire Left Rail',
            'Wide — six core empire buttons with tooltips',
          ),
          ('Region Minimap', 'Visible — wide chrome with viewport rectangle'),
          ('Game Map Province Side Panel', 'Open — wide layout panel visible'),
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
          await pumpWidgetbookStory(
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
