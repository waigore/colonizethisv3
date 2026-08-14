import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_intervention_diplomacy_phase_cases.dart';

void main() {
  group('intervention in Diplomacy phase', () {
    test(
      'human with embassy: resume with intervene declares war on aggressor',
      () {
        final game = interventionEmbassyMinorGame(gp1Human: true);
        final orders = interventionDeclareWarOrders('minor1');

        final pending = resolveDiplomacyPhase(game, orders);
        expect(pending.isPending, isTrue);
        expect(pending.pendingInterventions, isNotNull);
        final prompt = pending.pendingInterventions!.single;

        final resumed = resolveDiplomacyPhase(
          pending.game,
          orders,
          interventionDecisions: [
            InterventionDecision(
              aggressorGpId: prompt.aggressorGpId,
              defenderMinorOrTribeId: prompt.defenderMinorOrTribeId,
              interveningGpId: prompt.interveningGpId,
              choice: InterventionChoice.intervene,
            ),
          ],
        );
        expect(resumed.isPending, isFalse);
        final rel = getRelation(resumed.game, 'gp1', 'gp2');
        expect(rel, isNotNull);
        expect(rel!.atWar, isTrue);
      },
    );

    test(
      'AI with embassy: 0% intervene probability clears overtures (do nothing)',
      () {
        final result = resolveDiplomacyPhase(
          interventionEmbassyMinorGame(
            gp1Human: false,
            turnNumber: 5,
            gp1MinorScore: 20,
            gp1MinorLevel: RelationLevel.hostile,
          ),
          interventionDeclareWarOrders('minor1'),
        );
        expect(result.isPending, isFalse);
        expect(getOverture(result.game, 'gp1', 'minor1'), isNull);
        expect(getRelation(result.game, 'gp1', 'gp2')?.atWar, isNot(isTrue));
      },
    );

    test(
      'Tribe defender with purchased land: pending intervention for human holder',
      () {
        final result = resolveDiplomacyPhase(
          interventionTribePurchasedLandGame(),
          interventionDeclareWarOrders('tribe1'),
        );
        expect(result.isPending, isTrue);
        expect(
          result.pendingInterventions!.single.defenderMinorOrTribeId,
          'tribe1',
        );
      },
    );

    test('resolveTurnForGame returns TurnResolutionPendingIntervention', () {
      final orders = interventionDeclareWarOrders('minor1');
      final turnResult = resolveTurnForGame(
        game: interventionEmbassyMinorGame(gp1Human: true, turnNumber: 1),
        topology: const MapTopology(),
        orders: orders,
      );
      expect(turnResult, isA<TurnResolutionPendingIntervention>());
      final pending = turnResult as TurnResolutionPendingIntervention;

      final complete = resumeTurnResolutionWithInterventionDecisions(
        game: pending.game,
        decisions: [
          const InterventionDecision(
            aggressorGpId: 'gp2',
            defenderMinorOrTribeId: 'minor1',
            interveningGpId: 'gp1',
            choice: InterventionChoice.protest,
          ),
        ],
        config: TurnResolverConfig(
          topology: const MapTopology(),
          orders: orders,
        ),
      );
      expect(complete, isA<TurnResolutionComplete>());
      final rel = getRelation(
        (complete as TurnResolutionComplete).game,
        'gp1',
        'gp2',
      );
      expect(rel?.atPeace, isTrue);
      expect(rel!.score, lessThan(50));
    });
  });
}
