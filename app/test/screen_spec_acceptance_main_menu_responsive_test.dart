// Pins SPEC/ui/main-menu.md responsive ≤430 dp body padding / letter-spacing
// (Refs #2870 S6, #4352 Slice D). Split from screen_spec_acceptance_part2_test.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/main_menu.dart';

import 'screen_spec_acceptance_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtMainMenu — SPEC/ui/main-menu.md responsive ACs', () {
    // SPEC/ui/main-menu.md § Responsive rules; SPEC/ui/mockups/SHEL10002-main-menu.html
    // `@media (max-width: 430px)`. Refs #2870 S6.

    testWidgets('AC Narrow ≤ 430 dp (plain): menu body padding compacts to '
        'EdgeInsets.symmetric(horizontal: 12, vertical: 24)', (
      WidgetTester tester,
    ) async {
      await pumpScreenSpecMainMenuAtSize(
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
      await pumpScreenSpecMainMenuAtSize(
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
      await pumpScreenSpecMainMenuAtSize(
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
        textsWithLetterSpacing(kMainMenuButtonLetterSpacingNarrow),
        findsWidgets,
      );
      expect(
        textsWithLetterSpacing(kMainMenuButtonLetterSpacingDefault),
        findsNothing,
      );
    });

    testWidgets(
      'AC Wide > 430 dp (pixelArt): menu body padding stays default and '
      'button label letter-spacing stays at default constant',
      (WidgetTester tester) async {
        await pumpScreenSpecMainMenuAtSize(
          tester,
          size: const Size(800, 600),
          variant: MainMenuVariant.pixelArt,
        );

        final Padding bodyPadding = tester.widget<Padding>(
          find.byKey(const Key(kMainMenuBodyPaddingKey)),
        );
        expect(bodyPadding.padding, kMainMenuBodyPaddingDefault);

        expect(
          textsWithLetterSpacing(kMainMenuButtonLetterSpacingDefault),
          findsWidgets,
        );
        expect(
          textsWithLetterSpacing(kMainMenuButtonLetterSpacingNarrow),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC Narrow ≤ 430 dp (plain): button label Text widgets carry no '
      'explicit letter-spacing override (letter-spacing rule is pixelArt-only)',
      (WidgetTester tester) async {
        await pumpScreenSpecMainMenuAtSize(
          tester,
          size: const Size(360, 640),
          variant: MainMenuVariant.plain,
        );

        // Plain variant uses bare `Text(label)` for menu actions; no
        // explicit `letterSpacing` is set by main-menu code on those Texts.
        expect(
          textsWithLetterSpacing(kMainMenuButtonLetterSpacingNarrow),
          findsNothing,
        );
        expect(
          textsWithLetterSpacing(kMainMenuButtonLetterSpacingDefault),
          findsNothing,
        );
      },
    );

    for (final case_ in <({String name, Size size, EdgeInsets padding})>[
      (
        name:
            'AC ≤ 430 dp boundary: viewport exactly at 430 dp is treated as narrow',
        size: const Size(kMainMenuNarrowBreakpoint, 640),
        padding: kMainMenuBodyPaddingNarrow,
      ),
      (
        name: 'AC > 430 dp boundary: viewport 431 dp is treated as wide',
        size: const Size(kMainMenuNarrowBreakpoint + 1, 640),
        padding: kMainMenuBodyPaddingDefault,
      ),
    ]) {
      testWidgets(case_.name, (WidgetTester tester) async {
        await pumpScreenSpecMainMenuAtSize(
          tester,
          size: case_.size,
          variant: MainMenuVariant.plain,
        );
        final Padding bodyPadding = tester.widget<Padding>(
          find.byKey(const Key(kMainMenuBodyPaddingKey)),
        );
        expect(bodyPadding.padding, case_.padding);
      });
    }
  });
}
