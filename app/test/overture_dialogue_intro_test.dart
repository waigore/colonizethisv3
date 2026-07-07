import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Game minimalGame() {
    return Game(
      id: 'test',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: [
        Player(
          id: 'gp1',
          displayName: 'France',
          isHuman: false,
          treasury: 0,
        ),
      ],
    );
  }

  testWidgets('OvertureDialogueOverlay runs intro and then shows offer list',
      (WidgetTester tester) async {
    final game = minimalGame();
    final offers = const [
      OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 'gp2',
        stage: OvertureStage.embassy,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: OvertureDialogueOverlay(
          game: game,
          pendingOvertures: offers,
          onDecisions: (_) {},
          child: const SizedBox(),
        ),
      ),
    );

    // Intro (Jenny) phase: we keep tapping "Continue" until we reach the
    // "Diplomatic overtures" phase.
    for (var i = 0; i < 10; i++) {
      if (find.text('Diplomatic overtures').evaluate().isNotEmpty) break;
      final continueFinder = find.text('Continue');
      if (continueFinder.evaluate().isNotEmpty) {
        await tester.tap(continueFinder.first);
      }
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.text('Diplomatic overtures'), findsOneWidget);
    expect(find.text('Accept'), findsWidgets);
    expect(find.text('Reject'), findsWidgets);
    expect(find.text('Submit'), findsOneWidget);
  });
}

