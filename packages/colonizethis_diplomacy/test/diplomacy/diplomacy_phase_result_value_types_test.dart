import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomacy_game_fixtures.dart';

/// Value-equality and pending-state coverage for the Diplomacy-phase value
/// types in `diplomacy_phase_result.dart` (Refs #3290 test migration —
/// per-package coverage gate for `colonizethis_diplomacy`).
void main() {
  group('OvertureOffer value equality', () {
    OvertureOffer make() => const OvertureOffer(
          offererGpId: 'gp1',
          targetFactionId: 'tribe1',
          stage: OvertureStage.embassy,
        );

    test('positive: equal fields are equal and share a hashCode', () {
      final a = make();
      final b = make();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(identical(a, a), isTrue);
    });

    test('negative: differing offererGpId is unequal', () {
      expect(
        make(),
        isNot(const OvertureOffer(
          offererGpId: 'gp2',
          targetFactionId: 'tribe1',
          stage: OvertureStage.embassy,
        )),
      );
    });

    test('negative: differing targetFactionId is unequal', () {
      expect(
        make(),
        isNot(const OvertureOffer(
          offererGpId: 'gp1',
          targetFactionId: 'tribe2',
          stage: OvertureStage.embassy,
        )),
      );
    });

    test('negative: differing stage is unequal', () {
      expect(
        make(),
        isNot(const OvertureOffer(
          offererGpId: 'gp1',
          targetFactionId: 'tribe1',
          stage: OvertureStage.nap,
        )),
      );
    });
  });

  group('OvertureDecision value equality', () {
    OvertureDecision make() => const OvertureDecision(
          offererGpId: 'gp1',
          targetFactionId: 'tribe1',
          stage: OvertureStage.embassy,
          accepted: true,
        );

    test('positive: equal fields are equal and share a hashCode', () {
      expect(make(), equals(make()));
      expect(make().hashCode, equals(make().hashCode));
    });

    test('negative: differing accepted flag is unequal', () {
      expect(
        make(),
        isNot(const OvertureDecision(
          offererGpId: 'gp1',
          targetFactionId: 'tribe1',
          stage: OvertureStage.embassy,
          accepted: false,
        )),
      );
    });

    test('negative: differing stage is unequal', () {
      expect(
        make(),
        isNot(const OvertureDecision(
          offererGpId: 'gp1',
          targetFactionId: 'tribe1',
          stage: OvertureStage.nap,
          accepted: true,
        )),
      );
    });
  });

  group('InterventionPrompt value equality', () {
    InterventionPrompt make() => const InterventionPrompt(
          aggressorGpId: 'gp1',
          defenderMinorOrTribeId: 'minor1',
          interveningGpId: 'gp2',
        );

    test('positive: equal fields are equal and share a hashCode', () {
      expect(make(), equals(make()));
      expect(make().hashCode, equals(make().hashCode));
    });

    test('negative: differing aggressorGpId is unequal', () {
      expect(
        make(),
        isNot(const InterventionPrompt(
          aggressorGpId: 'gpX',
          defenderMinorOrTribeId: 'minor1',
          interveningGpId: 'gp2',
        )),
      );
    });

    test('negative: differing interveningGpId is unequal', () {
      expect(
        make(),
        isNot(const InterventionPrompt(
          aggressorGpId: 'gp1',
          defenderMinorOrTribeId: 'minor1',
          interveningGpId: 'gpZ',
        )),
      );
    });
  });

  group('InterventionDecision value equality', () {
    InterventionDecision make() => const InterventionDecision(
          aggressorGpId: 'gp1',
          defenderMinorOrTribeId: 'minor1',
          interveningGpId: 'gp2',
          choice: InterventionChoice.intervene,
        );

    test('positive: equal fields are equal and share a hashCode', () {
      expect(make(), equals(make()));
      expect(make().hashCode, equals(make().hashCode));
    });

    test('negative: differing choice is unequal', () {
      expect(
        make(),
        isNot(const InterventionDecision(
          aggressorGpId: 'gp1',
          defenderMinorOrTribeId: 'minor1',
          interveningGpId: 'gp2',
          choice: InterventionChoice.doNothing,
        )),
      );
    });

    test('negative: differing defenderMinorOrTribeId is unequal', () {
      expect(
        make(),
        isNot(const InterventionDecision(
          aggressorGpId: 'gp1',
          defenderMinorOrTribeId: 'minorOther',
          interveningGpId: 'gp2',
          choice: InterventionChoice.intervene,
        )),
      );
    });
  });

  group('CallToArmsPending value equality', () {
    CallToArmsPending make() => const CallToArmsPending(
          allyGpId: 'gp1',
          defenderGpId: 'gp2',
          aggressorGpId: 'gp3',
        );

    test('positive: equal fields are equal and share a hashCode', () {
      expect(make(), equals(make()));
      expect(make().hashCode, equals(make().hashCode));
    });

    test('negative: differing aggressorGpId is unequal', () {
      expect(
        make(),
        isNot(const CallToArmsPending(
          allyGpId: 'gp1',
          defenderGpId: 'gp2',
          aggressorGpId: 'gpX',
        )),
      );
    });
  });

  group('FtpOffer value equality', () {
    FtpOffer make() =>
        const FtpOffer(proposerGpId: 'gp1', targetGpId: 'gp2');

    test('positive: equal fields are equal and share a hashCode', () {
      expect(make(), equals(make()));
      expect(make().hashCode, equals(make().hashCode));
    });

    test('negative: differing targetGpId is unequal', () {
      expect(
        make(),
        isNot(const FtpOffer(proposerGpId: 'gp1', targetGpId: 'gpZ')),
      );
    });
  });

  group('FtpDecision value equality', () {
    FtpDecision make() => const FtpDecision(
          proposerGpId: 'gp1',
          targetGpId: 'gp2',
          accepted: true,
        );

    test('positive: equal fields are equal and share a hashCode', () {
      expect(make(), equals(make()));
      expect(make().hashCode, equals(make().hashCode));
    });

    test('negative: differing accepted flag is unequal', () {
      expect(
        make(),
        isNot(const FtpDecision(
          proposerGpId: 'gp1',
          targetGpId: 'gp2',
          accepted: false,
        )),
      );
    });
  });

  group('CallToArmsDecision value equality', () {
    CallToArmsDecision make() => const CallToArmsDecision(
          allyGpId: 'gp1',
          defenderGpId: 'gp2',
          aggressorGpId: 'gp3',
          accepted: true,
        );

    test('positive: equal fields are equal and share a hashCode', () {
      expect(make(), equals(make()));
      expect(make().hashCode, equals(make().hashCode));
    });

    test('negative: differing accepted flag is unequal', () {
      expect(
        make(),
        isNot(const CallToArmsDecision(
          allyGpId: 'gp1',
          defenderGpId: 'gp2',
          aggressorGpId: 'gp3',
          accepted: false,
        )),
      );
    });

    test('negative: differing defenderGpId is unequal', () {
      expect(
        make(),
        isNot(const CallToArmsDecision(
          allyGpId: 'gp1',
          defenderGpId: 'gpOther',
          aggressorGpId: 'gp3',
          accepted: true,
        )),
      );
    });
  });

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
