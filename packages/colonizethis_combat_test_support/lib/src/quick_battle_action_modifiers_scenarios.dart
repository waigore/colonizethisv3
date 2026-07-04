// Table-driven Quick Battle action-modifier scenarios (Refs #3865).

import 'package:colonizethis_combat/src/combat/quick_battle_action_modifiers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// One row in a Quick Battle action-modifier scenario table.
class QuickBattleActionModifierScenario {
  const QuickBattleActionModifierScenario({
    required this.scenarioId,
    required this.label,
    required this.run,
  });

  final String scenarioId;
  final String label;
  final void Function() run;
}

/// Runs [scenario] (setup + assertions live in [QuickBattleActionModifierScenario.run]).
void runQuickBattleActionModifierScenario(
  QuickBattleActionModifierScenario scenario,
) {
  scenario.run();
}

/// Scenarios for [aggregateActionModifiers].
List<QuickBattleActionModifierScenario> aggregateActionModifiersScenarios() => [
  QuickBattleActionModifierScenario(
    scenarioId: 'qam-neutral',
    label: 'no actions yields neutral 1.0 modifiers',
    run: () {
      final m = aggregateActionModifiers(const []);

      expect(m.offenseModifier, 1.0);
      expect(m.casualtiesDealtModifier, 1.0);
      expect(m.casualtiesTakenModifier, 1.0);
    },
  ),
  QuickBattleActionModifierScenario(
    scenarioId: 'qam-volley',
    label: 'volleyFire raises casualties dealt only',
    run: () {
      final m = aggregateActionModifiers(const [QuickBattleAction.volleyFire]);

      expect(m.casualtiesDealtModifier, closeTo(1.15, 1e-9));
      expect(m.offenseModifier, 1.0);
      expect(m.casualtiesTakenModifier, 1.0);
    },
  ),
  QuickBattleActionModifierScenario(
    scenarioId: 'qam-entrench',
    label: 'defendEntrench lowers casualties taken only',
    run: () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.defendEntrench,
      ]);

      expect(m.casualtiesTakenModifier, closeTo(0.85, 1e-9));
      expect(m.offenseModifier, 1.0);
      expect(m.casualtiesDealtModifier, 1.0);
    },
  ),
  QuickBattleActionModifierScenario(
    scenarioId: 'qam-maneuver',
    label: 'maneuver raises offense only',
    run: () {
      final m = aggregateActionModifiers(const [QuickBattleAction.maneuver]);

      expect(m.offenseModifier, closeTo(1.05, 1e-9));
      expect(m.casualtiesDealtModifier, 1.0);
      expect(m.casualtiesTakenModifier, 1.0);
    },
  ),
  QuickBattleActionModifierScenario(
    scenarioId: 'qam-fallback',
    label: 'fallBackRefuseFlank lowers offense and casualties taken',
    run: () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.fallBackRefuseFlank,
      ]);

      expect(m.offenseModifier, closeTo(0.8, 1e-9));
      expect(m.casualtiesTakenModifier, closeTo(0.75, 1e-9));
      expect(m.casualtiesDealtModifier, 1.0);
    },
  ),
  QuickBattleActionModifierScenario(
    scenarioId: 'qam-assault',
    label: 'assaultCharge raises offense and casualties taken',
    run: () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.assaultCharge,
      ]);

      expect(m.offenseModifier, closeTo(1.25, 1e-9));
      expect(m.casualtiesTakenModifier, closeTo(1.1, 1e-9));
      expect(m.casualtiesDealtModifier, 1.0);
    },
  ),
  QuickBattleActionModifierScenario(
    scenarioId: 'qam-combined',
    label: 'combined actions sum deltas in order',
    run: () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.maneuver,
        QuickBattleAction.volleyFire,
      ]);

      expect(m.offenseModifier, closeTo(1.05, 1e-9));
      expect(m.casualtiesDealtModifier, closeTo(1.15, 1e-9));
      expect(m.casualtiesTakenModifier, 1.0);
    },
  ),
  QuickBattleActionModifierScenario(
    scenarioId: 'qam-assault-clamp-high',
    label: 'repeated assaultCharge clamps offense to 1.5 upper bound',
    run: () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.assaultCharge,
        QuickBattleAction.assaultCharge,
        QuickBattleAction.assaultCharge,
      ]);

      expect(m.offenseModifier, 1.5);
    },
  ),
  QuickBattleActionModifierScenario(
    scenarioId: 'qam-fallback-clamp-low',
    label: 'repeated fallBackRefuseFlank clamps casualties taken to 0.5 floor',
    run: () {
      final m = aggregateActionModifiers(const [
        QuickBattleAction.fallBackRefuseFlank,
        QuickBattleAction.fallBackRefuseFlank,
        QuickBattleAction.fallBackRefuseFlank,
      ]);

      expect(m.casualtiesTakenModifier, 0.5);
      expect(m.offenseModifier, 0.5);
    },
  ),
];
