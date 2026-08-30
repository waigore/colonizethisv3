// Table-driven resolveCombatModeForBattle scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_mode_selection_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> resolveCombatModeForBattleScenarios() => [
  RunnableScenario(
    scenarioId: 'cms-capital-siege-qb',
    label: 'capital siege always returns QuickBattle',
    run: () {
      final game = capitalSiegeFixtureGame(includeAttackerPlayer: true);
      final ctx = capitalSiegeBattleContext(
        provinceId: 'capital',
        fortLevel: 1,
      );
      expect(
        resolveCombatModeForBattle(
          game,
          ctx,
          defaultMode: CombatMode.autoResolve,
        ),
        CombatMode.quickBattle,
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'cms-default-mode',
    label: 'uses default when no per-battle override',
    run: () {
      final game = capitalSiegeFixtureGame(includeAttackerPlayer: true);
      final ctx = capitalSiegeBattleContext(provinceId: 'prov', fortLevel: 0);
      expect(
        resolveCombatModeForBattle(
          game,
          ctx,
          defaultMode: CombatMode.autoResolve,
        ),
        CombatMode.autoResolve,
      );
      expect(
        resolveCombatModeForBattle(
          game,
          ctx,
          defaultMode: CombatMode.quickBattle,
        ),
        CombatMode.quickBattle,
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'cms-per-battle-override',
    label: 'uses per-battle override when provided',
    run: () {
      final game = capitalSiegeFixtureGame(includeAttackerPlayer: true);
      final ctx = capitalSiegeBattleContext(provinceId: 'prov', fortLevel: 0);
      expect(
        resolveCombatModeForBattle(
          game,
          ctx,
          defaultMode: CombatMode.autoResolve,
          perBattleOverrides: {'prov': CombatMode.quickBattle},
        ),
        CombatMode.quickBattle,
      );
      expect(
        resolveCombatModeForBattle(
          game,
          ctx,
          defaultMode: CombatMode.quickBattle,
          perBattleOverrides: {'prov': CombatMode.autoResolve},
        ),
        CombatMode.autoResolve,
      );
    },
  ),
];
