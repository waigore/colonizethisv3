import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/quick_battle_fixtures.dart';

/// Concern-split densify from quick_battle_test (Refs #4571).

void main() {
  group('QuickBattleDeployment', () {
    test('toJson/fromJson round-trips groups and lane terrain', () {
      const deployment = QuickBattleDeployment(
        groups: [
          QuickBattleGroup(
            lane: QuickBattleLane.left,
            line: QuickBattleLine.front,
            unitIds: ['u1'],
          ),
        ],
        laneTerrain: {
          'left': QuickBattleLaneTerrain.hill,
          'center': QuickBattleLaneTerrain.swamp,
        },
      );
      final restored = QuickBattleDeployment.fromJson(deployment.toJson());
      expect(restored.groups, hasLength(1));
      expect(restored.groups.first.unitIds, ['u1']);
      expect(restored.laneTerrain['left'], QuickBattleLaneTerrain.hill);
      expect(restored.laneTerrain['center'], QuickBattleLaneTerrain.swamp);
    });

    test('fromJson handles empty payload and unknown terrain', () {
      final restored = QuickBattleDeployment.fromJson({
        'laneTerrain': {'right': 'unknown-terrain'},
      });
      expect(restored.groups, isEmpty);
      expect(restored.laneTerrain['right'], QuickBattleLaneTerrain.open);
    });

    test('copyWith overrides only provided fields', () {
      const deployment = QuickBattleDeployment();
      final updated = deployment.copyWith(
        laneTerrain: {'left': QuickBattleLaneTerrain.town},
      );
      expect(updated.laneTerrain['left'], QuickBattleLaneTerrain.town);
      expect(updated.groups, isEmpty);
    });
  });
  group('QuickBattleInput', () {
    test('toJson/fromJson round-trips all fields', () {
      final input = sampleQuickBattleInput();
      final restored = QuickBattleInput.fromJson(input.toJson());
      expect(restored.attackerFactionId, 'A');
      expect(restored.defenderFactionId, 'D');
      expect(restored.provinceId, 'r1|p1');
      expect(restored.regionId, 'r1');
      expect(restored.fortLevel, 2);
      expect(restored.emplacedGuns, hasLength(1));
      expect(restored.emplacedGuns.first.id, 'g1');
      expect(restored.provinceTerrain, 'hills');
      expect(restored.seed, 99);
      expect(restored.maxRounds, 4);
      expect(restored.attackerLeaderMultiplier, 1.2);
      expect(restored.defenderLeaderMultiplier, 0.9);
      expect(restored.attackerCavalryShare, 0.3);
      expect(restored.defenderCavalryShare, 0.1);
      expect(restored.attackerGeneralMedals, 2);
      expect(restored.defenderGeneralMedals, 1);
      expect(restored.attackerDeployment.groups.first.unitIds, ['a1']);
      expect(restored.defenderDeployment.groups.first.unitIds, ['d1']);
    });

    test('fromJson applies defaults for optional fields', () {
      final restored = QuickBattleInput.fromJson({
        'attackerFactionId': 'A',
        'defenderFactionId': 'D',
        'provinceId': 'r1|p1',
        'regionId': 'r1',
        'attackerDeployment': const QuickBattleDeployment().toJson(),
        'defenderDeployment': const QuickBattleDeployment().toJson(),
      });
      expect(restored.fortLevel, 0);
      expect(restored.emplacedGuns, isEmpty);
      expect(restored.provinceTerrain, 'plains');
      expect(restored.seed, 0);
      expect(restored.maxRounds, 3);
      expect(restored.attackerLeaderMultiplier, 1.0);
      expect(restored.defenderLeaderMultiplier, 1.0);
      expect(restored.attackerCavalryShare, 0.0);
      expect(restored.defenderCavalryShare, 0.0);
      expect(restored.attackerGeneralMedals, 0);
      expect(restored.defenderGeneralMedals, 0);
    });
  });
  group('QuickBattleRoundActions', () {
    test('defaults to empty action list with null side actions', () {
      const actions = QuickBattleRoundActions();
      expect(actions.actions, isEmpty);
      expect(actions.attackerActions, isNull);
      expect(actions.defenderActions, isNull);
    });

    test('retains side-specific actions', () {
      const actions = QuickBattleRoundActions(
        attackerActions: [QuickBattleAction.assaultCharge],
        defenderActions: [QuickBattleAction.defendEntrench],
      );
      expect(actions.attackerActions, [QuickBattleAction.assaultCharge]);
      expect(actions.defenderActions, [QuickBattleAction.defendEntrench]);
    });
  });
  group('QuickBattleResult', () {
    test('toJson/fromJson round-trips all fields', () {
      const result = QuickBattleResult(
        winner: QuickBattleWinner.attacker,
        attackerCasualties: ['a1'],
        defenderCasualties: ['d1', 'd2'],
        provinceFlips: true,
        attackerRouts: false,
        defenderRouts: true,
        fortDowngradeFromDestroyedEmplaced: true,
        emplacedGunOutcomes: [
          QuickBattleEmplacedGunOutcome(id: 'g1', hp: 0, destroyed: true),
        ],
      );
      final restored = QuickBattleResult.fromJson(result.toJson());
      expect(restored.winner, QuickBattleWinner.attacker);
      expect(restored.attackerCasualties, ['a1']);
      expect(restored.defenderCasualties, ['d1', 'd2']);
      expect(restored.provinceFlips, isTrue);
      expect(restored.attackerRouts, isFalse);
      expect(restored.defenderRouts, isTrue);
      expect(restored.fortDowngradeFromDestroyedEmplaced, isTrue);
      expect(restored.emplacedGunOutcomes, hasLength(1));
      expect(restored.emplacedGunOutcomes.first.destroyed, isTrue);
    });

    test('fromJson falls back to mutualExhaustion for unknown winner', () {
      final restored = QuickBattleResult.fromJson({
        'winner': 'bogus',
        'attackerCasualties': const [],
        'defenderCasualties': const [],
        'provinceFlips': false,
      });
      expect(restored.winner, QuickBattleWinner.mutualExhaustion);
      expect(restored.attackerRouts, isFalse);
      expect(restored.defenderRouts, isFalse);
      expect(restored.fortDowngradeFromDestroyedEmplaced, isFalse);
      expect(restored.emplacedGunOutcomes, isEmpty);
    });
  });
}
