// Widget tests that verify screen functionality against SPEC/ui acceptance criteria.
// Screens match Widgetbook mockups (CtMainMenu, CtGameSetup). SPEC/ui/main-menu.md, SPEC/ui/game-setup.md.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/app_display_strings.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/game_setup.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';

void main() {
  suppressLogsForTests();

  group('CtMainMenu — SPEC/ui/main-menu.md acceptance criteria', () {
    Widget buildMainMenu({
      MainMenuState state = MainMenuState.default_,
      MainMenuVariant variant = MainMenuVariant.plain,
      bool resumeGameVisible = false,
      VoidCallback? onResumeGame,
      required VoidCallback onNewGame,
      required VoidCallback onLoadGame,
      required VoidCallback onSettings,
      required VoidCallback onQuit,
    }) {
      return MaterialApp(
        theme: AppThemes.colonial,
        home: CtMainMenu(
          variant: variant,
          state: state,
          version: formatDebugAwareVersion('v1.0.0'),
          onNewGame: onNewGame,
          resumeGameVisible: resumeGameVisible,
          onResumeGame: onResumeGame,
          onLoadGame: onLoadGame,
          onSettings: onSettings,
          onQuit: onQuit,
        ),
      );
    }

    testWidgets('AC Visibility: displays New Game, Load Game, Settings, Quit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Game'), findsOneWidget);
      expect(find.text('Load Game'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Quit'), findsOneWidget);
    });

    testWidgets('AC Resume game: hidden when resumeGameVisible is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resume game'), findsNothing);
    });

    testWidgets('AC Resume game: shown below New Game when resumeGameVisible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildMainMenu(
          resumeGameVisible: true,
          onResumeGame: () {},
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resume game'), findsOneWidget);
    });

    testWidgets('AC Resume game: tap invokes onResumeGame', (
      WidgetTester tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildMainMenu(
          resumeGameVisible: true,
          onResumeGame: () => called = true,
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resume game'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('AC Visibility: displays version in footer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(formatDebugAwareVersion('v1.0.0')), findsOneWidget);
    });

    testWidgets(
      'AC Load Game: when noSaves, Load Game is disabled and has tooltip',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildMainMenu(
            state: MainMenuState.noSaves,
            onNewGame: () {},
            onLoadGame: () {},
            onSettings: () {},
            onQuit: () {},
          ),
        );
        await tester.pumpAndSettle();

        final tooltipFinder = find.ancestor(
          of: find.text('Load Game'),
          matching: find.byType(Tooltip),
        );
        expect(tooltipFinder, findsOneWidget);
        expect(
          tester.widget<Tooltip>(tooltipFinder).message,
          'No saved games. Start a new game first.',
        );
      },
    );

    testWidgets('AC Load Game: when default, Load Game is enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      final tooltipFinder = find.ancestor(
        of: find.text('Load Game'),
        matching: find.byType(Tooltip),
      );
      expect(tooltipFinder, findsOneWidget);
      expect(tester.widget<Tooltip>(tooltipFinder).message, '');
    });

    testWidgets('AC After victory: shows subtitle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildMainMenu(
          state: MainMenuState.afterVictory,
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Congratulations, you won your last game.'),
        findsOneWidget,
      );
    });

    testWidgets('AC Navigation: tapping New Game invokes onNewGame', (
      WidgetTester tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildMainMenu(
          onNewGame: () => called = true,
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Game'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('AC Navigation: tapping Load Game invokes onLoadGame', (
      WidgetTester tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildMainMenu(
          onNewGame: () {},
          onLoadGame: () => called = true,
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Load Game'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('AC Navigation: tapping Settings invokes onSettings', (
      WidgetTester tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () => called = true,
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('AC Navigation: tapping Quit invokes onQuit', (
      WidgetTester tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildMainMenu(
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () => called = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quit'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('Coverage: pixelArt variant builds and navigation works', (
      WidgetTester tester,
    ) async {
      var newGameCalled = false;
      await tester.pumpWidget(
        buildMainMenu(
          variant: MainMenuVariant.pixelArt,
          onNewGame: () => newGameCalled = true,
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Game'), findsOneWidget);
      expect(find.text('Load Game'), findsOneWidget);
      await tester.tap(find.text('New Game'));
      await tester.pumpAndSettle();
      expect(newGameCalled, isTrue);
    });

    testWidgets('Coverage: pixelArt noSaves uses pixel-art Load Game button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildMainMenu(
          variant: MainMenuVariant.pixelArt,
          state: MainMenuState.noSaves,
          onNewGame: () {},
          onLoadGame: () {},
          onSettings: () {},
          onQuit: () {},
        ),
      );
      await tester.pumpAndSettle();

      final tooltipFinder = find.ancestor(
        of: find.text('Load Game'),
        matching: find.byType(Tooltip),
      );
      expect(tooltipFinder, findsOneWidget);
      expect(
        tester.widget<Tooltip>(tooltipFinder).message,
        'No saved games. Start a new game first.',
      );
    });

    // SPEC/ui/main-menu.md § Responsive rules; SPEC/ui/mockups/SHEL10002-main-menu.html
    // `@media (max-width: 430px)`. Refs #2870 S6.
    Future<void> pumpAtSize(
      WidgetTester tester, {
      required Size size,
      required MainMenuVariant variant,
    }) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: buildMainMenu(
            variant: variant,
            onNewGame: () {},
            onLoadGame: () {},
            onSettings: () {},
            onQuit: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('AC Narrow ≤ 430 dp (plain): menu body padding compacts to '
        'EdgeInsets.symmetric(horizontal: 12, vertical: 24)', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(
        tester,
        size: const Size(360, 640),
        variant: MainMenuVariant.plain,
      );

      final Padding bodyPadding = tester.widget<Padding>(
        find.byKey(const Key(kMainMenuBodyPaddingKey)),
      );
      expect(bodyPadding.padding, kMainMenuBodyPaddingNarrow);
    });

    testWidgets('AC Wide > 430 dp (plain): menu body padding stays at default '
        'EdgeInsets.symmetric(horizontal: 24)', (WidgetTester tester) async {
      await pumpAtSize(
        tester,
        size: const Size(800, 600),
        variant: MainMenuVariant.plain,
      );

      final Padding bodyPadding = tester.widget<Padding>(
        find.byKey(const Key(kMainMenuBodyPaddingKey)),
      );
      expect(bodyPadding.padding, kMainMenuBodyPaddingDefault);
    });

    testWidgets('AC Narrow ≤ 430 dp (pixelArt): menu body padding compacts and '
        'button label letter-spacing reduces to narrow constant', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(
        tester,
        size: const Size(360, 640),
        variant: MainMenuVariant.pixelArt,
      );

      final Padding bodyPadding = tester.widget<Padding>(
        find.byKey(const Key(kMainMenuBodyPaddingKey)),
      );
      expect(bodyPadding.padding, kMainMenuBodyPaddingNarrow);

      // Every wood-panel button label Text in the pixelArt tree has the
      // narrow letter-spacing applied; default-spacing labels are absent.
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text &&
              w.style?.letterSpacing == kMainMenuButtonLetterSpacingNarrow,
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text &&
              w.style?.letterSpacing == kMainMenuButtonLetterSpacingDefault,
        ),
        findsNothing,
      );
    });

    testWidgets(
      'AC Wide > 430 dp (pixelArt): menu body padding stays default and '
      'button label letter-spacing stays at default constant',
      (WidgetTester tester) async {
        await pumpAtSize(
          tester,
          size: const Size(800, 600),
          variant: MainMenuVariant.pixelArt,
        );

        final Padding bodyPadding = tester.widget<Padding>(
          find.byKey(const Key(kMainMenuBodyPaddingKey)),
        );
        expect(bodyPadding.padding, kMainMenuBodyPaddingDefault);

        expect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is Text &&
                w.style?.letterSpacing == kMainMenuButtonLetterSpacingDefault,
          ),
          findsWidgets,
        );
        expect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is Text &&
                w.style?.letterSpacing == kMainMenuButtonLetterSpacingNarrow,
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC Narrow ≤ 430 dp (plain): button label Text widgets carry no '
      'explicit letter-spacing override (letter-spacing rule is pixelArt-only)',
      (WidgetTester tester) async {
        await pumpAtSize(
          tester,
          size: const Size(360, 640),
          variant: MainMenuVariant.plain,
        );

        // Plain variant uses bare `Text(label)` for menu actions; no
        // explicit `letterSpacing` is set by main-menu code on those Texts.
        expect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is Text &&
                w.style?.letterSpacing == kMainMenuButtonLetterSpacingNarrow,
          ),
          findsNothing,
        );
        expect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is Text &&
                w.style?.letterSpacing == kMainMenuButtonLetterSpacingDefault,
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC ≤ 430 dp boundary: viewport exactly at 430 dp is treated as narrow',
      (WidgetTester tester) async {
        await pumpAtSize(
          tester,
          size: const Size(kMainMenuNarrowBreakpoint, 640),
          variant: MainMenuVariant.plain,
        );

        final Padding bodyPadding = tester.widget<Padding>(
          find.byKey(const Key(kMainMenuBodyPaddingKey)),
        );
        expect(bodyPadding.padding, kMainMenuBodyPaddingNarrow);
      },
    );

    testWidgets('AC > 430 dp boundary: viewport 431 dp is treated as wide', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(
        tester,
        size: const Size(kMainMenuNarrowBreakpoint + 1, 640),
        variant: MainMenuVariant.plain,
      );

      final Padding bodyPadding = tester.widget<Padding>(
        find.byKey(const Key(kMainMenuBodyPaddingKey)),
      );
      expect(bodyPadding.padding, kMainMenuBodyPaddingDefault);
    });
  });

  group('CtGameSetup — SPEC/ui/game-setup.md acceptance criteria', () {
    List<String> unselectedSlots() => List.filled(6, '');

    Widget buildGameSetup({
      GameSetupState state = GameSetupState.default_,
      GameSetupVariant variant = GameSetupVariant.plain,
      List<String> initialOrderedGpIds = const [],
      Map<String, String> initialLeaderVariantByGpId = const {},
      Size? viewportSize,
      void Function(List<String>, Map<String, String>)? onStartGame,
      VoidCallback? onBack,
    }) {
      final gpIds = initialOrderedGpIds.isEmpty
          ? unselectedSlots()
          : initialOrderedGpIds;
      final child = MaterialApp(
        theme: AppThemes.colonial,
        home: CtGameSetup(
          variant: variant,
          state: state,
          naming: defaultNamingConfig,
          initialOrderedGpIds: gpIds,
          initialLeaderVariantByGpId: initialLeaderVariantByGpId,
          onStartGame: onStartGame ?? (_, _) {},
          onBack: onBack ?? () {},
        ),
      );
      if (viewportSize != null) {
        return MediaQuery(
          data: MediaQueryData(size: viewportSize),
          child: child,
        );
      }
      return child;
    }

    testWidgets('AC Visibility: title, six slot rows, Start Game, Back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildGameSetup());
      await tester.pumpAndSettle();

      expect(find.text('Game Setup'), findsOneWidget);
      expect(find.text('Player 1 (You)'), findsOneWidget);
      expect(find.text('Player 2 (AI)'), findsOneWidget);
      expect(find.text('Player 6 (AI)'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets(
      'AC Initial state unselected: Select nation/leader, Start disabled',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameSetup(
            initialOrderedGpIds: unselectedSlots(),
            initialLeaderVariantByGpId: {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Select nation'), findsNWidgets(6));
        expect(find.text('Select leader'), findsNWidgets(6));
        final startFinder = find.widgetWithText(
          CtNinePatchButton,
          'Start Game',
        );
        expect(startFinder, findsOneWidget);
        expect(tester.widget<CtNinePatchButton>(startFinder).enabled, isFalse);
      },
    );

    testWidgets(
      'AC Start disabled until complete: all six slots filled enables Start',
      (WidgetTester tester) async {
        final gpIds = defaultNamingConfig.greatPowers
            .map((g) => g.id)
            .take(6)
            .toList();
        final leaderMap = <String, String>{};
        for (final id in gpIds) {
          final gp = defaultNamingConfig.gpById(id);
          if (gp != null && gp.leaderVariants.isNotEmpty) {
            leaderMap[id] = gp.defaultLeaderVariantId;
          }
        }

        await tester.pumpWidget(
          buildGameSetup(
            initialOrderedGpIds: gpIds,
            initialLeaderVariantByGpId: leaderMap,
          ),
        );
        await tester.pumpAndSettle();

        final startFinder = find.widgetWithText(
          CtNinePatchButton,
          'Start Game',
        );
        expect(startFinder, findsOneWidget);
        expect(tester.widget<CtNinePatchButton>(startFinder).enabled, isTrue);
      },
    );

    testWidgets(
      'AC No duplicate nations: selecting nation in slot 0 removes it from slot 1',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameSetup());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select nation').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('England').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select nation').first);
        await tester.pumpAndSettle();
        expect(find.text('England'), findsOneWidget);
        expect(find.text('France'), findsWidgets);
      },
    );

    testWidgets(
      'AC Leader follows nation: leader dropdown shows nation variants',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameSetup());
        await tester.pumpAndSettle();

        final nationDropdowns = find.byType(CtDropdown<String>);
        await tester.tap(nationDropdowns.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('England').last);
        await tester.pumpAndSettle();

        expect(find.text('Queen Victoria'), findsOneWidget);
      },
    );

    testWidgets('AC Start: onStartGame called with six gpIds and leader map', (
      WidgetTester tester,
    ) async {
      List<String>? receivedGpIds;
      Map<String, String>? receivedLeaders;

      final gpIds = defaultNamingConfig.greatPowers
          .map((g) => g.id)
          .take(6)
          .toList();
      final leaderMap = <String, String>{};
      for (final id in gpIds) {
        final gp = defaultNamingConfig.gpById(id);
        if (gp != null && gp.leaderVariants.isNotEmpty) {
          leaderMap[id] = gp.defaultLeaderVariantId;
        }
      }

      await tester.pumpWidget(
        buildGameSetup(
          initialOrderedGpIds: gpIds,
          initialLeaderVariantByGpId: leaderMap,
          onStartGame: (ids, leaders) {
            receivedGpIds = ids;
            receivedLeaders = leaders;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      expect(receivedGpIds, isNotNull);
      expect(receivedGpIds!.length, 6);
      expect(receivedLeaders, isNotNull);
      expect(receivedLeaders!.length, 6);
    });

    testWidgets('AC Back: onBack invoked when tapping Back', (
      WidgetTester tester,
    ) async {
      var backCalled = false;
      await tester.pumpWidget(buildGameSetup(onBack: () => backCalled = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(backCalled, isTrue);
    });

    testWidgets('AC Loading: Start disabled, Back enabled', (
      WidgetTester tester,
    ) async {
      var backCalled = false;
      await tester.pumpWidget(
        buildGameSetup(
          state: GameSetupState.loading,
          onBack: () => backCalled = true,
        ),
      );
      await tester.pump();

      expect(find.text('Starting…'), findsOneWidget);
      final startFinder = find.widgetWithText(CtNinePatchButton, 'Start Game');
      expect(tester.widget<CtNinePatchButton>(startFinder).enabled, isFalse);
      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(backCalled, isTrue);
    });

    testWidgets('Coverage: narrow viewport uses stacked slot layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildGameSetup(viewportSize: const Size(400, 800)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Game Setup'), findsOneWidget);
      expect(find.text('Player 1 (You)'), findsOneWidget);
      expect(find.text('Player 6 (AI)'), findsOneWidget);
      expect(find.text('Select nation'), findsNWidgets(6));
    });

    testWidgets('Coverage: pixelArt variant builds and Back works', (
      WidgetTester tester,
    ) async {
      var backCalled = false;
      await tester.pumpWidget(
        buildGameSetup(
          variant: GameSetupVariant.pixelArt,
          onBack: () => backCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(backCalled, isTrue);
    });

    testWidgets('Coverage: initialOrderedGpIds pad to six slots', (
      WidgetTester tester,
    ) async {
      final fourIds = defaultNamingConfig.greatPowers
          .map((g) => g.id)
          .take(4)
          .toList();
      await tester.pumpWidget(buildGameSetup(initialOrderedGpIds: fourIds));
      await tester.pumpAndSettle();

      expect(find.text('Game Setup'), findsOneWidget);
      expect(find.text('Player 1 (You)'), findsOneWidget);
    });

    testWidgets('Coverage: didUpdateWidget when initial data changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildGameSetup(
          initialOrderedGpIds: unselectedSlots(),
          initialLeaderVariantByGpId: {},
        ),
      );
      await tester.pumpAndSettle();

      final gpIds = defaultNamingConfig.greatPowers
          .map((g) => g.id)
          .take(6)
          .toList();
      final leaderMap = <String, String>{};
      for (final id in gpIds) {
        final gp = defaultNamingConfig.gpById(id);
        if (gp != null && gp.leaderVariants.isNotEmpty) {
          leaderMap[id] = gp.defaultLeaderVariantId;
        }
      }
      await tester.pumpWidget(
        buildGameSetup(
          initialOrderedGpIds: gpIds,
          initialLeaderVariantByGpId: leaderMap,
        ),
      );
      await tester.pumpAndSettle();

      final startFinder = find.widgetWithText(CtNinePatchButton, 'Start Game');
      expect(tester.widget<CtNinePatchButton>(startFinder).enabled, isTrue);
    });

    testWidgets('Coverage: clear nation in slot hits empty value branch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildGameSetup());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select nation').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('England').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CtDropdown<String>).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Select nation').first);
      await tester.tap(find.text('Select nation').first, warnIfMissed: false);
      await tester.pumpAndSettle();
    });

    testWidgets('Coverage: change leader in slot', (WidgetTester tester) async {
      await tester.pumpWidget(buildGameSetup());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CtDropdown<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('England').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CtDropdown<String>).at(1));
      await tester.pumpAndSettle();
      final leaderOptions = find.text('Queen Victoria');
      if (leaderOptions.evaluate().length > 1) {
        await tester.tap(leaderOptions.last);
      } else {
        await tester.tap(leaderOptions);
      }
      await tester.pumpAndSettle();
    });
  });
}
