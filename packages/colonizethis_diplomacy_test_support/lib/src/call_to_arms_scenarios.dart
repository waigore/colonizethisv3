// Table-driven call-to-arms scenarios (Refs #3837).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'call_to_arms_fixtures.dart';

/// One call-to-arms integration row with preserved [label].
class CallToArmsScenario {
  const CallToArmsScenario({required this.label, required this.run});

  final String label;
  final void Function() run;
}

void runCallToArmsScenario(CallToArmsScenario scenario) => scenario.run();

Orders _gp3DeclareWarOnGp2() => Orders(
  diplomaticOrdersByPlayerId: {
    'gp3': const [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'gp2',
      ),
    ],
  },
);

/// Scenarios from `diplomacy_call_to_arms_test.dart`.
List<CallToArmsScenario> callToArmsScenarios() => [
  CallToArmsScenario(
    label: 'human ally gets pending call to arms when ally GP is declared upon',
    run: () {
      final game = threePowerCallToArmsGame(
        gp1Human: true,
        gp2Human: true,
        gp1gp2Score: 80,
      );
      final result = resolveDiplomacyPhase(game, _gp3DeclareWarOnGp2());
      expect(result.isPending, isTrue);
      expect(result.pendingCallToArms, isNotNull);
      expect(result.pendingCallToArms!.length, 1);
      expect(result.pendingCallToArms!.first.allyGpId, 'gp1');
      expect(result.pendingCallToArms!.first.defenderGpId, 'gp2');
      expect(result.pendingCallToArms!.first.aggressorGpId, 'gp3');
    },
  ),
  CallToArmsScenario(
    label: 'AI ally refuses call to arms when already at war with another GP',
    run: () {
      final game = fourGpCallToArmsAtWarGame();
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp4': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final result = resolveDiplomacyPhase(game, orders);
      expect(result.isPending, isFalse);
      expect(factionsAtWar(result.game, 'gp1', 'gp4'), isFalse);
    },
  ),
  CallToArmsScenario(
    label: 'AI ally accepts when B–A score >= 50: enters war with aggressor',
    run: () {
      final game = threePowerCallToArmsGame(
        gp1Human: false,
        gp2Human: true,
        gp1gp2Score: 80,
      );
      final result = resolveDiplomacyPhase(game, _gp3DeclareWarOnGp2());
      expect(result.isPending, isFalse);
      expect(factionsAtWar(result.game, 'gp1', 'gp3'), isTrue);
    },
  ),
  CallToArmsScenario(
    label:
        'AI ally refuses when B–A score < 50 (allied level edge): no war with aggressor',
    run: () {
      final game = threePowerCallToArmsGame(
        gp1Human: false,
        gp2Human: true,
        gp1gp2Score: 40,
        gp1gp2Level: RelationLevel.allied,
      );
      final result = resolveDiplomacyPhase(game, _gp3DeclareWarOnGp2());
      expect(result.isPending, isFalse);
      expect(factionsAtWar(result.game, 'gp1', 'gp3'), isFalse);
      final rel = getRelation(result.game, 'gp1', 'gp2');
      expect(rel, isNotNull);
      expect(rel!.level, isNot(RelationLevel.allied));
      expect(rel.score, 0);
    },
  ),
  CallToArmsScenario(
    label: 'human accept on resume: at war with aggressor',
    run: () {
      final game = threePowerCallToArmsGame(
        gp1Human: true,
        gp2Human: true,
        gp1gp2Score: 80,
      );
      final orders = _gp3DeclareWarOnGp2();
      final pendingResult = resolveDiplomacyPhase(game, orders);
      expect(pendingResult.pendingCallToArms, isNotNull);
      final resumed = resolveDiplomacyPhase(
        pendingResult.game,
        orders,
        callToArmsDecisions: [
          CallToArmsDecision(
            allyGpId: 'gp1',
            defenderGpId: 'gp2',
            aggressorGpId: 'gp3',
            accepted: true,
          ),
        ],
      );
      expect(resumed.isPending, isFalse);
      expect(factionsAtWar(resumed.game, 'gp1', 'gp3'), isTrue);
    },
  ),
  CallToArmsScenario(
    label: 'human refuse on resume: score drops by 50 and leaves Allied band',
    run: () {
      final game = threePowerCallToArmsGame(
        gp1Human: true,
        gp2Human: true,
        gp1gp2Score: 80,
      );
      final orders = _gp3DeclareWarOnGp2();
      final pendingResult = resolveDiplomacyPhase(game, orders);
      final resumed = resolveDiplomacyPhase(
        pendingResult.game,
        orders,
        callToArmsDecisions: [
          CallToArmsDecision(
            allyGpId: 'gp1',
            defenderGpId: 'gp2',
            aggressorGpId: 'gp3',
            accepted: false,
          ),
        ],
      );
      expect(resumed.isPending, isFalse);
      expect(factionsAtWar(resumed.game, 'gp1', 'gp3'), isFalse);
      final rel = getRelation(resumed.game, 'gp1', 'gp2');
      expect(rel!.score, 30);
      expect(rel.level, RelationLevel.neutral);
    },
  ),
  CallToArmsScenario(
    label:
        'human refuse on resume: formal alliance cleared and allianceBroken logged',
    run: () {
      final game = threePowerCallToArmsGame(
        gp1Human: true,
        gp2Human: true,
        gp1gp2Score: 80,
      );
      final orders = _gp3DeclareWarOnGp2();
      final pendingResult = resolveDiplomacyPhase(game, orders);
      final resumed = resolveDiplomacyPhase(
        pendingResult.game,
        orders,
        callToArmsDecisions: [
          CallToArmsDecision(
            allyGpId: 'gp1',
            defenderGpId: 'gp2',
            aggressorGpId: 'gp3',
            accepted: false,
          ),
        ],
      );
      final rel = getRelation(resumed.game, 'gp1', 'gp2');
      expect(rel!.formalAlliance, isFalse);
      final broken = resumed.game.diplomaticHistoryEvents.where(
        (e) =>
            e.type == DiplomaticEventType.allianceBroken &&
            e.participants.contains('gp1') &&
            e.participants.contains('gp2'),
      );
      expect(broken.length, 1);
    },
  ),
  CallToArmsScenario(
    label:
        'human refuse applies -10 to other GPs but leaves the aggressor unchanged',
    run: () {
      final game = fourGpCallToArmsCascadeGame();
      const orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp3': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final pending = resolveDiplomacyPhase(game, orders);
      expect(pending.pendingCallToArms, isNotNull);
      final resumed = resolveDiplomacyPhase(
        pending.game,
        orders,
        callToArmsDecisions: [
          const CallToArmsDecision(
            allyGpId: 'gp1',
            defenderGpId: 'gp2',
            aggressorGpId: 'gp3',
            accepted: false,
          ),
        ],
      );
      expect(getRelation(resumed.game, 'gp1', 'gp4')!.score, 50);
      expect(getRelation(resumed.game, 'gp1', 'gp3')!.score, 56.0);
    },
  ),
];
