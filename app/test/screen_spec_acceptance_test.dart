// Widget tests that verify CtMainMenu screen functionality against SPEC/ui
// acceptance criteria. The CtGameSetup acceptance criteria live in
// `game_setup_spec_acceptance_test.dart` (split to keep both files within
// the `repo.dart_file_non_comment_line_size` budget per `SPEC/program/repo-lint.md`).
// Screen contract: SPEC/ui/main-menu.md.
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/app_display_strings.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_compass_rose.dart';
import 'package:colonizethis_app/widgets/ct_fleur_de_lis_ornament.dart';
import 'package:colonizethis_app/widgets/ct_main_menu_collage.dart';
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

    testWidgets(
      'AC Variant rendering (pixelArt): collage, compass rose, fleur-de-lis, brass divider all present',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildMainMenu(
            variant: MainMenuVariant.pixelArt,
            onNewGame: () {},
            onLoadGame: () {},
            onSettings: () {},
            onQuit: () {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CtMainMenuCollage), findsOneWidget);
        expect(find.byType(CtCompassRose), findsOneWidget);
        expect(find.byType(CtFleurDeLisOrnament), findsNWidgets(2));
        expect(find.byType(CtBrassDivider), findsOneWidget);
        expect(find.text('A GAME OF EMPIRE & DISCOVERY'), findsOneWidget);
      },
    );

    testWidgets(
      'AC 9 (pixelArt) Footer Quit: tap on the smaller border-only Quit chip '
      'invokes onQuit; the chip uses kMainMenuFooterQuitKey and does not '
      'render as a wood-panel CtNinePatchButton with brass corner brackets',
      (WidgetTester tester) async {
        var called = false;
        await tester.pumpWidget(
          buildMainMenu(
            variant: MainMenuVariant.pixelArt,
            onNewGame: () {},
            onLoadGame: () {},
            onSettings: () {},
            onQuit: () => called = true,
          ),
        );
        await tester.pumpAndSettle();

        final Finder quitChip = find.byKey(
          const Key(kMainMenuFooterQuitKey),
        );
        expect(quitChip, findsOneWidget);

        final RenderBox box = tester.renderObject<RenderBox>(quitChip);
        expect(
          box.size.height,
          lessThan(48),
          reason:
              'Footer Quit chip must be smaller than 48 dp primary buttons',
        );
        expect(
          box.size.height,
          greaterThanOrEqualTo(kMainMenuFooterQuitMinHeight),
          reason:
              'Footer Quit chip must clear the 44 dp accessibility minimum',
        );

        final Finder quitInsideNinePatch = find.descendant(
          of: find.byType(CtNinePatchButton),
          matching: find.text('Quit'),
        );
        expect(
          quitInsideNinePatch,
          findsNothing,
          reason:
              'pixelArt Quit must not render inside a wood-panel '
              'CtNinePatchButton (no brass corner brackets per AC 9)',
        );

        await tester.tap(quitChip);
        await tester.pumpAndSettle();
        expect(called, isTrue);
      },
    );

    testWidgets(
      'AC 9 (pixelArt) Footer Quit foreground: label uses '
      'EditorialMonoclePalette.muted token, not --fg',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildMainMenu(
            variant: MainMenuVariant.pixelArt,
            onNewGame: () {},
            onLoadGame: () {},
            onSettings: () {},
            onQuit: () {},
          ),
        );
        await tester.pumpAndSettle();

        final Finder quitChip = find.byKey(
          const Key(kMainMenuFooterQuitKey),
        );
        final Text quitLabel = tester.widget<Text>(
          find.descendant(of: quitChip, matching: find.text('Quit')),
        );
        expect(quitLabel.style?.color, EditorialMonoclePalette.muted);
      },
    );

    testWidgets(
      'AC Variant rendering (plain) Footer Quit: plain variant does not '
      'render the pixelArt Quit chip key (chip is pixelArt-only)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildMainMenu(
            onNewGame: () {},
            onLoadGame: () {},
            onSettings: () {},
            onQuit: () {},
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key(kMainMenuFooterQuitKey)),
          findsNothing,
          reason:
              'Footer Quit chip is pixelArt-only per Variant rendering table',
        );
      },
    );

    testWidgets(
      'AC Variant rendering (plain): no SVG collage, compass rose, fleur-de-lis, or brass divider',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildMainMenu(
            onNewGame: () {},
            onLoadGame: () {},
            onSettings: () {},
            onQuit: () {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CtMainMenuCollage), findsNothing);
        expect(find.byType(CtCompassRose), findsNothing);
        expect(find.byType(CtFleurDeLisOrnament), findsNothing);
        expect(find.byType(CtBrassDivider), findsNothing);
        expect(find.text('A GAME OF EMPIRE & DISCOVERY'), findsNothing);
      },
    );

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
}
