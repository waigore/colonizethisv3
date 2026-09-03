// Shared pump/fixtures for OVL30001 choice-effect goldens (Refs #4720 Slice G).
// SPEC/ui/overture-dialogue-overlay.md § Acceptance Criteria.
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/overture_dialogue_overlay.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

Game overtureChoiceEffectsGame() {
  return const Game(
    id: 'overture_choice_effects_goldens',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'Spain', isHuman: false, treasury: 0),
      Player(id: 'gp3', displayName: 'Portugal', isHuman: false, treasury: 0),
    ],
  );
}

const OvertureOffer spainNapOffer = OvertureOffer(
  offererGpId: 'gp2',
  targetFactionId: 'gp1',
  stage: OvertureStage.nap,
);

const OvertureOffer portugalJoinOffer = OvertureOffer(
  offererGpId: 'gp3',
  targetFactionId: 'gp1',
  stage: OvertureStage.joinEmpire,
);

const OvertureOffer spainConsulateGpOffer = OvertureOffer(
  offererGpId: 'gp2',
  targetFactionId: 'gp1',
  stage: OvertureStage.tradeConsulate,
);

const OvertureOffer spainConsulateMinorOffer = OvertureOffer(
  offererGpId: 'gp2',
  targetFactionId: 'minor1',
  stage: OvertureStage.tradeConsulate,
);

const OvertureOffer spainEmbassyGpOffer = OvertureOffer(
  offererGpId: 'gp2',
  targetFactionId: 'gp1',
  stage: OvertureStage.embassy,
);

const OvertureOffer spainEmbassyMinorOffer = OvertureOffer(
  offererGpId: 'gp2',
  targetFactionId: 'minor1',
  stage: OvertureStage.embassy,
);

Game overtureChoiceEffectsGameWithMinor() {
  return const Game(
    id: 'overture_choice_effects_goldens_minor',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'Spain', isHuman: false, treasury: 0),
    ],
    minorNations: [MinorNation(id: 'minor1', displayName: 'Bavaria')],
  );
}

const Widget overtureChoiceEffectsOverlayChild = ColoredBox(
  color: Color(0xFF101014),
  child: SizedBox.expand(),
);

Future<void> pumpOvertureChoiceEffectsGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size physicalSize,
  required List<OvertureOffer> offers,
  Game? game,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    settle: false,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: OvertureDialogueOverlay(
      game: game ?? overtureChoiceEffectsGame(),
      pendingOvertures: offers,
      skipIntroForTest: true,
      onDecisions: (_) {},
      child: overtureChoiceEffectsOverlayChild,
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
}
