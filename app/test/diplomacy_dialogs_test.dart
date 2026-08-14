import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_dialogs.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  testWidgets('GrantOrSubsidyDialog submits default valid grant amount', (
    WidgetTester tester,
  ) async {
    // Refs #3656: lightweight fixture (gp1 human treasury 5000 + gp2) replaces
    // the ~7-11s getDebugInitGameResult(); the grant dialog only reads players.
    final game = buildDiplomacyScreenTestGame();
    final humanPlayerId = game.players.first.id;
    final treasury = game.players.first.treasury;
    if (treasury < 1000) {
      return;
    }
    final targetFactionId = game.players.length >= 2
        ? game.players[1].id
        : (game.minorNations.isNotEmpty ? game.minorNations.first.id : 'm1');

    final bus = AppEventBus.create();
    GrantOrSubsidySubmittedEvent? submitted;
    final sub = bus.on<GrantOrSubsidySubmittedEvent>().listen((e) {
      submitted = e;
    });
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      buildAppShell(
        // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              child: const Text('Open'),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => GrantOrSubsidyDialog(
                    game: game,
                    humanPlayerId: humanPlayerId,
                    targetFactionId: targetFactionId,
                    isSubsidy: false,
                    bus: bus,
                  ),
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

    expect(submitted, isNotNull);
    expect(submitted!.amount, 1000);
    expect(submitted!.isSubsidy, isFalse);
    expect(find.text('Grant aid'), findsNothing);
  });

  testWidgets(
    'GrantOrSubsidyDialog submit disabled when treasury below minimum',
    (WidgetTester tester) async {
      final base = buildDiplomacyScreenTestGame();
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

      final bus = AppEventBus.create();
      var submittedCalled = false;
      final sub = bus.on<GrantOrSubsidySubmittedEvent>().listen((_) {
        submittedCalled = true;
      });
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        buildAppShell(
          // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                child: const Text('Open'),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => GrantOrSubsidyDialog(
                      game: game,
                      humanPlayerId: humanPlayerId,
                      targetFactionId: targetFactionId,
                      isSubsidy: false,
                      bus: bus,
                    ),
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
    },
  );

  testWidgets('GrantOrSubsidyDialog Cancel closes dialog', (
    WidgetTester tester,
  ) async {
    final game = buildDiplomacyScreenTestGame();
    final humanPlayerId = game.players.first.id;
    final targetFactionId = game.players.length >= 2
        ? game.players[1].id
        : (game.minorNations.isNotEmpty ? game.minorNations.first.id : 'm1');

    final bus = AppEventBus.create();
    var submittedCalled = false;
    final sub = bus.on<GrantOrSubsidySubmittedEvent>().listen((_) {
      submittedCalled = true;
    });
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      buildAppShell(
        // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              child: const Text('Open'),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => GrantOrSubsidyDialog(
                    game: game,
                    humanPlayerId: humanPlayerId,
                    targetFactionId: targetFactionId,
                    isSubsidy: false,
                    bus: bus,
                  ),
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
