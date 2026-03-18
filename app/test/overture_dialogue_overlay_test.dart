import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/features/game/dialogue/overture_dialogue_overlay.dart';

void main() {
  suppressLogsForTests();

  Game _game() {
    return const Game(
      id: 'g1',
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: [
        Player(id: 'gp1', displayName: 'Great Power 1', isHuman: true),
        Player(id: 'gp2', displayName: 'Great Power 2', isHuman: false),
      ],
    );
  }

  group('OvertureDialogueOverlay', () {
    testWidgets('skipIntroForTest: Accept/Reject toggles and Submit yields decisions',
        (WidgetTester tester) async {
      final offers = <OvertureOffer>[
        const OvertureOffer(
          offererGpId: 'gp2',
          targetFactionId: 'gp1',
          stage: OvertureStage.tradeConsulate,
        ),
        const OvertureOffer(
          offererGpId: 'gp2',
          targetFactionId: 'gp1',
          stage: OvertureStage.embassy,
        ),
      ];
      List<OvertureDecision>? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: OvertureDialogueOverlay(
            game: _game(),
            pendingOvertures: offers,
            skipIntroForTest: true,
            onDecisions: (d) => submitted = List.of(d),
            child: const Scaffold(body: Text('child')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Diplomatic overtures'), findsOneWidget);
      expect(find.textContaining('Great Power 2:'), findsNWidgets(2));

      // Reject second offer, keep first accepted.
      await tester.tap(find.text('Reject').last);
      await tester.pump();

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(submitted, isNotNull);
      expect(submitted, hasLength(2));
      expect(submitted![0].accepted, isTrue);
      expect(submitted![1].accepted, isFalse);
      expect(submitted![0].stage, OvertureStage.tradeConsulate);
      expect(submitted![1].stage, OvertureStage.embassy);
    });
  });
}

