import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

// Deep imports of the per-interaction value-type files: each file must be
// self-contained and constructible without the aggregator
// `diplomacy_phase_result.dart` (Refs #3419 step 9).
import 'package:colonizethis_diplomacy/src/diplomacy/phase_types/call_to_arms_pending.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/phase_types/ftp_offer.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/phase_types/intervention_prompt.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/phase_types/overture_offer.dart';

// Aggregator must continue to re-export every value type (preserved public
// surface for the package barrel and the turn package's narrow re-export).
import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_phase_result.dart'
    as aggregator;

/// Gates that splitting `diplomacy_phase_result.dart` into one file per
/// interaction family (Refs #3419 step 9) is behaviour-preserving: each new
/// file is independently importable and the aggregator still exposes the full
/// symbol surface.
void main() {
  group('per-type files are self-contained (deep import)', () {
    test('positive: each value type is constructible from its own file', () {
      const overture = OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 'gp2',
        stage: OvertureStage.embassy,
      );
      const overtureDecision = OvertureDecision(
        offererGpId: 'gp1',
        targetFactionId: 'gp2',
        stage: OvertureStage.embassy,
        accepted: true,
      );
      const ftp = FtpOffer(proposerGpId: 'gp1', targetGpId: 'gp2');
      const ftpDecision =
          FtpDecision(proposerGpId: 'gp1', targetGpId: 'gp2', accepted: false);
      const intervention = InterventionPrompt(
        aggressorGpId: 'gp1',
        defenderMinorOrTribeId: 'minor1',
        interveningGpId: 'gp2',
      );
      const interventionDecision = InterventionDecision(
        aggressorGpId: 'gp1',
        defenderMinorOrTribeId: 'minor1',
        interveningGpId: 'gp2',
        choice: InterventionChoice.intervene,
      );
      const callToArms = CallToArmsPending(
        allyGpId: 'gp1',
        defenderGpId: 'gp2',
        aggressorGpId: 'gp3',
      );
      const callToArmsDecision = CallToArmsDecision(
        allyGpId: 'gp1',
        defenderGpId: 'gp2',
        aggressorGpId: 'gp3',
        accepted: true,
      );

      expect(overture.stage, OvertureStage.embassy);
      expect(overtureDecision.accepted, isTrue);
      expect(ftp.targetGpId, 'gp2');
      expect(ftpDecision.accepted, isFalse);
      expect(intervention.interveningGpId, 'gp2');
      expect(interventionDecision.choice, InterventionChoice.intervene);
      expect(callToArms.aggressorGpId, 'gp3');
      expect(callToArmsDecision.accepted, isTrue);
    });

    test('negative: deep-import and aggregator-exported types are identical',
        () {
      // The aggregator re-export must resolve to the same class as the deep
      // import (no shadow/duplicate type introduced by the split).
      const fromFile = OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 'gp2',
        stage: OvertureStage.nap,
      );
      const aggregator.OvertureOffer fromAggregator = OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 'gp2',
        stage: OvertureStage.nap,
      );
      expect(fromFile, equals(fromAggregator));
      expect(fromFile.runtimeType, fromAggregator.runtimeType);
    });
  });

  group('aggregator re-exports preserve the full value-type surface', () {
    test('positive: DiplomacyPhaseResult builds with each pending list', () {
      final game = diplomacyGame(
        id: 'g',
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: true)],
      );
      final result = aggregator.DiplomacyPhaseResult(
        game,
        pendingOvertures: const [
          OvertureOffer(
            offererGpId: 'gp1',
            targetFactionId: 'gp2',
            stage: OvertureStage.embassy,
          ),
        ],
        pendingFtpOffers: const [
          FtpOffer(proposerGpId: 'gp1', targetGpId: 'gp2'),
        ],
        pendingInterventions: const [
          InterventionPrompt(
            aggressorGpId: 'gp1',
            defenderMinorOrTribeId: 'minor1',
            interveningGpId: 'gp2',
          ),
        ],
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
  });
}
