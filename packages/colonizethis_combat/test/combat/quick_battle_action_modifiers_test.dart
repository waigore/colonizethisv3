import 'package:colonizethis_combat/src/combat/quick_battle_action_modifiers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('aggregateActionModifiers', () {
    test('no actions yields neutral 1.0 modifiers', () {
      final m = aggregateActionModifiers(const []);

      expect(m.offenseModifier, 1.0);
      expect(m.casualtiesDealtModifier, 1.0);
      expect(m.casualtiesTakenModifier, 1.0);
    });

    test('volleyFire raises casualties dealt only', () {
      final m = aggregateActionModifiers(const [QuickBattleAction.volleyFire]);

      expect(m.casualtiesDealtModifier, closeTo(1.15, 1e-9));
      expect(m.offenseModifier, 1.0);
      expect(m.casualtiesTakenModifier, 1.0);
    });

    test('defendEntrench lowers casualties taken only', () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.defendEntrench,
      ]);

      expect(m.casualtiesTakenModifier, closeTo(0.85, 1e-9));
      expect(m.offenseModifier, 1.0);
      expect(m.casualtiesDealtModifier, 1.0);
    });

    test('maneuver raises offense only', () {
      final m = aggregateActionModifiers(const [QuickBattleAction.maneuver]);

      expect(m.offenseModifier, closeTo(1.05, 1e-9));
      expect(m.casualtiesDealtModifier, 1.0);
      expect(m.casualtiesTakenModifier, 1.0);
    });

    test('fallBackRefuseFlank lowers offense and casualties taken', () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.fallBackRefuseFlank,
      ]);

      expect(m.offenseModifier, closeTo(0.8, 1e-9));
      expect(m.casualtiesTakenModifier, closeTo(0.75, 1e-9));
      expect(m.casualtiesDealtModifier, 1.0);
    });

    test('assaultCharge raises offense and casualties taken', () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.assaultCharge,
      ]);

      expect(m.offenseModifier, closeTo(1.25, 1e-9));
      expect(m.casualtiesTakenModifier, closeTo(1.1, 1e-9));
      expect(m.casualtiesDealtModifier, 1.0);
    });

    test('combined actions sum deltas in order', () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.maneuver,
        QuickBattleAction.volleyFire,
      ]);

      expect(m.offenseModifier, closeTo(1.05, 1e-9));
      expect(m.casualtiesDealtModifier, closeTo(1.15, 1e-9));
      expect(m.casualtiesTakenModifier, 1.0);
    });

    test('repeated assaultCharge clamps offense to 1.5 upper bound', () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.assaultCharge,
        QuickBattleAction.assaultCharge,
        QuickBattleAction.assaultCharge,
      ]);

      expect(m.offenseModifier, 1.5);
    });

    test('repeated fallBackRefuseFlank clamps casualties taken to 0.5 floor', () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.fallBackRefuseFlank,
        QuickBattleAction.fallBackRefuseFlank,
        QuickBattleAction.fallBackRefuseFlank,
      ]);

      expect(m.casualtiesTakenModifier, 0.5);
      expect(m.offenseModifier, 0.5);
    });
  });
}
