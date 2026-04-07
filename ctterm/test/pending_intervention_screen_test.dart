// Pending intervention submit mapping. SPEC/tui/screens/pending-intervention.md.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:ctterm/screens/pending_intervention_screen.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('buildInterventionDecisionsForSubmit', () {
    test('maps each prompt to a decision with the matching choice', () {
      const prompts = [
        InterventionPrompt(
          aggressorGpId: 'a1',
          defenderMinorOrTribeId: 'm1',
          interveningGpId: 'h1',
        ),
        InterventionPrompt(
          aggressorGpId: 'a2',
          defenderMinorOrTribeId: 't1',
          interveningGpId: 'h2',
        ),
      ];
      const choices = [
        InterventionChoice.intervene,
        InterventionChoice.protest,
      ];

      final out = buildInterventionDecisionsForSubmit(
        prompts: prompts,
        choices: choices,
      );

      expect(out, hasLength(2));
      expect(out[0].aggressorGpId, 'a1');
      expect(out[0].defenderMinorOrTribeId, 'm1');
      expect(out[0].interveningGpId, 'h1');
      expect(out[0].choice, InterventionChoice.intervene);
      expect(out[1].aggressorGpId, 'a2');
      expect(out[1].choice, InterventionChoice.protest);
    });

    test('throws when prompts and choices lengths differ', () {
      const prompts = [
        InterventionPrompt(
          aggressorGpId: 'a',
          defenderMinorOrTribeId: 'm',
          interveningGpId: 'h',
        ),
      ];
      expect(
        () => buildInterventionDecisionsForSubmit(
          prompts: prompts,
          choices: const [
            InterventionChoice.doNothing,
            InterventionChoice.protest,
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('PendingInterventionScreen', () {
    test('constructs with required parameters', () {
      final game = Game(
        id: 't1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
      );
      var invoked = false;
      final screen = PendingInterventionScreen(
        game: game,
        prompts: const [
          InterventionPrompt(
            aggressorGpId: 'gp2',
            defenderMinorOrTribeId: 'minor1',
            interveningGpId: 'gp1',
          ),
        ],
        onDecisions: (_) => invoked = true,
      );

      expect(screen.game, game);
      expect(screen.prompts, hasLength(1));
      screen.onDecisions(const []);
      expect(invoked, isTrue);
    });
  });
}
