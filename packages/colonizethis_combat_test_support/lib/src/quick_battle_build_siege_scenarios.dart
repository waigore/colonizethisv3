// Table-driven buildQuickBattleInput and siege apply scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'quick_battle_build_test_support.dart';
import 'quick_battle_input_test_support.dart';
import 'scenario_runner.dart';

/// Scenarios for [buildQuickBattleInput], emplaced guns, and apply paths.
List<RunnableScenario> quickBattleBuildSiegeScenarios() => [
  RunnableScenario(
    scenarioId: 'qbbs-build-from-context',
    label: 'builds input from BattleContext',
    run: () {
      final game = quickBattleBuildContextGame();
      final ctx = quickBattleBuildContext();
      final input = buildQuickBattleInput(game, ctx, seed: 5);
      expect(input.attackerFactionId, 'att');
      expect(input.defenderFactionId, 'def');
      expect(input.provinceId, 'P1');
      expect(input.attackerDeployment.groups.single.unitIds, ['u1']);
      expect(input.defenderDeployment.groups.single.unitIds, ['u2']);
      expect(input.attackerGeneralMedals, 0);
      expect(input.defenderGeneralMedals, 0);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbbs-napoleon-bonus',
    label:
        'attacker with napoleon bonus wins more often than with reserve (same seed)',
    run: () {
      final fixtures = napoleonLeaderComparisonFixtures();
      final inputReserve = buildQuickBattleInput(
        fixtures.reserve,
        fixtures.ctx,
        seed: 100,
      );
      final inputNapoleon = buildQuickBattleInput(
        fixtures.napoleon,
        fixtures.ctx,
        seed: 100,
      );
      expect(inputReserve.attackerLeaderMultiplier, 1.0);
      expect(inputNapoleon.attackerLeaderMultiplier, 1.25);
      final resultReserve = resolveQuickBattle(inputReserve);
      final resultNapoleon = resolveQuickBattle(inputNapoleon);
      expect(
        resultNapoleon.attackerCasualties.length,
        lessThanOrEqualTo(resultReserve.attackerCasualties.length),
        reason: 'Napoleon bonus should not increase attacker casualties',
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'qbbs-spawn-guns-fort-level',
    label: 'buildQuickBattleInput spawns guns by fort level and stable ids',
    run: () {
      final fixtures = emplacedGunBuildFixtures();
      final input = buildQuickBattleInput(fixtures.game, fixtures.ctx);
      expect(input.emplacedGuns.length, 2);
      expect(input.emplacedGuns[0].id, 'qb:emplaced:oldWorld:P1:0');
      expect(input.emplacedGuns[0].rng, 11);
      expect(
        input.emplacedGuns[0].maxHp,
        emplacedVirtualGunMaxHpByFortLevel[2],
      );
      expect(
        input.emplacedGuns[0].attackStrength,
        closeTo(fortEmplacedStrength[2] * 1.30 * 0.5 * 1.04, 1e-9),
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'qbbs-resolve-duplicate-emplaced',
    label: 'resolveQuickBattle duplicate runs match emplaced outcomes',
    run: () {
      final input = centerFrontQuickBattleInput(
        attackerUnitIds: quickBattleUnitIds('a', 8),
        defenderUnitIds: quickBattleUnitIds('d', 6),
        provinceId: 'p1',
        seed: 12345,
        fortLevel: 1,
        emplacedGuns: [siegeEmplacedGun('qb:emplaced:oldWorld:p1:0', hp: 4)],
      );
      final r1 = resolveQuickBattle(input);
      final r2 = resolveQuickBattle(input);
      expect(
        r1.fortDowngradeFromDestroyedEmplaced,
        r2.fortDowngradeFromDestroyedEmplaced,
      );
      expect(r1.emplacedGunOutcomes.length, r2.emplacedGunOutcomes.length);
      for (var i = 0; i < r1.emplacedGunOutcomes.length; i++) {
        expect(r1.emplacedGunOutcomes[i].id, r2.emplacedGunOutcomes[i].id);
        expect(r1.emplacedGunOutcomes[i].hp, r2.emplacedGunOutcomes[i].hp);
        expect(
          r1.emplacedGunOutcomes[i].destroyed,
          r2.emplacedGunOutcomes[i].destroyed,
        );
      }
      expect(r1.defenderCasualties, r2.defenderCasualties);
      expect(r1.attackerCasualties, r2.attackerCasualties);
    },
  ),
  RunnableScenario(
    scenarioId: 'qbbs-apply-fort-downgrade',
    label:
        'applyQuickBattleResultToGame downgrades fort when flag set without flip',
    run: () {
      final fixtures = fortDowngradeApplyFixtures();
      const result = QuickBattleResult(
        winner: QuickBattleWinner.mutualExhaustion,
        attackerCasualties: [],
        defenderCasualties: [],
        provinceFlips: false,
        fortDowngradeFromDestroyedEmplaced: true,
        emplacedGunOutcomes: [
          QuickBattleEmplacedGunOutcome(id: 'g0', hp: 0, destroyed: true),
        ],
      );
      final after = applyQuickBattleResultToGame(
        fixtures.game,
        fixtures.ctx,
        result,
      );
      final province = after.worldState.oldWorld.provinces.first;
      expect(province.ownerId, 'def');
      expect(province.fortLevel, 1);
    },
  ),
];
