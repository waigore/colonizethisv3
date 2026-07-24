// Table-driven value-equality scenarios for diplomacy phase result types (Refs #4130).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

class PhaseResultValueTypeScenario {
  const PhaseResultValueTypeScenario({required this.label, required this.run});

  final String label;
  final void Function() run;
}

List<PhaseResultValueTypeScenario> phaseResultValueTypeScenarios() => [
      PhaseResultValueTypeScenario(
        label: 'OvertureOffer value equality',
        run: () {
          OvertureOffer make() => const OvertureOffer(
                offererGpId: 'gp1',
                targetFactionId: 'tribe1',
                stage: OvertureStage.embassy,
              );
          expect(make(), equals(make()));
          expect(make().hashCode, equals(make().hashCode));
          expect(
            make(),
            isNot(const OvertureOffer(
              offererGpId: 'gp2',
              targetFactionId: 'tribe1',
              stage: OvertureStage.embassy,
            )),
          );
          expect(
            make(),
            isNot(const OvertureOffer(
              offererGpId: 'gp1',
              targetFactionId: 'tribe2',
              stage: OvertureStage.embassy,
            )),
          );
          expect(
            make(),
            isNot(const OvertureOffer(
              offererGpId: 'gp1',
              targetFactionId: 'tribe1',
              stage: OvertureStage.nap,
            )),
          );
        },
      ),
      PhaseResultValueTypeScenario(
        label: 'OvertureDecision value equality',
        run: () {
          OvertureDecision make() => const OvertureDecision(
                offererGpId: 'gp1',
                targetFactionId: 'tribe1',
                stage: OvertureStage.embassy,
                accepted: true,
              );
          expect(make(), equals(make()));
          expect(make().hashCode, equals(make().hashCode));
          expect(
            make(),
            isNot(const OvertureDecision(
              offererGpId: 'gp1',
              targetFactionId: 'tribe1',
              stage: OvertureStage.embassy,
              accepted: false,
            )),
          );
          expect(
            make(),
            isNot(const OvertureDecision(
              offererGpId: 'gp1',
              targetFactionId: 'tribe1',
              stage: OvertureStage.nap,
              accepted: true,
            )),
          );
        },
      ),
      PhaseResultValueTypeScenario(
        label: 'InterventionPrompt value equality',
        run: () {
          InterventionPrompt make() => const InterventionPrompt(
                aggressorGpId: 'gp1',
                defenderMinorOrTribeId: 'minor1',
                interveningGpId: 'gp2',
              );
          expect(make(), equals(make()));
          expect(make().hashCode, equals(make().hashCode));
          expect(
            make(),
            isNot(const InterventionPrompt(
              aggressorGpId: 'gpX',
              defenderMinorOrTribeId: 'minor1',
              interveningGpId: 'gp2',
            )),
          );
          expect(
            make(),
            isNot(const InterventionPrompt(
              aggressorGpId: 'gp1',
              defenderMinorOrTribeId: 'minor1',
              interveningGpId: 'gpZ',
            )),
          );
        },
      ),
      PhaseResultValueTypeScenario(
        label: 'InterventionDecision value equality',
        run: () {
          InterventionDecision make() => const InterventionDecision(
                aggressorGpId: 'gp1',
                defenderMinorOrTribeId: 'minor1',
                interveningGpId: 'gp2',
                choice: InterventionChoice.intervene,
              );
          expect(make(), equals(make()));
          expect(make().hashCode, equals(make().hashCode));
          expect(
            make(),
            isNot(const InterventionDecision(
              aggressorGpId: 'gp1',
              defenderMinorOrTribeId: 'minor1',
              interveningGpId: 'gp2',
              choice: InterventionChoice.doNothing,
            )),
          );
          expect(
            make(),
            isNot(const InterventionDecision(
              aggressorGpId: 'gp1',
              defenderMinorOrTribeId: 'minorOther',
              interveningGpId: 'gp2',
              choice: InterventionChoice.intervene,
            )),
          );
        },
      ),
      PhaseResultValueTypeScenario(
        label: 'CallToArmsPending value equality',
        run: () {
          CallToArmsPending make() => const CallToArmsPending(
                allyGpId: 'gp1',
                defenderGpId: 'gp2',
                aggressorGpId: 'gp3',
              );
          expect(make(), equals(make()));
          expect(make().hashCode, equals(make().hashCode));
          expect(
            make(),
            isNot(const CallToArmsPending(
              allyGpId: 'gp1',
              defenderGpId: 'gp2',
              aggressorGpId: 'gpX',
            )),
          );
        },
      ),
      PhaseResultValueTypeScenario(
        label: 'FtpOffer value equality',
        run: () {
          FtpOffer make() =>
              const FtpOffer(proposerGpId: 'gp1', targetGpId: 'gp2');
          expect(make(), equals(make()));
          expect(make().hashCode, equals(make().hashCode));
          expect(
            make(),
            isNot(const FtpOffer(proposerGpId: 'gp1', targetGpId: 'gpZ')),
          );
        },
      ),
      PhaseResultValueTypeScenario(
        label: 'FtpDecision value equality',
        run: () {
          FtpDecision make() => const FtpDecision(
                proposerGpId: 'gp1',
                targetGpId: 'gp2',
                accepted: true,
              );
          expect(make(), equals(make()));
          expect(make().hashCode, equals(make().hashCode));
          expect(
            make(),
            isNot(const FtpDecision(
              proposerGpId: 'gp1',
              targetGpId: 'gp2',
              accepted: false,
            )),
          );
        },
      ),
      PhaseResultValueTypeScenario(
        label: 'CallToArmsDecision value equality',
        run: () {
          CallToArmsDecision make() => const CallToArmsDecision(
                allyGpId: 'gp1',
                defenderGpId: 'gp2',
                aggressorGpId: 'gp3',
                accepted: true,
              );
          expect(make(), equals(make()));
          expect(make().hashCode, equals(make().hashCode));
          expect(
            make(),
            isNot(const CallToArmsDecision(
              allyGpId: 'gp1',
              defenderGpId: 'gp2',
              aggressorGpId: 'gp3',
              accepted: false,
            )),
          );
          expect(
            make(),
            isNot(const CallToArmsDecision(
              allyGpId: 'gp1',
              defenderGpId: 'gpOther',
              aggressorGpId: 'gp3',
              accepted: true,
            )),
          );
        },
      ),
    ];
