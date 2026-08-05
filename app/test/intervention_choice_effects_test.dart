// Pins first-order Effect copy on the intervention choice picker (Refs #4267).
import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/intervention_choice_buttons.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'yarn_test_fixtures.dart';

const _kInterventionYarnMinimal = r'''
title: DialoguePoint/intervention_intro
---
Heavy tidings cross thy desk.
-> Continue
===

title: DialoguePoint/intervention_situation
---
Dispatch from thy minister.
-> Continue
===

title: DialoguePoint/intervention_reaction_intervene
---
Reaction.
-> Continue
===

title: DialoguePoint/intervention_reaction_do_nothing
---
Reaction.
-> Continue
===

title: DialoguePoint/intervention_reaction_protest
---
Reaction.
-> Continue
===
''';

Game _embassyInterventionGame() {
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
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Powhatan'),
    ],
    overtureStates: const [
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

Future<void> _pumpChoicePhase(WidgetTester tester, {required Game game}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: InterventionDialogueOverlay(
        game: game,
        prompts: const [
          InterventionPrompt(
            aggressorGpId: 'gp2',
            defenderMinorOrTribeId: 'minor1',
            interveningGpId: 'gp1',
          ),
        ],
        skipIntroForTest: true,
        assetBundle: YarnStringAssetBundle({
          kDialogueInterventionAsset: _kInterventionYarnMinimal,
        }),
        onDecisions: (_) {},
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

void main() {
  suppressLogsForTests();

  group('Intervention choice picker first-order effects (#4267)', () {
    testWidgets(
      'shows situation strip, hold reason, and per-choice Effect lines',
      (WidgetTester tester) async {
        await _pumpChoicePhase(tester, game: _embassyInterventionGame());

        expect(
          find.byKey(const ValueKey<String>(kInterventionChoiceSituationKey)),
          findsOneWidget,
        );
        expect(
          find.text('Castile declared war on Powhatan.'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>(kInterventionHoldReasonKey)),
          findsOneWidget,
        );
        expect(find.text('You hold: Embassy'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>(kInterventionEffectInterveneKey)),
          findsOneWidget,
        );
        expect(
          find.textContaining('Enter war with Castile this turn'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Lose Embassy and all overtures with Powhatan'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Relations with Castile worsen (−10)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Effect copy does not claim treasury cost or purchased-land loss on Do naught',
      (WidgetTester tester) async {
        await _pumpChoicePhase(tester, game: _embassyInterventionGame());

        final String doNothingEffect = tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(kInterventionEffectDoNothingKey),
              ),
            )
            .data!;
        expect(doNothingEffect.toLowerCase(), isNot(contains('treasury')));
        expect(doNothingEffect.toLowerCase(), isNot(contains('lose purchased')));
        expect(doNothingEffect, contains('Purchased land remains'));
      },
    );

    testWidgets(
      'choice picker renders inside scroll view for narrow layouts',
      (WidgetTester tester) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;

        await _pumpChoicePhase(tester, game: _embassyInterventionGame());

        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>(kInterventionEffectProtestKey)),
          findsOneWidget,
        );
      },
    );
  });
}
