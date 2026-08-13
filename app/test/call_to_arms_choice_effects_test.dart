// Pins first-order Effect copy on OVL40001 Call to Arms rows (Refs #4364).
import 'package:colonizethis_app/features/game/widgets/dialogue/call_to_arms_call_row.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/call_to_arms_dialogue_overlay.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Game _ctaGame() {
  return const Game(
    id: 'cta_choice_effects',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(
        id: 'gp_player',
        displayName: 'England',
        isHuman: true,
        treasury: 0,
      ),
      Player(
        id: 'gp_portugal',
        displayName: 'Portugal',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_spain',
        displayName: 'Spain',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_france',
        displayName: 'France',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_holland',
        displayName: 'Holland',
        isHuman: false,
        treasury: 0,
      ),
    ],
  );
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required List<CallToArmsPending> pending,
  required void Function(List<CallToArmsDecision>) onDecisions,
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: CallToArmsDialogueOverlay(
          game: _ctaGame(),
          pending: pending,
          onDecisions: onDecisions,
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'one pending call shows formal-alliance reason and Join/Refuse Effects',
    (tester) async {
      await _pumpOverlay(
        tester,
        pending: const [
          CallToArmsPending(
            allyGpId: 'gp_player',
            defenderGpId: 'gp_portugal',
            aggressorGpId: 'gp_spain',
          ),
        ],
        onDecisions: (_) {},
      );

      expect(
        find.byKey(
          ValueKey(CallToArmsCallRow.formalAllianceReasonKeyFor(0)),
        ),
        findsOneWidget,
      );
      expect(find.text('Formal alliance with Portugal'), findsOneWidget);
      expect(
        find.byKey(ValueKey(CallToArmsCallRow.joinEffectKeyFor(0))),
        findsOneWidget,
      );
      expect(
        find.text(
          'Effect: Enter war with Spain this turn. The treaty with Portugal stays.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey(CallToArmsCallRow.refuseEffectKeyFor(0))),
        findsOneWidget,
      );
      expect(
        find.text(
          'Effect: The treaty with Portugal ends. Relations with Portugal worsen (−50). Standing with other Great Powers worsens (−10).',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Friendly'), findsNothing);
    },
  );

  testWidgets(
    'two pending calls use each row defender/aggressor names only',
    (tester) async {
      await _pumpOverlay(
        tester,
        pending: const [
          CallToArmsPending(
            allyGpId: 'gp_player',
            defenderGpId: 'gp_portugal',
            aggressorGpId: 'gp_spain',
          ),
          CallToArmsPending(
            allyGpId: 'gp_player',
            defenderGpId: 'gp_france',
            aggressorGpId: 'gp_holland',
          ),
        ],
        onDecisions: (_) {},
      );

      expect(find.text('Formal alliance with Portugal'), findsOneWidget);
      expect(find.text('Formal alliance with France'), findsOneWidget);
      expect(
        find.text(
          'Effect: Enter war with Spain this turn. The treaty with Portugal stays.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Effect: Enter war with Holland this turn. The treaty with France stays.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey(CallToArmsCallRow.joinEffectKeyFor(0))),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey(CallToArmsCallRow.joinEffectKeyFor(1))),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Effect lines are read-only: Submit still emits unchanged decisions',
    (tester) async {
      List<CallToArmsDecision>? emitted;
      await _pumpOverlay(
        tester,
        pending: const [
          CallToArmsPending(
            allyGpId: 'gp_player',
            defenderGpId: 'gp_portugal',
            aggressorGpId: 'gp_spain',
          ),
        ],
        onDecisions: (d) => emitted = d,
      );

      await tester.tap(
        find.byKey(ValueKey(CallToArmsCallRow.joinToggleKeyFor(0))),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('callToArmsSubmitButton')));
      await tester.pump();

      expect(emitted, isNotNull);
      expect(emitted, hasLength(1));
      expect(emitted!.single.accepted, isTrue);
      expect(emitted!.single.defenderGpId, 'gp_portugal');
      expect(emitted!.single.aggressorGpId, 'gp_spain');
    },
  );
}
