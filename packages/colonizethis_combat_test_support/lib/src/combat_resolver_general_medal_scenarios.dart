// General-medal scenarios for land resolver (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> combatResolverGeneralMedalScenarios() => [
  RunnableScenario(
    scenarioId: 'crl-winning-general-medal',
    label: 'assigned winning general gains +1 medal immediately and persists',
    run: () {
      final game = landResolverBattleGame(
        turnNumber: 5,
        units: [
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'a2',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'd1',
            type: 'peasant_levies',
            ownerId: 'def',
            locationProvinceId: 'p',
          ),
        ],
        players: landResolverHumanPlayers,
        generals: const [General(id: 'g-att', ownerId: 'att', medals: 1)],
      );
      const ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: ['a1', 'a2'],
            generalId: 'g-att',
            generalMedals: 1,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final after = resolveBattleContext(game, ctx);
      final updatedGeneral = after.generals.firstWhere((g) => g.id == 'g-att');
      expect(updatedGeneral.medals, 2);
    },
  ),
  RunnableScenario(
    scenarioId: 'crl-leader-fallback-no-general',
    label: 'leader fallback medals apply when no uncommitted general exists',
    run: () {
      final game = landResolverBattleGame(
        turnNumber: 3,
        units: [
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'd1',
            type: 'grenadiers',
            ownerId: 'def',
            locationProvinceId: 'p',
          ),
        ],
        players: const [
          Player(
            id: 'att',
            displayName: 'Att',
            isHuman: true,
            leaderKey: 'napoleon',
          ),
          Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['a1']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final after = resolveBattleContext(game, ctx);
      expect(after.generals, isEmpty);
    },
  ),
  RunnableScenario(
    scenarioId: 'crl-general-medal-cap-4',
    label: 'general medals are capped at 4 on immediate engagement win',
    run: () {
      final game = landResolverBattleGame(
        turnNumber: 6,
        units: [
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'a2',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'd1',
            type: 'peasant_levies',
            ownerId: 'def',
            locationProvinceId: 'p',
          ),
        ],
        players: landResolverHumanPlayers,
        generals: const [General(id: 'g-att', ownerId: 'att', medals: 4)],
      );
      const ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['a1', 'a2']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final after = resolveBattleContext(game, ctx);
      final updatedGeneral = after.generals.firstWhere((g) => g.id == 'g-att');
      expect(updatedGeneral.medals, 4);
    },
  ),
];
