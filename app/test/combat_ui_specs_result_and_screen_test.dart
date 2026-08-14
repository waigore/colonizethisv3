// Pins SPEC/ui combat result dialog and Quick Battle screen contracts:
// - SPEC/ui/quick-battle-result-dialog.md
// - SPEC/ui/quick-battle-screen.md (inline result view chrome parity)
// Shared frames: combat_ui_specs_test_support.dart (Refs #4013, #4352).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app/features/game/screens/combat/quick_battle_screen.dart';

import 'combat_ui_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  group('QuickBattleResultDialog (SPEC/ui/quick-battle-result-dialog.md)', () {
    testWidgets('attacker wins + provinceFlips renders captured banner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        combatUiSpecsFrame(
          const QuickBattleResultDialog(
            result: QuickBattleResult(
              winner: QuickBattleWinner.attacker,
              attackerCasualties: ['a3'],
              defenderCasualties: ['d1', 'd2'],
              provinceFlips: true,
            ),
            attackerName: 'Castile',
            defenderName: 'England',
          ),
        ),
      );

      expect(find.textContaining('Castile'), findsWidgets);
      expect(find.textContaining('England'), findsWidgets);
      expect(find.textContaining('captured'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
    testWidgets('defender holds suppresses captured banner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        combatUiSpecsFrame(
          const QuickBattleResultDialog(
            result: QuickBattleResult(
              winner: QuickBattleWinner.defender,
              attackerCasualties: ['a1', 'a2'],
              defenderCasualties: ['d1'],
              provinceFlips: false,
            ),
            attackerName: 'Castile',
            defenderName: 'England',
          ),
        ),
      );

      expect(find.textContaining('captured'), findsNothing);
    });
    testWidgets('mutual exhaustion suppresses captured banner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        combatUiSpecsFrame(
          const QuickBattleResultDialog(
            result: QuickBattleResult(
              winner: QuickBattleWinner.mutualExhaustion,
              attackerCasualties: ['a1'],
              defenderCasualties: ['d1'],
              provinceFlips: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('captured'), findsNothing);
      expect(find.text('OK'), findsOneWidget);
    });
    testWidgets('OK button pops the dialog route', (WidgetTester tester) async {
      await tester.pumpWidget(
        combatUiSpecsFrame(
          Builder(
            builder: (ctx) {
              return TextButton(
                child: const Text('open'),
                onPressed: () {
                  showDialog<void>(
                    context: ctx,
                    builder: (_) => const QuickBattleResultDialog(
                      result: QuickBattleResult(
                        winner: QuickBattleWinner.attacker,
                        attackerCasualties: [],
                        defenderCasualties: [],
                        provinceFlips: true,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsNothing);
      // Underlying open button is visible again — dialog popped.
      expect(find.text('open'), findsOneWidget);
    });

    // Refs #2869 R18-R19 + SPEC/ui/quick-battle-result-dialog.md § Color contract.
    // Pins the dark editorial-monocle color tokens (--accent winner,
    // --danger provinceCaptured, --muted casualty rows) resolve via
    // theme.colorScheme / textTheme.bodySmall and not via hardcoded literals.
    testWidgets(
      'dark editorial-monocle: winner text resolves to --accent (theme.colorScheme.primary)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          combatUiSpecsDarkFrame(
            const QuickBattleResultDialog(
              result: QuickBattleResult(
                winner: QuickBattleWinner.attacker,
                attackerCasualties: ['a1'],
                defenderCasualties: ['d1'],
                provinceFlips: true,
              ),
              attackerName: 'Castile',
              defenderName: 'England',
            ),
          ),
        );

        final Text title = tester.widget<Text>(
          find.text('Battle Result: Castile wins'),
        );
        expect(title.style?.color, EditorialMonoclePalette.accent);
      },
    );

    testWidgets(
      'dark editorial-monocle: provinceCaptured line resolves to --danger and is bold',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          combatUiSpecsDarkFrame(
            const QuickBattleResultDialog(
              result: QuickBattleResult(
                winner: QuickBattleWinner.attacker,
                attackerCasualties: ['a1'],
                defenderCasualties: ['d1'],
                provinceFlips: true,
              ),
              attackerName: 'Castile',
              defenderName: 'England',
            ),
          ),
        );

        final Text captured = tester.widget<Text>(
          find.text('Province captured.'),
        );
        expect(captured.style?.color, EditorialMonoclePalette.danger);
        expect(captured.style?.fontWeight, FontWeight.bold);
      },
    );

    testWidgets(
      'dark editorial-monocle: casualty rows use bodySmall and resolve to --muted',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          combatUiSpecsDarkFrame(
            const QuickBattleResultDialog(
              result: QuickBattleResult(
                winner: QuickBattleWinner.attacker,
                attackerCasualties: ['a1', 'a2'],
                defenderCasualties: ['d1'],
                provinceFlips: false,
              ),
              attackerName: 'Castile',
              defenderName: 'England',
            ),
          ),
        );

        final Text attackerRow = tester.widget<Text>(
          find.text('Castile casualties: 2'),
        );
        final Text defenderRow = tester.widget<Text>(
          find.text('England casualties: 1'),
        );
        expect(attackerRow.style?.color, EditorialMonoclePalette.muted);
        expect(defenderRow.style?.color, EditorialMonoclePalette.muted);
      },
    );

    testWidgets(
      'defender holds (provinceFlips=false) suppresses captured banner under dark theme',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          combatUiSpecsDarkFrame(
            const QuickBattleResultDialog(
              result: QuickBattleResult(
                winner: QuickBattleWinner.defender,
                attackerCasualties: ['a1'],
                defenderCasualties: ['d1'],
                provinceFlips: false,
              ),
              attackerName: 'Castile',
              defenderName: 'England',
            ),
          ),
        );

        expect(find.text('Province captured.'), findsNothing);
      },
    );
  });

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
