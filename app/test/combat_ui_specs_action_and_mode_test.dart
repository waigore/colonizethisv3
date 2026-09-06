// Pins SPEC/ui quick-battle-action-selector.md (Refs #4013, #4352).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'combat_ui_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  group(
    'QuickBattleActionSelector (SPEC/ui/quick-battle-action-selector.md)',
    () {
      testWidgets('with cpRemaining=3 every action button is enabled', (
        WidgetTester tester,
      ) async {
        QuickBattleAction? picked;
        await pumpCombatUiSpecsSelector(
          tester,
          cpRemaining: 3,
          onActionSelected: (a) => picked = a,
        );

        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.byType(TextButton), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);

        await tester.tap(find.textContaining('Volley Fire'));
        await tester.pump();
        expect(picked, QuickBattleAction.volleyFire);
      });

      testWidgets('with cpRemaining=1 the 2-CP buttons are disabled', (
        WidgetTester tester,
      ) async {
        var taps = 0;
        await pumpCombatUiSpecsSelector(
          tester,
          cpRemaining: 1,
          onActionSelected: (_) => taps++,
        );

        await tester.tap(find.textContaining('Volley Fire'));
        await tester.pump();
        expect(taps, 1);

        await tester.tap(find.textContaining('Assault'), warnIfMissed: false);
        await tester.pump();
        expect(taps, 1);

        await tester.tap(find.textContaining('Fall Back'), warnIfMissed: false);
        await tester.pump();
        expect(taps, 1);
      });

      testWidgets('with cpRemaining=0 every action button is disabled', (
        WidgetTester tester,
      ) async {
        var taps = 0;
        await pumpCombatUiSpecsSelector(
          tester,
          cpRemaining: 0,
          onActionSelected: (_) => taps++,
        );

        for (final label in const [
          'Volley Fire',
          'Defend',
          'Maneuver',
          'Fall Back',
          'Assault',
        ]) {
          await tester.tap(find.textContaining(label), warnIfMissed: false);
        }
        await tester.pump();
        expect(taps, 0);
      });

      testWidgets(
        'CP indicator resolves to --muted under dark and fallback themes',
        (WidgetTester tester) async {
          await pumpCombatUiSpecsSelector(
            tester,
            cpRemaining: 3,
            onActionSelected: (_) {},
            dark: true,
          );
          expect(
            tester
                .widget<Text>(find.textContaining('Command Points: 3'))
                .style
                ?.color,
            EditorialMonoclePalette.muted,
          );

          await pumpCombatUiSpecsSelector(
            tester,
            cpRemaining: 0,
            onActionSelected: (_) {},
          );
          expect(
            tester
                .widget<Text>(find.textContaining('Command Points: 0'))
                .style
                ?.color,
            EditorialMonoclePalette.muted,
          );
        },
      );
    },
  );
}
