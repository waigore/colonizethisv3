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

Game _multiPromptInterventionGame() {
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

Future<void> _pumpChoicePhase(
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

Future<void> _advancePastSituationYarn(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void _expectNoEffectKeys(WidgetTester tester) {
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
        expect(find.text('Castile declared war on Powhatan.'), findsOneWidget);
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
        expect(
          doNothingEffect.toLowerCase(),
          isNot(contains('lose purchased')),
        );
        expect(doNothingEffect, contains('Purchased land remains'));
      },
    );

    testWidgets('choice picker renders inside scroll view for narrow layouts', (
      WidgetTester tester,
    ) async {
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
    });

    testWidgets(
      'Yarn situation phase does not mount Effect line keys (#4267 negative)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildAppShell(
            child: InterventionDialogueOverlay(
              game: _embassyInterventionGame(),
              prompts: const [
                InterventionPrompt(
                  aggressorGpId: 'gp2',
                  defenderMinorOrTribeId: 'minor1',
                  interveningGpId: 'gp1',
                ),
              ],
              skipIntroForTest: true,
              assetBundle: YarnStringAssetBundle({
                kDialogueInterventionAsset: kYarnInterventionMinimal,
              }),
              onDecisions: (_) {},
              child: const SizedBox.expand(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        _expectNoEffectKeys(tester);
        expect(find.text('Continue'), findsOneWidget);
      },
    );

    testWidgets(
      'does not submit decisions while choice picker is visible (#4267)',
      (WidgetTester tester) async {
        int decisionCallbacks = 0;
        await _pumpChoicePhase(
          tester,
          game: _embassyInterventionGame(),
          onDecisions: (_) => decisionCallbacks++,
        );

        expect(decisionCallbacks, 0);
        expect(
          find.byKey(const ValueKey<String>(kInterventionEffectInterveneKey)),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'multi-prompt batch shows situation and Effects per aggressor/defender pair',
      (WidgetTester tester) async {
        const prompts = [
          InterventionPrompt(
            aggressorGpId: 'gp2',
            defenderMinorOrTribeId: 'minor1',
            interveningGpId: 'gp1',
          ),
          InterventionPrompt(
            aggressorGpId: 'gp3',
            defenderMinorOrTribeId: 'minor2',
            interveningGpId: 'gp1',
          ),
        ];
        await _pumpChoicePhase(
          tester,
          game: _multiPromptInterventionGame(),
          prompts: prompts,
        );

        expect(find.text('Castile declared war on Powhatan.'), findsOneWidget);
        expect(
          find.textContaining('Enter war with Castile this turn'),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>(kInterventionDoNothingButtonKey)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await _advancePastSituationYarn(tester); // reaction Yarn
        await _advancePastSituationYarn(tester); // second prompt situation Yarn

        expect(find.text('France declared war on Creek.'), findsOneWidget);
        expect(
          find.textContaining('Enter war with France this turn'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Lose Embassy and all overtures with Creek'),
          findsOneWidget,
        );
      },
    );
  });
}
