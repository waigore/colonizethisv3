import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.error(StateError('missing intervention yarn'));
  }
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'InterventionDialogueOverlay degraded path submits do-nothing decisions when Yarn fails',
    (WidgetTester tester) async {
      final game = Game(
        id: 'iv_degraded',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
          Player(id: 'gp2', displayName: 'Aggressor', isHuman: false, treasury: 0),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
      );

      const prompts = [
        InterventionPrompt(
          aggressorGpId: 'gp2',
          defenderMinorOrTribeId: 'minor1',
          interveningGpId: 'gp1',
        ),
      ];

      List<InterventionDecision>? captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.colonial,
          home: InterventionDialogueOverlay(
            game: game,
            prompts: prompts,
            skipIntroForTest: true,
            assetBundle: _FailingAssetBundle(),
            onDecisions: (d) => captured = d,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Could not load intervention dialogue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!, hasLength(1));
      expect(captured!.single.choice, InterventionChoice.doNothing);
      expect(captured!.single.aggressorGpId, 'gp2');
      expect(captured!.single.defenderMinorOrTribeId, 'minor1');
      expect(captured!.single.interveningGpId, 'gp1');
    },
  );
}
