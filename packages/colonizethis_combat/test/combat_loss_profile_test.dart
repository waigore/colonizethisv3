import 'package:colonizethis_combat/src/combat/combat_loss_profile.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('combatLossProfileForStrengthRatio', () {
    test('blunts strong attacker victory when attacker morale is lower', () {
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
    });

    test('uses decisive attacker band at the blunt upper bound', () {
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
    });

    test('keeps exact ratio thresholds in the documented bands', () {
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
    });

    test('uses default close-fight profile below attacker edge', () {
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
    });
  });

  group('classifyCombatStrengthRatioBand (shared #3448 thresholds)', () {
    test('classifies at and above the strong-striker threshold', () {
      expect(
        classifyCombatStrengthRatioBand(kStrongStrikerStrengthRatioThreshold),
        CombatStrengthRatioBand.strongStriker,
      );
      expect(
        classifyCombatStrengthRatioBand(3.0),
        CombatStrengthRatioBand.strongStriker,
      );
    });

    test('classifies at and below the strong-target threshold', () {
      expect(
        classifyCombatStrengthRatioBand(kStrongTargetStrengthRatioThreshold),
        CombatStrengthRatioBand.strongTarget,
      );
      expect(
        classifyCombatStrengthRatioBand(0.1),
        CombatStrengthRatioBand.strongTarget,
      );
    });

    test('classifies the open interval between thresholds as even', () {
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
    });

    test('exposes the canonical breakpoint values', () {
      expect(kStrongStrikerStrengthRatioThreshold, 1.5);
      expect(kStrongTargetStrengthRatioThreshold, 0.67);
    });
  });

  group('combatCasualtyCount', () {
    test('rounds fractional losses up and clamps to available units', () {
      expect(combatCasualtyCount(unitCount: 3, lossFraction: 0.15), 1);
      expect(combatCasualtyCount(unitCount: 5, lossFraction: 0), 0);
      expect(combatCasualtyCount(unitCount: 2, lossFraction: 1.5), 2);
      expect(combatCasualtyCount(unitCount: 0, lossFraction: 0.6), 0);
    });
  });
}
