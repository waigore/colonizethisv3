// Golden for intervention choice-picker Effect presentation (Refs #4267).
import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/intervention_choice_buttons.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
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

void main() {
  suppressLogsForTests();

  testWidgets(
    'choice picker Effect presentation golden under editorial-monocle (#4267)',
    (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const boundaryKey = ValueKey<String>(
        'intervention_choice_picker_effects_golden',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 800),
        settle: false,
        includeLocalizations: true,
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
          child: const ColoredBox(color: Color(0xFF101014)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.byKey(const ValueKey<String>(kInterventionChoiceSituationKey)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>(kInterventionEffectInterveneKey)),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/intervention_choice_picker_effects.png'),
      );
    },
  );
}
