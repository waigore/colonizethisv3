// Pins SPEC/ui Quick Battle screen contracts (inline result chrome).
// Shared frames: combat_ui_specs_test_support.dart (Refs #4013, #4352).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/screens/combat/quick_battle_screen.dart';

import 'combat_ui_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  group('QuickBattleScreen inline _ResultView color parity (Refs #2869 R18)', () {
    testWidgets(
      'dark editorial-monocle: inline winner title resolves to --accent',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          combatUiSpecsDarkFrame(
            QuickBattleScreen(
              input: combatUiSpecsStandardQuickBattleInput(),
              onComplete: (_) {},
            ),
          ),
        );
        await tester.pump();

        final Finder titleFinder = find.textContaining('Battle Result:');
        expect(titleFinder, findsOneWidget);
        final Text title = tester.widget<Text>(titleFinder);
        expect(title.style?.color, EditorialMonoclePalette.accent);
      },
    );

    testWidgets(
      'dark editorial-monocle: inline casualty rows resolve to --muted',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          combatUiSpecsDarkFrame(
            QuickBattleScreen(
              input: combatUiSpecsStandardQuickBattleInput(),
              onComplete: (_) {},
            ),
          ),
        );
        await tester.pump();

        final Finder attackerRowFinder = find.textContaining(
          'Attacker casualties:',
        );
        final Finder defenderRowFinder = find.textContaining(
          'Defender casualties:',
        );
        expect(attackerRowFinder, findsOneWidget);
        expect(defenderRowFinder, findsOneWidget);

        final Text attackerRow = tester.widget<Text>(attackerRowFinder);
        final Text defenderRow = tester.widget<Text>(defenderRowFinder);
        expect(attackerRow.style?.color, EditorialMonoclePalette.muted);
        expect(defenderRow.style?.color, EditorialMonoclePalette.muted);
      },
    );

    testWidgets(
      'dark editorial-monocle: Continue button is the only action button on the inline view',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          combatUiSpecsDarkFrame(
            QuickBattleScreen(
              input: combatUiSpecsStandardQuickBattleInput(),
              onComplete: (_) {},
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Continue'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.byType(TextButton), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
      },
    );
  });

  group('QuickBattleScreen round phase title (Refs #2869 R7)', () {
    testWidgets(
      'dark editorial-monocle: round counter resolves to --accent + 0.05 letter-spacing',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          combatUiSpecsDarkFrame(
            QuickBattleScreen(
              input: combatUiSpecsStandardQuickBattleInput(),
              onComplete: (_) {},
              interactive: true,
            ),
          ),
        );
        await tester.pump();

        final Finder titleFinder = find.textContaining(
          'Quick Battle — Round 1',
        );
        expect(titleFinder, findsOneWidget);
        final Text title = tester.widget<Text>(titleFinder);
        expect(title.style?.color, EditorialMonoclePalette.accent);
        expect(
          title.style?.letterSpacing,
          QuickBattleScreen.roundCounterLetterSpacing,
        );
      },
    );

    testWidgets(
      'fallback Material theme: round counter still resolves to --accent + 0.05 letter-spacing',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          combatUiSpecsFrame(
            QuickBattleScreen(
              input: combatUiSpecsStandardQuickBattleInput(),
              onComplete: (_) {},
              interactive: true,
            ),
          ),
        );
        await tester.pump();

        final Finder titleFinder = find.textContaining(
          'Quick Battle — Round 1',
        );
        expect(titleFinder, findsOneWidget);
        final Text title = tester.widget<Text>(titleFinder);
        expect(title.style?.color, EditorialMonoclePalette.accent);
        expect(
          title.style?.letterSpacing,
          QuickBattleScreen.roundCounterLetterSpacing,
        );
      },
    );
  });
}
