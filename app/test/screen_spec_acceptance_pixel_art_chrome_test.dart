// Pins SPEC/ui/main-menu.md acceptance criteria:
// pixelArt chrome (collage, footer Quit, wood-panel gradients), scroll brackets.
// Responsive ≤430 dp ACs live in screen_spec_acceptance_main_menu_responsive_test.
// Concern split under repo.app_test_file_size (Refs #4013, #4352).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_compass_rose.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_fleur_de_lis_ornament.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_main_menu_collage.dart';
import 'package:colonizethis_app_fixtures/runtime/app_display_strings.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';

import 'app_shell_harness.dart';
import 'screen_spec_acceptance_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtMainMenu — SPEC/ui/main-menu.md acceptance criteria (pixelArt chrome)', () {
    testWidgets(
      'AC Variant rendering (pixelArt): collage, compass rose, fleur-de-lis, brass divider all present',
      (WidgetTester tester) async {
        await pumpScreenSpecMainMenu(tester, variant: MainMenuVariant.pixelArt);

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
        await pumpScreenSpecMainMenu(
          tester,
          variant: MainMenuVariant.pixelArt,
          onQuit: () => called = true,
        );

        final Finder quitChip = find.byKey(const Key(kMainMenuFooterQuitKey));
        expect(quitChip, findsOneWidget);

        final RenderBox box = tester.renderObject<RenderBox>(quitChip);
        expect(
          box.size.height,
          lessThan(48),
          reason: 'Footer Quit chip must be smaller than 48 dp primary buttons',
        );
        expect(
          box.size.height,
          greaterThanOrEqualTo(kMainMenuFooterQuitMinHeight),
          reason: 'Footer Quit chip must clear the 44 dp accessibility minimum',
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

    testWidgets('AC 9 (pixelArt) Footer Quit foreground: label uses '
        'EditorialMonoclePalette.muted token, not --fg', (
      WidgetTester tester,
    ) async {
      await pumpScreenSpecMainMenu(tester, variant: MainMenuVariant.pixelArt);

      final Finder quitChip = find.byKey(const Key(kMainMenuFooterQuitKey));
      final Text quitLabel = tester.widget<Text>(
        find.descendant(of: quitChip, matching: find.text('Quit')),
      );
      expect(quitLabel.style?.color, EditorialMonoclePalette.muted);
    });

    testWidgets(
      'AC Variant rendering (plain) Footer Quit: plain variant does not '
      'render the pixelArt Quit chip key (chip is pixelArt-only)',
      (WidgetTester tester) async {
        await pumpScreenSpecMainMenu(tester);

        expect(
          find.byKey(const Key(kMainMenuFooterQuitKey)),
          findsNothing,
          reason:
              'Footer Quit chip is pixelArt-only per Variant rendering table',
        );
      },
    );

    testWidgets(
      'AC 8 (pixelArt) wood-panel button rest gradient: New Game button '
      'paints the three-stop CtGradients.woodPanelButtonGradient '
      '(--surface-lite → --surface → --bg-deep) in the rest state',
      (WidgetTester tester) async {
        await pumpScreenSpecMainMenu(tester, variant: MainMenuVariant.pixelArt);

        final DecoratedBox surface = findGradientSurfaceFor(tester, 'New Game');
        final BoxDecoration decoration = surface.decoration as BoxDecoration;
        final LinearGradient gradient = decoration.gradient! as LinearGradient;
        expect(
          gradient.colors,
          CtGradients.woodPanelButtonGradient.colors,
          reason:
              'pixelArt wood-panel buttons must paint the three-stop '
              'CtGradients.woodPanelButtonGradient at rest.',
        );
        expect(gradient.stops, CtGradients.woodPanelButtonGradient.stops);
      },
    );

    testWidgets(
      'AC 8 (pixelArt) wood-panel button pressed gradient inversion: while '
      'a wood-panel button is held, the surface gradient swaps to '
      'CtGradients.woodPanelButtonGradientPressed; after release the '
      'gradient reverts to the rest CtGradients.woodPanelButtonGradient',
      (WidgetTester tester) async {
        await pumpScreenSpecMainMenu(tester, variant: MainMenuVariant.pixelArt);

        final Finder newGameButton = woodPanelButtonFinderFor('New Game');
        final Offset center = tester.getCenter(newGameButton);
        final TestGesture gesture = await tester.startGesture(center);
        await tester.pump();
        await tester.pumpAndSettle();

        final DecoratedBox pressed = findGradientSurfaceFor(tester, 'New Game');
        final BoxDecoration pressedDecoration =
            pressed.decoration as BoxDecoration;
        final LinearGradient pressedGradient =
            pressedDecoration.gradient! as LinearGradient;
        expect(
          pressedGradient.colors,
          CtGradients.woodPanelButtonGradientPressed.colors,
          reason:
              'Pressed wood-panel button must paint the inverted gradient '
              '(--bg-deep → --surface → --surface-lite).',
        );

        await gesture.up();
        await tester.pumpAndSettle();

        final DecoratedBox released = findGradientSurfaceFor(
          tester,
          'New Game',
        );
        final BoxDecoration releasedDecoration =
            released.decoration as BoxDecoration;
        final LinearGradient releasedGradient =
            releasedDecoration.gradient! as LinearGradient;
        expect(
          releasedGradient.colors,
          CtGradients.woodPanelButtonGradient.colors,
          reason:
              'Wood-panel button surface must revert to the rest gradient '
              'once the press gesture completes.',
        );
      },
    );

    testWidgets(
      'AC 8 negative (plain): pressing a Quit CtNinePatchButton in the plain '
      'variant does not swap its surface gradient (no pressedGradient '
      'configured for the legacy 2-stop CtNinePatchButton)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildAppShell(
            child: CtMainMenu(
              variant: MainMenuVariant.plain,
              state: MainMenuState.default_,
              version: formatDebugAwareVersion('v1.0.0'),
              onQuickStart: () {},
              onNewGame: () {},
              onLoadGame: () {},
              onSettings: () {},
              onQuit: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final DecoratedBox restSurface = findGradientSurfaceFor(tester, 'Quit');
        final BoxDecoration restDecoration =
            restSurface.decoration as BoxDecoration;
        final LinearGradient restGradient =
            restDecoration.gradient! as LinearGradient;
        expect(
          restGradient.colors,
          CtGradients.buttonGradient.colors,
          reason:
              'Plain-variant Quit button must paint the canonical 2-stop '
              'CtGradients.buttonGradient at rest.',
        );

        final Offset center = tester.getCenter(
          woodPanelButtonFinderFor('Quit'),
        );
        final TestGesture gesture = await tester.startGesture(center);
        await tester.pump();
        await tester.pumpAndSettle();

        final DecoratedBox pressed = findGradientSurfaceFor(tester, 'Quit');
        final BoxDecoration pressedDecoration =
            pressed.decoration as BoxDecoration;
        final LinearGradient pressedGradient =
            pressedDecoration.gradient! as LinearGradient;
        expect(
          pressedGradient.colors,
          CtGradients.buttonGradient.colors,
          reason:
              'Plain-variant CtNinePatchButton has no pressedGradient and '
              'must keep the canonical 2-stop gradient while held.',
        );

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'AC Variant rendering (plain): no SVG collage, compass rose, fleur-de-lis, or brass divider',
      (WidgetTester tester) async {
        await pumpScreenSpecMainMenu(tester);

        expect(find.byType(CtMainMenuCollage), findsNothing);
        expect(find.byType(CtCompassRose), findsNothing);
        expect(find.byType(CtFleurDeLisOrnament), findsNothing);
        expect(find.byType(CtBrassDivider), findsNothing);
        expect(find.text('A GAME OF EMPIRE & DISCOVERY'), findsNothing);
      },
    );

    // SPEC/ui/main-menu.md § Buttons region (scroll brackets) and
    // Variant rendering — scroll-bracket gutters AC.
    // Mockup: SPEC/ui/mockups/SHEL10002-main-menu.html
    // .buttons-region::before / .buttons-region::after. Refs #2860 S5.
    testWidgets(
      'AC Variant rendering (pixelArt): scroll-bracket gutters flank the buttons region',
      (WidgetTester tester) async {
        await pumpScreenSpecMainMenu(tester, variant: MainMenuVariant.pixelArt);

        final Finder leftBracket = find.byKey(
          const Key(kMainMenuScrollBracketLeftKey),
        );
        final Finder rightBracket = find.byKey(
          const Key(kMainMenuScrollBracketRightKey),
        );
        expect(leftBracket, findsOneWidget);
        expect(rightBracket, findsOneWidget);

        // Both brackets share a common Stack ancestor (the buttons-region
        // stack); the same Stack is therefore an ancestor of each bracket.
        final Finder leftStackAncestors = find.ancestor(
          of: leftBracket,
          matching: find.byType(Stack),
        );
        final Finder rightStackAncestors = find.ancestor(
          of: rightBracket,
          matching: find.byType(Stack),
        );
        final Set<Element> leftStacks = leftStackAncestors.evaluate().toSet();
        final Set<Element> rightStacks = rightStackAncestors.evaluate().toSet();
        expect(
          leftStacks.intersection(rightStacks).isNotEmpty,
          isTrue,
          reason:
              'left and right brackets must share a buttons-region Stack ancestor',
        );
      },
    );

    testWidgets(
      'AC Variant rendering (plain): no scroll-bracket gutters (negative)',
      (WidgetTester tester) async {
        await pumpScreenSpecMainMenu(tester);

        expect(
          find.byKey(const Key(kMainMenuScrollBracketLeftKey)),
          findsNothing,
        );
        expect(
          find.byKey(const Key(kMainMenuScrollBracketRightKey)),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC Variant rendering (pixelArt + resumeGameVisible): scroll brackets still flank the resized buttons region',
      (WidgetTester tester) async {
        await pumpScreenSpecMainMenu(
          tester,
          variant: MainMenuVariant.pixelArt,
          resumeGameVisible: true,
          onResumeGame: () {},
        );

        expect(
          find.byKey(const Key(kMainMenuScrollBracketLeftKey)),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key(kMainMenuScrollBracketRightKey)),
          findsOneWidget,
        );
      },
    );
  });
}
