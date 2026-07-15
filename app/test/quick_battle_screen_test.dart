import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/features/game/screens/combat/quick_battle_screen.dart';

import 'support/app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  QuickBattleInput input() {
    return const QuickBattleInput(
      attackerFactionId: 'gp1',
      defenderFactionId: 'gp2',
      attackerDeployment: QuickBattleDeployment(
        groups: [
          QuickBattleGroup(
            lane: QuickBattleLane.center,
            line: QuickBattleLine.front,
            unitIds: ['a1', 'a2'],
            cohesion: 3,
          ),
        ],
      ),
      defenderDeployment: QuickBattleDeployment(
        groups: [
          QuickBattleGroup(
            lane: QuickBattleLane.center,
            line: QuickBattleLine.front,
            unitIds: ['d1'],
            cohesion: 3,
          ),
        ],
      ),
      provinceId: 'oldWorld|p1',
      regionId: 'oldWorld',
      maxRounds: 3,
    );
  }

  group('QuickBattleScreen', () {
    testWidgets('non-interactive resolves and calls onComplete on Continue',
        (WidgetTester tester) async {
      QuickBattleResult? completed;
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: QuickBattleScreen(
              input: input(),
              onComplete: (r) => completed = r,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.textContaining('Battle Result:'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(completed, isNotNull);
    });

    testWidgets('interactive shows actions; selecting one produces result view',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: QuickBattleScreen(
              input: input(),
              onComplete: (_) {},
              interactive: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Quick Battle — Round 1'), findsOneWidget);
      expect(find.textContaining('Command Points:'), findsOneWidget);

      await tester.tap(find.textContaining('Volley Fire'));
      await tester.pump();

      expect(find.textContaining('Battle Result:'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
