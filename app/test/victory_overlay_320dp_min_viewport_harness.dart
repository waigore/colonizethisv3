// 320 dp minimum-viewport harness for VictoryOverlay (OVL20001).
// SPEC: SPEC/ui/mobile-adaptation.md § 7; SPEC/ui/victory-overlay.md.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'min_viewport_harness.dart';
import 'panel_test_fixtures.dart';

const Size kVictoryOverlayMinViewport = Size(kMinViewportWidth, 640);
const Size kVictoryOverlayWideRegressionViewport = Size(1024, 768);

Future<void> pumpVictoryOverlayAtViewport(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) {
  return pumpAtMinViewport(
    tester,
    size: size,
    child: Scaffold(body: child),
    settle: true,
  );
}

ct_models.VictoryState buildVictoryOverlayTestVictory({
  required String winnerPlayerId,
  int turnNumber = 7,
}) {
  return ct_models.VictoryState(
    winnerPlayerId: winnerPlayerId,
    type: ct_models.VictoryType.military,
    turnNumber: turnNumber,
  );
}

ct_models.Game buildVictoryOverlayTestGame() => buildVictoryPanelTestGame();
