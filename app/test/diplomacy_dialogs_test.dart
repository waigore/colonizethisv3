import 'package:colonizethis_app/features/game/widgets/diplomacy_dialogs.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  testWidgets('showGrantOrSubsidyDialog submits default valid grant amount',
      (WidgetTester tester) async {
    final game = getDebugInitGameResult().game;
    final humanPlayerId = game.players.first.id;
    final treasury = game.players.first.treasury;
    if (treasury < 1000) {
      return;
    }
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

    await tester.tap(find.widgetWithText(CtNinePatchButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(submittedCalled, isTrue);
    expect(submittedAmount, 1000);
    expect(find.text('Grant aid'), findsNothing);
  });

  testWidgets(
      'showGrantOrSubsidyDialog submit disabled when treasury below minimum',
      (WidgetTester tester) async {
    final base = getDebugInitGameResult().game;
    final humanPlayerId = base.players.first.id;
    final targetFactionId = base.players.length >= 2
        ? base.players[1].id
        : (base.minorNations.isNotEmpty ? base.minorNations.first.id : 'm1');

    final game = base.copyWith(
      players: [
        base.players.first.copyWith(treasury: 500),
        ...base.players.skip(1),
      ],
    );

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

    expect(find.text('Grant aid'), findsOneWidget);
    final submit = find.widgetWithText(CtNinePatchButton, 'Submit');
    final button = tester.widget<CtNinePatchButton>(submit);
    expect(button.enabled, isFalse);

    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(submittedCalled, isFalse);
    expect(find.text('Grant aid'), findsOneWidget);
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
