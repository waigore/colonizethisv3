import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/quick_battle_fixtures.dart';

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
      expect(gun.copyWith(hp: 0).hp, 0);
      expect(gun.copyWith(hp: 0).id, 'g1');
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
}
