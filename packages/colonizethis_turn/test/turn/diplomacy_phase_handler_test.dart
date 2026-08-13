import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import 'diplomacy_phase_handler_cases.dart';

void main() {
  group('diplomacyTurnPhaseHandler', () {
    test('continues pipeline when diplomacy resolves without pending input', () {
      final game = diplomacyPhaseHandlerTwoGpGame(gp2Human: false, score: 50);
      final outcome = diplomacyTurnPhaseHandler(
        TurnPipelineState(game: game),
        diplomacyPhaseHandlerConfig(const Orders()),
        2,
      );
      expect(outcome, isA<TurnPhaseStepContinue>());
    });

    test('exits with TurnResolutionPendingOvertures for human target', () {
      final game = diplomacyPhaseHandlerTwoGpGame(
        gp2Human: true,
        score: 50,
        gp1Treasury: overtureConsulateCost + 100,
      );
      final orders = diplomacyPhaseHandlerOrder(
        DiplomaticOrderType.establishOverture,
        stage: OvertureStage.tradeConsulate,
      );

      final result = runDiplomacyHandlerExpectExit(game: game, orders: orders);

      expect(result, isA<TurnResolutionPendingOvertures>());
      final pending = result as TurnResolutionPendingOvertures;
      expect(pending.pendingOvertures.single.targetFactionId, 'gp2');
    });

    test('exits with TurnResolutionPendingFtp for human target', () {
      final game = diplomacyPhaseHandlerTwoGpGame(
        gp2Human: true,
        score: 70,
        overtures: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'gp2',
            stage: OvertureStage.embassy,
          ),
          OvertureState(
            gpId: 'gp2',
            targetId: 'gp1',
            stage: OvertureStage.embassy,
          ),
        ],
      );
      final orders = diplomacyPhaseHandlerOrder(DiplomaticOrderType.establishFtp);

      final result = runDiplomacyHandlerExpectExit(game: game, orders: orders);

      expect(result, isA<TurnResolutionPendingFtp>());
      final pending = result as TurnResolutionPendingFtp;
      expect(pending.pendingFtpOffers!.single.targetGpId, 'gp2');
    });

    test('exits with TurnResolutionPendingIntervention for embassy holder', () {
      final result = runDiplomacyHandlerExpectExit(
        game: diplomacyPhaseHandlerInterventionGame(),
        orders: diplomacyPhaseHandlerInterventionOrders(),
      );

      expect(result, isA<TurnResolutionPendingIntervention>());
      expect(
        (result as TurnResolutionPendingIntervention)
            .pendingInterventions
            .single
            .interveningGpId,
        'gp1',
      );
    });

    test('exits with TurnResolutionPendingCallToArms for human formal ally', () {
      final result = runDiplomacyHandlerExpectExit(
        game: diplomacyPhaseHandlerCallToArmsGame(),
        orders: diplomacyPhaseHandlerCallToArmsOrders(),
      );

      expect(result, isA<TurnResolutionPendingCallToArms>());
      final pending = result as TurnResolutionPendingCallToArms;
      expect(pending.pendingCallToArms!.single.allyGpId, 'gp1');
      expect(pending.pendingCallToArms!.single.defenderGpId, 'gp2');
      expect(pending.pendingCallToArms!.single.aggressorGpId, 'gp3');
    });
  });
}
