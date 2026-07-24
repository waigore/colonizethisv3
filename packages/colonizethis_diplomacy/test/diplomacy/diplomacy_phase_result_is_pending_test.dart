import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('DiplomacyPhaseResult.isPending', () {
    final game = diplomacyGame(
      id: 'g',
      players: const [Player(id: 'gp1', displayName: 'A', isHuman: true)],
    );

    test('negative: no pending lists -> not pending', () {
      expect(DiplomacyPhaseResult(game).isPending, isFalse);
    });

    test('negative: all pending lists empty -> not pending', () {
      final result = DiplomacyPhaseResult(
        game,
        pendingOvertures: const [],
        pendingFtpOffers: const [],
        pendingInterventions: const [],
        pendingCallToArms: const [],
      );
      expect(result.isPending, isFalse);
    });

    test('positive: a pending overture -> pending', () {
      final result = DiplomacyPhaseResult(
        game,
        pendingOvertures: const [
          OvertureOffer(
            offererGpId: 'gp1',
            targetFactionId: 'tribe1',
            stage: OvertureStage.embassy,
          ),
        ],
      );
      expect(result.isPending, isTrue);
    });

    test('positive: a pending FTP offer -> pending', () {
      final result = DiplomacyPhaseResult(
        game,
        pendingFtpOffers: const [
          FtpOffer(proposerGpId: 'gp1', targetGpId: 'gp2'),
        ],
      );
      expect(result.isPending, isTrue);
    });

    test('positive: a pending intervention -> pending', () {
      final result = DiplomacyPhaseResult(
        game,
        pendingInterventions: const [
          InterventionPrompt(
            aggressorGpId: 'gp1',
            defenderMinorOrTribeId: 'minor1',
            interveningGpId: 'gp2',
          ),
        ],
      );
      expect(result.isPending, isTrue);
    });

    test('positive: a pending call to arms -> pending', () {
      final result = DiplomacyPhaseResult(
        game,
        pendingCallToArms: const [
          CallToArmsPending(
            allyGpId: 'gp1',
            defenderGpId: 'gp2',
            aggressorGpId: 'gp3',
          ),
        ],
      );
      expect(result.isPending, isTrue);
    });

    test('result retains the supplied game', () {
      expect(DiplomacyPhaseResult(game).game, same(game));
    });
  });
}
