// Widget tests for Military Units generals strip (#4233).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/military/military_generals_strip.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  const human = 'gp1';

  Widget buildStrip({
    List<General> generals = const [],
    int? generalCap,
  }) {
    final game = Game(
      id: 'g',
      players: [
        Player(
          id: human,
          displayName: 'Human',
          isHuman: true,
          generalCap: generalCap ?? 3,
        ),
      ],
      generals: generals,
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(provinces: [], units: []),
        newWorld: const RegionData(),
      ),
    );
    return buildAppShell(
      child: MilitaryGeneralsStrip(game: game, humanPlayerId: human),
    );
  }

  testWidgets('shows generals count cap and medal lines', (tester) async {
    await pumpSettledWidget(
      tester,
      buildStrip(
        generals: const [
          General(id: 'g1', ownerId: human, medals: 0),
          General(id: 'g2', ownerId: human, medals: 2),
        ],
      ),
    );

    expect(find.text('Generals: 2 of 3'), findsOneWidget);
    expect(find.text('General 1: 0 medals'), findsOneWidget);
    expect(find.text('General 2: 2 medals'), findsOneWidget);
    expect(
      find.text(
        'Each general can lead one invasion this turn. More medals mean a stronger fight.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Details toggles medal gloss', (tester) async {
    await pumpSettledWidget(
      tester,
      buildStrip(
        generals: const [General(id: 'g1', ownerId: human)],
      ),
    );

    expect(
      find.text(
        'Medals let more regiments fight, help troops hold the line, and can decide who strikes first.',
      ),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(CtActionTextButton, 'Details'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Medals let more regiments fight, help troops hold the line, and can decide who strikes first.',
      ),
      findsOneWidget,
    );
  });
}
