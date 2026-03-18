import 'package:colonizethis_app/features/game/widgets/diplomacy_dialogs.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  testWidgets('showGrantOrSubsidyDialog submits valid amount', (
    WidgetTester tester,
  ) async {
    final game = getDebugInitGameResult().game;
    final humanPlayerId = game.players.first.id;
    final targetFactionId = game.players.length >= 2
        ? game.players[1].id
        : (game.minorNations.isNotEmpty ? game.minorNations.first.id : 'm1');

    var submittedAmount = 0;
    var submittedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              child: const Text('Open'),
              onPressed: () {
                showGrantOrSubsidyDialog(
                  context: context,
                  game: game,
                  humanPlayerId: humanPlayerId,
                  targetFactionId: targetFactionId,
                  isSubsidy: false,
                  onSubmitted: (amount) {
                    submittedAmount = amount;
                    submittedCalled = true;
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Grant aid'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);

    // Controller default is '100'. Use a deterministic override.
    await tester.enterText(find.byType(TextField), '50');
    await tester.pump();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(submittedCalled, isTrue);
    expect(submittedAmount, 50);
    expect(find.text('Grant aid'), findsNothing);
  });

  testWidgets('showGrantOrSubsidyDialog invalid amount keeps dialog open',
      (WidgetTester tester) async {
    final game = getDebugInitGameResult().game;
    final humanPlayerId = game.players.first.id;
    final targetFactionId = game.players.length >= 2
        ? game.players[1].id
        : (game.minorNations.isNotEmpty ? game.minorNations.first.id : 'm1');

    final treasury = game.players.firstWhere((p) => p.id == humanPlayerId).treasury;
    final invalidAmount = treasury + 1;

    var submittedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              child: const Text('Open'),
              onPressed: () {
                showGrantOrSubsidyDialog(
                  context: context,
                  game: game,
                  humanPlayerId: humanPlayerId,
                  targetFactionId: targetFactionId,
                  isSubsidy: true,
                  onSubmitted: (_) {
                    submittedCalled = true;
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Set subsidy'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '$invalidAmount');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(submittedCalled, isFalse);
    // Should still be visible because doSubmit() returns without popping.
    expect(find.text('Set subsidy'), findsOneWidget);
  });

  testWidgets('showGrantOrSubsidyDialog Cancel closes dialog',
      (WidgetTester tester) async {
    final game = getDebugInitGameResult().game;
    final humanPlayerId = game.players.first.id;
    final targetFactionId = game.players.length >= 2
        ? game.players[1].id
        : (game.minorNations.isNotEmpty ? game.minorNations.first.id : 'm1');

    var submittedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              child: const Text('Open'),
              onPressed: () {
                showGrantOrSubsidyDialog(
                  context: context,
                  game: game,
                  humanPlayerId: humanPlayerId,
                  targetFactionId: targetFactionId,
                  isSubsidy: false,
                  onSubmitted: (_) {
                    submittedCalled = true;
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(submittedCalled, isFalse);
    expect(find.text('Grant aid'), findsNothing);
  });
}

