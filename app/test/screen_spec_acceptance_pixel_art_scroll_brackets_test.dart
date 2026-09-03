// Pins SPEC/ui/main-menu.md § Buttons region (scroll brackets) and
// Variant rendering — scroll-bracket gutters AC.
// Mockup: SPEC/ui/mockups/SHEL10002-main-menu.html
// .buttons-region::before / .buttons-region::after. Refs #2860 S5, #4720 Slice G.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/main_menu.dart';

import 'screen_spec_acceptance_test_support.dart';

void main() {
  suppressLogsForTests();

  group(
    'CtMainMenu — SPEC/ui/main-menu.md acceptance criteria (pixelArt chrome)',
    () {
      testWidgets(
        'AC Variant rendering (pixelArt): scroll-bracket gutters flank the buttons region',
        (WidgetTester tester) async {
          await pumpScreenSpecMainMenu(
            tester,
            variant: MainMenuVariant.pixelArt,
          );

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
          final Set<Element> rightStacks = rightStackAncestors
              .evaluate()
              .toSet();
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
    },
  );
}
