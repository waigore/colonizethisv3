// Shared 320 dp QuickBattleScreen pump (Refs #4720 Slice G).
// Family SoT: dialogs_320dp_min_viewport_support.dart.
// SPEC: SPEC/ui/mobile-adaptation.md § 7.

import 'package:colonizethis_app/features/game/screens/combat/quick_battle_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';

/// Minimum supported viewport — family SoT Size(320, 640).
const Size kQuickBattle320MinViewport = kDialogs320MinViewport;

/// Wide regression sentinel.
const Size kQuickBattle320WideViewport = kDialogs320WideRegressionViewport;

/// Minimal two-faction Quick Battle input (2 vs 1, maxRounds = 3).
QuickBattleInput buildQuickBattle320Input() {
  return const QuickBattleInput(
    attackerFactionId: 'gp1',
    defenderFactionId: 'gp2',
    attackerDeployment: QuickBattleDeployment(
      groups: [
        QuickBattleGroup(
          lane: QuickBattleLane.center,
          line: QuickBattleLine.front,
          unitIds: ['a1', 'a2'],
          cohesion: 3,
        ),
      ],
    ),
    defenderDeployment: QuickBattleDeployment(
      groups: [
        QuickBattleGroup(
          lane: QuickBattleLane.center,
          line: QuickBattleLine.front,
          unitIds: ['d1'],
          cohesion: 3,
        ),
      ],
    ),
    provinceId: 'oldWorld|p1',
    regionId: 'oldWorld',
    maxRounds: 3,
  );
}

Future<void> pumpQuickBattleScreen320(
  WidgetTester tester, {
  required Size size,
  required bool interactive,
  ValueChanged<QuickBattleResult>? onComplete,
}) async {
  await pumpDialogs320At(
    tester,
    QuickBattleScreen(
      input: buildQuickBattle320Input(),
      onComplete: onComplete ?? (_) {},
      interactive: interactive,
    ),
    size: size,
  );
}
