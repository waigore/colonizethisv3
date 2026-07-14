// Widget goldens for #3959 visual ACs left open after PR #3962:
// narrow pause affordance, save-name dialog (DLG70001), and load-list
// dialog (DLG80001). Pixel baselines under `app/test/goldens/` close the
// verify-github-issue UI proof gap.
//
// Harness: keyed `RepaintBoundary` + `AppThemes.editorialMonocle` via
// `support/golden_capture_harness.dart` (same pattern as
// `train_dialogs_goldens_test.dart` / `players_bar_goldens_test.dart`).
//
// AC mapping:
//  - AC1 narrow pause: hamburger + pause + Next turn at kMinViewportWidth
//  - AC2 DLG70001: default name field ({nation} - {leader} - {turn})
//  - AC6 DLG80001: manual + Auto-save rows (and empty-state companion)
//
// SPEC: SPEC/ui/in-game-shell-narrow.md § Top bar,
// SPEC/ui/save-game-name-dialog.md, SPEC/ui/load-game-list-dialog.md.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapNextTurnButtonKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_top_bar.dart';
import 'package:colonizethis_app/features/shell/save_load/default_save_display_name.dart';
import 'package:colonizethis_app/features/shell/save_load/load_game_list_dialog.dart';
import 'package:colonizethis_app/features/shell/save_load/save_game_name_dialog.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'support/editorial_monocle_dark_token_assertions.dart';
import 'support/golden_capture_harness.dart';

void _noop() {}

Game _sessionGame() {
  return Game(
    id: 'session',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(
        id: 'england',
        displayName: 'England',
        isHuman: true,
        leaderKey: 'england_leader',
      ),
    ],
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: narrow GameTopBar shows hamburger + pause + Next turn '
    '(Refs #3959 AC1)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('game_top_bar_narrow_pause_golden');
      const viewport = Size(kMinViewportWidth, 80);

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: viewport,
        center: false,
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: SizedBox(
          width: viewport.width,
          height: viewport.height,
          child: Column(
            children: <Widget>[
              GameTopBar(
                onToggleSideMenu: _noop,
                onPausePressed: _noop,
                onNextTurn: () async {},
                nextTurnEnabled: true,
                turnDisplayText: 'Turn 42 / Year 1650',
                nextTurnText: 'Next turn (42 / 1650)',
                menuTooltip: 'Menu',
                pauseTooltip: 'Pause menu',
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.byKey(GameTopBar.hamburgerKey), findsOneWidget);
      expect(find.byKey(GameTopBar.pauseButtonKey), findsOneWidget);
      expect(find.byKey(kGameMapNextTurnButtonKey), findsOneWidget);
      expect(find.byKey(GameTopBar.turnDisplayKey), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/game_top_bar_narrow_pause.png'),
      );
    },
  );

  testWidgets(
    'golden: DLG70001 Save Game Name dialog default name field '
    '(Refs #3959 AC2)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('save_game_name_dialog_golden');
      final game = _sessionGame();
      final expectedDefault = defaultSaveDisplayName(game);

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(420, 360),
        settle: false,
        includeLocalizations: true,
        wrapInProviderScope: true,
        overrides: <Override>[
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        ],
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: const SaveGameNameDialog(),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.byType(SaveGameNameDialog), findsOneWidget);
      expect(find.text('Save Game'), findsOneWidget);
      expect(find.text(expectedDefault), findsOneWidget);
      expect(find.byKey(SaveGameNameDialog.nameFieldKey), findsOneWidget);
      expect(find.byKey(SaveGameNameDialog.saveButtonKey), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/save_game_name_dialog_default.png'),
      );
    },
  );

  testWidgets(
    'golden: DLG80001 Load Game list with manual + Auto-save rows '
    '(Refs #3959 AC6)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('load_game_list_dialog_golden');

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(420, 480),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: const LoadGameListDialog(
          previewEntries: <LoadableSaveEntry>[
            LoadableSaveEntry(
              storageId: 'manual_a',
              label: 'Spain Save',
              kind: LoadableSaveKind.manual,
              turnNumber: 9,
            ),
            LoadableSaveEntry(
              storageId: kAutoSaveSlotId,
              label: 'Auto-save',
              kind: LoadableSaveKind.autoSave,
              turnNumber: 8,
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.byType(LoadGameListDialog), findsOneWidget);
      expect(find.text('Load Game'), findsOneWidget);
      expect(find.text('Spain Save'), findsOneWidget);
      // Badge + row label both use the Auto-save string (Refs #3985).
      expect(find.text('Auto-save'), findsNWidgets(2));
      expect(find.text('Turn 9'), findsOneWidget);
      expect(find.text('Turn 8'), findsOneWidget);
      expect(find.byKey(LoadGameListDialog.listKey), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/load_game_list_dialog_populated.png'),
      );
    },
  );

  testWidgets(
    'golden: DLG80001 Load Game empty list state (Refs #3959 AC6)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('load_game_list_empty_golden');

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(420, 280),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: const LoadGameListDialog(
          previewEntries: <LoadableSaveEntry>[],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(LoadGameListDialog.emptyStateKey), findsOneWidget);
      expect(find.text('No saved games.'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/load_game_list_dialog_empty.png'),
      );
    },
  );
}
