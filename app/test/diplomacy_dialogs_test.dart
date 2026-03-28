import 'package:colonizethis_app/features/game/widgets/diplomacy_dialogs.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  testWidgets('showGrantOrSubsidyDialog submits default grant amount via stepper',
      (WidgetTester tester) async {
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
    expect(find.textContaining('£'), findsWidgets);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CtNinePatchButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(submittedCalled, isTrue);
    expect(submittedAmount, 1000);
    expect(find.text('Grant aid'), findsNothing);
  });

  testWidgets(
      'showGrantOrSubsidyDialog submit disabled when treasury cannot fund minimum',
      (WidgetTester tester) async {
    final base = getDebugInitGameResult().game;
    final humanPlayerId = base.players.first.id;
    final p0 = base.players.firstWhere((p) => p.id == humanPlayerId);
    final game = base.copyWith(
      players: [
        p0.copyWith(treasury: 0),
        ...base.players.where((p) => p.id != humanPlayerId),
      ],
    );
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
    final submit = find.widgetWithText(CtNinePatchButton, 'Submit');
    final button = tester.widget<CtNinePatchButton>(submit);
    expect(button.onPressed, isNull);

    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(submittedCalled, isFalse);
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

    await tester.tap(find.widgetWithText(CtNinePatchButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(submittedCalled, isFalse);
    expect(find.text('Grant aid'), findsNothing);
  });
}
