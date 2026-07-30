import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'quick_battle_input_test_support.dart';
import 'scenario_runner.dart';


List<RunnableScenario> quickBattleInputBuilderScenarios() => [
  ..._quickBattleInputBuilderCoreScenarios(),
  ..._quickBattleInputBuilderRegionAndMedalScenarios(),
];

List<RunnableScenario> _quickBattleInputBuilderCoreScenarios() => [
  RunnableScenario(
    scenarioId: 'qbib-groups',
    label: 'produces QuickBattleInput with defender and attacker groups',
    run: () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: 'att',
            locationProvinceId: 'P1',
          ),
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: 'P1',
          ),
        ],
      );
      final input = buildQuickBattleInput(
        game,
        quickBattleInputBuilderContext(),
      );
      expect(input.provinceId, 'P1');
      expect(input.regionId, 'oldWorld');
      expect(input.attackerFactionId, 'att');
      expect(input.defenderFactionId, 'def');
      expect(input.attackerDeployment.groups.length, 1);
      expect(input.attackerDeployment.groups.first.unitIds, ['u1']);
      expect(input.defenderDeployment.groups.length, 1);
      expect(input.defenderDeployment.groups.first.unitIds, ['u2']);
      expect(
        input.attackerDeployment.groups.first.lane,
        QuickBattleLane.center,
      );
      expect(input.attackerDeployment.groups.first.line, QuickBattleLine.front);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbib-filter-missing',
    label: 'filters out unit ids not present in region',
    run: () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: [
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: 'P1',
          ),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['u2', 'missing'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['ghost']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final input = buildQuickBattleInput(game, ctx);
      expect(input.defenderDeployment.groups.first.unitIds, ['u2']);
      expect(input.attackerDeployment.groups.first.unitIds, isEmpty);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbib-leader-multipliers',
    label:
        'supplies leader multipliers from Game players (napoleon 1.25, frederick 1.15)',
    run: () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: 'att',
            locationProvinceId: 'P1',
          ),
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: 'P1',
          ),
        ],
        players: landResolverNapoleonFrederickPlayers,
      );
      final input = buildQuickBattleInput(
        game,
        quickBattleInputBuilderContext(),
      );
      expect(input.attackerLeaderMultiplier, 1.25);
      expect(input.defenderLeaderMultiplier, 1.15);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbib-default-multipliers',
    label: 'leader multipliers default to 1.0 when players have no leaderKey',
    run: () {
      final game = quickBattleInputBuilderGame(
        oldWorldUnits: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: 'att',
            locationProvinceId: 'P1',
          ),
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: 'P1',
          ),
        ],
      );
      final input = buildQuickBattleInput(
        game,
        quickBattleInputBuilderContext(),
      );
      expect(input.attackerLeaderMultiplier, 1.0);
      expect(input.defenderLeaderMultiplier, 1.0);
    },
  ),
];

List<RunnableScenario>
_quickBattleInputBuilderRegionAndMedalScenarios() => [
  RunnableScenario(
    scenarioId: 'qbib-new-world',
    label: 'builds input from newWorld BattleContext',
    run: () {
      const nw = 'newWorld';
      const provinceId = 'newWorld|N1';
      final game = quickBattleInputBuilderNewWorldGame(
        provinceId: provinceId,
        units: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: 'att',
            locationProvinceId: provinceId,
          ),
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: provinceId,
          ),
        ],
      );
      final input = buildQuickBattleInput(
        game,
        quickBattleInputBuilderContext(provinceId: provinceId, regionId: nw),
      );
      expect(input.regionId, nw);
      expect(input.defenderDeployment.groups.first.unitIds, ['u2']);
      expect(input.attackerDeployment.groups.first.unitIds, ['u1']);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbib-assignment-medals',
    label: 'passes attacker and defender medals from battle assignment',
    run: () {
      final game = quickBattleInputBuilderGame(
        turnNumber: 3,
        oldWorldUnits: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: 'att',
            locationProvinceId: 'P1',
          ),
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: 'P1',
          ),
        ],
        generals: const [
          General(id: 'ga', ownerId: 'att', medals: 3),
          General(id: 'gd', ownerId: 'def', medals: 2),
        ],
      );
      final ctx = quickBattleInputBuilderContext();
      final assignment = assignGeneralsForBattleContext(
        game: game,
        ctx: ctx,
        rng: battleAssignmentRng(game, ctx),
        ledger: CombatPhaseGeneralLedger(),
      );
      final input = buildQuickBattleInput(
        game,
        ctx,
        battleAssignment: assignment,
      );
      expect(input.attackerGeneralMedals, 3);
      expect(input.defenderGeneralMedals, 2);
    },
  ),
];
