// Table-driven combat mode selection scenarios (Refs #3865).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'scenario_runner.dart';



List<RunnableScenario> isCapitalSiegeScenarios() => [
  RunnableScenario(
    scenarioId: 'cms-not-siege-no-fort',
    label: 'returns false when not a siege (no fort)',
    run: () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'capital',
          ),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'capital',
        regionId: 'oldWorld',
        defenderFactionId: 'p1',
        defenderUnitIds: ['u1'],
        attackers: [AttackingSide(factionId: 'p2', unitIds: ['u2'])],
        fortLevel: 0,
        terrain: 'plains',
      );
      expect(isCapitalSiege(game, ctx), isFalse);
    },
  ),
  RunnableScenario(
    scenarioId: 'cms-siege-not-capital',
    label: 'returns false when siege but province is not a capital',
    run: () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'capital',
          ),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'other',
        regionId: 'oldWorld',
        defenderFactionId: 'p1',
        defenderUnitIds: ['u1'],
        attackers: [AttackingSide(factionId: 'p2', unitIds: ['u2'])],
        fortLevel: 1,
        terrain: 'plains',
      );
      expect(isCapitalSiege(game, ctx), isFalse);
    },
  ),
  RunnableScenario(
    scenarioId: 'cms-siege-gp-capital',
    label: 'returns true when siege of GP capital',
    run: () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: 'capital',
          ),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'capital',
        regionId: 'oldWorld',
        defenderFactionId: 'p1',
        defenderUnitIds: ['u1'],
        attackers: [AttackingSide(factionId: 'p2', unitIds: ['u2'])],
        fortLevel: 1,
        terrain: 'plains',
      );
      expect(isCapitalSiege(game, ctx), isTrue);
    },
  ),
];

List<RunnableScenario> resolveCombatModeForBattleScenarios() => [
  RunnableScenario(
    scenarioId: 'cms-capital-siege-qb',
    label: 'capital siege always returns QuickBattle',
    run: () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'p1', displayName: 'P1', isHuman: true, capitalProvinceId: 'capital'),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'capital',
        regionId: 'oldWorld',
        defenderFactionId: 'p1',
        defenderUnitIds: ['u1'],
        attackers: [AttackingSide(factionId: 'p2', unitIds: ['u2'])],
        fortLevel: 1,
        terrain: 'plains',
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
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'p1', displayName: 'P1', isHuman: true, capitalProvinceId: 'capital'),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'prov',
        regionId: 'oldWorld',
        defenderFactionId: 'p1',
        defenderUnitIds: ['u1'],
        attackers: [AttackingSide(factionId: 'p2', unitIds: ['u2'])],
        fortLevel: 0,
        terrain: 'plains',
      );
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
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [
          Player(id: 'p1', displayName: 'P1', isHuman: true, capitalProvinceId: 'capital'),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'prov',
        regionId: 'oldWorld',
        defenderFactionId: 'p1',
        defenderUnitIds: ['u1'],
        attackers: [AttackingSide(factionId: 'p2', unitIds: ['u2'])],
        fortLevel: 0,
        terrain: 'plains',
      );
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
