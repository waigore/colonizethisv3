import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('QuickBattleGroup', () {
    test('toJson/fromJson round-trips all fields', () {
      const group = QuickBattleGroup(
        lane: QuickBattleLane.center,
        line: QuickBattleLine.support,
        unitIds: ['u1', 'u2'],
        cohesion: 4,
      );

      final restored = QuickBattleGroup.fromJson(group.toJson());

      expect(restored.lane, QuickBattleLane.center);
      expect(restored.line, QuickBattleLine.support);
      expect(restored.unitIds, ['u1', 'u2']);
      expect(restored.cohesion, 4);
    });

    test('copyWith overrides only provided fields', () {
      const group = QuickBattleGroup(
        lane: QuickBattleLane.left,
        line: QuickBattleLine.front,
      );

      final updated = group.copyWith(lane: QuickBattleLane.right, cohesion: 1);

      expect(updated.lane, QuickBattleLane.right);
      expect(updated.line, QuickBattleLine.front);
      expect(updated.cohesion, 1);
      expect(updated.unitIds, isEmpty);
    });

    test('fromJson falls back to defaults for unknown/missing values', () {
      final restored = QuickBattleGroup.fromJson({
        'lane': 'not-a-lane',
        'line': 'not-a-line',
      });

      expect(restored.lane, QuickBattleLane.left);
      expect(restored.line, QuickBattleLine.front);
      expect(restored.unitIds, isEmpty);
      expect(restored.cohesion, 3);
    });
  });

  group('QuickBattleEmplacedGun', () {
    const gun = QuickBattleEmplacedGun(
      id: 'g1',
      maxHp: 10,
      hp: 7,
      attackStrength: 2.5,
      defenseStrength: 3.5,
      rng: 2,
    );

    test('toJson/fromJson round-trips all fields', () {
      final restored = QuickBattleEmplacedGun.fromJson(gun.toJson());

      expect(restored.id, 'g1');
      expect(restored.maxHp, 10);
      expect(restored.hp, 7);
      expect(restored.attackStrength, 2.5);
      expect(restored.defenseStrength, 3.5);
      expect(restored.rng, 2);
    });

    test('fromJson coerces integer strengths to double', () {
      final restored = QuickBattleEmplacedGun.fromJson({
        'id': 'g2',
        'maxHp': 5,
        'hp': 5,
        'attackStrength': 2,
        'defenseStrength': 4,
        'rng': 1,
      });

      expect(restored.attackStrength, 2.0);
      expect(restored.defenseStrength, 4.0);
    });

    test('copyWith overrides only provided fields', () {
      final updated = gun.copyWith(hp: 0);
      expect(updated.hp, 0);
      expect(updated.id, 'g1');
      expect(updated.maxHp, 10);
    });
  });

  group('QuickBattleEmplacedGunOutcome', () {
    test('toJson/fromJson round-trips', () {
      const outcome = QuickBattleEmplacedGunOutcome(
        id: 'g1',
        hp: 0,
        destroyed: true,
      );

      final restored = QuickBattleEmplacedGunOutcome.fromJson(outcome.toJson());

      expect(restored.id, 'g1');
      expect(restored.hp, 0);
      expect(restored.destroyed, isTrue);
    });

    test('fromJson defaults destroyed to false when absent', () {
      final restored = QuickBattleEmplacedGunOutcome.fromJson({
        'id': 'g3',
        'hp': 4,
      });
      expect(restored.destroyed, isFalse);
    });
  });

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
    QuickBattleInput buildInput() => const QuickBattleInput(
      attackerFactionId: 'A',
      defenderFactionId: 'D',
      provinceId: 'r1|p1',
      regionId: 'r1',
      attackerDeployment: QuickBattleDeployment(
        groups: [
          QuickBattleGroup(
            lane: QuickBattleLane.left,
            line: QuickBattleLine.front,
            unitIds: ['a1'],
          ),
        ],
      ),
      defenderDeployment: QuickBattleDeployment(
        groups: [
          QuickBattleGroup(
            lane: QuickBattleLane.right,
            line: QuickBattleLine.support,
            unitIds: ['d1'],
          ),
        ],
      ),
      fortLevel: 2,
      emplacedGuns: [
        QuickBattleEmplacedGun(
          id: 'g1',
          maxHp: 10,
          hp: 10,
          attackStrength: 3,
          defenseStrength: 5,
          rng: 2,
        ),
      ],
      provinceTerrain: 'hills',
      seed: 99,
      maxRounds: 4,
      attackerLeaderMultiplier: 1.2,
      defenderLeaderMultiplier: 0.9,
      attackerCavalryShare: 0.3,
      defenderCavalryShare: 0.1,
      attackerGeneralMedals: 2,
      defenderGeneralMedals: 1,
    );

    test('toJson/fromJson round-trips all fields', () {
      final restored = QuickBattleInput.fromJson(buildInput().toJson());

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
