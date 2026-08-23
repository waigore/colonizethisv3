// Shared overture / call-to-arms SPEC pin fixtures (Refs #4606 Slice D).

import 'package:colonizethis_app/features/game/widgets/dialogue/call_to_arms_call_row.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/call_to_arms_dialogue_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'dialogue_overlays_specs_test_support.dart';

const Game dialogueOverlaysGpTrioGame = Game(
  id: 'test_gp_trio',
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: 4),
    oldWorld: RegionData(),
    newWorld: RegionData(),
  ),
  players: [
    Player(id: 'gp_spain', displayName: 'Spain', isHuman: false, treasury: 0),
    Player(
      id: 'gp_portugal',
      displayName: 'Portugal',
      isHuman: false,
      treasury: 0,
    ),
    Player(id: 'gp_player', displayName: 'Player', isHuman: true, treasury: 0),
  ],
);

const List<OvertureOffer> dialogueOverlaysTwoOvertureOffers = [
  OvertureOffer(
    offererGpId: 'gp_spain',
    targetFactionId: 'gp_player',
    stage: OvertureStage.tradeConsulate,
  ),
  OvertureOffer(
    offererGpId: 'gp_portugal',
    targetFactionId: 'gp_player',
    stage: OvertureStage.embassy,
  ),
];

const List<CallToArmsPending> dialogueOverlaysTwoCtaPending = [
  CallToArmsPending(
    allyGpId: 'gp_player',
    defenderGpId: 'gp_portugal',
    aggressorGpId: 'gp_spain',
  ),
  CallToArmsPending(
    allyGpId: 'gp_player',
    defenderGpId: 'gp_spain',
    aggressorGpId: 'gp_portugal',
  ),
];

Widget dialogueOverlaysShell(Widget body) {
  return buildAppShell(
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    child: Scaffold(body: body),
  );
}

Widget wrapOvertureDialogueOverlay({
  required List<OvertureOffer> offers,
  required void Function(List<OvertureDecision>) onDecisions,
}) {
  return dialogueOverlaysShell(
    OvertureDialogueOverlay(
      game: dialogueOverlaysGpTrioGame,
      pendingOvertures: offers,
      skipIntroForTest: true,
      onDecisions: onDecisions,
      child: const SizedBox.expand(child: Center(child: Text('child-content'))),
    ),
  );
}

Widget wrapCallToArmsDialogueOverlay({
  required List<CallToArmsPending> pending,
  required void Function(List<CallToArmsDecision>) onDecisions,
}) {
  return dialogueOverlaysShell(
    CallToArmsDialogueOverlay(
      game: dialogueOverlaysGpTrioGame,
      pending: pending,
      onDecisions: onDecisions,
      child: const SizedBox.expand(child: Center(child: Text('child-content'))),
    ),
  );
}

Future<void> tapDialogueOverlayControl(
  WidgetTester tester,
  Finder finder, {
  bool warnIfMissed = true,
}) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder, warnIfMissed: warnIfMissed);
  await pumpDialogueOverlaysUntilSettled(tester);
}

String callToArmsPromptPlainText(WidgetTester tester) {
  final Text prompt = tester.widget<Text>(
    find.byKey(CallToArmsCallRow.promptKey),
  );
  return prompt.data ?? prompt.textSpan?.toPlainText() ?? '';
}
