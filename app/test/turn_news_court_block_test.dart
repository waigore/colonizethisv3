// Widget tests for DLG50001 **Your court** block (Refs #4532).
//
// SPEC: SPEC/ui/turn-news-dialog.md § Your court block.

import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  final baseGame = Game(
    id: 'g',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
    ],
  );

  Future<void> pumpDialog(
    WidgetTester tester, {
    TurnNewsDigest digest = const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
    TurnNewsCourtSummary courtSummary = const TurnNewsCourtSummary.empty(),
    VoidCallback? onOpenEvents,
  }) async {
    await pumpAppShell(
      tester,
      settle: true,
      child: TurnNewsDialog(
        game: baseGame,
        digest: digest,
        newTurnNumber: 2,
        courtSummary: courtSummary,
        onOpenEvents: onOpenEvents,
      ),
    );
  }

  testWidgets(
    'positive: empty gazette with court block omits empty copy',
    (WidgetTester tester) async {
      await pumpDialog(
        tester,
        courtSummary: const TurnNewsCourtSummary(clauses: ['Sailing finished']),
      );

      expect(find.text('No major events last turn.'), findsNothing);
      expect(find.textContaining('Your court:'), findsOneWidget);
      expect(find.textContaining('Sailing finished'), findsOneWidget);
    },
  );

  testWidgets(
    'positive: open Events tap invokes callback',
    (WidgetTester tester) async {
      var opened = false;
      await pumpDialog(
        tester,
        courtSummary: const TurnNewsCourtSummary(clauses: ['work finished']),
        onOpenEvents: () => opened = true,
      );

      await tester.tap(find.textContaining('Your court:'));
      await tester.pump();
      expect(opened, isTrue);
    },
  );

  testWidgets(
    'negative: empty gazette and empty court keeps empty copy',
    (WidgetTester tester) async {
      await pumpDialog(tester);

      expect(find.text('No major events last turn.'), findsOneWidget);
      expect(find.textContaining('Your court:'), findsNothing);
    },
  );

  testWidgets(
    'positive: court block and spy footer coexist',
    (WidgetTester tester) async {
      await pumpAppShell(
        tester,
        settle: true,
        child: TurnNewsDialog(
          game: baseGame,
          digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
          newTurnNumber: 2,
          courtSummary: const TurnNewsCourtSummary(clauses: ['work finished']),
          spyReportCount: 1,
          onOpenIntelligence: () {},
          onOpenEvents: () {},
        ),
      );

      expect(find.textContaining('Your court:'), findsOneWidget);
      expect(find.textContaining('open Intelligence'), findsOneWidget);
    },
  );

  testWidgets(
    'positive: court block wraps at 320 dp without overflow',
    (WidgetTester tester) async {
      await pumpAppShell(
        tester,
        settle: true,
        child: Center(
          child: SizedBox(
            width: 320,
            child: TurnNewsDialog(
              game: baseGame,
              digest: const TurnNewsDigest(resolvedTurnNumber: 1, lines: []),
              newTurnNumber: 2,
              courtSummary: const TurnNewsCourtSummary(
                clauses: [
                  'a decree was refused',
                  'Sailing finished',
                  'a battle was fought',
                ],
                overflowFamilyCount: 2,
              ),
              onOpenEvents: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final courtText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(TurnNewsDialog.courtBlockKey()),
          matching: find.byType(Text),
        ).first,
      );
      expect(courtText.style?.color, equals(EditorialMonoclePalette.muted));
    },
  );
}
