import 'package:colonizethis_combat/src/combat/combat_loss_profile.dart';
import 'package:colonizethis_test/test.dart';

import 'scenario_runner.dart';

class CombatLossProfileScenario implements LabeledScenario {
  const CombatLossProfileScenario({
    required this.scenarioId,
    required this.label,
    required this.run,
  });
  final String scenarioId;
  @override
  final String label;
  final void Function() run;
}

List<CombatLossProfileScenario> combatLossProfileForStrengthRatioScenarios() =>
    [
      CombatLossProfileScenario(
        scenarioId: 'clp-low-morale-blunt',
        label: 'blunts strong attacker victory when attacker morale is lower',
        run: () {
          final profile = combatLossProfileForStrengthRatio(
            attackerDefenderStrengthRatio: 2,
            attackerLowMorale: true,
          );
          expect(profile.attackerLossFraction, 0.6);
          expect(profile.defenderLossFraction, 0.4);
          expect(profile.bluntsAttackerVictory, isTrue);
          expect(
            profile.mutualEliminationOutcome,
            CombatMutualEliminationOutcome.mutualAnnihilation,
          );
        },
      ),
      CombatLossProfileScenario(
        scenarioId: 'clp-blunt-upper-bound',
        label: 'uses decisive attacker band at the blunt upper bound',
        run: () {
          final profile = combatLossProfileForStrengthRatio(
            attackerDefenderStrengthRatio: 4,
            attackerLowMorale: true,
          );
          expect(profile.attackerLossFraction, 0.15);
          expect(profile.defenderLossFraction, 1.0);
          expect(profile.bluntsAttackerVictory, isFalse);
          expect(
            profile.mutualEliminationOutcome,
            CombatMutualEliminationOutcome.attackerVictory,
          );
        },
      ),
      CombatLossProfileScenario(
        scenarioId: 'clp-exact-thresholds',
        label: 'keeps exact ratio thresholds in the documented bands',
        run: () {
          final attackerEdge = combatLossProfileForStrengthRatio(
            attackerDefenderStrengthRatio: 1,
            attackerLowMorale: false,
          );
          final strongAttacker = combatLossProfileForStrengthRatio(
            attackerDefenderStrengthRatio: 1.5,
            attackerLowMorale: false,
          );
          final strongDefender = combatLossProfileForStrengthRatio(
            attackerDefenderStrengthRatio: 0.67,
            attackerLowMorale: false,
          );
          expect(attackerEdge.attackerLossFraction, 0.3);
          expect(attackerEdge.defenderLossFraction, 0.6);
          expect(strongAttacker.attackerLossFraction, 0.15);
          expect(strongAttacker.defenderLossFraction, 1.0);
          expect(strongDefender.attackerLossFraction, 1.0);
          expect(strongDefender.defenderLossFraction, 0.15);
        },
      ),
      CombatLossProfileScenario(
        scenarioId: 'clp-close-fight',
        label: 'uses default close-fight profile below attacker edge',
        run: () {
          final profile = combatLossProfileForStrengthRatio(
            attackerDefenderStrengthRatio: 0.9,
            attackerLowMorale: false,
          );
          expect(profile.attackerLossFraction, 0.5);
          expect(profile.defenderLossFraction, 0.4);
          expect(profile.bluntsAttackerVictory, isFalse);
          expect(
            profile.mutualEliminationOutcome,
            CombatMutualEliminationOutcome.mutualAnnihilation,
          );
        },
      ),
    ];
List<CombatLossProfileScenario> classifyCombatStrengthRatioBandScenarios() => [
  CombatLossProfileScenario(
    scenarioId: 'clp-strong-striker',
    label: 'classifies at and above the strong-striker threshold',
    run: () {
      expect(
        classifyCombatStrengthRatioBand(kStrongStrikerStrengthRatioThreshold),
        CombatStrengthRatioBand.strongStriker,
      );
      expect(
        classifyCombatStrengthRatioBand(3.0),
        CombatStrengthRatioBand.strongStriker,
      );
    },
  ),
  CombatLossProfileScenario(
    scenarioId: 'clp-strong-target',
    label: 'classifies at and below the strong-target threshold',
    run: () {
      expect(
        classifyCombatStrengthRatioBand(kStrongTargetStrengthRatioThreshold),
        CombatStrengthRatioBand.strongTarget,
      );
      expect(
        classifyCombatStrengthRatioBand(0.1),
        CombatStrengthRatioBand.strongTarget,
      );
    },
  ),
  CombatLossProfileScenario(
    scenarioId: 'clp-even',
    label: 'classifies the open interval between thresholds as even',
    run: () {
      expect(
        classifyCombatStrengthRatioBand(1.0),
        CombatStrengthRatioBand.even,
      );
      expect(
        classifyCombatStrengthRatioBand(1.49),
        CombatStrengthRatioBand.even,
      );
      expect(
        classifyCombatStrengthRatioBand(0.68),
        CombatStrengthRatioBand.even,
      );
    },
  ),
  CombatLossProfileScenario(
    scenarioId: 'clp-breakpoints',
    label: 'exposes the canonical breakpoint values',
    run: () {
      expect(kStrongStrikerStrengthRatioThreshold, 1.5);
      expect(kStrongTargetStrengthRatioThreshold, 0.67);
    },
  ),
];
List<CombatLossProfileScenario> combatCasualtyCountScenarios() => [
  CombatLossProfileScenario(
    scenarioId: 'clp-casualty-round-clamp',
    label: 'rounds fractional losses up and clamps to available units',
    run: () {
      expect(combatCasualtyCount(unitCount: 3, lossFraction: 0.15), 1);
      expect(combatCasualtyCount(unitCount: 5, lossFraction: 0), 0);
      expect(combatCasualtyCount(unitCount: 2, lossFraction: 1.5), 2);
      expect(combatCasualtyCount(unitCount: 0, lossFraction: 0.6), 0);
    },
  ),
];
