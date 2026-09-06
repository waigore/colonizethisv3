// Fixtures for intervention choice picker effect pins (#4267, #4734 Slice J).

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/intervention_choice_buttons.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'yarn_test_fixtures.dart';

Game interventionChoiceEmbassyGame() {
  return Game(
    id: 'iv_choice_effects',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false, treasury: 0),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Powhatan')],
    overtureStates: const [
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

Game interventionChoiceMultiPromptGame() {
  return Game(
    id: 'iv_choice_effects_multi',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false, treasury: 0),
      Player(id: 'gp3', displayName: 'France', isHuman: false, treasury: 0),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Powhatan'),
      MinorNation(id: 'minor2', displayName: 'Creek'),
    ],
    overtureStates: const [
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
      ),
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor2',
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

Future<void> pumpInterventionChoicePhase(
  WidgetTester tester, {
  required Game game,
  List<InterventionPrompt> prompts = const [
    InterventionPrompt(
      aggressorGpId: 'gp2',
      defenderMinorOrTribeId: 'minor1',
      interveningGpId: 'gp1',
    ),
  ],
  void Function(List<InterventionDecision>)? onDecisions,
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: InterventionDialogueOverlay(
        game: game,
        prompts: prompts,
        skipIntroForTest: true,
        assetBundle: YarnStringAssetBundle({
          kDialogueInterventionAsset: kYarnInterventionMinimal,
        }),
        onDecisions: onDecisions ?? (_) {},
        child: const SizedBox.expand(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> advancePastInterventionSituationYarn(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void expectNoInterventionEffectKeys(WidgetTester tester) {
  expect(
    find.byKey(const ValueKey<String>(kInterventionEffectInterveneKey)),
    findsNothing,
  );
  expect(
    find.byKey(const ValueKey<String>(kInterventionEffectDoNothingKey)),
    findsNothing,
  );
  expect(
    find.byKey(const ValueKey<String>(kInterventionEffectProtestKey)),
    findsNothing,
  );
}
