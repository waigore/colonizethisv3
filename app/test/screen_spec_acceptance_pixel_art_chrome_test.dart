// Pins SPEC/ui/main-menu.md acceptance criteria:
// pixelArt chrome (collage, footer Quit, wood-panel gradients).
// Scroll-bracket gutters: screen_spec_acceptance_pixel_art_scroll_brackets_test.
// Responsive ≤430 dp ACs live in screen_spec_acceptance_main_menu_responsive_test.
// Concern split under repo.app_test_file_size (Refs #4013, #4352, #4720 Slice G).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_compass_rose.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_fleur_de_lis_ornament.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_main_menu_collage.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';

import 'screen_spec_acceptance_test_support.dart';

void main() {
  suppressLogsForTests();

  group(
    'CtMainMenu — SPEC/ui/main-menu.md acceptance criteria (pixelArt chrome)',
    () {
      testWidgets(
        'AC Variant rendering (pixelArt): collage, compass rose, fleur-de-lis, brass divider all present',
        (WidgetTester tester) async {
          await pumpScreenSpecMainMenu(
            tester,
            variant: MainMenuVariant.pixelArt,
          );

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

      // Wood-panel gradient ACs: screen_spec_acceptance_pixel_art_wood_panel_test.dart

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
    },
  );
}
