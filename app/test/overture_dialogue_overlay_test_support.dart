// Shared pump/fixtures for OvertureDialogueOverlay tests (Refs #4352).
// SPEC: SPEC/ui/incoming-overture-overlay.md.

import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

const OvertureOffer gp2TradeConsulateOffer = OvertureOffer(
  offererGpId: 'gp2',
  targetFactionId: 'gp1',
  stage: OvertureStage.tradeConsulate,
);

const OvertureOffer gp2EmbassyOffer = OvertureOffer(
  offererGpId: 'gp2',
  targetFactionId: 'gp1',
  stage: OvertureStage.embassy,
);

const List<OvertureOffer> singleGp2OvertureOffer = [gp2TradeConsulateOffer];
const List<OvertureOffer> twoStageGp2OvertureOffers = [
  gp2TradeConsulateOffer,
  gp2EmbassyOffer,
];

Game overtureOverlayGame() {
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

Future<void> pumpOvertureOverlay(
  WidgetTester tester, {
  List<OvertureOffer> offers = singleGp2OvertureOffer,
  void Function(List<OvertureDecision>)? onDecisions,
  Size surfaceSize = const Size(900, 900),
}) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    buildAppShell(
      child: OvertureDialogueOverlay(
        game: overtureOverlayGame(),
        pendingOvertures: offers,
        skipIntroForTest: true,
        onDecisions: onDecisions ?? (_) {},
        child: const Scaffold(body: Text('child')),
      ),
    ),
  );
  await tester.pump();
}
