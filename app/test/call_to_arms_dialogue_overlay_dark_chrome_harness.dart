// Pump harness for CallToArmsDialogueOverlay dark chrome tests (Refs #4734).

import 'package:colonizethis_app/features/game/widgets/dialogue/call_to_arms_dialogue_overlay.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Game callToArmsChromeTwoPlayerGame() {
  return const Game(
    id: 'cta_chrome',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(id: 'gp_player', displayName: 'Player', isHuman: true),
      Player(id: 'gp_portugal', displayName: 'Portugal', isHuman: false),
      Player(id: 'gp_spain', displayName: 'Spain', isHuman: false),
    ],
  );
}

Future<void> pumpCallToArmsOverlay(WidgetTester tester) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: CallToArmsDialogueOverlay(
          game: callToArmsChromeTwoPlayerGame(),
          pending: const [
            CallToArmsPending(
              allyGpId: 'gp_player',
              defenderGpId: 'gp_portugal',
              aggressorGpId: 'gp_spain',
            ),
          ],
          onDecisions: (_) {},
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder callToArmsJoinToggle(int rowIndex) => find.byKey(
      ValueKey<String>('callToArmsJoinToggle_$rowIndex'),
    );

Finder callToArmsRefuseToggle(int rowIndex) => find.byKey(
      ValueKey<String>('callToArmsRefuseToggle_$rowIndex'),
    );
