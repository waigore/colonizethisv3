import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  late Game baseGame;

  setUp(() {
    baseGame = TestFixtures.minimalGame(
      id: 'g1',
      players: [Player(id: 'gp1', displayName: 'A', isHuman: true)],
    );
  });

  group('OvertureOffer', () {
    test('equality and hashCode', () {
      const a = OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 'minor1',
        stage: OvertureStage.tradeConsulate,
      );
      const b = OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 'minor1',
        stage: OvertureStage.tradeConsulate,
      );
      final c = OvertureOffer(
        offererGpId: 'gp2',
        targetFactionId: 'minor1',
        stage: OvertureStage.tradeConsulate,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('equality with non-identical equal instance', () {
      final a = OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 't1',
        stage: OvertureStage.embassy,
      );
      final b = OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 't1',
        stage: OvertureStage.embassy,
      );
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('OvertureDecision', () {
    test('equality and hashCode', () {
      const a = OvertureDecision(
        offererGpId: 'gp1',
        targetFactionId: 'minor1',
        stage: OvertureStage.embassy,
        accepted: true,
      );
      const b = OvertureDecision(
        offererGpId: 'gp1',
        targetFactionId: 'minor1',
        stage: OvertureStage.embassy,
        accepted: true,
      );
      const c = OvertureDecision(
        offererGpId: 'gp1',
        targetFactionId: 'minor1',
        stage: OvertureStage.embassy,
        accepted: false,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('InterventionPrompt', () {
    test('equality and hashCode', () {
      const a = InterventionPrompt(
        aggressorGpId: 'gp2',
        defenderMinorOrTribeId: 'minor1',
        interveningGpId: 'gp1',
      );
      const b = InterventionPrompt(
        aggressorGpId: 'gp2',
        defenderMinorOrTribeId: 'minor1',
        interveningGpId: 'gp1',
      );
      const c = InterventionPrompt(
        aggressorGpId: 'gp3',
        defenderMinorOrTribeId: 'minor1',
        interveningGpId: 'gp1',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('InterventionDecision', () {
    test('equality and hashCode', () {
      const a = InterventionDecision(
        aggressorGpId: 'gp2',
        defenderMinorOrTribeId: 'minor1',
        interveningGpId: 'gp1',
        choice: InterventionChoice.intervene,
      );
      const b = InterventionDecision(
        aggressorGpId: 'gp2',
        defenderMinorOrTribeId: 'minor1',
        interveningGpId: 'gp1',
        choice: InterventionChoice.intervene,
      );
      const c = InterventionDecision(
        aggressorGpId: 'gp2',
        defenderMinorOrTribeId: 'minor1',
        interveningGpId: 'gp1',
        choice: InterventionChoice.protest,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('CallToArms types', () {
    test('CallToArmsPending equality and hashCode', () {
      const a = CallToArmsPending(
        allyGpId: 'gp1',
        defenderGpId: 'gp2',
        aggressorGpId: 'gp3',
      );
      const b = CallToArmsPending(
        allyGpId: 'gp1',
        defenderGpId: 'gp2',
        aggressorGpId: 'gp3',
      );
      const c = CallToArmsPending(
        allyGpId: 'gp9',
        defenderGpId: 'gp2',
        aggressorGpId: 'gp3',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('CallToArmsDecision equality and hashCode', () {
      const a = CallToArmsDecision(
        allyGpId: 'gp1',
        defenderGpId: 'gp2',
        aggressorGpId: 'gp3',
        accepted: true,
      );
      const b = CallToArmsDecision(
        allyGpId: 'gp1',
        defenderGpId: 'gp2',
        aggressorGpId: 'gp3',
        accepted: true,
      );
      const c = CallToArmsDecision(
        allyGpId: 'gp1',
        defenderGpId: 'gp2',
        aggressorGpId: 'gp3',
        accepted: false,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('DiplomacyPhaseResult', () {
    test('isPending true when pendingOvertures non-empty', () {
      final result = DiplomacyPhaseResult(
        baseGame,
        pendingOvertures: [
          OvertureOffer(
            offererGpId: 'gp1',
            targetFactionId: 'gp2',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );
      expect(result.isPending, isTrue);
    });

    test('isPending true when pendingInterventions non-empty', () {
      final result = DiplomacyPhaseResult(
        baseGame,
        pendingInterventions: const [
          InterventionPrompt(
            aggressorGpId: 'gp2',
            defenderMinorOrTribeId: 'minor1',
            interveningGpId: 'gp1',
          ),
        ],
      );
      expect(result.isPending, isTrue);
    });

    test('isPending true when pendingCallToArms non-empty', () {
      final result = DiplomacyPhaseResult(
        baseGame,
        pendingCallToArms: [
          CallToArmsPending(
            allyGpId: 'gp1',
            defenderGpId: 'gp2',
            aggressorGpId: 'gp3',
          ),
        ],
      );
      expect(result.isPending, isTrue);
    });

    test('isPending false when pendingOvertures null', () {
      final result = DiplomacyPhaseResult(baseGame);
      expect(result.isPending, isFalse);
    });

    test('isPending false when pendingOvertures empty', () {
      final result = DiplomacyPhaseResult(baseGame, pendingOvertures: []);
      expect(result.isPending, isFalse);
    });
  });

  group('gameFromTurnResolutionResult', () {
    test('reads carried game for TurnResolutionComplete', () {
      final complete = TurnResolutionComplete(baseGame);
      expect(
        identical(gameFromTurnResolutionResult(complete), baseGame),
        isTrue,
      );
    });

    test('reads carried game for TurnResolutionPendingOvertures', () {
      final pending = TurnResolutionPendingOvertures(
        game: baseGame,
        pendingOvertures: [
          OvertureOffer(
            offererGpId: 'gp1',
            targetFactionId: 'gp2',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );
      expect(
        identical(gameFromTurnResolutionResult(pending), baseGame),
        isTrue,
      );
    });
  });
}
